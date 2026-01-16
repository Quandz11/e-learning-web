using SKVI.Domain.Common;
using SKVI.Domain.Entities.Enrollment;

namespace SKVI.Domain.Entities.Course;

public class CourseLesson : BaseEntity
{
    public Guid SectionId { get; set; }
    public string Title { get; set; } = string.Empty;
    public int Duration { get; set; }
    public Guid? VideoId { get; set; }
    public int OrderIndex { get; set; }
    public bool IsPreview { get; set; } = false;
    
    // Navigation properties
    public CourseSection Section { get; set; } = null!;
    public Video? Video { get; set; }
    public ICollection<LessonProgress> LessonProgresses { get; set; } = new List<LessonProgress>();
}
