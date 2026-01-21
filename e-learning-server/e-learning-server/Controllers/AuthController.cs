using Microsoft.AspNetCore.Mvc;
using SKVI.Application.DTOs.Auth;
using SKVI.Application.Interfaces;
using Microsoft.AspNetCore.Authorization;
using System.Security.Claims;

namespace e_learning_server.Controllers;

[Route("api/auth")]
[ApiController]
public class AuthController : ControllerBase
{
    private readonly IAuthService _authService;
    private readonly ILogger<AuthController> _logger;
    private readonly IWebHostEnvironment _environment;

    public AuthController(IAuthService authService, ILogger<AuthController> logger, IWebHostEnvironment environment)
    {
        _authService = authService;
        _logger = logger;
        _environment = environment;
    }

    [HttpPost("login")]
    public async Task<IActionResult> Login([FromBody] LoginRequest request)
    {
        try
        {
            var ipAddress = HttpContext.Connection.RemoteIpAddress?.ToString() ?? "Unknown";
            var userAgent = Request.Headers.UserAgent.ToString();
            
            var response = await _authService.LoginAsync(request, ipAddress, userAgent);
            
            SetRefreshTokenCookie(response.RefreshToken);
            
            Console.WriteLine($"[AuthController] ✅ Login successful for {request.Email}, refresh token set in HttpOnly Cookie");
            return Ok(new { 
                accessToken = response.AccessToken, 
                expiresAt = response.ExpiresAt,
                requiresTwoFactor = response.RequiresTwoFactor 
            });
        }
        catch (UnauthorizedAccessException ex)
        {
            Console.WriteLine($"[AuthController] ❌ Login failed: {ex.Message}");
            return Unauthorized(new { message = ex.Message });
        }
    }

    [HttpPost("register")]
    public async Task<IActionResult> Register([FromBody] RegisterRequest request)
    {
        try
        {
            await _authService.RegisterAsync(request);
            // OTP Sent
            return Ok(new { message = "Registration successful. Please verify your email." });
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    [HttpPost("verify-otp")]
    public async Task<IActionResult> VerifyOtp([FromBody] VerifyOtpRequest request)
    {
        try
        {
             var response = await _authService.VerifyOtpAsync(request);
             
             SetRefreshTokenCookie(response.RefreshToken);
             
             return Ok(new { response.AccessToken, response.ExpiresAt, message = "Account verified." });
        }
        catch (UnauthorizedAccessException ex)
        {
            return Unauthorized(new { message = ex.Message });
        }
    }

    [HttpPost("resend-otp")]
    public async Task<IActionResult> ResendOtp([FromBody] ResendOtpRequest request)
    {
        try
        {
             await _authService.ResendOtpAsync(request);
             return Ok(new { message = "OTP resent successfully." });
        }
        catch (Exception ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    [HttpPost("refresh")]
    public async Task<IActionResult> Refresh()
    {
        var refreshToken = Request.Cookies["refreshToken"];
        
        Console.WriteLine($"[AuthController] 🔄 Refresh endpoint called");
        Console.WriteLine($"[AuthController] Cookie refreshToken present: {!string.IsNullOrEmpty(refreshToken)}");
        
        if (string.IsNullOrEmpty(refreshToken))
        {
            Console.WriteLine($"[AuthController] ❌ Refresh token is missing from cookies");
            return Unauthorized(new { message = "Refresh token is missing." });
        }

        try
        {
            var ipAddress = HttpContext.Connection.RemoteIpAddress?.ToString() ?? "Unknown";
            var userAgent = Request.Headers.UserAgent.ToString();

            var response = await _authService.RefreshTokenAsync(refreshToken, ipAddress, userAgent);
            
            SetRefreshTokenCookie(response.RefreshToken);
            
            Console.WriteLine($"[AuthController] ✅ Token refreshed successfully");
            
            return Ok(new { 
                accessToken = response.AccessToken, 
                expiresAt = response.ExpiresAt 
            });
        }
        catch (UnauthorizedAccessException ex)
        {
            Console.WriteLine($"[AuthController] ❌ Refresh failed: {ex.Message}");
            return Unauthorized(new { message = ex.Message });
        }
    }

    [HttpPost("logout")]
    public async Task<IActionResult> Logout()
    {
        var refreshToken = Request.Cookies["refreshToken"];
        
        if (!string.IsNullOrEmpty(refreshToken))
        {
            await _authService.LogoutAsync(refreshToken);
        }

        Response.Cookies.Delete("refreshToken");
        
        return Ok(new { message = "Logged out successfully." });
    }

    [Authorize]
    [HttpPost("2fa/setup")]
    public async Task<IActionResult> TwoFactorSetup()
    {
        try
        {
            var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (string.IsNullOrEmpty(userId)) return Unauthorized();

            var (secret, qrCodeUri) = await _authService.GenerateTwoFactorSetupAsync(Guid.Parse(userId));
            return Ok(new { secret, qrCodeUri });
        }
        catch (Exception ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    [Authorize]
    [HttpPost("2fa/enable")]
    public async Task<IActionResult> EnableTwoFactor([FromBody] TwoFactorEnableRequest request)
    {
        try
        {
            var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (string.IsNullOrEmpty(userId)) return Unauthorized();

            var response = await _authService.EnableTwoFactorAsync(Guid.Parse(userId), request.Secret, request.Code);
            
            SetRefreshTokenCookie(response.RefreshToken);
            
            return Ok(new { 
                accessToken = response.AccessToken, 
                expiresAt = response.ExpiresAt 
            });
        }
        catch (Exception ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    [Authorize]
    [HttpPost("2fa/disable")]
    public async Task<IActionResult> DisableTwoFactor([FromBody] TwoFactorDisableRequest request)
    {
        try
        {
            var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (string.IsNullOrEmpty(userId)) return Unauthorized();

            await _authService.DisableTwoFactorAsync(Guid.Parse(userId), request.Password);
            return Ok(new { message = "2FA disabled successfully." });
        }
        catch (Exception ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    [HttpPost("2fa/login-verify")]
    public async Task<IActionResult> LoginVerifyTwoFactor([FromBody] TwoFactorLoginRequest request)
    {
        try
        {
            // The user should be authenticated via the PreAuth token here?
            // Actually, if we use [Authorize], the PreAuth token must work.
            // If the PreAuth token is valid JWT, [Authorize] works.
            var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (string.IsNullOrEmpty(userId)) return Unauthorized();

            var response = await _authService.VerifyTwoFactorLoginAsync(Guid.Parse(userId), request.Code);
            
            SetRefreshTokenCookie(response.RefreshToken);
            
            return Ok(new { 
                accessToken = response.AccessToken, 
                expiresAt = response.ExpiresAt 
            });
        }
        catch (Exception ex)
        {
            return Unauthorized(new { message = ex.Message });
        }
    }

    private void SetRefreshTokenCookie(string refreshToken)
    {
        var cookieOptions = new CookieOptions
        {
            HttpOnly = true,
            Expires = DateTime.UtcNow.AddDays(7),
            SameSite = SameSiteMode.Strict, // HTTPS only - same-origin
            Secure = true // HTTPS required
        };
        
        Response.Cookies.Append("refreshToken", refreshToken, cookieOptions);
    }
}
