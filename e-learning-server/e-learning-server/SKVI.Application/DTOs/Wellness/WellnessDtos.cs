using System.ComponentModel.DataAnnotations;

namespace SKVI.Application.DTOs.Wellness;

public class UpsertWellnessPlanRequest
{
    [Required]
    [MaxLength(32)]
    public string PackageType { get; set; } = "TRIAL_3_DAYS";

    [Required]
    public DateTime StartDate { get; set; }

    public DateTime? EndDate { get; set; }

    [Range(12, 504)]
    public int FastingHours { get; set; } = 16;

    [Range(0, 12)]
    public int EatingHours { get; set; } = 8;

    [Range(0, 1439)]
    public int DailyFastStartMinuteOfDay { get; set; } = 20 * 60;

    [Range(30, 350)]
    public decimal StartWeightKg { get; set; }

    [Range(30, 350)]
    public decimal TargetWeightKg { get; set; }

    [MaxLength(64)]
    public string Timezone { get; set; } = "Asia/Ho_Chi_Minh";
}

public class UpdateWellnessScheduleRequest
{
    [Required]
    public DateTime StartDate { get; set; }

    [Required]
    public DateTime EndDate { get; set; }

    [Range(12, 504)]
    public int FastingHours { get; set; } = 16;

    [Range(0, 12)]
    public int EatingHours { get; set; } = 8;

    [Range(0, 1439)]
    public int DailyFastStartMinuteOfDay { get; set; } = 20 * 60;
}

public class UpsertWellnessDailyLogRequest
{
    [Required]
    public DateTime LogDate { get; set; }

    public DateTime? AteAtLocal { get; set; }

    [Range(0, 10000)]
    public int WaterMl { get; set; }

    [Range(0, 600)]
    public int WorkoutMinutes { get; set; }

    [MaxLength(128)]
    public string WorkoutType { get; set; } = string.Empty;

    [Range(30, 350)]
    public decimal? CurrentWeightKg { get; set; }

    [MaxLength(2048)]
    public string Notes { get; set; } = string.Empty;
}

public class WellnessCoachMoodRequest
{
    [Required]
    [MaxLength(32)]
    public string Mood { get; set; } = string.Empty;

    [Required]
    [MaxLength(32)]
    public string Energy { get; set; } = string.Empty;

    [Required]
    [MaxLength(32)]
    public string Hunger { get; set; } = string.Empty;

    [Required]
    [MaxLength(32)]
    public string Thirst { get; set; } = string.Empty;

    [MaxLength(32)]
    public string Stress { get; set; } = string.Empty;

    [Range(0, 24)]
    public int? SleepHours { get; set; }

    [MaxLength(2048)]
    public string Notes { get; set; } = string.Empty;
}

public class WellnessCoachMealRequest
{
    [Required]
    [MinLength(1)]
    [MaxLength(20)]
    public List<string> Ingredients { get; set; } = [];

    [Range(1, 12)]
    public int Servings { get; set; } = 1;

    [MaxLength(64)]
    public string Goal { get; set; } = "healthy";

    [MaxLength(64)]
    public string DietaryPreference { get; set; } = string.Empty;
}

public class WellnessResourceUpsertRequest
{
    [Required]
    [RegularExpression("^(MEDITATION|BREATHING|WORKOUT)$")]
    public string ResourceType { get; set; } = "MEDITATION";

    [Required]
    [MaxLength(256)]
    public string Title { get; set; } = string.Empty;

    [Required]
    [MaxLength(1024)]
    public string Url { get; set; } = string.Empty;

    [MaxLength(1024)]
    public string Description { get; set; } = string.Empty;

    public bool IsActive { get; set; } = true;

    [Range(1, 100)]
    public int RotationWeight { get; set; } = 1;
}

public class WellnessDashboardDto
{
    public WellnessPlanDto? Plan { get; set; }
    public WellnessDailyLogDto? TodayLog { get; set; }
    public WellnessFastingStatusDto? FastingStatus { get; set; }
    public WellnessResourceSetDto? TodayResources { get; set; }
    public WellnessInsightDto? TodayInsight { get; set; }
    public WellnessWeightProgressDto? WeightProgress { get; set; }
    public WellnessUpgradeSuggestionDto? UpgradeSuggestion { get; set; }
    public WellnessCheckoutConfigDto CheckoutConfig { get; set; } = new();
    public WellnessAccessDto Access { get; set; } = new();
}

public class WellnessAccessDto
{
    public bool IsUnlocked { get; set; }
    public string? CurrentPackage { get; set; }
    public List<string> AllowedPackages { get; set; } = [];
    public List<string> RequiredPackages { get; set; } = [];
    public string CtaPath { get; set; } = "/pricing";
    public string ReasonCode { get; set; } = string.Empty;
    public string Message { get; set; } = string.Empty;
}

public class WellnessAccessEvaluationDto
{
    public WellnessCheckoutConfigDto CheckoutConfig { get; set; } = new();
    public WellnessAccessDto Access { get; set; } = new();
}

public class WellnessPlanDto
{
    public Guid Id { get; set; }
    public string PackageType { get; set; } = string.Empty;
    public DateTime StartDate { get; set; }
    public DateTime EndDate { get; set; }
    public int FastingHours { get; set; }
    public int EatingHours { get; set; }
    public int DailyFastStartMinuteOfDay { get; set; }
    public string Timezone { get; set; } = string.Empty;
    public decimal StartWeightKg { get; set; }
    public decimal TargetWeightKg { get; set; }
    public decimal? LatestWeightKg { get; set; }
    public string Status { get; set; } = string.Empty;
    public int TotalDays { get; set; }
    public int ElapsedDays { get; set; }
    public int PreparationDays { get; set; }
    public int FastingDays { get; set; }
    public int RefeedDays { get; set; }
    public DateTime CreatedAt { get; set; }
}

public class WellnessDailyLogDto
{
    public Guid Id { get; set; }
    public DateTime LogDate { get; set; }
    public DateTime? AteAtLocal { get; set; }
    public int WaterMl { get; set; }
    public int WorkoutMinutes { get; set; }
    public string WorkoutType { get; set; } = string.Empty;
    public decimal? CurrentWeightKg { get; set; }
    public string Notes { get; set; } = string.Empty;
}

public class WellnessFastingStatusDto
{
    public string State { get; set; } = "FASTING";
    public DateTime WindowStartLocal { get; set; }
    public DateTime WindowEndLocal { get; set; }
    public DateTime CurrentTimeLocal { get; set; }
    public double ProgressPercent { get; set; }
    public int RemainingMinutes { get; set; }
    public string Label { get; set; } = string.Empty;
}

public class WellnessResourceItemDto
{
    public Guid Id { get; set; }
    public string ResourceType { get; set; } = string.Empty;
    public string Title { get; set; } = string.Empty;
    public string Url { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
}

public class WellnessResourceSetDto
{
    public WellnessResourceItemDto Meditation { get; set; } = new();
    public WellnessResourceItemDto Breathing { get; set; } = new();
    public WellnessResourceItemDto Workout { get; set; } = new();
    public string SelectionStrategy { get; set; } = "ROTATION";
}

public class WellnessInsightDto
{
    public Guid Id { get; set; }
    public DateTime InsightDate { get; set; }
    public string Summary { get; set; } = string.Empty;
    public string Tip { get; set; } = string.Empty;
    public string Risks { get; set; } = string.Empty;
    public string GeneratedBy { get; set; } = string.Empty;
}

public class WellnessCoachReplyDto
{
    public string Reply { get; set; } = string.Empty;
    public DateTime CreatedAt { get; set; }
}

public class WellnessMealSuggestionDto
{
    public string Ingredients { get; set; } = string.Empty;
    public int Servings { get; set; }
    public string Menu { get; set; } = string.Empty;
    public string NutritionNotes { get; set; } = string.Empty;
    public DateTime CreatedAt { get; set; }
}

public class WellnessWeightProgressDto
{
    public decimal StartWeightKg { get; set; }
    public decimal CurrentWeightKg { get; set; }
    public decimal TargetWeightKg { get; set; }
    public double ProgressPercent { get; set; }
}

public class WellnessProgressTimelineItemDto
{
    public DateTime LogDate { get; set; }
    public decimal? CurrentWeightKg { get; set; }
    public int WaterMl { get; set; }
    public int WorkoutMinutes { get; set; }
    public string WorkoutType { get; set; } = string.Empty;
    public bool HasCheckin { get; set; }
    public string Phase { get; set; } = string.Empty;
    public int PhaseDayIndex { get; set; }
    public int PhaseTotalDays { get; set; }
}

public class WellnessProgressTimelineDto
{
    public DateTime FromDate { get; set; }
    public DateTime ToDate { get; set; }
    public int RequestedDays { get; set; }
    public int LoggedDays { get; set; }
    public decimal? LatestWeightKg { get; set; }
    public int AverageWaterMl { get; set; }
    public int TotalWorkoutMinutes { get; set; }
    public List<WellnessProgressTimelineItemDto> Items { get; set; } = [];
}

public class WellnessUpgradeSuggestionDto
{
    public string Level { get; set; } = "NONE";
    public string Title { get; set; } = string.Empty;
    public string Message { get; set; } = string.Empty;
    public string SuggestedPackage { get; set; } = string.Empty;
    public string CtaPath { get; set; } = "/pricing";
}

public class WellnessCheckoutConfigDto
{
    public List<WellnessCheckoutPackageDto> Packages { get; set; } = [];
    public string CtaPath { get; set; } = "/pricing";
    public bool IsPersonalizedRoadmapPaid { get; set; }
}

public class WellnessCheckoutPackageDto
{
    public string Code { get; set; } = string.Empty;
    public string Name { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
    public decimal PriceVnd { get; set; }
    public int DurationDays { get; set; }
    public bool IsFeatured { get; set; }
    public int SortOrder { get; set; }
}

public class WellnessCalendarDayDto
{
    public DateTime Date { get; set; }
    public bool IsToday { get; set; }
    public bool IsInPlanRange { get; set; }
    public bool HasLog { get; set; }
}
