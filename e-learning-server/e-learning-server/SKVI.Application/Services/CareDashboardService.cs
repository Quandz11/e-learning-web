using Microsoft.EntityFrameworkCore;
using SKVI.Application.DTOs.Dashboard;
using SKVI.Application.Interfaces;
using SKVI.Infrastructure;

namespace SKVI.Application.Services;

public class CareDashboardService : ICareDashboardService
{
    private readonly ApplicationDbContext _context;
    private readonly ILogger<CareDashboardService> _logger;

    public CareDashboardService(ApplicationDbContext context, ILogger<CareDashboardService> logger)
    {
        _context = context;
        _logger = logger;
    }

    public async Task<CareDashboardStatsDto> GetStatsAsync(CancellationToken cancellationToken = default)
    {
        try
        {
            var now = DateTime.UtcNow;
            var thirtyDaysAgo = now.AddDays(-30);
            var sixtyDaysAgo = now.AddDays(-60);

            // TODO: Replace with actual Support Ticket table when created
            var pendingTickets = 0;  // Placeholder

            // TODO: Calculate from satisfaction ratings in support tickets
            var avgSatisfaction = 4.5m;  // Placeholder

            // TODO: Calculate from ticket resolution time
            var avgResponseTime = 2.5m;  // hours, placeholder

            var totalCustomersThisMonth = await _context.Users
                .Where(u => u.Role == "STUDENT" && !u.IsDeleted && u.CreatedAt >= thirtyDaysAgo)
                .CountAsync(cancellationToken);

            // Calculate satisfaction trend
            // TODO: Use actual satisfaction data from previous month
            var satisfactionTrend = 5.0m;  // percentage, placeholder

            return new CareDashboardStatsDto
            {
                PendingTickets = pendingTickets,
                AverageSatisfactionScore = avgSatisfaction,
                AverageResponseTimeHours = avgResponseTime,
                TotalCustomersThisMonth = totalCustomersThisMonth,
                SatisfactionTrendPercentage = satisfactionTrend
            };
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error retrieving care dashboard stats");
            throw;
        }
    }

    public async Task<List<SupportTicketDto>> GetSupportTicketsAsync(int page = 1, int pageSize = 20, string? status = null, string? search = null, CancellationToken cancellationToken = default)
    {
        // TODO: Implement when SupportTicket table is created
        return await Task.FromResult(new List<SupportTicketDto>());
    }

    public async Task<SupportTicketDto> GetSupportTicketAsync(string ticketId, CancellationToken cancellationToken = default)
    {
        // TODO: Implement when SupportTicket table is created
        return await Task.FromResult(new SupportTicketDto { Id = ticketId });
    }

    public async Task<string> CreateSupportTicketAsync(CreateSupportTicketDto request, CancellationToken cancellationToken = default)
    {
        // TODO: Implement when SupportTicket table is created
        return await Task.FromResult(Guid.NewGuid().ToString());
    }

    public async Task UpdateSupportTicketAsync(string ticketId, UpdateSupportTicketDto request, CancellationToken cancellationToken = default)
    {
        // TODO: Implement when SupportTicket table is created
        await Task.CompletedTask;
    }

    public async Task<List<CareCustomerDto>> GetCustomersAsync(int page = 1, int pageSize = 20, string? search = null, CancellationToken cancellationToken = default)
    {
        try
        {
            var query = _context.Users
                .Where(u => u.Role == "STUDENT" && !u.IsDeleted);

            if (!string.IsNullOrWhiteSpace(search))
            {
                query = query.Where(u => u.FullName!.Contains(search) || u.Email.Contains(search));
            }

            var customers = await query
                .OrderByDescending(u => u.CreatedAt)
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .Select(u => new CareCustomerDto
                {
                    Id = u.Id,
                    Email = u.Email,
                    FullName = u.FullName,
                    Phone = u.Phone,
                    TotalTickets = 0,  // TODO: Count from SupportTicket table
                    ResolvedTickets = 0,  // TODO: Count from SupportTicket table
                    AverageSatisfaction = null,  // TODO: Calculate from ratings
                    IsEmailVerified = u.IsEmailVerified,
                    IsPhoneVerified = u.IsPhoneVerified,
                    CreatedAt = u.CreatedAt
                })
                .ToListAsync(cancellationToken);

            return customers;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error retrieving customers");
            throw;
        }
    }

    public async Task<List<SatisfactionFeedbackDto>> GetSatisfactionTrendAsync(int days = 30, CancellationToken cancellationToken = default)
    {
        // TODO: Implement with actual satisfaction data
        return await Task.FromResult(new List<SatisfactionFeedbackDto>());
    }

    public async Task<List<CareChatMessageDto>> GetInboxMessagesAsync(CancellationToken cancellationToken = default)
    {
        // TODO: Implement when chat/message system is created
        return await Task.FromResult(new List<CareChatMessageDto>());
    }
}
