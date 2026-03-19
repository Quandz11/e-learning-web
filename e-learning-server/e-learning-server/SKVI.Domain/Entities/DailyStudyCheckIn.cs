using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace SKVI.Domain.Entities;

[Table("DailyStudyCheckIns")]
public class DailyStudyCheckIn
{
    [Key]
    public Guid Id { get; set; } = Guid.NewGuid();

    public Guid PlanId { get; set; }

    public DateTime CheckInDate { get; set; }

    public int MoodScore { get; set; }

    public int EnergyScore { get; set; }

    public int ConfidenceScore { get; set; }

    public int? ActualMinutesSpentToday { get; set; }

    public int MinutesAvailableTomorrow { get; set; }

    public string Notes { get; set; } = string.Empty;

    public bool NeedsSupport { get; set; }

    public string CoachAdvice { get; set; } = string.Empty;

    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    [ForeignKey(nameof(PlanId))]
    public virtual UserStudyPlan Plan { get; set; } = null!;
}
