namespace SKVI.Domain.Entities;

public class LessonProgress
{
    public Guid Id { get; set; }
    public Guid EnrollmentId { get; set; }
    public Guid LessonId { get; set; }
    public int WatchedSeconds { get; set; }
    public bool IsCompleted { get; set; }

    // Navigation properties
    public Enrollment Enrollment { get; set; } = null!;
    public CourseLesson Lesson { get; set; } = null!;
}
