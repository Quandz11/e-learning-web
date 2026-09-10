namespace SKVI.Application.DTOs.Auth;

public record LoginRequest(string Email, string Password);
public record RegisterRequest(string Email, string Password, string FullName, string? Phone, string? ReferralCode = null);
public record VerifyOtpRequest(string Email, string Otp);
public record ResendOtpRequest(string Email);
public record RefreshTokenRequest(string? RefreshToken);
public record LogoutRequest(string? RefreshToken);

public record AuthResponse(string AccessToken, string RefreshToken, DateTime ExpiresAt, bool RequiresTwoFactor = false);

public record TwoFactorEnableRequest(string Secret, string Code);
public record TwoFactorDisableRequest(string Password);
public record TwoFactorLoginRequest(string Code);
public record ForgotPasswordRequest(string Email);
public record VerifyForgotPasswordOtpRequest(string Email, string Otp, string NewPassword);
