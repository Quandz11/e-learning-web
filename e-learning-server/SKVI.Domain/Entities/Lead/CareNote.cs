using SKVI.Domain.Common;
using SKVI.Domain.Entities.Auth;

namespace SKVI.Domain.Entities.Lead;

public class CareNote : BaseEntity
{
    public Guid? LeadId { get; set; }
    public Guid? StudentId { get; set; }
    public Guid CareId { get; set; }
    public string Note { get; set; } = string.Empty;
    
    // Navigation properties
    public Lead? Lead { get; set; }
    public User? Student { get; set; }
    public User Care { get; set; } = null!;
}
