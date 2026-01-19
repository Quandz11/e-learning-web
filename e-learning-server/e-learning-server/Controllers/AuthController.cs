using Microsoft.AspNetCore.Mvc;
using SKVI.Application.DTOs.Auth;
using SKVI.Application.Interfaces;

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
            return Ok(new { response.AccessToken, response.ExpiresAt });
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
            return Ok(new { response.AccessToken, response.ExpiresAt });
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
