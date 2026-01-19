using SKVI.Application.DTOs.Users;
using SKVI.Shared;

namespace SKVI.Application.Interfaces;

public interface IUserService
{
    Task<PagedResult<UserDto>> GetPagedAsync(string? search, string? role, string? status, int page, int pageSize, CancellationToken cancellationToken = default);
    Task<UserDto> GetByIdAsync(Guid id, CancellationToken cancellationToken = default);
    Task<UserDto> CreateAsync(CreateUserRequest request, CancellationToken cancellationToken = default);
    Task<UserDto> UpdateAsync(Guid id, UpdateUserRequest request, CancellationToken cancellationToken = default);
    Task ResetPasswordAsync(Guid id, ResetPasswordRequest request, CancellationToken cancellationToken = default);
    Task DeleteAsync(Guid id, CancellationToken cancellationToken = default);
}
