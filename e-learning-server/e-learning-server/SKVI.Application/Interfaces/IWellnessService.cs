using SKVI.Application.DTOs.Wellness;

namespace SKVI.Application.Interfaces;

public interface IWellnessService
{
    Task<WellnessDashboardDto> GetDashboardAsync(Guid userId, CancellationToken cancellationToken = default);
    Task<WellnessPlanDto> UpsertPlanAsync(Guid userId, UpsertWellnessPlanRequest request, CancellationToken cancellationToken = default);
    Task<WellnessPlanDto> UpdateScheduleAsync(Guid userId, Guid planId, UpdateWellnessScheduleRequest request, CancellationToken cancellationToken = default);
    Task<WellnessDailyLogDto> UpsertDailyLogAsync(Guid userId, Guid planId, UpsertWellnessDailyLogRequest request, CancellationToken cancellationToken = default);
    Task<List<WellnessCalendarDayDto>> GetCalendarAsync(Guid userId, Guid planId, CancellationToken cancellationToken = default);
    Task<WellnessCoachReplyDto> AskMoodCoachAsync(Guid userId, Guid planId, WellnessCoachMoodRequest request, CancellationToken cancellationToken = default);
    Task<WellnessMealSuggestionDto> GenerateMealSuggestionAsync(Guid userId, Guid planId, WellnessCoachMealRequest request, CancellationToken cancellationToken = default);
    Task<WellnessWeightProgressDto> GetWeightProgressAsync(Guid userId, Guid planId, CancellationToken cancellationToken = default);
    Task<WellnessProgressTimelineDto> GetProgressTimelineAsync(Guid userId, Guid planId, int days = 30, bool includeFuture = false, CancellationToken cancellationToken = default);

    Task<List<WellnessResourceItemDto>> GetResourcesAsync(CancellationToken cancellationToken = default);
    Task<WellnessResourceItemDto> CreateResourceAsync(Guid actorUserId, WellnessResourceUpsertRequest request, CancellationToken cancellationToken = default);
    Task<WellnessResourceItemDto> UpdateResourceAsync(Guid actorUserId, Guid resourceId, WellnessResourceUpsertRequest request, CancellationToken cancellationToken = default);
}
