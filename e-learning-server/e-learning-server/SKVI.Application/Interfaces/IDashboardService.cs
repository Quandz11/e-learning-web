using SKVI.Application.DTOs.Dashboard;

namespace SKVI.Application.Interfaces;

public interface IDashboardService
{
    Task<DashboardStatsDto> GetDashboardStatsAsync(CancellationToken cancellationToken = default);
    Task<List<RecentOrderDto>> GetRecentOrdersAsync(int limit = 10, CancellationToken cancellationToken = default);
    Task<List<TopAgentDto>> GetTopAgentsAsync(int limit = 5, CancellationToken cancellationToken = default);
}
