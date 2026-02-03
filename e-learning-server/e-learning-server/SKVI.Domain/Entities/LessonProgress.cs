using System.ComponentModel.DataAnnotations;

namespace SKVI.Domain.Entities;

public class LessonProgress
{
    [Key]
    public Guid Id { get; set; }

    [Required]
    public Guid EnrollmentId { get; set; }

    [Required]
    public Guid LessonPartId { get; set; }

    public bool IsCompleted { get; set; } = false;

    [Range(0, int.MaxValue)]
    public int WatchedDuration { get; set; } = 0; // seconds

    public DateTime? CompletedAt { get; set; }

    [Required]
    public DateTime LastWatchedAt { get; set; }

    // Navigation properties
    public Enrollment Enrollment { get; set; } = null!;
    public LessonPart LessonPart { get; set; } = null!;
}
