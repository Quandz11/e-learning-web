namespace SKVI.Domain.Entities;

public class CourseLesson
{
    public Guid CourseId { get; set; }
    public Guid LessonId { get; set; }
    public int OrderIndex { get; set; }

    // Navigation properties
    public Course Course { get; set; } = null!;
    public Lesson Lesson { get; set; } = null!;
}
