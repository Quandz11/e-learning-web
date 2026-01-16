using SKVI.Domain.Common;

namespace SKVI.Domain.Entities.Course;

public class CourseSection : BaseEntity
{
    public Guid CourseId { get; set; }
    public string Title { get; set; } = string.Empty;
    public int OrderIndex { get; set; }
    
    // Navigation properties
    public Course Course { get; set; } = null!;
    public ICollection<CourseLesson> Lessons { get; set; } = new List<CourseLesson>();
}
