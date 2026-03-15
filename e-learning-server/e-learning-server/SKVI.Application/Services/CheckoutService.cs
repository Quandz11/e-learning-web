using System.Globalization;
using System.Security.Cryptography;
using System.Text.Json;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using SKVI.Application.DTOs.Payments;
using SKVI.Application.Interfaces;
using SKVI.Domain.Entities;
using SKVI.Infrastructure;
using SKVI.Infrastructure.Services;

namespace SKVI.Application.Services;

public class CheckoutService : ICheckoutService
{
    private const string OrderStatusPending = "PENDING";
    private const string OrderStatusPaid = "PAID";
    private const string OrderStatusFailed = "FAILED";
    private const string OrderStatusCancelled = "CANCELLED";

    private readonly ApplicationDbContext _context;
    private readonly IPayOSService _payOSService;
    private readonly PayOSSettings _payOSSettings;
    private readonly ILogger<CheckoutService> _logger;

    public CheckoutService(
        ApplicationDbContext context,
        IPayOSService payOSService,
        IOptions<PayOSSettings> payOSSettings,
        ILogger<CheckoutService> logger)
    {
        _context = context;
        _payOSService = payOSService;
        _payOSSettings = payOSSettings.Value;
        _logger = logger;
    }

    public async Task<ReferralPreviewResponse?> PreviewReferralAsync(string referralCode, CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(referralCode))
        {
            return null;
        }

        var cabin = await FindActiveCabinByReferralCodeAsync(referralCode, includeOwner: true, cancellationToken);
        if (cabin == null)
        {
            return null;
        }

        return new ReferralPreviewResponse
        {
            ReferralCode = cabin.ReferralCode ?? NormalizeReferralCode(referralCode),
            CabinId = cabin.Id.ToString(),
            CabinName = cabin.Name,
            OwnerUserId = cabin.OwnerUserId.ToString(),
            OwnerName = FirstNonEmpty(cabin.OwnerUser?.FullName, cabin.OwnerUser?.Email, cabin.Name) ?? cabin.Name
        };
    }

    public async Task<CheckoutResponse> CreateCheckoutAsync(Guid userId, CheckoutRequest request, CancellationToken cancellationToken = default)
    {
        if (request.CourseIds == null || request.CourseIds.Count == 0)
        {
            throw new ArgumentException("CourseIds is required");
        }

        var courseIds = ParseCourseIds(request.CourseIds);
        if (courseIds.Count == 0)
        {
            throw new ArgumentException("CourseIds is required");
        }

        var courses = await _context.Courses
            .AsNoTracking()
            .Where(c => courseIds.Contains(c.Id) && c.IsPublished)
            .ToListAsync(cancellationToken);

        if (courses.Count != courseIds.Count)
        {
            throw new InvalidOperationException("One or more courses are not found or not published");
        }

        var alreadyEnrolledCourseIds = await _context.Enrollments
            .AsNoTracking()
            .Where(e => e.UserId == userId && e.Status == "ACTIVE" && courseIds.Contains(e.CourseId))
            .Select(e => e.CourseId)
            .ToListAsync(cancellationToken);

        if (alreadyEnrolledCourseIds.Count > 0)
        {
            throw new InvalidOperationException("You already enrolled one or more selected courses.");
        }

        Cabin? cabin = null;
        if (!string.IsNullOrWhiteSpace(request.ReferralCode))
        {
            cabin = await FindActiveCabinByReferralCodeAsync(request.ReferralCode, includeOwner: false, cancellationToken);

            if (cabin == null)
            {
                throw new InvalidOperationException("Invalid referral code.");
            }
        }

        var payableCourses = courses.Where(c => !c.IsFree).ToList();
        var hasPaidCourse = payableCourses.Count > 0;
        var payableAmount = payableCourses.Sum(c => c.Price);
        var requiresPayment = hasPaidCourse;

        if (requiresPayment && payableAmount <= 0)
        {
            throw new InvalidOperationException("Selected paid courses are misconfigured. Please contact support.");
        }

        var paymentMethod = await EnsureVietQrPaymentMethodAsync(cancellationToken);
        var now = DateTime.UtcNow;

        var order = new Order
        {
            Id = Guid.NewGuid(),
            BuyerId = userId,
            CabinId = cabin?.Id,
            TotalAmount = payableAmount,
            Status = OrderStatusPending,
            LastPaymentStatus = OrderStatusPending,
            CreatedAt = now,
            ExpiresAt = requiresPayment ? now.AddMinutes(Math.Max(1, _payOSSettings.ExpiredMinutes)) : null
        };

        if (requiresPayment)
        {
            order.PayOSOrderCode = await GenerateUniquePayOSOrderCodeAsync(cancellationToken);
        }

        var courseLookup = courses.ToDictionary(c => c.Id, c => c);
        var orderItems = courses
            .Select(c => new OrderItem
            {
                Id = Guid.NewGuid(),
                OrderId = order.Id,
                CourseId = c.Id,
                Price = c.IsFree ? 0 : c.Price
            })
            .ToList();

        var paymentTransaction = new PaymentTransaction
        {
            Id = Guid.NewGuid(),
            OrderId = order.Id,
            PaymentMethodId = paymentMethod.Id,
            Provider = "PAYOS",
            Amount = payableAmount,
            Status = requiresPayment ? "INIT" : "SUCCESS",
            CreatedAt = now
        };

        _context.Orders.Add(order);
        _context.OrderItems.AddRange(orderItems);
        _context.PaymentTransactions.Add(paymentTransaction);

        if (!requiresPayment)
        {
            order.Status = OrderStatusPaid;
            order.LastPaymentStatus = OrderStatusPaid;
            order.PaidAt = now;

            await _context.SaveChangesAsync(cancellationToken);
            await CompletePaidOrderAsync(order.Id, cancellationToken);

            return BuildCheckoutResponse(order, orderItems, courses, null, null, null, false, null);
        }

        var amountInt = ConvertVndAmount(payableAmount);
        var payOSOrderCode = order.PayOSOrderCode ?? throw new InvalidOperationException("PayOS order code was not generated.");
        var description = BuildPayOSDescription(payOSOrderCode);
        var cancelUrl = _payOSSettings.CancelUrl;
        var returnUrl = _payOSSettings.ReturnUrl;
        var expiredAtUnix = (int)new DateTimeOffset(order.ExpiresAt ?? now.AddMinutes(15)).ToUnixTimeSeconds();
        var payableOrderItems = orderItems
            .Where(i => courseLookup.TryGetValue(i.CourseId, out var course) && !course.IsFree)
            .ToList();

        if (payableOrderItems.Count == 0)
        {
            throw new InvalidOperationException("No payable items found for payment request.");
        }

        var createLinkRequest = new PayOSCreatePaymentLinkRequest
        {
            OrderCode = payOSOrderCode,
            Amount = amountInt,
            Description = description,
            CancelUrl = cancelUrl,
            ReturnUrl = returnUrl,
            ExpiredAt = expiredAtUnix,
            Items = payableOrderItems.Select(i => new PayOSItemRequest
            {
                Name = NormalizePayOSItemName(courseLookup[i.CourseId].Title, i.CourseId),
                Quantity = 1,
                Price = ConvertVndAmount(i.Price)
            }).ToList()
        };

        createLinkRequest.Signature = _payOSService.CreatePaymentRequestSignature(
            createLinkRequest.Amount,
            createLinkRequest.CancelUrl,
            createLinkRequest.Description,
            createLinkRequest.OrderCode,
            createLinkRequest.ReturnUrl);

        try
        {
            var payOSData = await _payOSService.CreatePaymentLinkAsync(createLinkRequest, cancellationToken);
            paymentTransaction.PaymentLinkId = payOSData.PaymentLinkId;
            paymentTransaction.ProviderTransactionId = payOSData.PaymentLinkId;
            paymentTransaction.RawPayload = JsonSerializer.Serialize(payOSData);
            order.LastPaymentStatus = string.IsNullOrWhiteSpace(payOSData.Status) ? OrderStatusPending : payOSData.Status;

            await _context.SaveChangesAsync(cancellationToken);

            return BuildCheckoutResponse(order, orderItems, courses, payOSData.CheckoutUrl, payOSData.QrCode, payOSData.PaymentLinkId, true, payOSData);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to create PayOS payment link for order {OrderId}", order.Id);

            order.Status = OrderStatusFailed;
            order.LastPaymentStatus = OrderStatusFailed;
            paymentTransaction.Status = "FAILED";
            paymentTransaction.RawPayload = ex.Message;

            await _context.SaveChangesAsync(cancellationToken);
            throw;
        }
    }

    public async Task<IReadOnlyList<UserOrderSummaryDto>> GetUserOrdersAsync(Guid userId, CancellationToken cancellationToken = default)
    {
        var orders = await _context.Orders
            .AsNoTracking()
            .Include(o => o.OrderItems)
                .ThenInclude(oi => oi.Course)
            .Where(o => o.BuyerId == userId)
            .OrderByDescending(o => o.CreatedAt)
            .ToListAsync(cancellationToken);

        return orders.Select(o => new UserOrderSummaryDto
        {
            OrderId = o.Id.ToString(),
            PayOSOrderCode = o.PayOSOrderCode,
            TotalAmount = o.TotalAmount,
            Status = o.Status,
            LastPaymentStatus = o.LastPaymentStatus,
            CreatedAt = o.CreatedAt,
            PaidAt = o.PaidAt,
            Items = o.OrderItems.Select(oi => new CheckoutItemDto
            {
                CourseId = oi.CourseId.ToString(),
                Title = oi.Course.Title,
                Price = oi.Price,
                IsFree = oi.Course.IsFree
            }).ToList()
        }).ToList();
    }

    public async Task<OrderStatusResponse?> GetOrderStatusAsync(Guid userId, Guid orderId, bool refreshFromProvider, CancellationToken cancellationToken = default)
    {
        var order = await _context.Orders
            .Include(o => o.OrderItems)
                .ThenInclude(oi => oi.Course)
            .Include(o => o.PaymentTransactions)
            .FirstOrDefaultAsync(o => o.Id == orderId && o.BuyerId == userId, cancellationToken);

        if (order == null)
        {
            return null;
        }

        if (refreshFromProvider)
        {
            await RefreshOrderStatusFromProviderAsync(order, cancellationToken);
        }

        return MapToOrderStatusResponse(order);
    }

    public async Task<OrderStatusResponse?> GetOrderStatusByCodeAsync(Guid userId, int orderCode, bool refreshFromProvider, CancellationToken cancellationToken = default)
    {
        var order = await _context.Orders
            .Include(o => o.OrderItems)
                .ThenInclude(oi => oi.Course)
            .Include(o => o.PaymentTransactions)
            .FirstOrDefaultAsync(o => o.PayOSOrderCode == orderCode && o.BuyerId == userId, cancellationToken);

        if (order == null)
        {
            return null;
        }

        if (refreshFromProvider)
        {
            await RefreshOrderStatusFromProviderAsync(order, cancellationToken);
        }

        return MapToOrderStatusResponse(order);
    }

    public async Task HandlePayOSWebhookAsync(PayOSWebhookRequest request, CancellationToken cancellationToken = default)
    {
        if (!_payOSService.VerifyWebhookSignature(request.Data, request.Signature))
        {
            _logger.LogWarning("Received PayOS webhook with invalid signature");
            return;
        }

        if (!TryGetInt32(request.Data, "orderCode", out var orderCode))
        {
            _logger.LogWarning("Received PayOS webhook without orderCode");
            return;
        }

        var order = await _context.Orders
            .Include(o => o.OrderItems)
                .ThenInclude(oi => oi.Course)
            .Include(o => o.PaymentTransactions)
            .Include(o => o.Cabin)
            .FirstOrDefaultAsync(o => o.PayOSOrderCode == orderCode, cancellationToken);

        if (order == null)
        {
            _logger.LogInformation("Ignoring PayOS webhook because orderCode {OrderCode} was not found", orderCode);
            return;
        }

        var transaction = order.PaymentTransactions
            .OrderByDescending(t => t.CreatedAt)
            .FirstOrDefault();

        if (transaction == null)
        {
            var paymentMethod = await EnsureVietQrPaymentMethodAsync(cancellationToken);
            transaction = new PaymentTransaction
            {
                Id = Guid.NewGuid(),
                OrderId = order.Id,
                PaymentMethodId = paymentMethod.Id,
                Provider = "PAYOS",
                Amount = order.TotalAmount,
                Status = "INIT",
                CreatedAt = DateTime.UtcNow
            };
            _context.PaymentTransactions.Add(transaction);
        }

        transaction.RawPayload = JsonSerializer.Serialize(request);
        transaction.WebhookProcessedAt = DateTime.UtcNow;

        if (TryGetString(request.Data, "paymentLinkId", out var paymentLinkId) && !string.IsNullOrWhiteSpace(paymentLinkId))
        {
            transaction.PaymentLinkId = paymentLinkId;
            transaction.ProviderTransactionId ??= paymentLinkId;
        }

        if (TryGetString(request.Data, "reference", out var reference) && !string.IsNullOrWhiteSpace(reference))
        {
            transaction.Reference = reference;
        }

        var providerCode = TryGetString(request.Data, "code", out var code) ? code : request.Code;
        var isSuccess = request.Success && string.Equals(request.Code, "00", StringComparison.OrdinalIgnoreCase) && string.Equals(providerCode, "00", StringComparison.OrdinalIgnoreCase);

        if (isSuccess)
        {
            order.LastPaymentStatus = OrderStatusPaid;
            transaction.Status = "SUCCESS";

            if (!string.Equals(order.Status, OrderStatusPaid, StringComparison.OrdinalIgnoreCase))
            {
                order.Status = OrderStatusPaid;
                order.PaidAt ??= DateTime.UtcNow;
                await _context.SaveChangesAsync(cancellationToken);
                await CompletePaidOrderAsync(order.Id, cancellationToken);
                return;
            }
        }
        else if (!string.Equals(order.Status, OrderStatusPaid, StringComparison.OrdinalIgnoreCase))
        {
            order.Status = OrderStatusFailed;
            order.LastPaymentStatus = TryGetString(request.Data, "desc", out var providerDesc) ? providerDesc : request.Desc;
            transaction.Status = "FAILED";
        }

        await _context.SaveChangesAsync(cancellationToken);
    }

    public async Task ConfirmWebhookUrlAsync(CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(_payOSSettings.WebhookUrl))
        {
            throw new InvalidOperationException("PayOS webhook URL is not configured.");
        }

        await _payOSService.ConfirmWebhookUrlAsync(_payOSSettings.WebhookUrl, cancellationToken);
    }

    private async Task RefreshOrderStatusFromProviderAsync(Order order, CancellationToken cancellationToken)
    {
        if (!order.PayOSOrderCode.HasValue || string.Equals(order.Status, OrderStatusPaid, StringComparison.OrdinalIgnoreCase))
        {
            return;
        }

        PayOSPaymentLinkInfoData providerInfo;
        try
        {
            providerInfo = await _payOSService.GetPaymentLinkInfoAsync(order.PayOSOrderCode.Value.ToString(), cancellationToken);
        }
        catch (Exception ex)
        {
            _logger.LogWarning(ex, "Failed to refresh order status from PayOS for order {OrderId}", order.Id);
            return;
        }

        order.LastPaymentStatus = providerInfo.Status;

        var latestTransaction = order.PaymentTransactions
            .OrderByDescending(t => t.CreatedAt)
            .FirstOrDefault();

        if (latestTransaction != null)
        {
            latestTransaction.PaymentLinkId ??= providerInfo.Id;
            latestTransaction.ProviderTransactionId ??= providerInfo.Id;
            latestTransaction.RawPayload = JsonSerializer.Serialize(providerInfo);
        }

        var normalizedStatus = (providerInfo.Status ?? string.Empty).ToUpperInvariant();
        switch (normalizedStatus)
        {
            case "PAID":
                if (!string.Equals(order.Status, OrderStatusPaid, StringComparison.OrdinalIgnoreCase))
                {
                    order.Status = OrderStatusPaid;
                    order.PaidAt ??= DateTime.UtcNow;
                    if (latestTransaction != null)
                    {
                        latestTransaction.Status = "SUCCESS";
                    }

                    await _context.SaveChangesAsync(cancellationToken);
                    await CompletePaidOrderAsync(order.Id, cancellationToken);
                    return;
                }
                break;

            case "CANCELLED":
                if (!string.Equals(order.Status, OrderStatusPaid, StringComparison.OrdinalIgnoreCase))
                {
                    order.Status = OrderStatusCancelled;
                    if (latestTransaction != null)
                    {
                        latestTransaction.Status = "FAILED";
                    }
                }
                break;

            case "FAILED":
                if (!string.Equals(order.Status, OrderStatusPaid, StringComparison.OrdinalIgnoreCase))
                {
                    order.Status = OrderStatusFailed;
                    if (latestTransaction != null)
                    {
                        latestTransaction.Status = "FAILED";
                    }
                }
                break;

            case "PROCESSING":
            case "PENDING":
            default:
                if (!string.Equals(order.Status, OrderStatusPaid, StringComparison.OrdinalIgnoreCase))
                {
                    order.Status = OrderStatusPending;
                    if (latestTransaction != null && latestTransaction.Status == "FAILED")
                    {
                        latestTransaction.Status = "INIT";
                    }
                }
                break;
        }

        await _context.SaveChangesAsync(cancellationToken);
    }

    private async Task CompletePaidOrderAsync(Guid orderId, CancellationToken cancellationToken)
    {
        var order = await _context.Orders
            .Include(o => o.OrderItems)
                .ThenInclude(oi => oi.Course)
            .Include(o => o.Cabin)
            .FirstOrDefaultAsync(o => o.Id == orderId, cancellationToken);

        if (order == null)
        {
            return;
        }

        var userId = order.BuyerId;
        var now = DateTime.UtcNow;
        foreach (var item in order.OrderItems)
        {
            var defaultDurationDays = item.Course?.DefaultAccessDurationDays;
            var accessDurationDays = defaultDurationDays.HasValue && defaultDurationDays.Value > 0
                ? defaultDurationDays.Value
                : (int?)null;
            var accessExpiresAt = accessDurationDays.HasValue
                ? (DateTime?)now.AddDays(accessDurationDays.Value)
                : null;

            var existingEnrollment = await _context.Enrollments
                .FirstOrDefaultAsync(e => e.UserId == userId && e.CourseId == item.CourseId, cancellationToken);

            if (existingEnrollment == null)
            {
                _context.Enrollments.Add(new Enrollment
                {
                    Id = Guid.NewGuid(),
                    UserId = userId,
                    CourseId = item.CourseId,
                    OrderId = order.Id,
                    EnrolledAt = now,
                    LastAccessedAt = now,
                    ProgressPercentage = 0,
                    Status = "ACTIVE",
                    SourceType = "PAYMENT",
                    AccessDurationDays = accessDurationDays,
                    AccessExpiresAt = accessExpiresAt
                });
            }
            else
            {
                existingEnrollment.Status = "ACTIVE";

                var isDuplicatePaidCallback = existingEnrollment.OrderId == order.Id
                    && existingEnrollment.SourceType == "PAYMENT";

                if (!isDuplicatePaidCallback)
                {
                    existingEnrollment.OrderId = order.Id;
                    existingEnrollment.LastAccessedAt = now;
                    existingEnrollment.AccessDurationDays = accessDurationDays;
                    existingEnrollment.AccessExpiresAt = accessExpiresAt;
                }

                if (existingEnrollment.SourceType == "FREE" || existingEnrollment.SourceType == "ADMIN")
                {
                    existingEnrollment.SourceType = "PAYMENT";
                }
            }
        }

        await _context.SaveChangesAsync(cancellationToken);
        await CreateCommissionIfEligibleAsync(order, cancellationToken);
    }

    private async Task CreateCommissionIfEligibleAsync(Order order, CancellationToken cancellationToken)
    {
        if (!order.CabinId.HasValue || order.TotalAmount <= 0)
        {
            return;
        }

        var paidItems = order.OrderItems.Where(oi => oi.Price > 0).ToList();
        if (paidItems.Count == 0)
        {
            return;
        }

        var commissionCabinIds = await ResolveCommissionCabinChainAsync(order.CabinId.Value, cancellationToken);
        if (commissionCabinIds.Count == 0)
        {
            return;
        }

        var existingLedgerCabinIds = await _context.CommissionLedgers
            .AsNoTracking()
            .Where(x => x.OrderId == order.Id && commissionCabinIds.Contains(x.CabinId))
            .Select(x => x.CabinId)
            .ToListAsync(cancellationToken);

        var existingLedgerCabinIdSet = existingLedgerCabinIds.ToHashSet();
        var targetCabinIds = commissionCabinIds
            .Where(cabinId => !existingLedgerCabinIdSet.Contains(cabinId))
            .ToList();

        if (targetCabinIds.Count == 0)
        {
            return;
        }

        var cabins = await _context.Cabins
            .AsNoTracking()
            .Where(c => targetCabinIds.Contains(c.Id))
            .ToDictionaryAsync(c => c.Id, cancellationToken);

        if (cabins.Count == 0)
        {
            return;
        }

        var courseIds = paidItems.Select(x => x.CourseId).Distinct().ToList();
        var rules = await _context.CommissionRules
            .AsNoTracking()
            .Where(r =>
                r.CabinId.HasValue
                && targetCabinIds.Contains(r.CabinId.Value)
                && (r.CourseId == null || courseIds.Contains(r.CourseId.Value)))
            .ToListAsync(cancellationToken);

        var rulesByCabinId = rules
            .Where(r => r.CabinId.HasValue)
            .GroupBy(r => r.CabinId!.Value)
            .ToDictionary(group => group.Key, group => group.ToList());

        var ledgersToCreate = new List<CommissionLedger>();
        var now = DateTime.UtcNow;

        foreach (var cabinId in commissionCabinIds)
        {
            if (!targetCabinIds.Contains(cabinId) || !cabins.TryGetValue(cabinId, out var cabin))
            {
                continue;
            }

            rulesByCabinId.TryGetValue(cabinId, out var cabinRules);
            cabinRules ??= new List<CommissionRule>();

            var cabinLevelRule = cabinRules.FirstOrDefault(r => r.CourseId == null);
            var courseRuleLookup = cabinRules
                .Where(r => r.CourseId.HasValue)
                .GroupBy(r => r.CourseId!.Value)
                .ToDictionary(group => group.Key, group => group.First().Rate);

            decimal commissionAmount = 0;
            foreach (var item in paidItems)
            {
                var rate = courseRuleLookup.TryGetValue(item.CourseId, out var courseRate)
                    ? courseRate
                    : (cabinLevelRule?.Rate ?? cabin.CommissionRate);

                if (rate <= 0)
                {
                    continue;
                }

                commissionAmount += item.Price * (rate / 100m);
            }

            var roundedAmount = decimal.Round(commissionAmount, 2, MidpointRounding.AwayFromZero);
            if (roundedAmount <= 0)
            {
                continue;
            }

            ledgersToCreate.Add(new CommissionLedger
            {
                Id = Guid.NewGuid(),
                CabinId = cabinId,
                OrderId = order.Id,
                Amount = roundedAmount,
                Status = "PENDING",
                CreatedAt = now
            });
        }

        if (ledgersToCreate.Count == 0)
        {
            return;
        }

        _context.CommissionLedgers.AddRange(ledgersToCreate);
        await _context.SaveChangesAsync(cancellationToken);
    }

    private async Task<Cabin?> FindActiveCabinByReferralCodeAsync(string referralCode, bool includeOwner, CancellationToken cancellationToken)
    {
        var normalizedReferralCode = NormalizeReferralCode(referralCode);

        IQueryable<Cabin> query = _context.Cabins.AsNoTracking();
        if (includeOwner)
        {
            query = query.Include(c => c.OwnerUser);
        }

        return await query.FirstOrDefaultAsync(
            c => c.IsActive && c.ReferralCode != null && c.ReferralCode.ToUpper() == normalizedReferralCode,
            cancellationToken);
    }

    private async Task<IReadOnlyList<Guid>> ResolveCommissionCabinChainAsync(Guid referralCabinId, CancellationToken cancellationToken)
    {
        const int maxDepth = 10;

        var orderedCabinIds = new List<Guid> { referralCabinId };
        var visitedCabinIds = new HashSet<Guid> { referralCabinId };
        var currentChildCabinIds = new List<Guid> { referralCabinId };

        for (var depth = 0; depth < maxDepth && currentChildCabinIds.Count > 0; depth++)
        {
            var parentLinks = await _context.CabinMembers
                .AsNoTracking()
                .Where(x => currentChildCabinIds.Contains(x.ChildCabinId))
                .OrderBy(x => x.Level)
                .ThenBy(x => x.CreatedAt)
                .ToListAsync(cancellationToken);

            if (parentLinks.Count == 0)
            {
                break;
            }

            var nextChildCabinIds = new List<Guid>();

            foreach (var parentLink in parentLinks)
            {
                if (!visitedCabinIds.Add(parentLink.ParentCabinId))
                {
                    continue;
                }

                orderedCabinIds.Add(parentLink.ParentCabinId);
                nextChildCabinIds.Add(parentLink.ParentCabinId);
            }

            currentChildCabinIds = nextChildCabinIds;
        }

        return orderedCabinIds;
    }

    private static string NormalizeReferralCode(string referralCode)
    {
        return referralCode.Trim().ToUpperInvariant();
    }

    private async Task<PaymentMethod> EnsureVietQrPaymentMethodAsync(CancellationToken cancellationToken)
    {
        var method = await _context.PaymentMethods
            .FirstOrDefaultAsync(pm => pm.Code == "VIETQR", cancellationToken);

        if (method != null)
        {
            if (!method.IsActive)
            {
                method.IsActive = true;
                await _context.SaveChangesAsync(cancellationToken);
            }
            return method;
        }

        method = new PaymentMethod
        {
            Id = Guid.NewGuid(),
            Code = "VIETQR",
            Name = "PayOS VietQR",
            IsActive = true
        };

        _context.PaymentMethods.Add(method);
        await _context.SaveChangesAsync(cancellationToken);

        return method;
    }

    private static IReadOnlyList<Guid> ParseCourseIds(IEnumerable<string> rawCourseIds)
    {
        var parsed = new List<Guid>();
        foreach (var raw in rawCourseIds)
        {
            if (string.IsNullOrWhiteSpace(raw))
            {
                continue;
            }

            if (!Guid.TryParse(raw, out var courseId))
            {
                throw new ArgumentException($"Invalid course id: {raw}");
            }

            parsed.Add(courseId);
        }

        return parsed.Distinct().ToList();
    }

    private static int ConvertVndAmount(decimal amount)
    {
        if (amount < 0)
        {
            throw new ArgumentException("Amount must be non-negative.");
        }

        if (amount != decimal.Truncate(amount))
        {
            throw new InvalidOperationException("Amount must be an integer value in VND.");
        }

        if (amount > int.MaxValue)
        {
            throw new InvalidOperationException("Amount exceeds supported range.");
        }

        return (int)amount;
    }

    private static string NormalizePayOSItemName(string? name, Guid courseId)
    {
        var value = string.IsNullOrWhiteSpace(name)
            ? $"COURSE-{courseId.ToString("N")[..8]}"
            : name.Trim();

        value = value
            .Replace("\r", " ", StringComparison.Ordinal)
            .Replace("\n", " ", StringComparison.Ordinal)
            .Replace("\t", " ", StringComparison.Ordinal);

        while (value.Contains("  ", StringComparison.Ordinal))
        {
            value = value.Replace("  ", " ", StringComparison.Ordinal);
        }

        return value.Length > 100 ? value[..100] : value;
    }

    private static string BuildPayOSDescription(int orderCode)
    {
        // Keep description compact (9 chars) due bank display constraints in PayOS docs.
        return $"DH{orderCode % 10000000:D7}";
    }

    private async Task<int> GenerateUniquePayOSOrderCodeAsync(CancellationToken cancellationToken)
    {
        const int min = 10_000_000;
        const int max = 999_999_999;

        for (var i = 0; i < 20; i++)
        {
            var code = RandomNumberGenerator.GetInt32(min, max);
            var exists = await _context.Orders.AsNoTracking().AnyAsync(o => o.PayOSOrderCode == code, cancellationToken);
            if (!exists)
            {
                return code;
            }
        }

        throw new InvalidOperationException("Unable to generate a unique PayOS order code.");
    }

    private static bool TryGetInt32(JsonElement element, string propertyName, out int value)
    {
        value = default;
        if (!element.TryGetProperty(propertyName, out var prop))
        {
            return false;
        }

        if (prop.ValueKind == JsonValueKind.Number)
        {
            return prop.TryGetInt32(out value);
        }

        if (prop.ValueKind == JsonValueKind.String)
        {
            return int.TryParse(prop.GetString(), out value);
        }

        return false;
    }

    private static bool TryGetString(JsonElement element, string propertyName, out string value)
    {
        value = string.Empty;
        if (!element.TryGetProperty(propertyName, out var prop))
        {
            return false;
        }

        if (prop.ValueKind == JsonValueKind.String)
        {
            value = prop.GetString() ?? string.Empty;
            return true;
        }

        value = prop.GetRawText();
        return true;
    }

    private static CheckoutResponse BuildCheckoutResponse(
        Order order,
        IEnumerable<OrderItem> orderItems,
        IEnumerable<Course> courses,
        string? checkoutUrl,
        string? qrCode,
        string? paymentLinkId,
        bool requiresPayment,
        PayOSCreatePaymentLinkData? payOSData)
    {
        var courseLookup = courses.ToDictionary(c => c.Id, c => c);
        var paymentInstruction = BuildPaymentInstructionFromCreateData(payOSData, order.PayOSOrderCode, order.TotalAmount);

        return new CheckoutResponse
        {
            OrderId = order.Id.ToString(),
            PayOSOrderCode = order.PayOSOrderCode,
            TotalAmount = order.TotalAmount,
            Status = order.Status,
            RequiresPayment = requiresPayment,
            CheckoutUrl = checkoutUrl,
            QrCode = qrCode,
            PaymentLinkId = paymentLinkId,
            PaymentInstruction = paymentInstruction,
            CreatedAt = order.CreatedAt,
            ExpiresAt = order.ExpiresAt,
            Items = orderItems.Select(oi => new CheckoutItemDto
            {
                CourseId = oi.CourseId.ToString(),
                Title = courseLookup.TryGetValue(oi.CourseId, out var mappedCourse) ? mappedCourse.Title : string.Empty,
                Price = oi.Price,
                IsFree = courseLookup.TryGetValue(oi.CourseId, out var mappedCourseForFree) ? mappedCourseForFree.IsFree : oi.Price <= 0
            }).ToList()
        };
    }

    private static OrderStatusResponse MapToOrderStatusResponse(Order order)
    {
        var latestTransaction = order.PaymentTransactions.OrderByDescending(t => t.CreatedAt).FirstOrDefault();
        var paymentInstruction = TryBuildPaymentInstructionFromRawPayload(
            latestTransaction?.RawPayload,
            order.PayOSOrderCode,
            order.TotalAmount,
            out var checkoutUrl,
            out var qrCode);

        if (paymentInstruction == null && order.PayOSOrderCode.HasValue)
        {
            paymentInstruction = new PaymentInstructionDto
            {
                TransferContent = BuildPayOSDescription(order.PayOSOrderCode.Value),
                Amount = order.TotalAmount
            };
        }

        return new OrderStatusResponse
        {
            OrderId = order.Id.ToString(),
            PayOSOrderCode = order.PayOSOrderCode,
            TotalAmount = order.TotalAmount,
            Status = order.Status,
            LastPaymentStatus = order.LastPaymentStatus,
            IsPaid = string.Equals(order.Status, OrderStatusPaid, StringComparison.OrdinalIgnoreCase),
            CreatedAt = order.CreatedAt,
            PaidAt = order.PaidAt,
            PaymentLinkId = latestTransaction?.PaymentLinkId,
            CheckoutUrl = checkoutUrl,
            QrCode = qrCode,
            PaymentInstruction = paymentInstruction,
            Items = order.OrderItems.Select(oi => new CheckoutItemDto
            {
                CourseId = oi.CourseId.ToString(),
                Title = oi.Course.Title,
                Price = oi.Price,
                IsFree = oi.Course.IsFree
            }).ToList()
        };
    }

    private static PaymentInstructionDto? BuildPaymentInstructionFromCreateData(PayOSCreatePaymentLinkData? payOSData, int? orderCode, decimal fallbackAmount)
    {
        if (payOSData == null)
        {
            return null;
        }

        var (resolvedBankName, resolvedBankShortName) = ResolveBankIdentity(payOSData.Bin);
        var transferContent = FirstNonEmpty(
            payOSData.Description,
            orderCode.HasValue ? BuildPayOSDescription(orderCode.Value) : null);

        return new PaymentInstructionDto
        {
            BankBin = payOSData.Bin,
            BankName = resolvedBankName,
            BankShortName = resolvedBankShortName,
            AccountNumber = payOSData.AccountNumber,
            AccountName = payOSData.AccountName,
            TransferContent = transferContent,
            Amount = payOSData.Amount > 0 ? payOSData.Amount : fallbackAmount
        };
    }

    private static PaymentInstructionDto? TryBuildPaymentInstructionFromRawPayload(
        string? rawPayload,
        int? orderCode,
        decimal fallbackAmount,
        out string? checkoutUrl,
        out string? qrCode)
    {
        checkoutUrl = null;
        qrCode = null;

        if (string.IsNullOrWhiteSpace(rawPayload))
        {
            return null;
        }

        try
        {
            using var document = JsonDocument.Parse(rawPayload);
            if (document.RootElement.ValueKind != JsonValueKind.Object)
            {
                return null;
            }

            var root = document.RootElement;
            checkoutUrl = GetJsonString(root, "CheckoutUrl");
            qrCode = GetJsonString(root, "QrCode");

            var bankBin = GetJsonString(root, "Bin");
            var bankName = FirstNonEmpty(GetJsonString(root, "BankName"), GetJsonString(root, "Name"));
            var bankShortName = FirstNonEmpty(GetJsonString(root, "BankShortName"), GetJsonString(root, "ShortName"));

            if (string.IsNullOrWhiteSpace(bankName) || string.IsNullOrWhiteSpace(bankShortName))
            {
                var (resolvedBankName, resolvedBankShortName) = ResolveBankIdentity(bankBin);
                bankName = FirstNonEmpty(bankName, resolvedBankName);
                bankShortName = FirstNonEmpty(bankShortName, resolvedBankShortName);
            }

            var transferContent = FirstNonEmpty(
                GetJsonString(root, "TransferContent"),
                GetJsonString(root, "Description"),
                orderCode.HasValue ? BuildPayOSDescription(orderCode.Value) : null);

            var amount = GetJsonDecimal(root, "Amount") ?? fallbackAmount;
            var accountNumber = GetJsonString(root, "AccountNumber");
            var accountName = GetJsonString(root, "AccountName");

            var hasAnyMetadata = !string.IsNullOrWhiteSpace(bankBin)
                || !string.IsNullOrWhiteSpace(bankName)
                || !string.IsNullOrWhiteSpace(bankShortName)
                || !string.IsNullOrWhiteSpace(accountNumber)
                || !string.IsNullOrWhiteSpace(accountName)
                || !string.IsNullOrWhiteSpace(transferContent)
                || amount > 0;

            if (!hasAnyMetadata)
            {
                return null;
            }

            return new PaymentInstructionDto
            {
                BankBin = bankBin,
                BankName = bankName,
                BankShortName = bankShortName,
                AccountNumber = accountNumber,
                AccountName = accountName,
                TransferContent = transferContent,
                Amount = amount
            };
        }
        catch
        {
            return null;
        }
    }

    private static string? GetJsonString(JsonElement root, string propertyName)
    {
        if (!TryGetJsonProperty(root, propertyName, out var property))
        {
            return null;
        }

        return property.ValueKind switch
        {
            JsonValueKind.String => property.GetString(),
            JsonValueKind.Number => property.GetRawText(),
            JsonValueKind.True => "true",
            JsonValueKind.False => "false",
            _ => null
        };
    }

    private static decimal? GetJsonDecimal(JsonElement root, string propertyName)
    {
        if (!TryGetJsonProperty(root, propertyName, out var property))
        {
            return null;
        }

        if (property.ValueKind == JsonValueKind.Number)
        {
            if (property.TryGetDecimal(out var decimalValue))
            {
                return decimalValue;
            }

            if (property.TryGetInt64(out var int64Value))
            {
                return int64Value;
            }

            if (property.TryGetDouble(out var doubleValue))
            {
                return Convert.ToDecimal(doubleValue, CultureInfo.InvariantCulture);
            }

            return null;
        }

        if (property.ValueKind == JsonValueKind.String)
        {
            var raw = property.GetString();
            if (decimal.TryParse(raw, NumberStyles.Any, CultureInfo.InvariantCulture, out var parsedInvariant))
            {
                return parsedInvariant;
            }

            if (decimal.TryParse(raw, NumberStyles.Any, CultureInfo.CurrentCulture, out var parsedCurrent))
            {
                return parsedCurrent;
            }
        }

        return null;
    }

    private static bool TryGetJsonProperty(JsonElement root, string propertyName, out JsonElement property)
    {
        foreach (var jsonProperty in root.EnumerateObject())
        {
            if (string.Equals(jsonProperty.Name, propertyName, StringComparison.OrdinalIgnoreCase))
            {
                property = jsonProperty.Value;
                return true;
            }
        }

        property = default;
        return false;
    }

    private static string? FirstNonEmpty(params string?[] values)
    {
        foreach (var value in values)
        {
            if (!string.IsNullOrWhiteSpace(value))
            {
                return value;
            }
        }

        return null;
    }

    private static (string? BankName, string? BankShortName) ResolveBankIdentity(string? bankBin)
    {
        return bankBin switch
        {
            "970422" => ("Ngan hang TMCP Quan doi", "MB"),
            "970415" => ("Ngan hang TMCP Cong thuong Viet Nam", "VietinBank"),
            "970436" => ("Ngan hang TMCP Ngoai thuong Viet Nam", "Vietcombank"),
            "970405" => ("Ngan hang Nong nghiep va Phat trien Nong thon Viet Nam", "Agribank"),
            "970418" => ("Ngan hang Dau tu va Phat trien Viet Nam", "BIDV"),
            "970423" => ("Ngan hang TMCP Tien Phong", "TPBank"),
            "970432" => ("Ngan hang TMCP Viet Nam Thinh Vuong", "VPBank"),
            _ => (null, null)
        };
    }
}
