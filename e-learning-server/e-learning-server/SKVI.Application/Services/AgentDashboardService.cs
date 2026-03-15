using Microsoft.EntityFrameworkCore;
using SKVI.Application.DTOs.Dashboard;
using SKVI.Application.Interfaces;
using SKVI.Infrastructure;

namespace SKVI.Application.Services;

public class AgentDashboardService : IAgentDashboardService
{
    private const string OrderStatusPaid = "PAID";
    private const string CommissionStatusPending = "PENDING";
    private const string CommissionStatusApproved = "APPROVED";
    private const string CommissionStatusPaid = "PAID";

    private readonly ApplicationDbContext _context;
    private readonly ILogger<AgentDashboardService> _logger;

    public AgentDashboardService(ApplicationDbContext context, ILogger<AgentDashboardService> logger)
    {
        _context = context;
        _logger = logger;
    }

    public async Task<AgentDashboardStatsDto> GetStatsAsync(Guid agentId, CancellationToken cancellationToken = default)
    {
        try
        {
            var agentCabinIds = await GetAgentCabinIdsAsync(agentId, cancellationToken);
            if (agentCabinIds.Count == 0)
            {
                return new AgentDashboardStatsDto
                {
                    LeaderboardRank = 1
                };
            }

            var now = DateTime.UtcNow;
            var monthStart = new DateTime(now.Year, now.Month, 1, 0, 0, 0, DateTimeKind.Utc);
            var nextMonthStart = monthStart.AddMonths(1);
            var previousMonthStart = monthStart.AddMonths(-1);

            var totalSalesThisMonth = await SumPaidOrderSalesAsync(agentCabinIds, monthStart, nextMonthStart, cancellationToken);
            var previousMonthSales = await SumPaidOrderSalesAsync(agentCabinIds, previousMonthStart, monthStart, cancellationToken);

            var totalStudentsFromReferral = await _context.Orders
                .AsNoTracking()
                .Where(o =>
                    o.CabinId.HasValue
                    && agentCabinIds.Contains(o.CabinId.Value)
                    && o.Status == OrderStatusPaid)
                .Select(o => o.BuyerId)
                .Distinct()
                .CountAsync(cancellationToken);

            var commissionPending = await _context.CommissionLedgers
                .AsNoTracking()
                .Where(x =>
                    agentCabinIds.Contains(x.CabinId)
                    && (x.Status == CommissionStatusPending || x.Status == CommissionStatusApproved))
                .SumAsync(x => (decimal?)x.Amount, cancellationToken) ?? 0m;

            var commissionReceived = await _context.CommissionLedgers
                .AsNoTracking()
                .Where(x => agentCabinIds.Contains(x.CabinId) && x.Status == CommissionStatusPaid)
                .SumAsync(x => (decimal?)x.Amount, cancellationToken) ?? 0m;

            var currentMonthCommission = await SumCommissionAsync(agentCabinIds, monthStart, nextMonthStart, cancellationToken);
            var previousMonthCommission = await SumCommissionAsync(agentCabinIds, previousMonthStart, monthStart, cancellationToken);

            var leaderboard = await BuildLeaderboardSnapshotAsync(monthStart, nextMonthStart, cancellationToken);
            var leaderboardRank = leaderboard.FindIndex(x => x.OwnerUserId == agentId) + 1;
            if (leaderboardRank == 0)
            {
                leaderboardRank = Math.Max(1, leaderboard.Count + 1);
            }

            var salesGrowthPercentage = CalculateGrowthPercentage(totalSalesThisMonth, previousMonthSales);
            var commissionGrowthPercentage = CalculateGrowthPercentage(currentMonthCommission, previousMonthCommission);

            return new AgentDashboardStatsDto
            {
                TotalSalesThisMonth = totalSalesThisMonth,
                CommissionPending = commissionPending,
                CommissionReceived = commissionReceived,
                TotalActiveReferrals = totalStudentsFromReferral,
                TotalStudentsFromReferral = totalStudentsFromReferral,
                SalesGrowthPercentage = salesGrowthPercentage,
                CommissionGrowthPercentage = commissionGrowthPercentage,
                LeaderboardRank = leaderboardRank
            };
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error retrieving agent dashboard stats for agent {AgentId}", agentId);
            throw;
        }
    }

    public async Task<List<SalesDataDto>> GetSalesChartAsync(Guid agentId, int month = 0, CancellationToken cancellationToken = default)
    {
        var agentCabinIds = await GetAgentCabinIdsAsync(agentId, cancellationToken);
        if (agentCabinIds.Count == 0)
        {
            return new List<SalesDataDto>();
        }

        var (fromUtc, toUtc) = ResolveMonthRange(month, DateTime.UtcNow);

        var salesByDay = await _context.Orders
            .AsNoTracking()
            .Where(o =>
                o.CabinId.HasValue
                && agentCabinIds.Contains(o.CabinId.Value)
                && o.Status == OrderStatusPaid
                && o.PaidAt.HasValue
                && o.PaidAt.Value >= fromUtc
                && o.PaidAt.Value < toUtc)
            .GroupBy(o => o.PaidAt!.Value.Date)
            .Select(group => new
            {
                Date = group.Key,
                Amount = group.Sum(x => x.TotalAmount),
                OrdersCount = group.Count()
            })
            .ToListAsync(cancellationToken);

        return salesByDay
            .OrderBy(x => x.Date)
            .Select(x => new SalesDataDto
            {
                Week = x.Date.ToString("yyyy-MM-dd"),
                Amount = x.Amount,
                CoursesSold = x.OrdersCount
            })
            .ToList();
    }

    public async Task<List<ReferralDto>> GetReferralsAsync(Guid agentId, int page = 1, int pageSize = 20, string? status = null, CancellationToken cancellationToken = default)
    {
        var agentCabinIds = await GetAgentCabinIdsAsync(agentId, cancellationToken);
        if (agentCabinIds.Count == 0)
        {
            return new List<ReferralDto>();
        }

        var normalizedStatus = string.IsNullOrWhiteSpace(status)
            ? null
            : status.Trim().ToUpperInvariant();

        var safePage = Math.Max(1, page);
        var safePageSize = Math.Clamp(pageSize, 1, 100);

        IQueryable<SKVI.Domain.Entities.CommissionLedger> query = _context.CommissionLedgers
            .AsNoTracking()
            .Where(x => agentCabinIds.Contains(x.CabinId))
            .Include(x => x.Cabin)
                .ThenInclude(c => c.OwnerUser)
            .Include(x => x.Order)
                .ThenInclude(o => o.Buyer)
            .OrderByDescending(x => x.CreatedAt);

        if (!string.IsNullOrWhiteSpace(normalizedStatus))
        {
            query = query.Where(x => x.Status == normalizedStatus);
        }

        var ledgers = await query
            .Skip((safePage - 1) * safePageSize)
            .Take(safePageSize)
            .ToListAsync(cancellationToken);

        return ledgers.Select(ledger =>
        {
            var order = ledger.Order;
            var customerName = FirstNonEmpty(order.Buyer?.FullName, order.Buyer?.Email, "Unknown");
            var customerEmail = FirstNonEmpty(order.Buyer?.Email, "-");
            var referrerName = FirstNonEmpty(ledger.Cabin.OwnerUser?.FullName, ledger.Cabin.OwnerUser?.Email, ledger.Cabin.Name, "Agent");
            var normalizedLedgerStatus = NormalizeCommissionStatus(ledger.Status);
            var salesAmount = order.TotalAmount;

            return new ReferralDto
            {
                Id = ledger.Id.ToString(),
                ReferrerName = referrerName,
                CustomerEmail = customerEmail,
                CustomerName = customerName,
                Status = normalizedLedgerStatus,
                SalesAmount = salesAmount,
                CommissionPercentage = salesAmount > 0
                    ? decimal.Round((ledger.Amount / salesAmount) * 100m, 2, MidpointRounding.AwayFromZero)
                    : 0,
                CommissionAmount = ledger.Amount,
                CreatedAt = ledger.CreatedAt,
                ApprovedAt = normalizedLedgerStatus == CommissionStatusApproved || normalizedLedgerStatus == CommissionStatusPaid
                    ? ledger.CreatedAt
                    : null,
                PaidAt = normalizedLedgerStatus == CommissionStatusPaid
                    ? (order.PaidAt ?? ledger.CreatedAt)
                    : null
            };
        }).ToList();
    }

    public async Task<CommissionBreakdownDto> GetCommissionAsync(Guid agentId, CancellationToken cancellationToken = default)
    {
        var agentCabinIds = await GetAgentCabinIdsAsync(agentId, cancellationToken);
        if (agentCabinIds.Count == 0)
        {
            return new CommissionBreakdownDto
            {
                EarningThisMonth = 0,
                PendingPayment = 0,
                TotalPaidLifetime = 0,
                History = new()
            };
        }

        var now = DateTime.UtcNow;
        var monthStart = new DateTime(now.Year, now.Month, 1, 0, 0, 0, DateTimeKind.Utc);
        var nextMonthStart = monthStart.AddMonths(1);

        var earningThisMonth = await SumCommissionAsync(agentCabinIds, monthStart, nextMonthStart, cancellationToken);

        var pendingPayment = await _context.CommissionLedgers
            .AsNoTracking()
            .Where(x =>
                agentCabinIds.Contains(x.CabinId)
                && (x.Status == CommissionStatusPending || x.Status == CommissionStatusApproved))
            .SumAsync(x => (decimal?)x.Amount, cancellationToken) ?? 0m;

        var totalPaidLifetime = await _context.CommissionLedgers
            .AsNoTracking()
            .Where(x => agentCabinIds.Contains(x.CabinId) && x.Status == CommissionStatusPaid)
            .SumAsync(x => (decimal?)x.Amount, cancellationToken) ?? 0m;

        var recentLedgers = await _context.CommissionLedgers
            .AsNoTracking()
            .Where(x => agentCabinIds.Contains(x.CabinId))
            .OrderByDescending(x => x.CreatedAt)
            .Take(20)
            .Select(x => new
            {
                x.Id,
                x.OrderId,
                x.Amount,
                x.Status,
                x.CreatedAt
            })
            .ToListAsync(cancellationToken);

        var history = recentLedgers
            .Select(x => new CommissionHistoryDto
            {
                Id = x.Id.ToString(),
                Description = $"Order #{x.OrderId.ToString()[..8]}",
                Amount = x.Amount,
                Status = NormalizeCommissionStatus(x.Status),
                Date = x.CreatedAt
            })
            .ToList();

        return new CommissionBreakdownDto
        {
            EarningThisMonth = earningThisMonth,
            PendingPayment = pendingPayment,
            TotalPaidLifetime = totalPaidLifetime,
            History = history
        };
    }

    public async Task<List<AgentStudentDto>> GetStudentsAsync(Guid agentId, int page = 1, int pageSize = 20, CancellationToken cancellationToken = default)
    {
        try
        {
            var agentCabinIds = await GetAgentCabinIdsAsync(agentId, cancellationToken);
            if (agentCabinIds.Count == 0)
            {
                return new List<AgentStudentDto>();
            }

            var referredStudentIds = await _context.Orders
                .AsNoTracking()
                .Where(o =>
                    o.CabinId.HasValue
                    && agentCabinIds.Contains(o.CabinId.Value)
                    && o.Status == OrderStatusPaid)
                .Select(o => o.BuyerId)
                .Distinct()
                .ToListAsync(cancellationToken);

            if (referredStudentIds.Count == 0)
            {
                return new List<AgentStudentDto>();
            }

            var safePage = Math.Max(1, page);
            var safePageSize = Math.Clamp(pageSize, 1, 100);

            var students = await _context.Users
                .AsNoTracking()
                .Where(u => u.Role == "STUDENT" && !u.IsDeleted)
                .Where(u => referredStudentIds.Contains(u.Id))
                .OrderByDescending(u => u.CreatedAt)
                .Skip((safePage - 1) * safePageSize)
                .Take(safePageSize)
                .Select(u => new AgentStudentDto
                {
                    Id = u.Id,
                    Email = u.Email,
                    FullName = u.FullName,
                    TotalCoursesEnrolled = u.Enrollments.Count,
                    CoursesCompleted = u.Enrollments.Count(e => e.CompletedAt.HasValue),
                    AverageCompletionRate = u.Enrollments.Count > 0 
                        ? decimal.Round((decimal)u.Enrollments.Count(e => e.CompletedAt.HasValue) * 100m / u.Enrollments.Count, 2, MidpointRounding.AwayFromZero)
                        : 0,
                    EnrolledDate = u.CreatedAt
                })
                .ToListAsync(cancellationToken);

            return students;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error retrieving students for agent {AgentId}", agentId);
            throw;
        }
    }

    public async Task<List<LeaderboardEntryDto>> GetLeaderboardAsync(CancellationToken cancellationToken = default)
    {
        var now = DateTime.UtcNow;
        var monthStart = new DateTime(now.Year, now.Month, 1, 0, 0, 0, DateTimeKind.Utc);
        var nextMonthStart = monthStart.AddMonths(1);

        var leaderboard = await BuildLeaderboardSnapshotAsync(monthStart, nextMonthStart, cancellationToken);
        return leaderboard
            .Select((entry, index) => new LeaderboardEntryDto
            {
                Rank = index + 1,
                AgentName = entry.AgentName,
                TotalSales = entry.TotalSales,
                StudentsEnrolled = entry.StudentsEnrolled,
                Commission = entry.Commission,
                IsCurrentAgent = false,
                BonusThreshold = 0
            })
            .ToList();
    }

    public async Task<ReferralLinkResponseDto> GenerateReferralLinkAsync(Guid agentId, GenerateReferralLinkRequestDto request, CancellationToken cancellationToken = default)
    {
        // TODO: Implement referral link generation
        var code = request.CustomCode ?? Guid.NewGuid().ToString().Substring(0, 8).ToUpper();
        
        return await Task.FromResult(new ReferralLinkResponseDto
        {
            Code = code,
            Link = $"https://nhinanchualanh.vn/register?ref={code}",
            CopyText = code,
            CreatedAt = DateTime.UtcNow
        });
    }

    public async Task<AgentReportDto> GetReportAsync(Guid agentId, int year, int month, CancellationToken cancellationToken = default)
    {
        var agentCabinIds = await GetAgentCabinIdsAsync(agentId, cancellationToken);
        if (agentCabinIds.Count == 0)
        {
            return new AgentReportDto
            {
                Month = $"{year:0000}-{month:00}",
                TotalSales = 0,
                ReferralsCount = 0,
                CommissionEarned = 0,
                SalesBreakdown = new()
            };
        }

        var now = DateTime.UtcNow;
        var safeYear = year > 0 ? year : now.Year;
        var safeMonth = month switch
        {
            >= 1 and <= 12 => month,
            >= 0 and <= 11 => month + 1,
            _ => now.Month
        };

        var monthStart = new DateTime(safeYear, safeMonth, 1, 0, 0, 0, DateTimeKind.Utc);
        var nextMonthStart = monthStart.AddMonths(1);

        var totalSales = await SumPaidOrderSalesAsync(agentCabinIds, monthStart, nextMonthStart, cancellationToken);

        var referralsCount = await _context.Orders
            .AsNoTracking()
            .Where(o =>
                o.CabinId.HasValue
                && agentCabinIds.Contains(o.CabinId.Value)
                && o.Status == OrderStatusPaid
                && o.PaidAt.HasValue
                && o.PaidAt.Value >= monthStart
                && o.PaidAt.Value < nextMonthStart)
            .Select(o => o.BuyerId)
            .Distinct()
            .CountAsync(cancellationToken);

        var commissionEarned = await SumCommissionAsync(agentCabinIds, monthStart, nextMonthStart, cancellationToken);

        var salesByDay = await _context.Orders
            .AsNoTracking()
            .Where(o =>
                o.CabinId.HasValue
                && agentCabinIds.Contains(o.CabinId.Value)
                && o.Status == OrderStatusPaid
                && o.PaidAt.HasValue
                && o.PaidAt.Value >= monthStart
                && o.PaidAt.Value < nextMonthStart)
            .GroupBy(o => o.PaidAt!.Value.Date)
            .Select(group => new
            {
                Date = group.Key,
                Amount = group.Sum(x => x.TotalAmount),
                OrdersCount = group.Count()
            })
            .ToListAsync(cancellationToken);

        return new AgentReportDto
        {
            Month = $"{safeYear:0000}-{safeMonth:00}",
            TotalSales = totalSales,
            ReferralsCount = referralsCount,
            CommissionEarned = commissionEarned,
            SalesBreakdown = salesByDay
                .OrderBy(x => x.Date)
                .Select(x => new SalesDataDto
                {
                    Week = x.Date.ToString("yyyy-MM-dd"),
                    Amount = x.Amount,
                    CoursesSold = x.OrdersCount
                })
                .ToList()
        };
    }

    private async Task<List<Guid>> GetAgentCabinIdsAsync(Guid agentId, CancellationToken cancellationToken)
    {
        return await _context.Cabins
            .AsNoTracking()
            .Where(c => c.OwnerUserId == agentId)
            .Select(c => c.Id)
            .ToListAsync(cancellationToken);
    }

    private async Task<decimal> SumPaidOrderSalesAsync(
        IReadOnlyList<Guid> cabinIds,
        DateTime fromUtc,
        DateTime toUtc,
        CancellationToken cancellationToken)
    {
        return await _context.Orders
            .AsNoTracking()
            .Where(o =>
                o.CabinId.HasValue
                && cabinIds.Contains(o.CabinId.Value)
                && o.Status == OrderStatusPaid
                && o.PaidAt.HasValue
                && o.PaidAt.Value >= fromUtc
                && o.PaidAt.Value < toUtc)
            .SumAsync(o => (decimal?)o.TotalAmount, cancellationToken) ?? 0m;
    }

    private async Task<decimal> SumCommissionAsync(
        IReadOnlyList<Guid> cabinIds,
        DateTime fromUtc,
        DateTime toUtc,
        CancellationToken cancellationToken)
    {
        return await _context.CommissionLedgers
            .AsNoTracking()
            .Where(x =>
                cabinIds.Contains(x.CabinId)
                && x.CreatedAt >= fromUtc
                && x.CreatedAt < toUtc)
            .SumAsync(x => (decimal?)x.Amount, cancellationToken) ?? 0m;
    }

    private async Task<List<LeaderboardSnapshotEntry>> BuildLeaderboardSnapshotAsync(
        DateTime fromUtc,
        DateTime toUtc,
        CancellationToken cancellationToken)
    {
        var salesByOwner = await (
            from order in _context.Orders.AsNoTracking()
            join cabin in _context.Cabins.AsNoTracking() on order.CabinId!.Value equals cabin.Id
            where order.CabinId.HasValue
                  && order.Status == OrderStatusPaid
                  && order.PaidAt.HasValue
                  && order.PaidAt.Value >= fromUtc
                  && order.PaidAt.Value < toUtc
            group order by cabin.OwnerUserId into grouped
            select new
            {
                OwnerUserId = grouped.Key,
                TotalSales = grouped.Sum(x => x.TotalAmount),
                StudentsEnrolled = grouped.Select(x => x.BuyerId).Distinct().Count()
            })
            .ToListAsync(cancellationToken);

        if (salesByOwner.Count == 0)
        {
            return new List<LeaderboardSnapshotEntry>();
        }

        var ownerIds = salesByOwner.Select(x => x.OwnerUserId).Distinct().ToList();

        var owners = await _context.Users
            .AsNoTracking()
            .Where(u => ownerIds.Contains(u.Id))
            .Select(u => new { u.Id, u.FullName, u.Email })
            .ToListAsync(cancellationToken);

        var ownerNames = owners.ToDictionary(
            x => x.Id,
            x => FirstNonEmpty(x.FullName, x.Email, "Agent"));

        var commissionByOwner = await (
            from ledger in _context.CommissionLedgers.AsNoTracking()
            join cabin in _context.Cabins.AsNoTracking() on ledger.CabinId equals cabin.Id
            where ownerIds.Contains(cabin.OwnerUserId)
                  && ledger.CreatedAt >= fromUtc
                  && ledger.CreatedAt < toUtc
            group ledger by cabin.OwnerUserId into grouped
            select new
            {
                OwnerUserId = grouped.Key,
                Commission = grouped.Sum(x => x.Amount)
            })
            .ToDictionaryAsync(x => x.OwnerUserId, x => x.Commission, cancellationToken);

        return salesByOwner
            .Select(x => new LeaderboardSnapshotEntry
            {
                OwnerUserId = x.OwnerUserId,
                AgentName = ownerNames.TryGetValue(x.OwnerUserId, out var name)
                    ? name
                    : "Agent",
                TotalSales = x.TotalSales,
                StudentsEnrolled = x.StudentsEnrolled,
                Commission = commissionByOwner.TryGetValue(x.OwnerUserId, out var commission)
                    ? commission
                    : 0m
            })
            .OrderByDescending(x => x.TotalSales)
            .ThenBy(x => x.AgentName)
            .ToList();
    }

    private static decimal CalculateGrowthPercentage(decimal current, decimal previous)
    {
        if (previous <= 0)
        {
            return current > 0 ? 100m : 0m;
        }

        return decimal.Round(((current - previous) / previous) * 100m, 2, MidpointRounding.AwayFromZero);
    }

    private static (DateTime FromUtc, DateTime ToUtc) ResolveMonthRange(int month, DateTime nowUtc)
    {
        var resolvedMonth = month switch
        {
            >= 1 and <= 12 => month,
            >= 0 and <= 11 => month + 1,
            _ => nowUtc.Month
        };

        var fromUtc = new DateTime(nowUtc.Year, resolvedMonth, 1, 0, 0, 0, DateTimeKind.Utc);
        return (fromUtc, fromUtc.AddMonths(1));
    }

    private static string NormalizeCommissionStatus(string? status)
    {
        var normalized = status?.Trim().ToUpperInvariant();
        return normalized switch
        {
            CommissionStatusApproved => CommissionStatusApproved,
            CommissionStatusPaid => CommissionStatusPaid,
            _ => CommissionStatusPending
        };
    }

    private static string FirstNonEmpty(params string?[] values)
    {
        foreach (var value in values)
        {
            if (!string.IsNullOrWhiteSpace(value))
            {
                return value.Trim();
            }
        }

        return string.Empty;
    }

    private sealed class LeaderboardSnapshotEntry
    {
        public Guid OwnerUserId { get; set; }
        public string AgentName { get; set; } = string.Empty;
        public decimal TotalSales { get; set; }
        public int StudentsEnrolled { get; set; }
        public decimal Commission { get; set; }
    }
}
