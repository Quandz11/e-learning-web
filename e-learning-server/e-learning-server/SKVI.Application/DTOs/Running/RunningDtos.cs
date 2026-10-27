using System.ComponentModel.DataAnnotations;

namespace SKVI.Application.DTOs.Running;

public class CreateRunningActivityRequest
{
    [Required]
    [Range(0.01, 500.0, ErrorMessage = "Quãng đường phải từ 0.01 km đến 500 km")]
    public decimal DistanceKm { get; set; }

    [Required]
    [Range(1, 86400, ErrorMessage = "Thời gian chạy phải từ 1 giây đến 24 giờ")]
    public int DurationSeconds { get; set; }

    public DateTime? ActivityDate { get; set; }

    [MaxLength(256)]
    public string? Title { get; set; }

    [MaxLength(1024)]
    public string? Notes { get; set; }

    [MaxLength(32)]
    public string TrackingMode { get; set; } = "GPS"; // "GPS" | "MANUAL"

    public int? EnergyEarned { get; set; }

    public Guid? LinkedGoalId { get; set; }
}

public class RunningActivityDto
{
    public Guid Id { get; set; }
    public Guid UserId { get; set; }
    public decimal DistanceKm { get; set; }
    public int DurationSeconds { get; set; }
    public decimal? PaceMinPerKm { get; set; }
    public string PaceFormatted { get; set; } = string.Empty;
    public int CaloriesBurned { get; set; }
    public DateTime ActivityDate { get; set; }
    public string Title { get; set; } = string.Empty;
    public string? Notes { get; set; }
    public string TrackingMode { get; set; } = "GPS";
    public int EnergyEarned { get; set; }
    public string? BadgesEarnedJson { get; set; }
    public List<string> BadgesEarned { get; set; } = [];
    public Guid? LinkedGoalId { get; set; }
    public DateTime CreatedAt { get; set; }
}

public class RunningSummaryDto
{
    public decimal TotalDistanceKm { get; set; }
    public int TotalDurationSeconds { get; set; }
    public int TotalCalories { get; set; }
    public int TotalRunsCount { get; set; }
    public decimal WeekDistanceKm { get; set; }
    public decimal MonthDistanceKm { get; set; }
    public decimal? AveragePaceMinPerKm { get; set; }
    public string AveragePaceFormatted { get; set; } = string.Empty;
    public decimal LongestRunKm { get; set; }
    public int CurrentStreakDays { get; set; }
    public int TotalEnergyEarned { get; set; }
    public List<string> UnlockedBadges { get; set; } = [];
}

public class PaginatedRunningActivitiesDto
{
    public List<RunningActivityDto> Items { get; set; } = [];
    public int TotalCount { get; set; }
    public int Page { get; set; }
    public int PageSize { get; set; }
    public int TotalPages => (int)Math.Ceiling((double)TotalCount / (PageSize > 0 ? PageSize : 10));
}
