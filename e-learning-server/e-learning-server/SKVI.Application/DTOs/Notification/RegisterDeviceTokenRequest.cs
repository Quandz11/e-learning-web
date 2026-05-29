using System.ComponentModel.DataAnnotations;

namespace SKVI.Application.DTOs.Notification;

public class RegisterDeviceTokenRequest
{
    [Required]
    public string DeviceId { get; set; } = string.Empty;

    [Required]
    public string Token { get; set; } = string.Empty;

    [Required]
    public string Platform { get; set; } = string.Empty;

    public string? AppVersion { get; set; }
}
