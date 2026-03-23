using SKVI.Application.DTOs.Auth;

namespace SKVI.Application.Interfaces;

public interface IPhoneAuthService
{
    Task RegisterByPhoneAsync(PhoneRegisterRequest request, CancellationToken cancellationToken = default);

    Task<AuthResponse> VerifyPhoneRegistrationOtpAsync(
        PhoneRegisterOtpVerifyRequest request,
        string ipAddress,
        string userAgent,
        CancellationToken cancellationToken = default
    );

    Task ResendPhoneRegistrationOtpAsync(
        PhoneRegisterResendOtpRequest request,
        CancellationToken cancellationToken = default
    );

    Task RequestPhoneLoginOtpAsync(PhoneLoginOtpRequest request, CancellationToken cancellationToken = default);

    Task<AuthResponse> VerifyPhoneLoginOtpAsync(
        PhoneLoginOtpVerifyRequest request,
        string ipAddress,
        string userAgent,
        CancellationToken cancellationToken = default
    );
}
