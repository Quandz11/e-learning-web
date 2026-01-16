using SKVI.Domain.Common;
using SKVI.Domain.Entities.Auth;

namespace SKVI.Domain.Entities.Enrollment;

public class Enrollment : BaseEntity
{
    public Guid StudentId { get; set; }
    public Guid CourseId { get; set; }
    public decimal Progress { get; set; } = 0;
    public DateTime EnrolledAt { get; set; }
    public DateTime? CompletedAt { get; set; }
    
    // Navigation properties
    public User Student { get; set; } = null!;
    public Course.Course Course { get; set; } = null!;
    public ICollection<LessonProgress> LessonProgresses { get; set; } = new List<LessonProgress>();
}
