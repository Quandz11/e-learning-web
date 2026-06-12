using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace SKVI.Domain.Entities;

[Table("WellnessPlans")]
public class WellnessPlan
{
    [Key]
    public Guid Id { get; set; } = Guid.NewGuid();

    public Guid UserId { get; set; }

    [Required]
    [MaxLength(32)]
    public string PackageType { get; set; } = "TRIAL_3_DAYS";

    public DateTime StartDate { get; set; }

    public DateTime EndDate { get; set; }

    public int FastingHours { get; set; } = 16;

    public int EatingHours { get; set; } = 8;

    public int DailyFastStartMinuteOfDay { get; set; } = 20 * 60;

    [MaxLength(64)]
    public string Timezone { get; set; } = "Asia/Ho_Chi_Minh";

    [Column(TypeName = "decimal(6,2)")]
    public decimal StartWeightKg { get; set; }

    [Column(TypeName = "decimal(6,2)")]
    public decimal TargetWeightKg { get; set; }

    [Column(TypeName = "decimal(6,2)")]
    public decimal? LatestWeightKg { get; set; }

    [Required]
    [MaxLength(32)]
    public string Status { get; set; } = "ACTIVE";

    public DateTime? LastInsightAt { get; set; }

    [MaxLength(32)]
    public string UpgradeSuggestionLevel { get; set; } = "NONE";

    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;

    [ForeignKey(nameof(UserId))]
    public virtual User User { get; set; } = null!;

    public virtual ICollection<WellnessDailyLog> DailyLogs { get; set; } = new List<WellnessDailyLog>();

    public virtual ICollection<WellnessInsight> Insights { get; set; } = new List<WellnessInsight>();

    public virtual ICollection<WellnessResourceAssignment> ResourceAssignments { get; set; } = new List<WellnessResourceAssignment>();

    public virtual ICollection<WellnessCoachMessage> CoachMessages { get; set; } = new List<WellnessCoachMessage>();

    public virtual ICollection<WellnessMealSuggestion> MealSuggestions { get; set; } = new List<WellnessMealSuggestion>();

    public virtual ICollection<WellnessDailyTask> DailyTasks { get; set; } = new List<WellnessDailyTask>();
}

