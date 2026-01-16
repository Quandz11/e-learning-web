using SKVI.Domain.Common;
using SKVI.Domain.Entities.Auth;

namespace SKVI.Domain.Entities.Admin;

public class AuditLog : BaseEntity
{
    public Guid? UserId { get; set; }
    public string Action { get; set; } = string.Empty;
    public string TargetTable { get; set; } = string.Empty;
    public Guid? TargetId { get; set; }
    public string? Metadata { get; set; } // JSON metadata
    
    // Navigation properties
    public User? User { get; set; }
}
