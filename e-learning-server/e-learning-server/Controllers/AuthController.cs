using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.RateLimiting;
using SKVI.Application.DTOs.Auth;
using SKVI.Application.Interfaces;

namespace e_learning_server.Controllers;

[Route("api/auth")]
[ApiController]
[EnableRateLimiting("AuthRateLimit")]
public class AuthController : ControllerBase
{
    private readonly IAuthService _authService;
    private readonly ILogger<AuthController> _logger;

    public AuthController(IAuthService authService, ILogger<AuthController> logger)
    {
        _authService = authService;
        _logger = logger;
    }

    [HttpPost("login")]
    public async Task<IActionResult> Login([FromBody] LoginRequest request)
    {
        try
        {
            var ipAddress = GetClientIpAddress();
            var userAgent = Request.Headers.UserAgent.ToString();
            var response = await _authService.LoginAsync(request, ipAddress, userAgent);

            SetRefreshTokenCookie(response.RefreshToken);

            return Ok(new
            {
                accessToken = response.AccessToken,
                refreshToken = response.RefreshToken,
                expiresAt = response.ExpiresAt,
                requiresTwoFactor = response.RequiresTwoFactor
            });
        }
        catch (UnauthorizedAccessException ex)
        {
            return ApiError(StatusCodes.Status401Unauthorized, "AUTH_INVALID_CREDENTIALS", ex.Message);
        }
    }

    [HttpPost("register")]
    public async Task<IActionResult> Register([FromBody] RegisterRequest request)
    {
        try
        {
            await _authService.RegisterAsync(request);
            return Ok(new { message = "Đăng ký thành công. Vui lòng xác thực mã OTP để kích hoạt tài khoản." });
        }
        catch (InvalidOperationException ex)
        {
            return ApiError(StatusCodes.Status400BadRequest, "AUTH_REGISTER_INVALID", ex.Message);
        }
    }

    [HttpPost("verify-otp")]
    public async Task<IActionResult> VerifyOtp([FromBody] VerifyOtpRequest request)
    {
        try
        {
            var response = await _authService.VerifyOtpAsync(request);
            SetRefreshTokenCookie(response.RefreshToken);

            return Ok(new
            {
                accessToken = response.AccessToken,
                refreshToken = response.RefreshToken,
                expiresAt = response.ExpiresAt,
                message = "Xác thực tài khoản thành công."
            });
        }
        catch (UnauthorizedAccessException ex)
        {
            return ApiError(StatusCodes.Status401Unauthorized, "AUTH_OTP_INVALID", ex.Message);
        }
    }

    [HttpPost("resend-otp")]
    public async Task<IActionResult> ResendOtp([FromBody] ResendOtpRequest request)
    {
        try
        {
            await _authService.ResendOtpAsync(request);
            return Ok(new { message = "Đã gửi lại mã xác thực OTP thành công." });
        }
        catch (Exception ex)
        {
            return ApiError(StatusCodes.Status400BadRequest, "AUTH_RESEND_OTP_FAILED", ex.Message);
        }
    }

    [HttpPost("forgot-password")]
    public async Task<IActionResult> RequestForgotPassword([FromBody] ForgotPasswordRequest request)
    {
        try
        {
            await _authService.RequestForgotPasswordOtpAsync(request.Email);
            return Ok(new { message = "Đã gửi mã OTP đặt lại mật khẩu về email của bạn." });
        }
        catch (UnauthorizedAccessException ex)
        {
            return ApiError(StatusCodes.Status404NotFound, "AUTH_USER_NOT_FOUND", ex.Message);
        }
        catch (Exception ex)
        {
            return ApiError(StatusCodes.Status400BadRequest, "AUTH_FORGOT_PASSWORD_FAILED", ex.Message);
        }
    }

    [HttpPost("resend-forgot-password-otp")]
    public async Task<IActionResult> ResendForgotPasswordOtp([FromBody] ForgotPasswordRequest request)
    {
        try
        {
            await _authService.ResendForgotPasswordOtpAsync(request.Email);
            return Ok(new { message = "Đã gửi lại mã OTP đặt lại mật khẩu về email." });
        }
        catch (UnauthorizedAccessException ex)
        {
            return ApiError(StatusCodes.Status404NotFound, "AUTH_USER_NOT_FOUND", ex.Message);
        }
        catch (Exception ex)
        {
            return ApiError(StatusCodes.Status400BadRequest, "AUTH_RESEND_OTP_FAILED", ex.Message);
        }
    }

    [HttpPost("verify-forgot-password-otp")]
    public async Task<IActionResult> VerifyForgotPasswordOtp([FromBody] VerifyForgotPasswordOtpRequest request)
    {
        try
        {
            await _authService.VerifyForgotPasswordOtpAsync(request.Email, request.Otp, request.NewPassword);
            return Ok(new { message = "Mật khẩu đã được đặt lại thành công." });
        }
        catch (UnauthorizedAccessException ex)
        {
            return ApiError(StatusCodes.Status400BadRequest, "AUTH_OTP_INVALID", ex.Message);
        }
        catch (InvalidOperationException ex)
        {
            return ApiError(StatusCodes.Status400BadRequest, "AUTH_VALIDATION_ERROR", ex.Message);
        }
        catch (Exception ex)
        {
            return ApiError(StatusCodes.Status400BadRequest, "AUTH_RESET_PASSWORD_FAILED", ex.Message);
        }
    }

    [HttpPost("refresh")]
    public async Task<IActionResult> Refresh([FromBody] RefreshTokenRequest? request)
    {
        var refreshToken = request?.RefreshToken;
        if (string.IsNullOrWhiteSpace(refreshToken))
        {
            refreshToken = Request.Cookies["refreshToken"];
        }

        if (string.IsNullOrWhiteSpace(refreshToken))
        {
            return ApiError(StatusCodes.Status401Unauthorized, "AUTH_REFRESH_TOKEN_MISSING", "Không tìm thấy phiên làm việc để làm mới mã truy cập.");
        }

        try
        {
            var ipAddress = GetClientIpAddress();
            var userAgent = Request.Headers.UserAgent.ToString();
            var response = await _authService.RefreshTokenAsync(refreshToken, ipAddress, userAgent);

            SetRefreshTokenCookie(response.RefreshToken);

            return Ok(new
            {
                accessToken = response.AccessToken,
                refreshToken = response.RefreshToken,
                expiresAt = response.ExpiresAt
            });
        }
        catch (UnauthorizedAccessException ex)
        {
            return ApiError(StatusCodes.Status401Unauthorized, "AUTH_REFRESH_FAILED", ex.Message);
        }
    }

    [HttpPost("logout")]
    public async Task<IActionResult> Logout([FromBody] LogoutRequest? request)
    {
        var refreshToken = request?.RefreshToken;
        if (string.IsNullOrWhiteSpace(refreshToken))
        {
            refreshToken = Request.Cookies["refreshToken"];
        }

        if (!string.IsNullOrWhiteSpace(refreshToken))
        {
            await _authService.LogoutAsync(refreshToken);
        }

        Response.Cookies.Delete("refreshToken");
        return Ok(new { message = "Đăng xuất thành công." });
    }

    [Authorize]
    [HttpPost("2fa/setup")]
    public async Task<IActionResult> TwoFactorSetup()
    {
        try
        {
            var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (string.IsNullOrWhiteSpace(userId))
            {
                return ApiError(StatusCodes.Status401Unauthorized, "AUTH_UNAUTHORIZED", "Phiên đăng nhập không hợp lệ hoặc đã hết hạn.");
            }

            var (secret, qrCodeUri) = await _authService.GenerateTwoFactorSetupAsync(Guid.Parse(userId));
            return Ok(new { secret, qrCodeUri });
        }
        catch (Exception ex)
        {
            return ApiError(StatusCodes.Status400BadRequest, "AUTH_2FA_SETUP_FAILED", ex.Message);
        }
    }

    [Authorize]
    [HttpPost("2fa/enable")]
    public async Task<IActionResult> EnableTwoFactor([FromBody] TwoFactorEnableRequest request)
    {
        try
        {
            var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (string.IsNullOrWhiteSpace(userId))
            {
                return ApiError(StatusCodes.Status401Unauthorized, "AUTH_UNAUTHORIZED", "Phiên đăng nhập không hợp lệ hoặc đã hết hạn.");
            }

            var response = await _authService.EnableTwoFactorAsync(Guid.Parse(userId), request.Secret, request.Code);
            SetRefreshTokenCookie(response.RefreshToken);

            return Ok(new
            {
                accessToken = response.AccessToken,
                refreshToken = response.RefreshToken,
                expiresAt = response.ExpiresAt,
                message = "Đã bật xác thực hai lớp (2FA) thành công."
            });
        }
        catch (Exception ex)
        {
            return ApiError(StatusCodes.Status400BadRequest, "AUTH_2FA_ENABLE_FAILED", ex.Message);
        }
    }

    [Authorize]
    [HttpPost("2fa/disable")]
    public async Task<IActionResult> DisableTwoFactor([FromBody] TwoFactorDisableRequest request)
    {
        try
        {
            var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (string.IsNullOrWhiteSpace(userId))
            {
                return ApiError(StatusCodes.Status401Unauthorized, "AUTH_UNAUTHORIZED", "Phiên đăng nhập không hợp lệ hoặc đã hết hạn.");
            }

            await _authService.DisableTwoFactorAsync(Guid.Parse(userId), request.Password);
            return Ok(new { message = "Đã tắt xác thực hai lớp (2FA) thành công." });
        }
        catch (Exception ex)
        {
            return ApiError(StatusCodes.Status400BadRequest, "AUTH_2FA_DISABLE_FAILED", ex.Message);
        }
    }

    [HttpPost("2fa/login-verify")]
    public async Task<IActionResult> LoginVerifyTwoFactor([FromBody] TwoFactorLoginRequest request)
    {
        try
        {
            var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (string.IsNullOrWhiteSpace(userId))
            {
                return ApiError(StatusCodes.Status401Unauthorized, "AUTH_UNAUTHORIZED", "Phiên đăng nhập không hợp lệ hoặc đã hết hạn.");
            }

            var response = await _authService.VerifyTwoFactorLoginAsync(Guid.Parse(userId), request.Code);
            SetRefreshTokenCookie(response.RefreshToken);

            return Ok(new
            {
                accessToken = response.AccessToken,
                refreshToken = response.RefreshToken,
                expiresAt = response.ExpiresAt
            });
        }
        catch (Exception ex)
        {
            return ApiError(StatusCodes.Status401Unauthorized, "AUTH_2FA_VERIFY_FAILED", ex.Message);
        }
    }

    [Authorize]
    [DisableRateLimiting]
    [HttpGet("sessions")]
    public async Task<IActionResult> GetActiveSessions()
    {
        try
        {
            var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (string.IsNullOrWhiteSpace(userId))
            {
                return ApiError(StatusCodes.Status401Unauthorized, "AUTH_UNAUTHORIZED", "Phiên đăng nhập không hợp lệ hoặc đã hết hạn.");
            }

            var currentRefreshToken = User.FindFirst("sid")?.Value;
            var sessions = await _authService.GetActiveSessionsAsync(Guid.Parse(userId), currentRefreshToken);
            return Ok(sessions);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error getting active sessions");
            return ApiError(StatusCodes.Status400BadRequest, "AUTH_GET_SESSIONS_FAILED", ex.Message);
        }
    }

    [Authorize]
    [DisableRateLimiting]
    [HttpPost("sessions/revoke")]
    public async Task<IActionResult> RevokeSession([FromBody] RevokeSessionRequest request)
    {
        try
        {
            var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (string.IsNullOrWhiteSpace(userId))
            {
                return ApiError(StatusCodes.Status401Unauthorized, "AUTH_UNAUTHORIZED", "Phiên đăng nhập không hợp lệ hoặc đã hết hạn.");
            }

            await _authService.RevokeSessionAsync(Guid.Parse(userId), request.SessionId);
            return Ok(new { message = "Đã thu hồi phiên đăng nhập thành công." });
        }
        catch (KeyNotFoundException ex)
        {
            return ApiError(StatusCodes.Status404NotFound, "AUTH_SESSION_NOT_FOUND", ex.Message);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error revoking session");
            return ApiError(StatusCodes.Status400BadRequest, "AUTH_REVOKE_SESSION_FAILED", ex.Message);
        }
    }

    [Authorize]
    [DisableRateLimiting]
    [HttpPost("sessions/revoke-all")]
    public async Task<IActionResult> RevokeAllSessions()
    {
        try
        {
            var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (string.IsNullOrWhiteSpace(userId))
            {
                return ApiError(StatusCodes.Status401Unauthorized, "AUTH_UNAUTHORIZED", "Phiên đăng nhập không hợp lệ hoặc đã hết hạn.");
            }

            var currentRefreshToken = User.FindFirst("sid")?.Value;
            await _authService.RevokeAllSessionsAsync(Guid.Parse(userId), currentRefreshToken);
            return Ok(new { message = "Đã đăng xuất khỏi tất cả các thiết bị khác thành công." });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error revoking all sessions");
            return ApiError(StatusCodes.Status400BadRequest, "AUTH_REVOKE_ALL_SESSIONS_FAILED", ex.Message);
        }
    }

    private void SetRefreshTokenCookie(string refreshToken)
    {
        var cookieOptions = new CookieOptions
        {
            HttpOnly = true,
            Expires = DateTime.UtcNow.AddDays(7),
            SameSite = SameSiteMode.None,
            Secure = true
        };

        Response.Cookies.Append("refreshToken", refreshToken, cookieOptions);
    }

    private string GetClientIpAddress() => HttpContext.Connection.RemoteIpAddress?.ToString() ?? "Unknown";

    private IActionResult ApiError(int statusCode, string code, string message, object? errors = null)
    {
        return StatusCode(statusCode, new { code, message, errors });
    }
}
