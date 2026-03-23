using System.ComponentModel.DataAnnotations;
using SKVI.Application.DTOs.Wellness;

namespace SKVI.Application.DTOs.Ai;

public class InitializeStudyPlanRequest
{
    [Required]
    public string Goal { get; set; } = string.Empty;

    [Required]
    public string CurrentKnowledge { get; set; } = string.Empty;

    public string Motivation { get; set; } = string.Empty;

    [Range(15, 240)]
    public int TimeBudgetMinutesPerDay { get; set; } = 45;

    public string PreferredStudyTime { get; set; } = string.Empty;

    public string Constraints { get; set; } = string.Empty;

    public Guid? PrimaryCourseId { get; set; }
}

public class SubmitStudyTaskResultRequest
{
    public bool IsCompleted { get; set; } = true;

    public string Feedback { get; set; } = string.Empty;

    [Range(0, 240)]
    public int? ActualMinutesSpent { get; set; }

    [Range(1, 5)]
    public int? DifficultyRating { get; set; }

    [Range(1, 5)]
    public int? ConfidenceRating { get; set; }

    public bool NeedsSupport { get; set; }
}

public class DailyStudyCheckInRequest
{
    [Range(1, 5)]
    public int MoodScore { get; set; }

    [Range(1, 5)]
    public int EnergyScore { get; set; }

    [Range(1, 5)]
    public int ConfidenceScore { get; set; }

    [Range(0, 240)]
    public int? ActualMinutesSpentToday { get; set; }

    [Range(15, 240)]
    public int MinutesAvailableTomorrow { get; set; } = 45;

    public string Notes { get; set; } = string.Empty;

    public bool NeedsSupport { get; set; }
}

public class UserStudyPlanDto
{
    public Guid Id { get; set; }
    public string Goal { get; set; } = string.Empty;
    public string CurrentKnowledgeLevel { get; set; } = string.Empty;
    public string Motivation { get; set; } = string.Empty;
    public int TimeBudgetMinutesPerDay { get; set; }
    public string PreferredStudyTime { get; set; } = string.Empty;
    public string Constraints { get; set; } = string.Empty;
    public Guid? PrimaryCourseId { get; set; }
    public string PrimaryCourseTitle { get; set; } = string.Empty;
    public int CurrentStreakDays { get; set; }
    public DateTime? LastCheckInDate { get; set; }
    public string LatestGuidanceMessage { get; set; } = string.Empty;
    public string Status { get; set; } = string.Empty;
    public int PlanVersion { get; set; }
    public DateTime CreatedAt { get; set; }
}

public class DailyStudyTaskDto
{
    public Guid Id { get; set; }
    public DateTime TaskDate { get; set; }
    public string Title { get; set; } = string.Empty;
    public string Content { get; set; } = string.Empty;
    public string TaskType { get; set; } = string.Empty;
    public int EstimatedMinutes { get; set; }
    public int SortOrder { get; set; }
    public string Status { get; set; } = string.Empty;
    public Guid? RelatedCourseId { get; set; }
    public string RelatedCourseTitle { get; set; } = string.Empty;
    public Guid? RelatedLessonPartId { get; set; }
    public string RelatedLessonTitle { get; set; } = string.Empty;
    public string ReflectionPrompt { get; set; } = string.Empty;
    public bool IsCompleted { get; set; }
    public string UserFeedback { get; set; } = string.Empty;
    public string AiAdvice { get; set; } = string.Empty;
    public int? ActualMinutesSpent { get; set; }
    public int? DifficultyRating { get; set; }
    public int? ConfidenceRating { get; set; }
    public bool NeedsSupport { get; set; }
    public DateTime? CompletedAt { get; set; }
}

public class DailyStudyCheckInDto
{
    public Guid Id { get; set; }
    public DateTime CheckInDate { get; set; }
    public int MoodScore { get; set; }
    public int EnergyScore { get; set; }
    public int ConfidenceScore { get; set; }
    public int? ActualMinutesSpentToday { get; set; }
    public int MinutesAvailableTomorrow { get; set; }
    public string Notes { get; set; } = string.Empty;
    public bool NeedsSupport { get; set; }
    public string CoachAdvice { get; set; } = string.Empty;
}

public class StudyPlanDashboardDto
{
    public UserStudyPlanDto? Plan { get; set; }
    public List<DailyStudyTaskDto> TodayTasks { get; set; } = [];
    public DailyStudyCheckInDto? LatestCheckIn { get; set; }
    public int OpenSupportAlerts { get; set; }
    public string GuidanceMessage { get; set; } = string.Empty;
}

public class AiCoachStatusDto
{
    public bool IsEnabled { get; set; }
    public WellnessAccessDto? Access { get; set; }
}
