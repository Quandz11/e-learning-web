namespace SKVI.Application.DTOs.Auth;

public record LoginRequest(string Email, string Password);
public record RegisterRequest(string Email, string Password, string FullName, string? Phone);
public record AuthResponse(string AccessToken, string RefreshToken, DateTime ExpiresAt);
public record RefreshTokenRequest(string RefreshToken);
public record VerifyOtpRequest(string Email, string Otp);
public record ResendOtpRequest(string Email);
