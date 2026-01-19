using Microsoft.EntityFrameworkCore;
using SKVI.Application.DTOs.Users;
using SKVI.Application.Interfaces;
using SKVI.Domain.Entities;
using SKVI.Infrastructure;
using SKVI.Infrastructure.Security;
using SKVI.Shared;

namespace SKVI.Application.Services;

public class UserService : IUserService
{
    private static readonly HashSet<string> AllowedRoles = new(new[] { "ADMIN", "CARE", "CABIN_OWNER", "STUDENT", "LECTURER" }, StringComparer.OrdinalIgnoreCase);
    private static readonly HashSet<string> AllowedStatuses = new(new[] { "ACTIVE", "INACTIVE", "SUSPENDED" }, StringComparer.OrdinalIgnoreCase);

    private readonly ApplicationDbContext _dbContext;
    private readonly IPasswordHasher _passwordHasher;

    public UserService(ApplicationDbContext dbContext, IPasswordHasher passwordHasher)
    {
        _dbContext = dbContext;
        _passwordHasher = passwordHasher;
    }

    public async Task<PagedResult<UserDto>> GetPagedAsync(string? search, string? role, string? status, int page, int pageSize, CancellationToken cancellationToken = default)
    {
        page = page <= 0 ? 1 : page;
        pageSize = pageSize <= 0 ? 20 : Math.Min(pageSize, 100);

        var query = _dbContext.Users.AsNoTracking().Where(u => !u.IsDeleted);

        if (!string.IsNullOrWhiteSpace(search))
        {
            var term = search.Trim().ToLower();
            query = query.Where(u =>
                (u.Email != null && u.Email.ToLower().Contains(term)) ||
                (u.FullName != null && u.FullName.ToLower().Contains(term)) ||
                (u.Phone != null && u.Phone.ToLower().Contains(term)));
        }

        if (!string.IsNullOrWhiteSpace(role))
        {
            query = query.Where(u => u.Role == role);
        }

        if (!string.IsNullOrWhiteSpace(status))
        {
            query = query.Where(u => u.Status == status);
        }

        var total = await query.CountAsync(cancellationToken);
        var items = await query
            .OrderByDescending(u => u.CreatedAt)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync(cancellationToken);

        return new PagedResult<UserDto>
        {
            Items = items.Select(MapToDto).ToList(),
            Total = total,
            Page = page,
            PageSize = pageSize
        };
    }

    public async Task<UserDto> GetByIdAsync(Guid id, CancellationToken cancellationToken = default)
    {
        var user = await _dbContext.Users.AsNoTracking().FirstOrDefaultAsync(u => u.Id == id && !u.IsDeleted, cancellationToken);
        if (user == null)
        {
            throw new KeyNotFoundException("User not found");
        }
        return MapToDto(user);
    }

    public async Task<UserDto> CreateAsync(CreateUserRequest request, CancellationToken cancellationToken = default)
    {
        ValidateRoleAndStatus(request.Role, request.Status);

        var email = request.Email.Trim().ToLower();
        var exists = await _dbContext.Users.AnyAsync(u => u.Email.ToLower() == email && !u.IsDeleted, cancellationToken);
        if (exists)
        {
            throw new InvalidOperationException("Email already exists");
        }

        var user = new User
        {
            Id = Guid.NewGuid(),
            Email = request.Email.Trim(),
            PasswordHash = _passwordHasher.HashPassword(request.Password),
            FullName = request.FullName?.Trim(),
            Phone = request.Phone?.Trim(),
            Role = request.Role.ToUpper(),
            Status = request.Status.ToUpper(),
            AvatarUrl = request.AvatarUrl,
            IsEmailVerified = false,
            IsPhoneVerified = false,
            CreatedAt = DateTime.UtcNow,
            UpdatedAt = DateTime.UtcNow,
            IsDeleted = false
        };

        _dbContext.Users.Add(user);
        await _dbContext.SaveChangesAsync(cancellationToken);

        return MapToDto(user);
    }

    public async Task<UserDto> UpdateAsync(Guid id, UpdateUserRequest request, CancellationToken cancellationToken = default)
    {
        ValidateRoleAndStatus(request.Role, request.Status);

        var user = await _dbContext.Users.FirstOrDefaultAsync(u => u.Id == id && !u.IsDeleted, cancellationToken);
        if (user == null)
        {
            throw new KeyNotFoundException("User not found");
        }

        user.FullName = request.FullName?.Trim();
        user.Phone = request.Phone?.Trim();
        user.Role = request.Role.ToUpper();
        user.Status = request.Status.ToUpper();
        user.AvatarUrl = request.AvatarUrl;
        user.UpdatedAt = DateTime.UtcNow;

        await _dbContext.SaveChangesAsync(cancellationToken);

        return MapToDto(user);
    }

    public async Task ResetPasswordAsync(Guid id, ResetPasswordRequest request, CancellationToken cancellationToken = default)
    {
        var user = await _dbContext.Users.FirstOrDefaultAsync(u => u.Id == id && !u.IsDeleted, cancellationToken);
        if (user == null)
        {
            throw new KeyNotFoundException("User not found");
        }

        user.PasswordHash = _passwordHasher.HashPassword(request.NewPassword);
        user.UpdatedAt = DateTime.UtcNow;
        await _dbContext.SaveChangesAsync(cancellationToken);
    }

    public async Task DeleteAsync(Guid id, CancellationToken cancellationToken = default)
    {
        var user = await _dbContext.Users.Include(u => u.RefreshTokens).FirstOrDefaultAsync(u => u.Id == id && !u.IsDeleted, cancellationToken);
        if (user == null)
        {
            throw new KeyNotFoundException("User not found");
        }

        user.IsDeleted = true;
        user.Status = "INACTIVE";
        user.RefreshTokens.Clear();
        user.UpdatedAt = DateTime.UtcNow;

        await _dbContext.SaveChangesAsync(cancellationToken);
    }

    private static void ValidateRoleAndStatus(string role, string status)
    {
        if (!AllowedRoles.Contains(role))
        {
            throw new InvalidOperationException("Invalid role");
        }
        if (!AllowedStatuses.Contains(status))
        {
            throw new InvalidOperationException("Invalid status");
        }
    }

    private static UserDto MapToDto(User user) => new()
    {
        Id = user.Id,
        Email = user.Email,
        FullName = user.FullName,
        Phone = user.Phone,
        Role = user.Role,
        Status = user.Status,
        AvatarUrl = user.AvatarUrl,
        IsEmailVerified = user.IsEmailVerified,
        IsPhoneVerified = user.IsPhoneVerified,
        CreatedAt = user.CreatedAt
    };
}
