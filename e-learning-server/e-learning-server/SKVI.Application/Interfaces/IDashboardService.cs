using SKVI.Application.DTOs.Dashboard;

namespace SKVI.Application.Interfaces;

public interface IDashboardService
{
    Task<DashboardStatsDto> GetDashboardStatsAsync(CancellationToken cancellationToken = default);
}
