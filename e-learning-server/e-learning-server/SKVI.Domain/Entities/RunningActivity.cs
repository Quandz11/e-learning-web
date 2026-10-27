using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace SKVI.Domain.Entities;

[Table("RunningActivities")]
public class RunningActivity
{
    [Key]
    public Guid Id { get; set; } = Guid.NewGuid();

    public Guid UserId { get; set; }

    [Column(TypeName = "decimal(8,2)")]
    public decimal DistanceKm { get; set; }

    public int DurationSeconds { get; set; }

    [Column(TypeName = "decimal(6,2)")]
    public decimal? PaceMinPerKm { get; set; }

    public int CaloriesBurned { get; set; }

    public DateTime ActivityDate { get; set; } = DateTime.UtcNow;

    [MaxLength(256)]
    public string Title { get; set; } = "Chạy bộ";

    [MaxLength(1024)]
    public string? Notes { get; set; }

    [MaxLength(32)]
    public string TrackingMode { get; set; } = "GPS"; // "GPS" | "MANUAL"

    public int EnergyEarned { get; set; }

    [MaxLength(512)]
    public string? BadgesEarnedJson { get; set; }

    public Guid? LinkedGoalId { get; set; }

    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    [ForeignKey(nameof(UserId))]
    public virtual User User { get; set; } = null!;
}
