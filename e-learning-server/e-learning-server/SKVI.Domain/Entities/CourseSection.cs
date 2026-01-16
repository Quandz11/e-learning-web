namespace SKVI.Domain.Entities;

public class CourseSection
{
    public Guid Id { get; set; }
    public Guid CourseId { get; set; }
    public string Title { get; set; } = string.Empty;
    public int OrderIndex { get; set; }

    // Navigation properties
    public Course Course { get; set; } = null!;
    public ICollection<CourseLesson> CourseLessons { get; set; } = new List<CourseLesson>();
}
