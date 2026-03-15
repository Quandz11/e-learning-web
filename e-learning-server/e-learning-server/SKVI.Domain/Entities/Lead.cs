namespace SKVI.Domain.Entities;

public class Lead
{
    public Guid Id { get; set; }
    public string? FullName { get; set; }
    public string? Email { get; set; }
    public string? Phone { get; set; }
    public string? Goal { get; set; }
    public string? ZaloUserId { get; set; }
    public string? Source { get; set; } // ZALO, FACEBOOK, MANUAL
    public string Status { get; set; } = "NEW"; // NEW, CONTACTED, CONSULTING, CONVERTED, LOST
    public Guid? AssignedCareId { get; set; }
    public Guid? AssignedCabinId { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;

    // Navigation properties
    public User? AssignedCare { get; set; }
    public Cabin? AssignedCabin { get; set; }
    public ICollection<CareNote> CareNotes { get; set; } = new List<CareNote>();
}
