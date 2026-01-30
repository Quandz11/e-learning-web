namespace SKVI.Application.DTOs.Courses;

public class CourseResponse
{
    public Guid Id { get; set; }
    public string Title { get; set; } = string.Empty;
    public string? Description { get; set; }
    public decimal Price { get; set; }
    public bool IsFree { get; set; }
    public Guid LecturerId { get; set; }
    public LecturerInfo? Lecturer { get; set; }
    public string? ThumbnailUrl { get; set; }
    public bool IsPublished { get; set; }
    public List<string> LearningOutcomes { get; set; } = new();
    public DateTime CreatedAt { get; set; }
    public List<CourseSectionResponse> Sections { get; set; } = new();
}

public class LecturerInfo
{
    public Guid Id { get; set; }
    public string FullName { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public string? AvatarUrl { get; set; }
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
    public string? EmbedUrl { get; set; }
    public Guid? DocumentId { get; set; }
    public string? DocumentUrl { get; set; }
    public string? DocumentFileName { get; set; }
}

public class StudentDto
{
    public Guid Id { get; set; }
    public string FullName { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public string? AvatarUrl { get; set; }
    public DateTime EnrolledAt { get; set; }
}
