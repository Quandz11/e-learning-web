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

    private readonly UserSessionService _sessions;
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
        IPhoneOtpSender phoneOtpSender, UserSessionService sessions
    )
    {
        _sessions = sessions;
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
            throw new InvalidOperationException("Phone number is already registered.");
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
                throw new InvalidOperationException("Email already exists.");
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
            throw new UnauthorizedAccessException("Phone number does not exist.");
        }

        if (user.IsDeleted)
        {
            throw new UnauthorizedAccessException("Account has been deleted.");
        }

        if (user.Status == "ACTIVE" && user.IsPhoneVerified)
        {
            return await GenerateTokensForUserAsync(user, ipAddress, userAgent, cancellationToken);
        }

        ValidateOtp(user, request.Otp);

        user.IsPhoneVerified = true;
        user.IsEmailVerified = true;
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
            throw new UnauthorizedAccessException("Phone number does not exist.");
        }

        if (user.IsDeleted)
        {
            throw new UnauthorizedAccessException("Account has been deleted.");
        }

        if (user.Status == "ACTIVE" && user.IsPhoneVerified)
        {
            throw new InvalidOperationException("Phone number is already verified.");
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

    public async Task RequestPhoneForgotPasswordOtpAsync(
        PhoneForgotPasswordOtpRequest request,
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
            throw new UnauthorizedAccessException("Tài khoản chưa sẵn sàng để khởi tạo lại mật khẩu.");
        }

        var otp = GenerateOtp();
        user.OtpCode = otp;
        user.OtpExpiration = DateTime.UtcNow.AddMinutes(OtpExpirationMinutes);
        user.UpdatedAt = DateTime.UtcNow;

        await _context.SaveChangesAsync(cancellationToken);

        var trackingId = BuildTrackingId("forgot_password", user.Id);
        await _phoneOtpSender.SendOtpAsync(
            normalizedPhone,
            otp,
            "forgot_password",
            trackingId,
            cancellationToken
        );
    }

    public async Task ResendPhoneForgotPasswordOtpAsync(
        PhoneForgotPasswordOtpRequest request,
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
            throw new UnauthorizedAccessException("Tài khoản chưa sẵn sàng để khởi tạo lại mật khẩu.");
        }

        var otp = GenerateOtp();
        user.OtpCode = otp;
        user.OtpExpiration = DateTime.UtcNow.AddMinutes(OtpExpirationMinutes);
        user.UpdatedAt = DateTime.UtcNow;

        await _context.SaveChangesAsync(cancellationToken);

        var trackingId = BuildTrackingId("resend_forgot_password", user.Id);
        await _phoneOtpSender.SendOtpAsync(
            normalizedPhone,
            otp,
            "forgot_password",
            trackingId,
            cancellationToken
        );
    }

    public async Task VerifyPhoneForgotPasswordOtpAsync(
        PhoneForgotPasswordOtpVerifyRequest request,
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
            throw new UnauthorizedAccessException("Tài khoản chưa sẵn sàng để khởi tạo lại mật khẩu.");
        }

        ValidateOtp(user, request.Otp);
        ValidatePassword(request.NewPassword);

        user.PasswordHash = _passwordHasher.HashPassword(request.NewPassword.Trim());
        user.IsPhoneVerified = true;
        user.OtpCode = null;
        user.OtpExpiration = null;
        user.UpdatedAt = DateTime.UtcNow;

        await _context.SaveChangesAsync(cancellationToken);
    }

    private static void ValidateOtp(User user, string otp)
    {
        if (string.IsNullOrWhiteSpace(user.OtpCode) || user.OtpExpiration == null)
        {
            throw new UnauthorizedAccessException("OTP does not exist or has expired.");
        }

        if (!string.Equals(user.OtpCode, otp, StringComparison.Ordinal))
        {
            throw new UnauthorizedAccessException("OTP is invalid.");
        }

        if (user.OtpExpiration.Value < DateTime.UtcNow)
        {
            throw new UnauthorizedAccessException("OTP has expired.");
        }
    }

    private async Task<User?> GetUniqueUserByPhoneAsync(string normalizedPhone, CancellationToken cancellationToken)
    {
        var phoneCandidates = BuildPhoneCandidates(normalizedPhone)
            .Select(candidate => candidate.StartsWith("+", StringComparison.Ordinal) ? candidate[1..] : candidate)
            .Distinct(StringComparer.OrdinalIgnoreCase)
            .ToList();
        if (phoneCandidates.Count == 0)
        {
            return null;
        }

        var users = await _context.Users
            .Where(u => u.Phone != null && !u.IsDeleted)
            .Select(u => new
            {
                User = u,
                PhoneClean = u.Phone!
                    .Replace(" ", string.Empty)
                    .Replace("-", string.Empty)
                    .Replace(".", string.Empty)
                    .Replace("(", string.Empty)
                    .Replace(")", string.Empty)
                    .Replace("+", string.Empty)
            })
            .Where(entry => phoneCandidates.Contains(entry.PhoneClean))
            .OrderByDescending(entry => entry.User.CreatedAt)
            .Select(entry => entry.User)
            .ToListAsync(cancellationToken);

        if (users.Count <= 1)
        {
            return users.SingleOrDefault();
        }

        throw new InvalidOperationException("Phone number is linked to multiple accounts. Please contact support.");
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

    private Task<AuthResponse> GenerateTokensForUserAsync(User user, string ipAddress, string userAgent, CancellationToken cancellationToken) =>
        _sessions.CreateAsync(user, ipAddress, userAgent, cancellationToken);

    private static string GenerateOtp()
    {
        return Random.Shared.Next(100000, 999999).ToString();
    }

    private static string BuildTrackingId(string purpose, Guid userId)
    {
        return $"{purpose}_{userId:N}_{DateTimeOffset.UtcNow.ToUnixTimeMilliseconds()}";
    }

    private static void ValidatePassword(string password)
    {
        if (string.IsNullOrWhiteSpace(password) || password.Trim().Length < 8)
        {
            throw new InvalidOperationException("Mật khẩu phải có ít nhất 8 ký tự.");
        }
    }

    private static string NormalizePhone(string phone)
    {
        if (string.IsNullOrWhiteSpace(phone))
        {
            throw new InvalidOperationException("Phone number is required.");
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
            throw new InvalidOperationException("Phone number format is invalid.");
        }

        return normalized;
    }
}

