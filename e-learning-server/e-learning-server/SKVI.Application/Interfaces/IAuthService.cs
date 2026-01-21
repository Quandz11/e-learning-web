using SKVI.Application.DTOs.Auth;

namespace SKVI.Application.Interfaces;

public interface IAuthService
{
    Task<AuthResponse> LoginAsync(LoginRequest request, string ipAddress, string userAgent);
    Task RegisterAsync(RegisterRequest request);
    Task<AuthResponse> VerifyOtpAsync(VerifyOtpRequest request);
    Task ResendOtpAsync(ResendOtpRequest request);
    Task<AuthResponse> RefreshTokenAsync(string refreshToken, string ipAddress, string userAgent);
    Task LogoutAsync(string refreshToken);

    // 2FA
    Task<(string Secret, string QrCodeUri)> GenerateTwoFactorSetupAsync(Guid userId);
    Task<AuthResponse> EnableTwoFactorAsync(Guid userId, string secret, string code);
    Task DisableTwoFactorAsync(Guid userId, string password);
    Task<AuthResponse> VerifyTwoFactorLoginAsync(Guid userId, string code);
}

public interface ITokenService
{
    string GenerateAccessToken(Guid userId, string email, string role, string? fullName = null);
    string GenerateRefreshToken();
}

public interface IPasswordHasher
{
    string HashPassword(string password);
    bool VerifyPassword(string password, string passwordHash);
}
