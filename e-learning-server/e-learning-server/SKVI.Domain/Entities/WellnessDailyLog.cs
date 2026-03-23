using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace SKVI.Domain.Entities;

[Table("WellnessDailyLogs")]
public class WellnessDailyLog
{
    [Key]
    public Guid Id { get; set; } = Guid.NewGuid();

    public Guid PlanId { get; set; }

    public DateTime LogDate { get; set; }

    public DateTime? AteAtUtc { get; set; }

    public int WaterMl { get; set; }

    public int WorkoutMinutes { get; set; }

    [MaxLength(128)]
    public string WorkoutType { get; set; } = string.Empty;

    [Column(TypeName = "decimal(6,2)")]
    public decimal? CurrentWeightKg { get; set; }

    public string NotesEncrypted { get; set; } = string.Empty;

    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;

    [ForeignKey(nameof(PlanId))]
    public virtual WellnessPlan Plan { get; set; } = null!;
}

