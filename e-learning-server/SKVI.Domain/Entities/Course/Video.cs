using SKVI.Domain.Common;

namespace SKVI.Domain.Entities.Course;

public class Video : BaseEntity
{
    public string BunnyLibraryId { get; set; } = string.Empty;
    public string BunnyVideoId { get; set; } = string.Empty;
    public int Duration { get; set; }
    
    // Navigation properties
    public ICollection<CourseLesson> Lessons { get; set; } = new List<CourseLesson>();
}
