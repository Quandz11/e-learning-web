using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace SKVI.Domain.Entities;

[Table("WellnessInsights")]
public class WellnessInsight
{
    [Key]
    public Guid Id { get; set; } = Guid.NewGuid();

    public Guid PlanId { get; set; }

    public DateTime InsightDate { get; set; }

    public string SummaryEncrypted { get; set; } = string.Empty;

    public string TipEncrypted { get; set; } = string.Empty;

    public string RisksEncrypted { get; set; } = string.Empty;

    [MaxLength(32)]
    public string GeneratedBy { get; set; } = "SYSTEM";

    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    [ForeignKey(nameof(PlanId))]
    public virtual WellnessPlan Plan { get; set; } = null!;
}

