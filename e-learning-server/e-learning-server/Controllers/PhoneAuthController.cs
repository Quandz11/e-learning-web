using Microsoft.AspNetCore.Mvc;
using SKVI.Application.DTOs.Auth;
using SKVI.Application.Interfaces;

namespace e_learning_server.Controllers;

[Route("api/auth/phone")]
[ApiController]
public class PhoneAuthController : ControllerBase
{
    private readonly IPhoneAuthService _phoneAuthService;
    private readonly ILogger<PhoneAuthController> _logger;

    public PhoneAuthController(IPhoneAuthService phoneAuthService, ILogger<PhoneAuthController> logger)
    {
        _phoneAuthService = phoneAuthService;
        _logger = logger;
    }

    [HttpPost("register")]
    public async Task<IActionResult> Register([FromBody] PhoneRegisterRequest request)
    {
        try
        {
            await _phoneAuthService.RegisterByPhoneAsync(request);
            return Ok(new { message = "Đăng ký thành công. Vui lòng nhập OTP đã gửi qua Zalo." });
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    [HttpPost("verify-register-otp")]
    public async Task<IActionResult> VerifyRegisterOtp([FromBody] PhoneRegisterOtpVerifyRequest request)
    {
        try
        {
            var ipAddress = GetClientIpAddress();
            var userAgent = Request.Headers.UserAgent.ToString();

            var response = await _phoneAuthService.VerifyPhoneRegistrationOtpAsync(request, ipAddress, userAgent);

            SetRefreshTokenCookie(response.RefreshToken);
            return Ok(new
            {
                accessToken = response.AccessToken,
                expiresAt = response.ExpiresAt,
                message = "Xác minh số điện thoại thành công."
            });
        }
        catch (UnauthorizedAccessException ex)
        {
            return Unauthorized(new { message = ex.Message });
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    [HttpPost("resend-register-otp")]
    public async Task<IActionResult> ResendRegisterOtp([FromBody] PhoneRegisterResendOtpRequest request)
    {
        try
        {
            await _phoneAuthService.ResendPhoneRegistrationOtpAsync(request);
            return Ok(new { message = "Đã gửi lại OTP qua Zalo." });
        }
        catch (UnauthorizedAccessException ex)
        {
            return Unauthorized(new { message = ex.Message });
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    [HttpPost("request-login-otp")]
    public async Task<IActionResult> RequestLoginOtp([FromBody] PhoneLoginOtpRequest request)
    {
        try
        {
            await _phoneAuthService.RequestPhoneLoginOtpAsync(request);
            return Ok(new { message = "OTP đăng nhập đã được gửi qua Zalo." });
        }
        catch (UnauthorizedAccessException ex)
        {
            return Unauthorized(new { message = ex.Message });
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    [HttpPost("verify-login-otp")]
    public async Task<IActionResult> VerifyLoginOtp([FromBody] PhoneLoginOtpVerifyRequest request)
    {
        try
        {
            var ipAddress = GetClientIpAddress();
            var userAgent = Request.Headers.UserAgent.ToString();

            var response = await _phoneAuthService.VerifyPhoneLoginOtpAsync(request, ipAddress, userAgent);
            SetRefreshTokenCookie(response.RefreshToken);

            return Ok(new
            {
                accessToken = response.AccessToken,
                expiresAt = response.ExpiresAt
            });
        }
        catch (UnauthorizedAccessException ex)
        {
            return Unauthorized(new { message = ex.Message });
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Phone login OTP verification failed.");
            return BadRequest(new { message = "Không thể xác minh OTP ở thời điểm hiện tại." });
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

    private string GetClientIpAddress()
    {
        var forwardedFor = Request.Headers["X-Forwarded-For"].FirstOrDefault();
        if (!string.IsNullOrEmpty(forwardedFor))
        {
            var ips = forwardedFor.Split(',');
            if (ips.Length > 0)
            {
                return ips[0].Trim();
            }
        }

        var realIp = Request.Headers["X-Real-IP"].FirstOrDefault();
        if (!string.IsNullOrEmpty(realIp))
        {
            return realIp;
        }

        return HttpContext.Connection.RemoteIpAddress?.ToString() ?? "Unknown";
    }
}
