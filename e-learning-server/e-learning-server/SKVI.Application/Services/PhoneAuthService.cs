using System.Text.RegularExpressions;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Options;
using SKVI.Application.DTOs.Auth;
using SKVI.Application.Interfaces;
using SKVI.Domain.Entities;
using SKVI.Infrastructure;
using SKVI.Infrastructure.Security;

namespace SKVI.Application.Services;

public class PhoneAuthService : IPhoneAuthService
{
    private const int OtpExpirationMinutes = 10;

    private readonly ApplicationDbContext _context;
    private readonly IPasswordHasher _passwordHasher;
    private readonly ITokenService _tokenService;
    private readonly JwtSettings _jwtSettings;
    private readonly IUserReferralService _userReferralService;
    private readonly IPhoneOtpSender _phoneOtpSender;

    public PhoneAuthService(
        ApplicationDbContext context,
        IPasswordHasher passwordHasher,
        ITokenService tokenService,
        IOptions<JwtSettings> jwtSettings,
        IUserReferralService userReferralService,
        IPhoneOtpSender phoneOtpSender
    )
    {
        _context = context;
        _passwordHasher = passwordHasher;
        _tokenService = tokenService;
        _jwtSettings = jwtSettings.Value;
        _userReferralService = userReferralService;
        _phoneOtpSender = phoneOtpSender;
    }

    public async Task RegisterByPhoneAsync(PhoneRegisterRequest request, CancellationToken cancellationToken = default)
    {
        var normalizedPhone = NormalizePhone(request.Phone);

        var existingByPhone = await GetUniqueUserByPhoneAsync(normalizedPhone, cancellationToken);
        if (existingByPhone != null)
        {
            throw new InvalidOperationException("Số điện thoại đã được đăng ký.");
        }

        var hasExplicitEmail = !string.IsNullOrWhiteSpace(request.Email);
        var email = hasExplicitEmail
            ? request.Email!.Trim().ToLowerInvariant()
            : $"phone.{normalizedPhone}.{Guid.NewGuid():N}@phone.local";

        if (hasExplicitEmail)
        {
            var emailExists = await _context.Users
                .AnyAsync(u => u.Email == email && !u.IsDeleted, cancellationToken);

            if (emailExists)
            {
                throw new InvalidOperationException("Email đã tồn tại.");
            }
        }

        var otp = GenerateOtp();

        var user = new User
        {
            Id = Guid.NewGuid(),
            Email = email,
            Phone = normalizedPhone,
            FullName = request.FullName?.Trim(),
            PasswordHash = _passwordHasher.HashPassword(
                string.IsNullOrWhiteSpace(request.Password) ? Guid.NewGuid().ToString("N") : request.Password
            ),
            Role = "STUDENT",
            Status = "PENDING",
            IsEmailVerified = !hasExplicitEmail,
            IsPhoneVerified = false,
            OtpCode = otp,
            OtpExpiration = DateTime.UtcNow.AddMinutes(OtpExpirationMinutes),
            CreatedAt = DateTime.UtcNow,
            UpdatedAt = DateTime.UtcNow
        };

        _context.Users.Add(user);
        await _context.SaveChangesAsync(cancellationToken);

        if (!string.IsNullOrWhiteSpace(request.ReferralCode))
        {
            await _userReferralService.ApplyReferralCodeForNewUserAsync(
                user.Id,
                request.ReferralCode.Trim().ToUpperInvariant()
            );
        }

        var trackingId = BuildTrackingId("register", user.Id);
        await _phoneOtpSender.SendOtpAsync(
            normalizedPhone,
            otp,
            "register",
            trackingId,
            cancellationToken
        );
    }

    public async Task<AuthResponse> VerifyPhoneRegistrationOtpAsync(
        PhoneRegisterOtpVerifyRequest request,
        string ipAddress,
        string userAgent,
        CancellationToken cancellationToken = default
    )
    {
        var normalizedPhone = NormalizePhone(request.Phone);
        var user = await GetUniqueUserByPhoneAsync(normalizedPhone, cancellationToken);
        if (user == null)
        {
            throw new UnauthorizedAccessException("Số điện thoại không tồn tại.");
        }

        if (user.IsDeleted)
        {
            throw new UnauthorizedAccessException("Tài khoản đã bị xóa.");
        }

        if (user.Status == "ACTIVE" && user.IsPhoneVerified)
        {
            return await GenerateTokensForUserAsync(user, ipAddress, userAgent, cancellationToken);
        }

        ValidateOtp(user, request.Otp);

        user.IsPhoneVerified = true;
        user.Status = "ACTIVE";
        user.OtpCode = null;
        user.OtpExpiration = null;
        user.UpdatedAt = DateTime.UtcNow;

        await _context.SaveChangesAsync(cancellationToken);
        await _userReferralService.CompleteReferralForUserAsync(user.Id);

        return await GenerateTokensForUserAsync(user, ipAddress, userAgent, cancellationToken);
    }

    public async Task ResendPhoneRegistrationOtpAsync(
        PhoneRegisterResendOtpRequest request,
        CancellationToken cancellationToken = default
    )
    {
        var normalizedPhone = NormalizePhone(request.Phone);
        var user = await GetUniqueUserByPhoneAsync(normalizedPhone, cancellationToken);
        if (user == null)
        {
            throw new UnauthorizedAccessException("Số điện thoại không tồn tại.");
        }

        if (user.IsDeleted)
        {
            throw new UnauthorizedAccessException("Tài khoản đã bị xóa.");
        }

        if (user.Status == "ACTIVE" && user.IsPhoneVerified)
        {
            throw new InvalidOperationException("Số điện thoại đã được xác minh.");
        }

        var otp = GenerateOtp();
        user.OtpCode = otp;
        user.OtpExpiration = DateTime.UtcNow.AddMinutes(OtpExpirationMinutes);
        user.UpdatedAt = DateTime.UtcNow;

        await _context.SaveChangesAsync(cancellationToken);

        var trackingId = BuildTrackingId("resend_register", user.Id);
        await _phoneOtpSender.SendOtpAsync(
            normalizedPhone,
            otp,
            "register",
            trackingId,
            cancellationToken
        );
    }

    public async Task RequestPhoneLoginOtpAsync(PhoneLoginOtpRequest request, CancellationToken cancellationToken = default)
    {
        var normalizedPhone = NormalizePhone(request.Phone);
        var user = await GetUniqueUserByPhoneAsync(normalizedPhone, cancellationToken);
        if (user == null)
        {
            throw new UnauthorizedAccessException("Số điện thoại không tồn tại.");
        }

        if (user.IsDeleted)
        {
            throw new UnauthorizedAccessException("Tài khoản đã bị xóa.");
        }

        if (user.Status != "ACTIVE")
        {
            throw new UnauthorizedAccessException("Tài khoản chưa sẵn sàng để đăng nhập.");
        }

        var otp = GenerateOtp();
        user.OtpCode = otp;
        user.OtpExpiration = DateTime.UtcNow.AddMinutes(OtpExpirationMinutes);
        user.UpdatedAt = DateTime.UtcNow;

        await _context.SaveChangesAsync(cancellationToken);

        var trackingId = BuildTrackingId("login", user.Id);
        await _phoneOtpSender.SendOtpAsync(
            normalizedPhone,
            otp,
            "login",
            trackingId,
            cancellationToken
        );
    }

    public async Task<AuthResponse> VerifyPhoneLoginOtpAsync(
        PhoneLoginOtpVerifyRequest request,
        string ipAddress,
        string userAgent,
        CancellationToken cancellationToken = default
    )
    {
        var normalizedPhone = NormalizePhone(request.Phone);
        var user = await GetUniqueUserByPhoneAsync(normalizedPhone, cancellationToken);
        if (user == null)
        {
            throw new UnauthorizedAccessException("Số điện thoại không tồn tại.");
        }

        if (user.IsDeleted)
        {
            throw new UnauthorizedAccessException("Tài khoản đã bị xóa.");
        }

        if (user.Status != "ACTIVE")
        {
            throw new UnauthorizedAccessException("Tài khoản chưa active.");
        }

        ValidateOtp(user, request.Otp);

        user.IsPhoneVerified = true;
        user.OtpCode = null;
        user.OtpExpiration = null;
        user.UpdatedAt = DateTime.UtcNow;

        await _context.SaveChangesAsync(cancellationToken);

        return await GenerateTokensForUserAsync(user, ipAddress, userAgent, cancellationToken);
    }

    private static void ValidateOtp(User user, string otp)
    {
        if (string.IsNullOrWhiteSpace(user.OtpCode) || user.OtpExpiration == null)
        {
            throw new UnauthorizedAccessException("OTP không tồn tại hoặc đã hết hạn.");
        }

        if (!string.Equals(user.OtpCode, otp, StringComparison.Ordinal))
        {
            throw new UnauthorizedAccessException("OTP không hợp lệ.");
        }

        if (user.OtpExpiration.Value < DateTime.UtcNow)
        {
            throw new UnauthorizedAccessException("OTP đã hết hạn.");
        }
    }

    private async Task<User?> GetUniqueUserByPhoneAsync(string normalizedPhone, CancellationToken cancellationToken)
    {
        var users = await _context.Users
            .Where(u => u.Phone == normalizedPhone && !u.IsDeleted)
            .OrderByDescending(u => u.CreatedAt)
            .ToListAsync(cancellationToken);

        if (users.Count <= 1)
        {
            return users.SingleOrDefault();
        }

        throw new InvalidOperationException("Số điện thoại đang gắn với nhiều tài khoản. Vui lòng liên hệ hỗ trợ.");
    }

    private async Task<AuthResponse> GenerateTokensForUserAsync(
        User user,
        string ipAddress,
        string userAgent,
        CancellationToken cancellationToken
    )
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
        await _context.SaveChangesAsync(cancellationToken);

        return new AuthResponse(
            accessToken,
            refreshToken,
            DateTime.UtcNow.AddMinutes(_jwtSettings.AccessTokenExpirationMinutes)
        );
    }

    private static string GenerateOtp()
    {
        return Random.Shared.Next(100000, 999999).ToString();
    }

    private static string BuildTrackingId(string purpose, Guid userId)
    {
        return $"{purpose}_{userId:N}_{DateTimeOffset.UtcNow.ToUnixTimeMilliseconds()}";
    }

    private static string NormalizePhone(string phone)
    {
        if (string.IsNullOrWhiteSpace(phone))
        {
            throw new InvalidOperationException("Số điện thoại là bắt buộc.");
        }

        var normalized = Regex.Replace(phone.Trim(), @"[\s\-\.\(\)]", string.Empty);

        if (normalized.StartsWith("+", StringComparison.Ordinal))
        {
            normalized = normalized[1..];
        }

        if (normalized.StartsWith("0", StringComparison.Ordinal))
        {
            normalized = "84" + normalized[1..];
        }

        if (!Regex.IsMatch(normalized, @"^\d{9,15}$"))
        {
            throw new InvalidOperationException("Số điện thoại không đúng định dạng.");
        }

        return normalized;
    }
}
