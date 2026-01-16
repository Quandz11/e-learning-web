using SKVI.Domain.Common;
using SKVI.Domain.Entities.Course;

namespace SKVI.Domain.Entities.Enrollment;

public class LessonProgress : BaseEntity
{
    public Guid EnrollmentId { get; set; }
    public Guid LessonId { get; set; }
    public int WatchedSeconds { get; set; } = 0;
    public bool IsCompleted { get; set; } = false;
    
    // Navigation properties
    public Enrollment Enrollment { get; set; } = null!;
    public CourseLesson Lesson { get; set; } = null!;
}
