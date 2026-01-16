using SKVI.Domain.Common;
using SKVI.Domain.Enums;
using SKVI.Domain.Entities.Auth;

namespace SKVI.Domain.Entities.Lead;

public class Lead : BaseEntity
{
    public string FullName { get; set; } = string.Empty;
    public string? Phone { get; set; }
    public string? ZaloUserId { get; set; }
    public LeadSource Source { get; set; }
    public LeadStatus Status { get; set; } = LeadStatus.NEW;
    public Guid? AssignedCareId { get; set; }
    public Guid? AssignedCabinId { get; set; }
    
    // Navigation properties
    public User? AssignedCare { get; set; }
    public Entities.Cabin.Cabin? AssignedCabin { get; set; }
    public ICollection<CareNote> CareNotes { get; set; } = new List<CareNote>();
}
