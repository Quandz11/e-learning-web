namespace SKVI.Domain.Entities;

public class Lesson
{
    public Guid Id { get; set; }
    public string Title { get; set; } = string.Empty;
    public string? Description { get; set; }
    public string? ThumbnailUrl { get; set; }
    public Guid? CategoryId { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime? UpdatedAt { get; set; }

    // Navigation properties
    public Category? Category { get; set; }
    public ICollection<LessonPart> LessonParts { get; set; } = new List<LessonPart>();
    public ICollection<CourseLesson> CourseLessons { get; set; } = new List<CourseLesson>();
}
