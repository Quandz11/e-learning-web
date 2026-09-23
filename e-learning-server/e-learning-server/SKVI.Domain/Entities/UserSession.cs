using System.ComponentModel.DataAnnotations;

namespace SKVI.Domain.Entities;

public class UserSession
{
    public Guid Id { get; set; }
    public Guid UserId { get; set; }
    public User User { get; set; } = null!;
    [MaxLength(200)] public string DeviceName { get; set; } = "Unknown";
    [MaxLength(40)] public string Platform { get; set; } = "Web";
    [MaxLength(1000)] public string UserAgent { get; set; } = "";
    [MaxLength(64)] public string IpAddress { get; set; } = "Unknown";
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime LastActiveAt { get; set; } = DateTime.UtcNow;
    public DateTime ExpiresAt { get; set; }
    public DateTime? RevokedAt { get; set; }
    [Timestamp] public byte[] Version { get; set; } = [];
}
