namespace SKVI.Application.DTOs.Auth;

public record PhoneRegisterRequest(
    string FullName,
    string Phone,
    string? Email = null,
    string? Password = null,
    string? ReferralCode = null
);

public record PhoneRegisterOtpVerifyRequest(string Phone, string Otp);

public record PhoneRegisterResendOtpRequest(string Phone);

public record PhoneForgotPasswordOtpRequest(string Phone);

public record PhoneForgotPasswordOtpVerifyRequest(string Phone, string Otp, string NewPassword);
