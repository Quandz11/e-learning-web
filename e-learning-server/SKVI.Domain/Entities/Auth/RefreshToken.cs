using SKVI.Domain.Common;

namespace SKVI.Domain.Entities.Auth;

public class RefreshToken : BaseEntity
{
    public Guid UserId { get; set; }
    public string TokenHash { get; set; } = string.Empty;
    public string? DeviceId { get; set; }
    public string? IpAddress { get; set; }
    public DateTime ExpiresAt { get; set; }
    public DateTime? RevokedAt { get; set; }
    
    // Navigation properties
    public User User { get; set; } = null!;
}
