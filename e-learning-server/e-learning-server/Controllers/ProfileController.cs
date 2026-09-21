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

        // Validate image magic bytes to prevent renamed script attacks
        var headerBuffer = new byte[12];
        using (var peekStream = file.OpenReadStream())
        {
            var bytesRead = await peekStream.ReadAsync(headerBuffer, 0, headerBuffer.Length, cancellationToken);
            if (bytesRead < 4 || !IsValidImageHeader(headerBuffer))
            {
                return BadRequest(new { message = "Invalid image content format" });
            }
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

    [HttpDelete("me")]
    public async Task<IActionResult> DeleteAccount(CancellationToken cancellationToken = default)
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
            return NotFound(new { message = "Không tìm thấy tài khoản." });
        }

        // Soft delete user
        user.IsDeleted = true;
        user.UpdatedAt = DateTime.UtcNow;

        // Revoke all active refresh tokens
        var refreshTokens = await _dbContext.RefreshTokens
            .Where(rt => rt.UserId == userGuid && rt.RevokedAt == null)
            .ToListAsync(cancellationToken);

        foreach (var token in refreshTokens)
        {
            token.RevokedAt = DateTime.UtcNow;
        }

        await _dbContext.SaveChangesAsync(cancellationToken);

        return Ok(new { message = "Tài khoản của bạn đã được xóa thành công." });
    }

    private static bool IsValidImageHeader(byte[] bytes)
    {
        // JPEG: FF D8 FF
        if (bytes.Length >= 3 && bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF)
            return true;

        // PNG: 89 50 4E 47
        if (bytes.Length >= 4 && bytes[0] == 0x89 && bytes[1] == 0x50 && bytes[2] == 0x4E && bytes[3] == 0x47)
            return true;

        // GIF: GIF8
        if (bytes.Length >= 4 && bytes[0] == 0x47 && bytes[1] == 0x49 && bytes[2] == 0x46 && bytes[3] == 0x38)
            return true;

        // WEBP: starts with "RIFF" (52 49 46 46) and bytes 8..11 are "WEBP" (57 45 42 50)
        if (bytes.Length >= 12 &&
            bytes[0] == 0x52 && bytes[1] == 0x49 && bytes[2] == 0x46 && bytes[3] == 0x46 &&
            bytes[8] == 0x57 && bytes[9] == 0x45 && bytes[10] == 0x42 && bytes[11] == 0x50)
            return true;

        return false;
    }
}
