namespace SKVI.Domain.Entities;

public class CareNote
{
    public Guid Id { get; set; }
    public Guid? LeadId { get; set; }
    public Guid? StudentId { get; set; }
    public Guid CareId { get; set; }
    public string Note { get; set; } = string.Empty;
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    // Navigation properties
    public Lead? Lead { get; set; }
    public User? Student { get; set; }
    public User Care { get; set; } = null!;
}
