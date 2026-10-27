using SKVI.Application.DTOs.Running;

namespace SKVI.Application.Interfaces;

public interface IRunningService
{
    Task<RunningActivityDto> CreateActivityAsync(Guid userId, CreateRunningActivityRequest request, CancellationToken cancellationToken = default);
    Task<PaginatedRunningActivitiesDto> GetActivitiesAsync(Guid userId, int page = 1, int pageSize = 20, int? month = null, int? year = null, CancellationToken cancellationToken = default);
    Task<RunningActivityDto?> GetActivityByIdAsync(Guid userId, Guid activityId, CancellationToken cancellationToken = default);
    Task<bool> DeleteActivityAsync(Guid userId, Guid activityId, CancellationToken cancellationToken = default);
    Task<RunningSummaryDto> GetSummaryAsync(Guid userId, CancellationToken cancellationToken = default);
}
