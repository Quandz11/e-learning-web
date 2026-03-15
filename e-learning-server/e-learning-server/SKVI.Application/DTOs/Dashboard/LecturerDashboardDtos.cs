namespace SKVI.Application.DTOs.Dashboard;

public class LecturerDashboardStatsDto
{
    public int TotalCoursesTeaching { get; set; }
    public int TotalStudentsActive { get; set; }
    public decimal AverageCompletionRate { get; set; }  // percentage 0-100
    public decimal CourseRevenueThisMonth { get; set; }
    public decimal CompletionRateTrendPercentage { get; set; }  // vs last month
    public int UnreviewedQuizzes { get; set; }
}

public class LecturerCourseDto
{
    public Guid Id { get; set; }
    public string Title { get; set; } = string.Empty;
    public string? Description { get; set; }
    public int EnrolledStudents { get; set; }
    public decimal CompletionRate { get; set; }  // percentage
    public decimal Rating { get; set; }
    public decimal Revenue { get; set; }
    public bool IsPublished { get; set; }
    public DateTime CreatedAt { get; set; }
}

public class LecturerLessonDto
{
    public Guid Id { get; set; }
    public Guid CourseId { get; set; }
    public string Title { get; set; } = string.Empty;
    public int Order { get; set; }
    public bool IsPublished { get; set; }
    public int ViewCount { get; set; }
    public decimal EngagementRate { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime? UpcomingDate { get; set; }  // For future scheduled lessons
}

public class PendingQuizDto
{
    public Guid Id { get; set; }
    public Guid CourseId { get; set; }
    public string CourseName { get; set; } = string.Empty;
    public string QuizTitle { get; set; } = string.Empty;
    public int PendingSubmissions { get; set; }
    public int GradedSubmissions { get; set; }
    public DateTime CreatedAt { get; set; }
}

public class QuizSubmissionDto
{
    public string Id { get; set; } = string.Empty;
    public string StudentName { get; set; } = string.Empty;
    public string StudentEmail { get; set; } = string.Empty;
    public Guid CourseId { get; set; }
    public string CourseName { get; set; } = string.Empty;
    public string QuizTitle { get; set; } = string.Empty;
    public decimal? Score { get; set; }
    public string Status { get; set; } = string.Empty;  // Pending, Graded
    public DateTime SubmittedAt { get; set; }
}

public class StudentProgressDto
{
    public Guid StudentId { get; set; }
    public string Email { get; set; } = string.Empty;
    public string? FullName { get; set; }
    public List<CourseProgressDetailDto> CourseProgress { get; set; } = new();
}

public class CourseProgressDetailDto
{
    public Guid CourseId { get; set; }
    public string CourseName { get; set; } = string.Empty;
    public decimal CompletionPercentage { get; set; }
    public int LessonsCompleted { get; set; }
    public int TotalLessons { get; set; }
    public decimal? AverageQuizScore { get; set; }
    public DateTime EnrolledDate { get; set; }
    public DateTime? CompletedDate { get; set; }
}

public class LecturerAnalyticsDto
{
    public List<LessonEngagementDto> LessonEngagement { get; set; } = new();
    public List<DropoffPointDto> DropoffPoints { get; set; } = new();
    public decimal OverallEngagementRate { get; set; }
}

public class LessonEngagementDto
{
    public Guid LessonId { get; set; }
    public string LessonTitle { get; set; } = string.Empty;
    public int ViewCount { get; set; }
    public decimal EngagementRate { get; set; }  // percentage of students who completed
    public decimal AverageTimeSpent { get; set; }  // minutes
}

public class DropoffPointDto
{
    public Guid LessonId { get; set; }
    public string LessonTitle { get; set; } = string.Empty;
    public int DropoffCount { get; set; }
    public decimal DropoffRate { get; set; }  // percentage
}

public class LecturerMessageDto
{
    public string Id { get; set; } = string.Empty;
    public Guid StudentId { get; set; }
    public string StudentName { get; set; } = string.Empty;
    public string StudentEmail { get; set; } = string.Empty;
    public string Message { get; set; } = string.Empty;
    public DateTime CreatedAt { get; set; }
    public bool IsRead { get; set; }
}

public class GradeQuizSubmissionDto
{
    public decimal Score { get; set; }
    public string? Feedback { get; set; }
}

public class ZoomClassDto
{
    public string Id { get; set; } = string.Empty;
    public Guid CourseId { get; set; }
    public string CourseName { get; set; } = string.Empty;
    public DateTime ScheduledAt { get; set; }
    public string ZoomLink { get; set; } = string.Empty;
    public string? Topic { get; set; }
    public int ExpectedStudents { get; set; }
    public string Status { get; set; } = string.Empty;  // Scheduled, Ongoing, Completed
}
