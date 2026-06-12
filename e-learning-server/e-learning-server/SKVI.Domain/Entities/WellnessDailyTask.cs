using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace SKVI.Domain.Entities;

[Table("WellnessDailyTasks")]
public class WellnessDailyTask
{
    [Key]
    public Guid Id { get; set; } = Guid.NewGuid();

    public Guid WellnessPlanId { get; set; }

    public Guid? LessonId { get; set; }

    public int DayIndex { get; set; }

    public DateTime TaskDate { get; set; }

    [Required]
    public string Title { get; set; } = string.Empty;

    public string Content { get; set; } = string.Empty;

    public int EstimatedMinutes { get; set; } = 20;

    public int SortOrder { get; set; }

    public string Status { get; set; } = "PLANNED";

    public bool IsCompleted { get; set; } = false;

    public DateTime? CompletedAt { get; set; }

    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    [ForeignKey(nameof(WellnessPlanId))]
    public virtual WellnessPlan WellnessPlan { get; set; } = null!;

    [ForeignKey(nameof(LessonId))]
    public virtual Lesson? Lesson { get; set; }
}
