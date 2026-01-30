using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using SKVI.Application.DTOs.Profile;
using SKVI.Application.Interfaces;
using SKVI.Infrastructure;
using System.Security.Claims;

namespace e_learning_server.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize] // All authenticated users can access
public class ProfileController : ControllerBase
{
    private readonly ApplicationDbContext _dbContext;
    private readonly IPasswordHasher _passwordHasher;
    private readonly IBunnyStreamService _bunnyStreamService;

    public ProfileController(ApplicationDbContext dbContext, IPasswordHasher passwordHasher, IBunnyStreamService bunnyStreamService)
    {
        _dbContext = dbContext;
        _passwordHasher = passwordHasher;
        _bunnyStreamService = bunnyStreamService;
    }

    [HttpGet("me")]
    public async Task<IActionResult> GetMyProfile(CancellationToken cancellationToken = default)
    {
        var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (string.IsNullOrEmpty(userId) || !Guid.TryParse(userId, out var userGuid))
        {
            return Unauthorized();
        }

        var user = await _dbContext.Users
            .AsNoTracking()
            .FirstOrDefaultAsync(u => u.Id == userGuid && !u.IsDeleted, cancellationToken);

        if (user == null)
        {
            return NotFound(new { message = "User not found" });
        }

        var profile = new UserProfileDto
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
            IsTwoFactorEnabled = user.IsTwoFactorEnabled,
            CreatedAt = user.CreatedAt,
            UpdatedAt = user.UpdatedAt
        };

        return Ok(profile);
    }

    [HttpPut("me")]
    public async Task<IActionResult> UpdateMyProfile([FromBody] UpdateProfileRequest request, CancellationToken cancellationToken = default)
    {
        var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (string.IsNullOrEmpty(userId) || !Guid.TryParse(userId, out var userGuid))
        {
            return Unauthorized();
        }

        var user = await _dbContext.Users
            .FirstOrDefaultAsync(u => u.Id == userGuid && !u.IsDeleted, cancellationToken);

        if (user == null)
        {
            return NotFound(new { message = "User not found" });
        }

        // Update profile fields
        user.FullName = request.FullName?.Trim();
        user.Phone = request.Phone?.Trim();
        user.AvatarUrl = request.AvatarUrl?.Trim();
        user.UpdatedAt = DateTime.UtcNow;

        await _dbContext.SaveChangesAsync(cancellationToken);

        var profile = new UserProfileDto
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
            IsTwoFactorEnabled = user.IsTwoFactorEnabled,
            CreatedAt = user.CreatedAt,
            UpdatedAt = user.UpdatedAt
        };

        return Ok(profile);
    }

    [HttpPost("change-password")]
    public async Task<IActionResult> ChangePassword([FromBody] ChangePasswordRequest request, CancellationToken cancellationToken = default)
    {
        var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (string.IsNullOrEmpty(userId) || !Guid.TryParse(userId, out var userGuid))
        {
            return Unauthorized();
        }

        var user = await _dbContext.Users
            .FirstOrDefaultAsync(u => u.Id == userGuid && !u.IsDeleted, cancellationToken);

        if (user == null)
        {
            return NotFound(new { message = "User not found" });
        }

        // Verify current password
        if (!_passwordHasher.VerifyPassword(request.CurrentPassword, user.PasswordHash))
        {
            return BadRequest(new { message = "Current password is incorrect" });
        }

        // Update password
        user.PasswordHash = _passwordHasher.HashPassword(request.NewPassword);
        user.UpdatedAt = DateTime.UtcNow;

        // Revoke all refresh tokens for security
        var refreshTokens = await _dbContext.RefreshTokens
            .Where(rt => rt.UserId == userGuid && rt.RevokedAt == null)
            .ToListAsync(cancellationToken);

        foreach (var token in refreshTokens)
        {
            token.RevokedAt = DateTime.UtcNow;
        }

        await _dbContext.SaveChangesAsync(cancellationToken);

        return Ok(new { message = "Password changed successfully. Please login again." });
    }

    [HttpPost("upload-avatar")]
    public async Task<IActionResult> UploadAvatar(IFormFile file, CancellationToken cancellationToken = default)
    {
        if (file == null || file.Length == 0)
        {
            return BadRequest(new { message = "No file uploaded" });
        }

        // Validate file type
        var allowedExtensions = new[] { ".jpg", ".jpeg", ".png", ".webp", ".gif" };
        var extension = Path.GetExtension(file.FileName).ToLowerInvariant();
        if (!allowedExtensions.Contains(extension))
        {
            return BadRequest(new { message = "Invalid file type. Allowed types: jpg, jpeg, png, webp, gif" });
        }

        // Validate file size (e.g. max 5MB)
        if (file.Length > 5 * 1024 * 1024)
        {
             return BadRequest(new { message = "File size exceeds 5MB limit" });
        }

        try
        {
            using var stream = file.OpenReadStream();
            var url = await _bunnyStreamService.UploadImageAsync(stream, file.FileName, "avatars", cancellationToken);
            
            // Return the URL. We do NOT update the user profile here. 
            // The frontend will receive the URL and user must click "Save" on the profile form to persist it.
            return Ok(new { url });
        }
        catch (Exception ex)
        {
            return BadRequest(new { message = "Failed to upload avatar: " + ex.Message });
        }
    }
}
