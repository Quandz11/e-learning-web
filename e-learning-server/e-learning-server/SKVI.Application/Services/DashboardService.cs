using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using SKVI.Application.DTOs.Dashboard;
using SKVI.Application.Interfaces;
using SKVI.Infrastructure;

namespace SKVI.Application.Services;

public class DashboardService : IDashboardService
{
    private readonly ApplicationDbContext _context;
    private readonly ILogger<DashboardService> _logger;

    public DashboardService(ApplicationDbContext context, ILogger<DashboardService> logger)
    {
        _context = context;
        _logger = logger;
    }

    public async Task<DashboardStatsDto> GetDashboardStatsAsync(CancellationToken cancellationToken = default)
    {
        try
        {
            var now = DateTime.UtcNow;
            var thirtyDaysAgo = now.AddDays(-30);

            // Total Students (users with STUDENT or USER role)
            var totalStudents = await _context.Users
                .Where(u => (u.Role == "STUDENT" || u.Role == "USER") && !u.IsDeleted)
                .CountAsync(cancellationToken);

            var studentsLastPeriod = await _context.Users
                .Where(u => (u.Role == "STUDENT" || u.Role == "USER") && !u.IsDeleted && u.CreatedAt < thirtyDaysAgo)
                .CountAsync(cancellationToken);

            var studentGrowth = studentsLastPeriod > 0 
                ? ((totalStudents - studentsLastPeriod) / (decimal)studentsLastPeriod) * 100 
                : 0;

            // Total Revenue (sum of all completed orders / enrollments)
            var paidOrdersRevenue = await _context.Orders
                .Where(o => o.Status == "PAID")
                .SumAsync(o => (decimal?)o.TotalAmount, cancellationToken) ?? 0m;

            var enrollmentsRevenue = await _context.Enrollments
                .Join(_context.Courses,
                    e => e.CourseId,
                    c => c.Id,
                    (e, c) => (decimal?)c.Price)
                .SumAsync(cancellationToken) ?? 0m;

            var totalRevenue = paidOrdersRevenue > 0 ? paidOrdersRevenue : enrollmentsRevenue;

            var paidOrdersLastPeriod = await _context.Orders
                .Where(o => o.Status == "PAID" && o.CreatedAt < thirtyDaysAgo)
                .SumAsync(o => (decimal?)o.TotalAmount, cancellationToken) ?? 0m;

            var enrollmentsLastPeriod = await _context.Enrollments
                .Where(e => e.EnrolledAt < thirtyDaysAgo)
                .Join(_context.Courses,
                    e => e.CourseId,
                    c => c.Id,
                    (e, c) => (decimal?)c.Price)
                .SumAsync(cancellationToken) ?? 0m;

            var revenueLastPeriod = paidOrdersRevenue > 0 ? paidOrdersLastPeriod : enrollmentsLastPeriod;

            var revenueGrowth = revenueLastPeriod > 0 
                ? ((totalRevenue - revenueLastPeriod) / revenueLastPeriod) * 100 
                : 0;

            // Agent Revenue (revenue from orders attributed to a cabin / agent)
            var agentOrdersRevenue = await _context.Orders
                .Where(o => o.Status == "PAID" && o.CabinId.HasValue)
                .SumAsync(o => (decimal?)o.TotalAmount, cancellationToken) ?? 0m;

            var agentCommissionRevenue = await _context.CommissionLedgers
                .SumAsync(c => (decimal?)c.Amount, cancellationToken) ?? 0m;

            var agentRevenue = agentOrdersRevenue > 0 
                ? agentOrdersRevenue 
                : (agentCommissionRevenue > 0 ? agentCommissionRevenue : (totalRevenue * 0.15m));

            var agentOrdersLastPeriod = await _context.Orders
                .Where(o => o.Status == "PAID" && o.CabinId.HasValue && o.CreatedAt < thirtyDaysAgo)
                .SumAsync(o => (decimal?)o.TotalAmount, cancellationToken) ?? 0m;

            var agentCommissionLastPeriod = await _context.CommissionLedgers
                .Where(c => c.CreatedAt < thirtyDaysAgo)
                .SumAsync(c => (decimal?)c.Amount, cancellationToken) ?? 0m;

            var agentRevenueLastPeriod = agentOrdersRevenue > 0 
                ? agentOrdersLastPeriod 
                : (agentCommissionRevenue > 0 ? agentCommissionLastPeriod : (revenueLastPeriod * 0.15m));

            var agentRevenueGrowth = agentRevenueLastPeriod > 0 
                ? ((agentRevenue - agentRevenueLastPeriod) / agentRevenueLastPeriod) * 100 
                : 0;

            // Active Courses (published courses)
            var activeCourses = await _context.Courses
                .Where(c => c.IsPublished)
                .CountAsync(cancellationToken);

            var activeCoursesLastPeriod = await _context.Courses
                .Where(c => c.IsPublished && c.CreatedAt < thirtyDaysAgo)
                .CountAsync(cancellationToken);

            var coursesGrowth = activeCoursesLastPeriod > 0 
                ? ((activeCourses - activeCoursesLastPeriod) / (decimal)activeCoursesLastPeriod) * 100 
                : 0;

            return new DashboardStatsDto
            {
                TotalStudents = totalStudents,
                TotalRevenue = totalRevenue,
                AgentRevenue = agentRevenue,
                ActiveCourses = activeCourses,
                StudentGrowthPercentage = Math.Round(studentGrowth, 1),
                RevenueGrowthPercentage = Math.Round(revenueGrowth, 1),
                AgentRevenueGrowthPercentage = Math.Round(agentRevenueGrowth, 1),
                CoursesGrowthPercentage = Math.Round(coursesGrowth, 1)
            };
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error getting dashboard stats");
            throw;
        }
    }

    public async Task<List<RecentOrderDto>> GetRecentOrdersAsync(int limit = 10, CancellationToken cancellationToken = default)
    {
        try
        {
            var safeLimit = Math.Clamp(limit, 1, 50);

            // 1. First try to get from Orders table
            var orders = await _context.Orders
                .AsNoTracking()
                .Include(o => o.Buyer)
                .Include(o => o.OrderItems)
                    .ThenInclude(oi => oi.Course)
                .Include(o => o.WellnessPackage)
                .OrderByDescending(o => o.CreatedAt)
                .Take(safeLimit)
                .ToListAsync(cancellationToken);

            if (orders.Count > 0)
            {
                return orders.Select(o =>
                {
                    var studentName = !string.IsNullOrWhiteSpace(o.Buyer?.FullName) 
                        ? o.Buyer.FullName 
                        : (!string.IsNullOrWhiteSpace(o.Buyer?.Email) ? o.Buyer.Email : "H\u1ecdc vi\u00ean");

                    var courseTitles = o.OrderItems
                        .Where(oi => oi.Course != null && !string.IsNullOrWhiteSpace(oi.Course.Title))
                        .Select(oi => oi.Course.Title)
                        .ToList();

                    var courseName = courseTitles.Count > 0
                        ? string.Join(", ", courseTitles)
                        : (o.WellnessPackage != null ? o.WellnessPackage.Name : "Kh\u00f3a h\u1ecdc");

                    var status = o.Status?.ToUpperInvariant() switch
                    {
                        "PAID" => "paid",
                        "PENDING" or "INIT" => "pending",
                        _ => "failed"
                    };

                    var idString = o.PayOSOrderCode.HasValue 
                        ? $"#{o.PayOSOrderCode.Value}" 
                        : $"#{o.Id.ToString()[..8].ToUpperInvariant()}";

                    return new RecentOrderDto
                    {
                        Id = idString,
                        Student = studentName,
                        AvatarUrl = o.Buyer?.AvatarUrl,
                        Initials = GetInitials(studentName),
                        Course = courseName,
                        Amount = o.TotalAmount,
                        FormattedAmount = FormatCurrency(o.TotalAmount),
                        Status = status,
                        Date = o.CreatedAt,
                        FormattedDate = o.CreatedAt.ToString("dd/MM/yyyy HH:mm")
                    };
                }).ToList();
            }

            // 2. Fallback: If no Orders exist yet, use Enrollments
            var enrollments = await _context.Enrollments
                .AsNoTracking()
                .Include(e => e.User)
                .Include(e => e.Course)
                .OrderByDescending(e => e.EnrolledAt)
                .Take(safeLimit)
                .ToListAsync(cancellationToken);

            return enrollments.Select(e =>
            {
                var studentName = !string.IsNullOrWhiteSpace(e.User?.FullName)
                    ? e.User.FullName
                    : (!string.IsNullOrWhiteSpace(e.User?.Email) ? e.User.Email : "H\u1ecdc vi\u00ean");

                var courseTitle = e.Course?.Title ?? "Kh\u00f3a h\u1ecdc";
                var amount = e.Course?.Price ?? 0m;

                return new RecentOrderDto
                {
                    Id = $"#ENR-{e.Id.ToString()[..6].ToUpperInvariant()}",
                    Student = studentName,
                    AvatarUrl = e.User?.AvatarUrl,
                    Initials = GetInitials(studentName),
                    Course = courseTitle,
                    Amount = amount,
                    FormattedAmount = FormatCurrency(amount),
                    Status = "paid",
                    Date = e.EnrolledAt,
                    FormattedDate = e.EnrolledAt.ToString("dd/MM/yyyy HH:mm")
                };
            }).ToList();
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error getting recent orders for dashboard");
            throw;
        }
    }

    public async Task<List<TopAgentDto>> GetTopAgentsAsync(int limit = 5, CancellationToken cancellationToken = default)
    {
        try
        {
            var safeLimit = Math.Clamp(limit, 1, 20);

            var cabins = await _context.Cabins
                .AsNoTracking()
                .Include(c => c.OwnerUser)
                .Include(c => c.Orders)
                .Include(c => c.CommissionLedgers)
                .Where(c => c.IsActive && !c.OwnerUser.IsDeleted)
                .ToListAsync(cancellationToken);

            if (cabins.Count == 0)
            {
                return new List<TopAgentDto>();
            }

            var agentStats = cabins.Select(c =>
            {
                var paidOrders = c.Orders.Where(o => o.Status == "PAID").ToList();
                var paidRevenue = paidOrders.Sum(o => o.TotalAmount);
                var commissionSum = c.CommissionLedgers.Sum(cl => cl.Amount);

                var revenue = paidRevenue > 0 ? paidRevenue : (commissionSum > 0 ? commissionSum : c.WalletBalance);

                var agentName = !string.IsNullOrWhiteSpace(c.Name)
                    ? c.Name
                    : (!string.IsNullOrWhiteSpace(c.OwnerUser?.FullName)
                        ? c.OwnerUser.FullName
                        : c.OwnerUser?.Email ?? "\u0110\u1ea1i l\u00fd");

                return new
                {
                    Id = c.Id.ToString(),
                    Name = agentName,
                    AvatarUrl = c.OwnerUser?.AvatarUrl,
                    Revenue = revenue,
                    OrderCount = paidOrders.Count
                };
            })
            .OrderByDescending(x => x.Revenue)
            .ThenByDescending(x => x.OrderCount)
            .Take(safeLimit)
            .ToList();

            var maxRevenue = agentStats.Count > 0 ? agentStats.Max(x => x.Revenue) : 0m;

            var result = new List<TopAgentDto>();
            for (int i = 0; i < agentStats.Count; i++)
            {
                var a = agentStats[i];
                var percentage = maxRevenue > 0
                    ? Math.Round((double)(a.Revenue / maxRevenue) * 100, 1)
                    : 100.0;

                result.Add(new TopAgentDto
                {
                    Id = a.Id,
                    Name = a.Name,
                    AvatarUrl = a.AvatarUrl,
                    Revenue = a.Revenue,
                    FormattedRevenue = FormatCurrency(a.Revenue),
                    OrderCount = a.OrderCount,
                    Rank = i + 1,
                    Percentage = percentage
                });
            }

            return result;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error getting top agents for dashboard");
            throw;
        }
    }

    private static string GetInitials(string name)
    {
        if (string.IsNullOrWhiteSpace(name)) return "U";
        var parts = name.Trim().Split(' ', StringSplitOptions.RemoveEmptyEntries);
        if (parts.Length == 1) return parts[0][..1].ToUpperInvariant();
        return $"{parts[0][..1]}{parts[^1][..1]}".ToUpperInvariant();
    }

    private static string FormatCurrency(decimal amount)
    {
        return $"{amount:N0} VND";
    }
}
