namespace SKVI.Application.Interfaces;

public interface IPhoneOtpSender
{
    Task SendOtpAsync(
        string normalizedPhone,
        string otpCode,
        string purpose,
        string trackingId,
        CancellationToken cancellationToken = default
    );
}
