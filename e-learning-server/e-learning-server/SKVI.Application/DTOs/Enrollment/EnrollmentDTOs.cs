using System.ComponentModel.DataAnnotations;

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
    public string? CourseThumbnail { get; set; }
    public required DateTime EnrolledAt { get; set; }
    public int ProgressPercentage { get; set; }
    public DateTime? CompletedAt { get; set; }
    public DateTime LastAccessedAt { get; set; }
    public int? AccessDurationDays { get; set; }
    public DateTime? AccessExpiresAt { get; set; }
    public bool IsExpired { get; set; }
    public string Status { get; set; } = "ACTIVE";
}

public class AdminEnrollmentResponse
{
    public required string Id { get; set; }
    public required string CourseId { get; set; }
    public required string CourseTitle { get; set; }
    public string? CourseThumbnail { get; set; }
    public required string UserId { get; set; }
    public required string UserEmail { get; set; }
    public string? UserFullName { get; set; }
    public required DateTime EnrolledAt { get; set; }
    public int ProgressPercentage { get; set; }
    public DateTime? CompletedAt { get; set; }
    public DateTime LastAccessedAt { get; set; }
    public int? AccessDurationDays { get; set; }
    public DateTime? AccessExpiresAt { get; set; }
    public required string Status { get; set; }
}

public class AdminAddEnrollmentRequest
{
    public required string CourseId { get; set; }

    [Range(1, 3650)]
    public int? AccessDurationDays { get; set; }
}

public class AdminSetEnrollmentStatusRequest
{
    public required string Status { get; set; } // ACTIVE | INACTIVE
}

public class CourseProgressResponse
{
    public required string EnrollmentId { get; set; }
    public int ProgressPercentage { get; set; }
    public int CompletedParts { get; set; }
    public int TotalParts { get; set; }
    public DateTime? CompletedAt { get; set; }
    public int? AccessDurationDays { get; set; }
    public DateTime? AccessExpiresAt { get; set; }
    public bool IsExpired { get; set; }
    public List<LessonProgressDto> PartProgress { get; set; } = new();
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
    public int WatchedDuration { get; set; } // seconds
}

public class MarkCompleteRequest
{
    public required string LessonId { get; set; }
}
