using SKVI.Application.DTOs.Referrals;
using SKVI.Shared;

namespace SKVI.Application.Interfaces;

public interface IUserReferralService
{
    Task<UserReferralOverviewDto> GetOrCreateMyReferralAsync(Guid userId, CancellationToken cancellationToken = default);
    Task ApplyReferralCodeForNewUserAsync(Guid newUserId, string referralCode, CancellationToken cancellationToken = default);
    Task CompleteReferralForUserAsync(Guid referredUserId, CancellationToken cancellationToken = default);
    Task<PagedResult<AdminUserReferralItemDto>> GetAdminPagedAsync(string? search, bool? isActive, int page, int pageSize, CancellationToken cancellationToken = default);
    Task<AdminUserReferralItemDto> UpdateForAdminAsync(Guid referralId, AdminUpdateUserReferralRequest request, CancellationToken cancellationToken = default);
    Task<AdminBulkUpdateDiscountPercentResultDto> BulkUpdateDiscountPercentForAdminAsync(AdminBulkUpdateDiscountPercentRequest request, CancellationToken cancellationToken = default);
    Task<AdminUserReferralItemDto> RegenerateDiscountCodeForAdminAsync(Guid referralId, CancellationToken cancellationToken = default);
}
