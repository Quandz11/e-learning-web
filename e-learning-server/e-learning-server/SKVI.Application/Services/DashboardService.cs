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
            var sixtyDaysAgo = now.AddDays(-60);

            // Total Students (users with STUDENT role)
            var totalStudents = await _context.Users
                .Where(u => u.Role == "STUDENT" && !u.IsDeleted)
                .CountAsync(cancellationToken);

            var studentsLastPeriod = await _context.Users
                .Where(u => u.Role == "STUDENT" && !u.IsDeleted && u.CreatedAt < thirtyDaysAgo)
                .CountAsync(cancellationToken);

            var studentGrowth = studentsLastPeriod > 0 
                ? ((totalStudents - studentsLastPeriod) / (decimal)studentsLastPeriod) * 100 
                : 0;

            // Total Revenue (sum of all completed orders/enrollments)
            // Note: Assuming revenue from enrollments where payment is completed
            // If you have an Orders table, use that instead
            var totalRevenue = await _context.Enrollments
                .Where(e => e.EnrolledAt >= DateTime.MinValue) // All enrollments
                .Join(_context.Courses,
                    e => e.CourseId,
                    c => c.Id,
                    (e, c) => c.Price)
                .SumAsync(cancellationToken);

            var revenueLastPeriod = await _context.Enrollments
                .Where(e => e.EnrolledAt < thirtyDaysAgo)
                .Join(_context.Courses,
                    e => e.CourseId,
                    c => c.Id,
                    (e, c) => c.Price)
                .SumAsync(cancellationToken);

            var revenueGrowth = revenueLastPeriod > 0 
                ? ((totalRevenue - revenueLastPeriod) / revenueLastPeriod) * 100 
                : 0;

            // Agent Revenue (revenue from CABIN_OWNER referrals)
            // This is simplified - you might want to add a referral/commission system
            var agentRevenue = await _context.Enrollments
                .Where(e => e.EnrolledAt >= DateTime.MinValue)
                .Join(_context.Courses,
                    e => e.CourseId,
                    c => c.Id,
                    (e, c) => c.Price * 0.15m) // Assuming 15% commission
                .SumAsync(cancellationToken);

            var agentRevenueLastPeriod = await _context.Enrollments
                .Where(e => e.EnrolledAt < thirtyDaysAgo)
                .Join(_context.Courses,
                    e => e.CourseId,
                    c => c.Id,
                    (e, c) => c.Price * 0.15m)
                .SumAsync(cancellationToken);

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
}
