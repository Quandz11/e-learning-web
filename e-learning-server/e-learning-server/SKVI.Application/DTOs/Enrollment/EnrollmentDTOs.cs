namespace SKVI.Application.DTOs.Enrollment;

public class EnrollmentRequest
{
    public required string CourseId { get; set; }
}

public class EnrollmentResponse
{
    public required string Id { get; set; }
    public required string CourseId { get; set; }
    public required string CourseTitle { get; set; }
    public required DateTime EnrolledAt { get; set; }
    public int ProgressPercentage { get; set; }
    public DateTime? CompletedAt { get; set; }
    public DateTime LastAccessedAt { get; set; }
}

public class CourseProgressResponse
{
    public required string EnrollmentId { get; set; }
    public int ProgressPercentage { get; set; }
    public int CompletedLessons { get; set; }
    public int TotalLessons { get; set; }
    public DateTime? CompletedAt { get; set; }
    public List<LessonProgressDto> LessonProgress { get; set; } = new();
}

public class LessonProgressDto
{
    public required string LessonPartId { get; set; }
    public required string LessonPartTitle { get; set; }
    public bool IsCompleted { get; set; }
    public int WatchedDuration { get; set; }
    public DateTime? CompletedAt { get; set; }
    public DateTime LastWatchedAt { get; set; }
}

public class UpdateProgressRequest
{
    public required string LessonId { get; set; }
    public required int WatchedDuration { get; set; } // seconds
}

public class MarkCompleteRequest
{
    public required string LessonId { get; set; }
}
