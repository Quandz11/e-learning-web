using System.Text.RegularExpressions;
using Microsoft.EntityFrameworkCore;
using SKVI.Application.DTOs.Referrals;
using SKVI.Application.Interfaces;
using SKVI.Domain.Entities;
using SKVI.Infrastructure;
using SKVI.Shared;

namespace SKVI.Application.Services;

public class UserReferralService : IUserReferralService
{
    private const string ReferralChars = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789";
    private const string ReferralStatusCompleted = "COMPLETED";
    private const string ReferralStatusPending = "PENDING";
    private const string OrderStatusPaid = "PAID";
    private static readonly Regex DiscountCodeRegex = new("^[A-Z0-9_-]{4,32}$", RegexOptions.Compiled);
    private readonly ApplicationDbContext _context;

    public UserReferralService(ApplicationDbContext context)
    {
        _context = context;
    }

    public async Task<UserReferralOverviewDto> GetOrCreateMyReferralAsync(Guid userId, CancellationToken cancellationToken = default)
    {
        var userExists = await _context.Users
            .AsNoTracking()
            .AnyAsync(u => u.Id == userId && !u.IsDeleted, cancellationToken);

        if (!userExists)
        {
            throw new KeyNotFoundException("User not found.");
        }

        var referral = await _context.UserReferrals
            .FirstOrDefaultAsync(r => r.UserId == userId && r.IsActive, cancellationToken);

        if (referral == null)
        {
            referral = await CreateReferralProfileAsync(userId, cancellationToken);
            _context.UserReferrals.Add(referral);
            await _context.SaveChangesAsync(cancellationToken);
        }

        var totalInvites = await _context.ReferralTransactions
            .CountAsync(t => t.ReferrerUserId == userId, cancellationToken);

        var successfulInvites = await _context.ReferralTransactions
            .CountAsync(t => t.ReferrerUserId == userId && t.Status == ReferralStatusCompleted, cancellationToken);

        return new UserReferralOverviewDto
        {
            Referral = new UserReferralDto
            {
                Id = referral.Id,
                UserId = referral.UserId,
                ReferralCode = referral.ReferralCode,
                DiscountCode = referral.DiscountCode,
                DiscountPercent = referral.DiscountPercent,
                IsActive = referral.IsActive,
                CreatedAt = referral.CreatedAt,
                UpdatedAt = referral.UpdatedAt
            },
            Stats = new UserReferralStatsDto
            {
                TotalInvites = totalInvites,
                SuccessfulInvites = successfulInvites,
                PendingInvites = totalInvites - successfulInvites
            }
        };
    }

    public async Task ApplyReferralCodeForNewUserAsync(Guid newUserId, string referralCode, CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(referralCode))
        {
            return;
        }

        var normalizedCode = referralCode.Trim().ToUpperInvariant();

        var referral = await _context.UserReferrals
            .FirstOrDefaultAsync(r => r.ReferralCode == normalizedCode && r.IsActive, cancellationToken);

        if (referral == null)
        {
            return;
        }

        if (referral.UserId == newUserId)
        {
            return;
        }

        var existing = await _context.ReferralTransactions
            .AnyAsync(t => t.ReferredUserId == newUserId, cancellationToken);

        if (existing)
        {
            return;
        }

        var referredUser = await _context.Users
            .FirstOrDefaultAsync(u => u.Id == newUserId && !u.IsDeleted, cancellationToken);

        if (referredUser == null)
        {
            return;
        }

        referredUser.ReferredByUserId = referral.UserId;
        referredUser.UpdatedAt = DateTime.UtcNow;

        _context.ReferralTransactions.Add(new ReferralTransaction
        {
            Id = Guid.NewGuid(),
            ReferrerUserId = referral.UserId,
            ReferredUserId = newUserId,
            UserReferralId = referral.Id,
            ReferralCode = referral.ReferralCode,
            Status = "PENDING",
            CreatedAt = DateTime.UtcNow
        });

        await _context.SaveChangesAsync(cancellationToken);
    }

    public async Task CompleteReferralForUserAsync(Guid referredUserId, CancellationToken cancellationToken = default)
    {
        var tx = await _context.ReferralTransactions
            .FirstOrDefaultAsync(t => t.ReferredUserId == referredUserId && t.Status == ReferralStatusPending, cancellationToken);

        if (tx == null)
        {
            return;
        }

        tx.Status = ReferralStatusCompleted;
        tx.CompletedAt = DateTime.UtcNow;

        await _context.SaveChangesAsync(cancellationToken);
    }

    public async Task<PagedResult<AdminUserReferralItemDto>> GetAdminPagedAsync(string? search, bool? isActive, int page, int pageSize, CancellationToken cancellationToken = default)
    {
        var safePage = Math.Max(1, page);
        var safePageSize = Math.Clamp(pageSize, 1, 100);

        var query = _context.UserReferrals
            .AsNoTracking()
            .AsQueryable();

        if (isActive.HasValue)
        {
            query = query.Where(r => r.IsActive == isActive.Value);
        }

        if (!string.IsNullOrWhiteSpace(search))
        {
            var keyword = search.Trim().ToUpper();
            query = query.Where(r =>
                r.ReferralCode.ToUpper().Contains(keyword) ||
                r.DiscountCode.ToUpper().Contains(keyword) ||
                r.User.Email.ToUpper().Contains(keyword) ||
                (r.User.FullName != null && r.User.FullName.ToUpper().Contains(keyword)));
        }

        var total = await query.CountAsync(cancellationToken);
        var items = await query
            .OrderByDescending(r => r.CreatedAt)
            .Skip((safePage - 1) * safePageSize)
            .Take(safePageSize)
            .Select(r => new AdminUserReferralItemDto
            {
                Id = r.Id,
                UserId = r.UserId,
                UserName = r.User.FullName,
                UserEmail = r.User.Email,
                ReferralCode = r.ReferralCode,
                DiscountCode = r.DiscountCode,
                DiscountPercent = r.DiscountPercent,
                IsActive = r.IsActive,
                TotalInvites = _context.ReferralTransactions.Count(t => t.UserReferralId == r.Id),
                SuccessfulInvites = _context.ReferralTransactions.Count(t => t.UserReferralId == r.Id && t.Status == ReferralStatusCompleted),
                PendingInvites = _context.ReferralTransactions.Count(t => t.UserReferralId == r.Id && t.Status == ReferralStatusPending),
                ReferredPaidOrderCount = _context.Orders.Count(o =>
                    o.Status == OrderStatusPaid &&
                    _context.ReferralTransactions.Any(t =>
                        t.UserReferralId == r.Id &&
                        t.Status == ReferralStatusCompleted &&
                        t.ReferredUserId == o.BuyerId)),
                ReferredPaidRevenue = _context.Orders
                    .Where(o =>
                        o.Status == OrderStatusPaid &&
                        _context.ReferralTransactions.Any(t =>
                            t.UserReferralId == r.Id &&
                            t.Status == ReferralStatusCompleted &&
                            t.ReferredUserId == o.BuyerId))
                    .Select(o => (decimal?)o.TotalAmount)
                    .Sum() ?? 0m,
                CreatedAt = r.CreatedAt,
                UpdatedAt = r.UpdatedAt
            })
            .ToListAsync(cancellationToken);

        return new PagedResult<AdminUserReferralItemDto>
        {
            Items = items,
            Total = total,
            Page = safePage,
            PageSize = safePageSize
        };
    }

    public async Task<AdminUserReferralItemDto> UpdateForAdminAsync(Guid referralId, AdminUpdateUserReferralRequest request, CancellationToken cancellationToken = default)
    {
        var referral = await _context.UserReferrals
            .FirstOrDefaultAsync(r => r.Id == referralId, cancellationToken);

        if (referral == null)
        {
            throw new KeyNotFoundException("User referral not found.");
        }

        var normalizedDiscountCode = NormalizeDiscountCode(request.DiscountCode);
        EnsureDiscountPercentValid(request.DiscountPercent);
        await EnsureDiscountCodeAvailableAsync(normalizedDiscountCode, referralId, cancellationToken);

        referral.DiscountCode = normalizedDiscountCode;
        referral.DiscountPercent = request.DiscountPercent;
        referral.IsActive = request.IsActive;
        referral.UpdatedAt = DateTime.UtcNow;

        await _context.SaveChangesAsync(cancellationToken);

        return await GetAdminItemByIdAsync(referralId, cancellationToken);
    }

    public async Task<AdminBulkUpdateDiscountPercentResultDto> BulkUpdateDiscountPercentForAdminAsync(AdminBulkUpdateDiscountPercentRequest request, CancellationToken cancellationToken = default)
    {
        if (request.ReferralIds == null || request.ReferralIds.Count == 0)
        {
            throw new ArgumentException("At least one referral id is required.");
        }

        EnsureDiscountPercentValid(request.DiscountPercent);

        var distinctIds = request.ReferralIds
            .Where(id => id != Guid.Empty)
            .Distinct()
            .ToList();

        if (distinctIds.Count == 0)
        {
            throw new ArgumentException("At least one valid referral id is required.");
        }

        var referrals = await _context.UserReferrals
            .Where(r => distinctIds.Contains(r.Id))
            .ToListAsync(cancellationToken);

        if (referrals.Count == 0)
        {
            throw new KeyNotFoundException("No user referral was found for selected ids.");
        }

        var now = DateTime.UtcNow;
        foreach (var referral in referrals)
        {
            referral.DiscountPercent = request.DiscountPercent;
            referral.UpdatedAt = now;
        }

        await _context.SaveChangesAsync(cancellationToken);

        return new AdminBulkUpdateDiscountPercentResultDto
        {
            RequestedCount = distinctIds.Count,
            UpdatedCount = referrals.Count,
            DiscountPercent = request.DiscountPercent,
            UpdatedAt = now
        };
    }

    public async Task<AdminUserReferralItemDto> RegenerateDiscountCodeForAdminAsync(Guid referralId, CancellationToken cancellationToken = default)
    {
        var referral = await _context.UserReferrals
            .FirstOrDefaultAsync(r => r.Id == referralId, cancellationToken);

        if (referral == null)
        {
            throw new KeyNotFoundException("User referral not found.");
        }

        var discountCode = await GenerateUniqueCodeAsync(10, async code =>
            await _context.UserReferrals.AnyAsync(r => r.DiscountCode == code && r.Id != referralId, cancellationToken), "INV");

        referral.DiscountCode = discountCode;
        referral.UpdatedAt = DateTime.UtcNow;

        await _context.SaveChangesAsync(cancellationToken);

        return await GetAdminItemByIdAsync(referralId, cancellationToken);
    }

    private async Task<UserReferral> CreateReferralProfileAsync(Guid userId, CancellationToken cancellationToken)
    {
        var referralCode = await GenerateUniqueCodeAsync(8, async code =>
            await _context.UserReferrals.AnyAsync(r => r.ReferralCode == code, cancellationToken));

        var discountCode = await GenerateUniqueCodeAsync(10, async code =>
            await _context.UserReferrals.AnyAsync(r => r.DiscountCode == code, cancellationToken), "INV");

        return new UserReferral
        {
            Id = Guid.NewGuid(),
            UserId = userId,
            ReferralCode = referralCode,
            DiscountCode = discountCode,
            DiscountPercent = 5,
            IsActive = true,
            CreatedAt = DateTime.UtcNow,
            UpdatedAt = DateTime.UtcNow
        };
    }

    private async Task<string> GenerateUniqueCodeAsync(int length, Func<string, Task<bool>> existsAsync, string? prefix = null)
    {
        for (var i = 0; i < 40; i++)
        {
            var raw = GenerateCode(length);
            var candidate = string.IsNullOrWhiteSpace(prefix)
                ? raw
                : $"{prefix}-{raw}";

            var exists = await existsAsync(candidate);
            if (!exists)
            {
                return candidate;
            }
        }

        throw new InvalidOperationException("Unable to generate unique referral code.");
    }

    private static string GenerateCode(int length)
    {
        var chars = new char[length];
        for (var i = 0; i < length; i++)
        {
            chars[i] = ReferralChars[Random.Shared.Next(ReferralChars.Length)];
        }

        return new string(chars);
    }

    private async Task EnsureDiscountCodeAvailableAsync(string discountCode, Guid currentReferralId, CancellationToken cancellationToken)
    {
        var exists = await _context.UserReferrals
            .AsNoTracking()
            .AnyAsync(r => r.DiscountCode == discountCode && r.Id != currentReferralId, cancellationToken);

        if (exists)
        {
            throw new InvalidOperationException("Discount code already exists.");
        }
    }

    private static void EnsureDiscountPercentValid(decimal discountPercent)
    {
        if (discountPercent < 0 || discountPercent > 100)
        {
            throw new ArgumentException("Discount percent must be between 0 and 100.");
        }
    }

    private static string NormalizeDiscountCode(string discountCode)
    {
        if (string.IsNullOrWhiteSpace(discountCode))
        {
            throw new ArgumentException("Discount code is required.");
        }

        var normalized = discountCode.Trim().ToUpperInvariant();
        if (!DiscountCodeRegex.IsMatch(normalized))
        {
            throw new ArgumentException("Discount code must be 4-32 chars and only include A-Z, 0-9, '_' or '-'.");
        }

        return normalized;
    }

    private async Task<AdminUserReferralItemDto> GetAdminItemByIdAsync(Guid referralId, CancellationToken cancellationToken)
    {
        var item = await _context.UserReferrals
            .AsNoTracking()
            .Where(r => r.Id == referralId)
            .Select(r => new AdminUserReferralItemDto
            {
                Id = r.Id,
                UserId = r.UserId,
                UserName = r.User.FullName,
                UserEmail = r.User.Email,
                ReferralCode = r.ReferralCode,
                DiscountCode = r.DiscountCode,
                DiscountPercent = r.DiscountPercent,
                IsActive = r.IsActive,
                TotalInvites = _context.ReferralTransactions.Count(t => t.UserReferralId == r.Id),
                SuccessfulInvites = _context.ReferralTransactions.Count(t => t.UserReferralId == r.Id && t.Status == ReferralStatusCompleted),
                PendingInvites = _context.ReferralTransactions.Count(t => t.UserReferralId == r.Id && t.Status == ReferralStatusPending),
                ReferredPaidOrderCount = _context.Orders.Count(o =>
                    o.Status == OrderStatusPaid &&
                    _context.ReferralTransactions.Any(t =>
                        t.UserReferralId == r.Id &&
                        t.Status == ReferralStatusCompleted &&
                        t.ReferredUserId == o.BuyerId)),
                ReferredPaidRevenue = _context.Orders
                    .Where(o =>
                        o.Status == OrderStatusPaid &&
                        _context.ReferralTransactions.Any(t =>
                            t.UserReferralId == r.Id &&
                            t.Status == ReferralStatusCompleted &&
                            t.ReferredUserId == o.BuyerId))
                    .Select(o => (decimal?)o.TotalAmount)
                    .Sum() ?? 0m,
                CreatedAt = r.CreatedAt,
                UpdatedAt = r.UpdatedAt
            })
            .FirstOrDefaultAsync(cancellationToken);

        if (item == null)
        {
            throw new KeyNotFoundException("User referral not found.");
        }

        return item;
    }
}
