using SKVI.Application.DTOs.Articles;
using SKVI.Application.DTOs.Categories;
using SKVI.Application.DTOs.Courses;
using SKVI.Application.DTOs.Enrollment;
using SKVI.Application.DTOs.Testimonial;

namespace SKVI.Application.DTOs.Mobile;

public class MobileHomeFeedDto
{
    public List<CourseResponse> FeaturedCourses { get; set; } = new();
    public List<EnrollmentResponse> MyEnrollments { get; set; } = new();
    public List<CategoryDto> Categories { get; set; } = new();
    public List<ArticleListDto> RecentArticles { get; set; } = new();
    public List<TestimonialDto> Testimonials { get; set; } = new();
}

public class MobileLearningProgressDto
{
    public double OverallProgressPercent { get; set; } = 0;
    public int TotalMinutesLearned { get; set; } = 0;
    public int CompletedLessonsCount { get; set; } = 0;
    public int TotalEnrolledCoursesCount { get; set; } = 0;
    public int CurrentStreakDays { get; set; } = 0;
    public List<DailyStudyTimeDto> WeeklyStudyStats { get; set; } = new();
}

public class DailyStudyTimeDto
{
    public string DayOfWeek { get; set; } = string.Empty; // T2, T3, T4, T5, T6, T7, CN
    public int DayIndex { get; set; } = 0; // 0 for Mon ... 6 for Sun
    public int MinutesLearned { get; set; } = 0;
    public int GoalMinutes { get; set; } = 30;
    public bool IsToday { get; set; } = false;
}

public class MobileCourseDetailDto
{
    public CourseResponse Course { get; set; } = null!;
    public bool IsEnrolled { get; set; } = false;
    public double ProgressPercent { get; set; } = 0;
    public Guid? LastAccessedLessonPartId { get; set; }
    public List<Guid> CompletedLessonPartIds { get; set; } = new();
}

public class UserReminderDto
{
    public Guid Id { get; set; }
    public string ClientId { get; set; } = string.Empty;
    public string Type { get; set; } = "custom";
    public string Title { get; set; } = string.Empty;
    public string Message { get; set; } = string.Empty;
    public bool Enabled { get; set; } = true;
    public int StartTimeHour { get; set; } = 8;
    public int StartTimeMinute { get; set; } = 0;
    public int EndTimeHour { get; set; } = 21;
    public int EndTimeMinute { get; set; } = 0;
    public List<int> RepeatDays { get; set; } = new();
    public bool SoundEnabled { get; set; } = true;
    public bool VibrationEnabled { get; set; } = true;
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;
}

public class SyncRemindersRequestDto
{
    public List<UserReminderDto> Reminders { get; set; } = new();
}
