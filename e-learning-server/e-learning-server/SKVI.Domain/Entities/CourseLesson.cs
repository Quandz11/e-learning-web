namespace SKVI.Domain.Entities;

public class CourseLesson
{
    public Guid Id { get; set; }
    public Guid SectionId { get; set; }
    public string Title { get; set; } = string.Empty;
    public int Duration { get; set; }
    public Guid VideoId { get; set; }
    public int OrderIndex { get; set; }
    public bool IsPreview { get; set; }

    // Navigation properties
    public CourseSection Section { get; set; } = null!;
    public Video Video { get; set; } = null!;
    public ICollection<LessonProgress> LessonProgresses { get; set; } = new List<LessonProgress>();
}
