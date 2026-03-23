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
            return Ok(new { message = "Phone registration successful. Please enter the OTP sent via Zalo." });
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
                message = "Phone number verified successfully."
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
            return Ok(new { message = "OTP has been resent via Zalo." });
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
    [HttpPost("request-forgot-password-otp")]
    public async Task<IActionResult> RequestForgotPasswordOtp([FromBody] PhoneForgotPasswordOtpRequest request)
    {
        try
        {
            await _phoneAuthService.RequestPhoneForgotPasswordOtpAsync(request);
            return Ok(new { message = "Đã gửi OTP quên mật khẩu qua Zalo." });
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

    [HttpPost("resend-forgot-password-otp")]
    public async Task<IActionResult> ResendForgotPasswordOtp([FromBody] PhoneForgotPasswordOtpRequest request)
    {
        try
        {
            await _phoneAuthService.ResendPhoneForgotPasswordOtpAsync(request);
            return Ok(new { message = "Đã gửi lại OTP quên mật khẩu qua Zalo." });
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

    [HttpPost("verify-forgot-password-otp")]
    public async Task<IActionResult> VerifyForgotPasswordOtp([FromBody] PhoneForgotPasswordOtpVerifyRequest request)
    {
        try
        {
            await _phoneAuthService.VerifyPhoneForgotPasswordOtpAsync(request);
            return Ok(new { message = "Mật khẩu đã được cập nhật thành công." });
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
            _logger.LogError(ex, "Phone forgot-password OTP verification failed.");
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

