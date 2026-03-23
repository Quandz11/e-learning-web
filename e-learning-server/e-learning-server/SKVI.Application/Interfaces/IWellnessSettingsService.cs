using SKVI.Application.DTOs.Wellness;

namespace SKVI.Application.Interfaces;

public interface IWellnessSettingsService
{
    Task<WellnessCheckoutConfigDto> GetCheckoutConfigAsync(CancellationToken cancellationToken = default);
    Task<WellnessAdminSettingsDto> GetAdminSettingsAsync(CancellationToken cancellationToken = default);
    Task<WellnessAdminSettingsDto> UpdateSettingsAsync(
        Guid actorUserId,
        UpdateWellnessAdminSettingsRequest request,
        CancellationToken cancellationToken = default);
    Task<List<WellnessUserPackageDto>> GetUserPackagesAsync(Guid userId, CancellationToken cancellationToken = default);
    Task<WellnessUserPackageDto> GrantPackageToUserAsync(
        Guid actorUserId,
        Guid userId,
        GrantWellnessUserPackageRequest request,
        CancellationToken cancellationToken = default);
    Task<WellnessUserPackageDto> UpdateUserPackageAsync(
        Guid actorUserId,
        Guid userId,
        Guid userPackageId,
        UpdateWellnessUserPackageRequest request,
        CancellationToken cancellationToken = default);
}
