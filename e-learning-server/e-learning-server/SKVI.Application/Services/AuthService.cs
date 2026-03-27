using Microsoft.EntityFrameworkCore;
using SKVI.Application.DTOs.Auth;
using SKVI.Application.Interfaces;
using SKVI.Domain.Entities;
using SKVI.Infrastructure;
using SKVI.Infrastructure.Security; // For JwtSettings access if needed directly, but mostly config in Program.cs
using Microsoft.Extensions.Options;
using System.Text.RegularExpressions;

namespace SKVI.Application.Services;

public class AuthService : IAuthService
{
    private readonly ApplicationDbContext _context;
    private readonly IPasswordHasher _passwordHasher;
    private readonly ITokenService _tokenService;
    private readonly JwtSettings _jwtSettings;
    private readonly IUserReferralService _userReferralService;

    private readonly IEmailService _emailService;

    public AuthService(
        ApplicationDbContext context, 
        IPasswordHasher passwordHasher, 
        ITokenService tokenService,
        IOptions<JwtSettings> jwtSettings,
        IUserReferralService userReferralService,
        IEmailService emailService)
    {
        _context = context;
        _passwordHasher = passwordHasher;
        _tokenService = tokenService;
        _jwtSettings = jwtSettings.Value;
        _userReferralService = userReferralService;
        _emailService = emailService;
    }

    public async Task<AuthResponse> LoginAsync(LoginRequest request, string ipAddress, string userAgent)
    {
        var identifier = request.Email?.Trim() ?? string.Empty;
        if (string.IsNullOrWhiteSpace(identifier))
        {
            throw new UnauthorizedAccessException("Invalid credentials.");
        }
        if (string.IsNullOrWhiteSpace(request.Password))
        {
            throw new UnauthorizedAccessException("Invalid credentials.");
        }

        var isPhoneLogin = IsPhoneIdentifier(identifier);
        var user = await FindUserForLoginAsync(identifier, isPhoneLogin);

        if (user == null || !_passwordHasher.VerifyPassword(request.Password, user.PasswordHash))
        {
            throw new UnauthorizedAccessException("Invalid credentials.");
        }

        if (user.IsDeleted)
        {
            throw new UnauthorizedAccessException("Account is deleted.");
        }

        if (!user.IsEmailVerified && !user.IsPhoneVerified)
        {
            throw new UnauthorizedAccessException("Account is not verified. Please complete OTP verification.");
        }

        if (isPhoneLogin && !user.IsPhoneVerified)
        {
            throw new UnauthorizedAccessException("Phone number is not verified.");
        }

        if (user.Status != "ACTIVE")
        {
            throw new UnauthorizedAccessException("Account is not active.");
        }

        if (user.IsTwoFactorEnabled)
        {
            // Return Pre-Auth Token (a special JWT or just use existing token logic with a flag? 
            // Better to return a partial response. 
            // For simplicity, we can generate a temporary access token with a special claim or scope "pre_auth".
            // AND return RequiresTwoFactor=true.
            
            // NOTE: Here we reuse GenerateTokensForUser but the frontend needs to know it's not fully logged in yet?
            // Actually, secure implementation:
            // Return a "PreAuthToken" which allows access ONLY to 2FA verify endpoints.
            // But existing GenerateTokensForUser returns full access. 
            // Let's modify GenTokens or create a specific helper.
            // For MVP: Let's use the standard token but the Controller/Frontend will redirect to 2FA page.
            // Ideally, we secure endpoints by checking a "2fa_verified" claim if 2fa is enabled.
            // But that requires changing Jwt Middleware.
            
            // Alternative: Return a SHORT LIVED (5 min) token with a claim "amr": "pwd" (Authentication Method Reference).
            // Full login token has "amr": "pwd", "mfa".
            // Let's stick to the simplest approach: Return a standard token BUT with RequiresTwoFactor=true/
            // The FRONTEND must respect this flag and not allow dashboard access.
            // SECURITY RISK: If backend endpoints don't enforce 2FA, this token works.
            // Correct approach: The Token returned here SHOULD NOT have the Role claims yet? 
            // OR we add a custom claim "PreAuth=true".
            
            // Let's create a PreAuth Token function.
            var preAuthToken = _tokenService.GenerateAccessToken(user.Id, user.Email, "PRE_AUTH", user.FullName);
            return new AuthResponse(preAuthToken, "", DateTime.UtcNow.AddMinutes(5), true);
        }

        return await GenerateTokensForUser(user, ipAddress, userAgent);
    }

    private async Task<User?> FindUserForLoginAsync(string identifier, bool isPhoneLogin)
    {
        if (!isPhoneLogin)
        {
            var normalizedEmail = identifier.Trim().ToLowerInvariant();
            return await _context.Users.FirstOrDefaultAsync(u => u.Email == normalizedEmail);
        }

        var phoneCandidates = BuildPhoneCandidates(identifier);
        if (phoneCandidates.Count == 0)
        {
            return null;
        }

        var users = await _context.Users
            .Where(u => u.Phone != null && phoneCandidates.Contains(u.Phone) && !u.IsDeleted)
            .OrderByDescending(u => u.CreatedAt)
            .ToListAsync();

        if (users.Count <= 1)
        {
            return users.SingleOrDefault();
        }

        throw new UnauthorizedAccessException("Phone number is linked to multiple accounts. Please contact support.");
    }

    private static bool IsPhoneIdentifier(string identifier)
    {
        if (string.IsNullOrWhiteSpace(identifier))
        {
            return false;
        }

        var normalized = Regex.Replace(identifier.Trim(), @"[\s\-\.\(\)]", string.Empty);
        if (normalized.StartsWith("+", StringComparison.Ordinal))
        {
            normalized = normalized[1..];
        }

        return Regex.IsMatch(normalized, @"^\d{9,15}$");
    }

    private static string NormalizePhone(string phone)
    {
        var normalized = Regex.Replace(phone.Trim(), @"[\s\-\.\(\)]", string.Empty);

        if (normalized.StartsWith("+", StringComparison.Ordinal))
        {
            normalized = normalized[1..];
        }

        if (normalized.StartsWith("0", StringComparison.Ordinal))
        {
            normalized = "84" + normalized[1..];
        }

        return normalized;
    }

    private static List<string> BuildPhoneCandidates(string identifier)
    {
        if (string.IsNullOrWhiteSpace(identifier))
        {
            return new List<string>();
        }

        var cleaned = Regex.Replace(identifier.Trim(), @"[\s\-\.\(\)]", string.Empty);
        if (string.IsNullOrWhiteSpace(cleaned))
        {
            return new List<string>();
        }

        var candidates = new HashSet<string>(StringComparer.OrdinalIgnoreCase)
        {
            cleaned
        };

        var noPlus = cleaned.StartsWith("+", StringComparison.Ordinal) ? cleaned[1..] : cleaned;
        candidates.Add(noPlus);

        if (noPlus.StartsWith("0", StringComparison.Ordinal) && noPlus.Length > 1)
        {
            candidates.Add("84" + noPlus[1..]);
        }

        if (noPlus.StartsWith("84", StringComparison.Ordinal) && noPlus.Length > 2)
        {
            candidates.Add("0" + noPlus[2..]);
            candidates.Add("+" + noPlus);
        }

        return candidates.Where(value => !string.IsNullOrWhiteSpace(value)).Distinct(StringComparer.OrdinalIgnoreCase).ToList();
    }

    public async Task RegisterAsync(RegisterRequest request)
    {
        if (await _context.Users.AnyAsync(u => u.Email == request.Email))
        {
            throw new InvalidOperationException("Email is already registered.");
        }

        var otp = Random.Shared.Next(100000, 999999).ToString();
        var normalizedPhone = string.IsNullOrWhiteSpace(request.Phone) ? null : NormalizePhone(request.Phone);
        if (!string.IsNullOrWhiteSpace(normalizedPhone) && !Regex.IsMatch(normalizedPhone, @"^\d{9,15}$"))
        {
            throw new InvalidOperationException("Phone number format is invalid.");
        }

        var user = new User
        {
            Id = Guid.NewGuid(),
            Email = request.Email,
            PasswordHash = _passwordHasher.HashPassword(request.Password),
            FullName = request.FullName,
            Phone = normalizedPhone,
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

        if (!string.IsNullOrWhiteSpace(request.ReferralCode))
        {
            await _userReferralService.ApplyReferralCodeForNewUserAsync(user.Id, request.ReferralCode);
        }
        
        // Send OTP Email
        string subject = "Verify your account - SKVI E-Learning";
        string body = $"<h3>Welcome to SKVI!</h3><p>Your verification code is: <strong>{otp}</strong></p><p>This code expires in 10 minutes.</p>";
        
        await _emailService.SendEmailAsync(user.Email, subject, body);
        

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
        user.IsPhoneVerified = true;
        user.Status = "ACTIVE";
        user.OtpCode = null;
        user.OtpExpiration = null;
        
        await _context.SaveChangesAsync();

        await _userReferralService.CompleteReferralForUserAsync(user.Id);

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
        var newAccessToken = _tokenService.GenerateAccessToken(user.Id, user.Email, user.Role, user.FullName);
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

    // 2FA Implementations

    public async Task<(string Secret, string QrCodeUri)> GenerateTwoFactorSetupAsync(Guid userId)
    {
        var user = await _context.Users.FindAsync(userId);
        if (user == null) throw new UnauthorizedAccessException("User not found.");

        var key = OtpNet.KeyGeneration.GenerateRandomKey(20);
        var secret = OtpNet.Base32Encoding.ToString(key);
        
        // Format: otpauth://totp/{Issuer}:{AccountName}?secret={Secret}&issuer={Issuer}&algorithm=SHA1&digits=6&period=30
        var issuer = "SKVI-Learning";
        var account = user.Email;
        var uri = $"otpauth://totp/{issuer}:{account}?secret={secret}&issuer={issuer}&algorithm=SHA1&digits=6&period=30";

        return (secret, uri);
    }

    public async Task<AuthResponse> EnableTwoFactorAsync(Guid userId, string secret, string code)
    {
        var user = await _context.Users.FindAsync(userId);
        if (user == null) throw new UnauthorizedAccessException("User not found.");

        var secretBytes = OtpNet.Base32Encoding.ToBytes(secret);
        var totp = new OtpNet.Totp(secretBytes);
        
        if (!totp.VerifyTotp(code, out _, new OtpNet.VerificationWindow(2, 2)))
        {
             throw new UnauthorizedAccessException("Invalid code.");
        }

        user.TwoFactorSecret = secret;
        user.IsTwoFactorEnabled = true;
        await _context.SaveChangesAsync();

        return await GenerateTokensForUser(user, "Unknown", "Unknown"); // Return fresh tokens
    }

    public async Task DisableTwoFactorAsync(Guid userId, string password)
    {
        var user = await _context.Users.FindAsync(userId);
        if (user == null) throw new UnauthorizedAccessException("User not found.");

        if (!_passwordHasher.VerifyPassword(password, user.PasswordHash))
        {
            throw new UnauthorizedAccessException("Invalid password.");
        }

        user.IsTwoFactorEnabled = false;
        user.TwoFactorSecret = null;
        await _context.SaveChangesAsync();
    }

    public async Task<AuthResponse> VerifyTwoFactorLoginAsync(Guid userId, string code)
    {
        var user = await _context.Users.FindAsync(userId);
        if (user == null) throw new UnauthorizedAccessException("User not found.");

        if (!user.IsTwoFactorEnabled || string.IsNullOrEmpty(user.TwoFactorSecret))
        {
            throw new UnauthorizedAccessException("2FA is not enabled for this user.");
        }


        var secretBytes = OtpNet.Base32Encoding.ToBytes(user.TwoFactorSecret);
        var totp = new OtpNet.Totp(secretBytes);

        if (!totp.VerifyTotp(code, out _, new OtpNet.VerificationWindow(2, 2)))
        {
            throw new UnauthorizedAccessException("Invalid 2FA code.");
        }

        return await GenerateTokensForUser(user, "Unknown", "Unknown"); // Should pass IP/UA
    }

    // Session Management Methods
    public async Task<List<ActiveSessionDto>> GetActiveSessionsAsync(Guid userId, string? currentRefreshToken)
    {
        var sessions = await _context.RefreshTokens
            .Where(rt => rt.UserId == userId && 
                         rt.RevokedAt == null && 
                         rt.ExpiresAt > DateTime.UtcNow)
            .OrderByDescending(rt => rt.CreatedAt)
            .ToListAsync();

        return sessions.Select(s => new ActiveSessionDto
        {
            SessionId = s.Id,
            DeviceName = ParseDeviceName(s.UserAgent),
            Browser = ParseBrowser(s.UserAgent),
            IpAddress = s.IpAddress ?? "Unknown",
            LoginTime = s.CreatedAt,
            ExpiresAt = s.ExpiresAt,
            IsCurrentSession = !string.IsNullOrEmpty(currentRefreshToken) && s.TokenHash == currentRefreshToken
        }).ToList();
    }

    public async Task RevokeSessionAsync(Guid userId, Guid sessionId)
    {
        var session = await _context.RefreshTokens
            .FirstOrDefaultAsync(rt => rt.Id == sessionId && rt.UserId == userId);
        
        if (session == null)
            throw new KeyNotFoundException("Session not found");
        
        session.RevokedAt = DateTime.UtcNow;
        await _context.SaveChangesAsync();
    }

    public async Task RevokeAllSessionsAsync(Guid userId, string? currentRefreshToken)
    {
        var sessions = await _context.RefreshTokens
            .Where(rt => rt.UserId == userId && 
                         rt.RevokedAt == null && 
                         (!string.IsNullOrEmpty(currentRefreshToken) ? rt.TokenHash != currentRefreshToken : true))
            .ToListAsync();

        foreach (var session in sessions)
        {
            session.RevokedAt = DateTime.UtcNow;
        }

        await _context.SaveChangesAsync();
    }

    // Helper methods for parsing UserAgent
    private string ParseDeviceName(string? userAgent)
    {
        if (string.IsNullOrEmpty(userAgent)) return "Unknown Device";
        
        if (userAgent.Contains("Windows NT 10")) return "Windows 10/11 PC";
        if (userAgent.Contains("Windows")) return "Windows PC";
        if (userAgent.Contains("Macintosh") || userAgent.Contains("Mac OS X")) return "Mac";
        if (userAgent.Contains("iPhone")) return "iPhone";
        if (userAgent.Contains("iPad")) return "iPad";
        if (userAgent.Contains("Android")) return "Android Device";
        if (userAgent.Contains("Linux")) return "Linux PC";
        
        return "Unknown Device";
    }

    private string ParseBrowser(string? userAgent)
    {
        if (string.IsNullOrEmpty(userAgent)) return "Unknown";
        
        if (userAgent.Contains("Edg/")) return "Edge";
        if (userAgent.Contains("Chrome/")) return "Chrome";
        if (userAgent.Contains("Firefox/")) return "Firefox";
        if (userAgent.Contains("Safari/") && !userAgent.Contains("Chrome")) return "Safari";
        if (userAgent.Contains("Opera") || userAgent.Contains("OPR")) return "Opera";
        
        return "Unknown Browser";
    }
}
