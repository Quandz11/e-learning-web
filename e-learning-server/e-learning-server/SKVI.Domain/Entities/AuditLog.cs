using System.Text.Json;

namespace SKVI.Domain.Entities;

public class AuditLog
{
    public Guid Id { get; set; }
    public Guid? UserId { get; set; }
    public string Action { get; set; } = string.Empty;
    public string? TargetTable { get; set; }
    public Guid? TargetId { get; set; }
    public string? Metadata { get; set; } // Stored as JSON string
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
}
