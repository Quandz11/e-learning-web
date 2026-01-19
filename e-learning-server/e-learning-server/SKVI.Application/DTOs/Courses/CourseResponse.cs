namespace SKVI.Application.DTOs.Courses;

public class CourseResponse
{
    public Guid Id { get; set; }
    public string Title { get; set; } = string.Empty;
    public string? Description { get; set; }
    public decimal Price { get; set; }
    public bool IsFree { get; set; }
    public Guid LecturerId { get; set; }
    public string? ThumbnailUrl { get; set; }
    public bool IsPublished { get; set; }
    public DateTime CreatedAt { get; set; }
    public List<CourseSectionResponse> Sections { get; set; } = new();
}

public class CourseSectionResponse
{
    public Guid Id { get; set; }
    public string Title { get; set; } = string.Empty;
    public int OrderIndex { get; set; }
    public List<CourseLessonResponse> Lessons { get; set; } = new();
}

public class CourseLessonResponse
{
    public Guid Id { get; set; }
    public string Title { get; set; } = string.Empty;
    public int Duration { get; set; }
    public Guid VideoId { get; set; }
    public int OrderIndex { get; set; }
    public bool IsPreview { get; set; }
    public string? PlaybackUrl { get; set; }
}
