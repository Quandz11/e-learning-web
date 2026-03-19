using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace SKVI.Domain.Entities;

[Table("StudentSupportAlerts")]
public class StudentSupportAlert
{
    [Key]
    public Guid Id { get; set; } = Guid.NewGuid();

    public Guid UserId { get; set; }

    public Guid PlanId { get; set; }

    public Guid? DailyStudyTaskId { get; set; }

    public Guid? DailyStudyCheckInId { get; set; }

    [Required]
    public string Severity { get; set; } = "MEDIUM";

    [Required]
    public string Reason { get; set; } = string.Empty;

    [Required]
    public string Status { get; set; } = "OPEN";

    [Required]
    public string SourceType { get; set; } = "SYSTEM";

    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    public DateTime? ResolvedAt { get; set; }

    [ForeignKey(nameof(UserId))]
    public virtual User User { get; set; } = null!;

    [ForeignKey(nameof(PlanId))]
    public virtual UserStudyPlan Plan { get; set; } = null!;

    [ForeignKey(nameof(DailyStudyTaskId))]
    public virtual DailyStudyTask? DailyStudyTask { get; set; }

    [ForeignKey(nameof(DailyStudyCheckInId))]
    public virtual DailyStudyCheckIn? DailyStudyCheckIn { get; set; }
}
