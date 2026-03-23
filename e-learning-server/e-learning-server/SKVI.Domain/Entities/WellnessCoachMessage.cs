using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace SKVI.Domain.Entities;

[Table("WellnessCoachMessages")]
public class WellnessCoachMessage
{
    [Key]
    public Guid Id { get; set; } = Guid.NewGuid();

    public Guid PlanId { get; set; }

    [MaxLength(16)]
    public string Role { get; set; } = "USER";

    [MaxLength(24)]
    public string MessageType { get; set; } = "GENERAL";

    public string ContentEncrypted { get; set; } = string.Empty;

    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    [ForeignKey(nameof(PlanId))]
    public virtual WellnessPlan Plan { get; set; } = null!;
}

