using SKVI.Application.DTOs.Wellness;

namespace SKVI.Application.Interfaces;

public interface IWellnessAccessService
{
    Task<WellnessAccessEvaluationDto> EvaluateAccessAsync(
        Guid userId,
        string? requiredPackageType = null,
        CancellationToken cancellationToken = default);

    Task EnsureAccessAsync(
        Guid userId,
        string packageType,
        CancellationToken cancellationToken = default);
}
