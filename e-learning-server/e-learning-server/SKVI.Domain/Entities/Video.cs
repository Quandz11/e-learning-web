namespace SKVI.Domain.Entities;

public class Video
{
    public Guid Id { get; set; }
    public string? BunnyLibraryId { get; set; }
    public string? BunnyVideoId { get; set; }
    public int Duration { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    // Navigation properties
    public ICollection<CourseLesson> CourseLessons { get; set; } = new List<CourseLesson>();
}
