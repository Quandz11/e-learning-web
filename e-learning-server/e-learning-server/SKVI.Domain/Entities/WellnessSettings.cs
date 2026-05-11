using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace SKVI.Domain.Entities;

[Table("WellnessSettings")]
public class WellnessSettings
{
    [Key]
    public Guid Id { get; set; } = Guid.NewGuid();

    [Required]
    [MaxLength(128)]
    public string CtaPath { get; set; } = "/pricing";

    public bool IsPersonalizedRoadmapPaid { get; set; } = true;

    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;
}
