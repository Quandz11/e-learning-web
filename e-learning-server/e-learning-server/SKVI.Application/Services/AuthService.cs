using Microsoft.EntityFrameworkCore;
using SKVI.Application.DTOs.Auth;
using SKVI.Application.Interfaces;
using SKVI.Domain.Entities;
using SKVI.Infrastructure;
using SKVI.Infrastructure.Security; // For JwtSettings access if needed directly, but mostly config in Program.cs
using Microsoft.Extensions.Options;

namespace SKVI.Application.Services;

public class AuthService : IAuthService
{
    private readonly ApplicationDbContext _context;
    private readonly IPasswordHasher _passwordHasher;
    private readonly ITokenService _tokenService;
    private readonly JwtSettings _jwtSettings;

    private readonly IEmailService _emailService;

    public AuthService(
        ApplicationDbContext context, 
        IPasswordHasher passwordHasher, 
        ITokenService tokenService,
        IOptions<JwtSettings> jwtSettings,
        IEmailService emailService)
    {
        _context = context;
        _passwordHasher = passwordHasher;
        _tokenService = tokenService;
        _jwtSettings = jwtSettings.Value;
        _emailService = emailService;
    }

    public async Task<AuthResponse> LoginAsync(LoginRequest request, string ipAddress, string userAgent)
    {
        var user = await _context.Users.FirstOrDefaultAsync(u => u.Email == request.Email);
        
        if (user == null || !_passwordHasher.VerifyPassword(request.Password, user.PasswordHash))
        {
            throw new UnauthorizedAccessException("Invalid email or password.");
        }

        if (user.IsDeleted)
        {
            throw new UnauthorizedAccessException("Account is deleted.");
        }

        if (!user.IsEmailVerified)
        {
             // Or check Status == "PENDING"
             throw new UnauthorizedAccessException("Account is not verified. Please check your email for OTP.");
        }

        if (user.Status != "ACTIVE")
        {
            throw new UnauthorizedAccessException("Account is not active.");
        }

        return await GenerateTokensForUser(user, ipAddress, userAgent);
    }

    public async Task RegisterAsync(RegisterRequest request)
    {
        if (await _context.Users.AnyAsync(u => u.Email == request.Email))
        {
            throw new InvalidOperationException("Email is already registered.");
        }

        var otp = Random.Shared.Next(100000, 999999).ToString();

        var user = new User
        {
            Id = Guid.NewGuid(),
            Email = request.Email,
            PasswordHash = _passwordHasher.HashPassword(request.Password),
            FullName = request.FullName,
            Phone = request.Phone,
            Role = "STUDENT", // Default role
            Status = "PENDING",
            IsEmailVerified = false,
            OtpCode = otp,
            OtpExpiration = DateTime.UtcNow.AddMinutes(10), // OTP valid for 10 mins
            CreatedAt = DateTime.UtcNow,
            UpdatedAt = DateTime.UtcNow
        };

        _context.Users.Add(user);
        await _context.SaveChangesAsync();
        
        // Send OTP Email
        string subject = "Verify your account - SKVI E-Learning";
        string body = $"<h3>Welcome to SKVI!</h3><p>Your verification code is: <strong>{otp}</strong></p><p>This code expires in 10 minutes.</p>";
        
        await _emailService.SendEmailAsync(user.Email, subject, body);
        
        Console.WriteLine($"[DEV] OTP for {user.Email}: {otp}"); // For dev testing
    }

    public async Task<AuthResponse> VerifyOtpAsync(VerifyOtpRequest request)
    {
        var user = await _context.Users.FirstOrDefaultAsync(u => u.Email == request.Email);
        
        if (user == null)
        {
             throw new UnauthorizedAccessException("Invalid email.");
        }

        if (user.IsEmailVerified)
        {
            return await GenerateTokensForUser(user, "Unknown", "Unknown"); // Already verified
        }

        if (user.OtpCode != request.Otp)
        {
            throw new UnauthorizedAccessException("Invalid OTP.");
        }

        if (user.OtpExpiration < DateTime.UtcNow)
        {
            throw new UnauthorizedAccessException("OTP has expired.");
        }

        // Verify Success
        user.IsEmailVerified = true;
        user.Status = "ACTIVE";
        user.OtpCode = null;
        user.OtpExpiration = null;
        
        await _context.SaveChangesAsync();

        return await GenerateTokensForUser(user, "Unknown", "Unknown"); // Pass real IP/UA if forwarded
    }

    public async Task ResendOtpAsync(ResendOtpRequest request)
    {
        var user = await _context.Users.FirstOrDefaultAsync(u => u.Email == request.Email);
        
        if (user == null)
        {
             throw new UnauthorizedAccessException("Invalid email.");
        }

        if (user.IsEmailVerified)
        {
            throw new InvalidOperationException("Email is already verified.");
        }

        var otp = Random.Shared.Next(100000, 999999).ToString();
        user.OtpCode = otp;
        user.OtpExpiration = DateTime.UtcNow.AddMinutes(10);
        
        await _context.SaveChangesAsync();

        // Send OTP Email
        string subject = "Resend Verification Code - SKVI E-Learning";
        string body = $"<h3>Validation Code</h3><p>Your new verification code is: <strong>{otp}</strong></p>";
        
        await _emailService.SendEmailAsync(user.Email, subject, body);
        Console.WriteLine($"[DEV] Resend OTP for {user.Email}: {otp}");
    }

    private async Task<AuthResponse> GenerateTokensForUser(User user, string ipAddress, string userAgent)
    {
        var accessToken = _tokenService.GenerateAccessToken(user.Id, user.Email, user.Role, user.FullName);
        var refreshToken = _tokenService.GenerateRefreshToken();
        
        var refreshTokenEntity = new RefreshToken
        {
            Id = Guid.NewGuid(),
            UserId = user.Id,
            TokenHash = refreshToken,
            IpAddress = ipAddress,
            UserAgent = userAgent,
            ExpiresAt = DateTime.UtcNow.AddDays(_jwtSettings.RefreshTokenExpirationDays),
            CreatedAt = DateTime.UtcNow
        };
        
        _context.RefreshTokens.Add(refreshTokenEntity);
        await _context.SaveChangesAsync();

        return new AuthResponse(accessToken, refreshToken, DateTime.UtcNow.AddMinutes(_jwtSettings.AccessTokenExpirationMinutes));
    }

    public async Task<AuthResponse> RefreshTokenAsync(string refreshToken, string ipAddress, string userAgent)
    {
        var tokenEntity = await _context.RefreshTokens
            .Include(t => t.User)
            .FirstOrDefaultAsync(t => t.TokenHash == refreshToken);

        if (tokenEntity == null)
        {
            throw new UnauthorizedAccessException("Invalid refresh token.");
        }

        if (tokenEntity.RevokedAt != null)
        {
            // Token Reuse Detected! Security Alert!
            // Revoke all tokens for this user family?
            // For now, just fail.
            throw new UnauthorizedAccessException("Token already revoked.");
        }

        if (tokenEntity.ExpiresAt < DateTime.UtcNow)
        {
            throw new UnauthorizedAccessException("Token expired.");
        }

        // Rotate Token
        // 1. Revoke old token
        tokenEntity.RevokedAt = DateTime.UtcNow;
        
        // 2. Generate new tokens
        var user = tokenEntity.User;
        var newAccessToken = _tokenService.GenerateAccessToken(user.Id, user.Email, user.Role);
        var newRefreshToken = _tokenService.GenerateRefreshToken();
        
        var newRefreshTokenEntity = new RefreshToken
        {
            Id = Guid.NewGuid(),
            UserId = user.Id,
            TokenHash = newRefreshToken,
            IpAddress = ipAddress,
            UserAgent = userAgent,
            ExpiresAt = DateTime.UtcNow.AddDays(_jwtSettings.RefreshTokenExpirationDays),
            CreatedAt = DateTime.UtcNow
        };
        
        _context.RefreshTokens.Add(newRefreshTokenEntity);
        await _context.SaveChangesAsync();
        
        return new AuthResponse(newAccessToken, newRefreshToken, DateTime.UtcNow.AddMinutes(_jwtSettings.AccessTokenExpirationMinutes));
    }

    public async Task LogoutAsync(string refreshToken)
    {
        var tokenEntity = await _context.RefreshTokens.FirstOrDefaultAsync(t => t.TokenHash == refreshToken);
        if (tokenEntity != null)
        {
            tokenEntity.RevokedAt = DateTime.UtcNow;
            await _context.SaveChangesAsync();
        }
    }
}
