using Microsoft.EntityFrameworkCore;
using SKVI.Application.DTOs.Running;
using SKVI.Application.Interfaces;
using SKVI.Domain.Entities;
using SKVI.Infrastructure;

namespace SKVI.Application.Services;

public class RunningService : IRunningService
{
    private readonly ApplicationDbContext _db;

    public RunningService(ApplicationDbContext db)
    {
        _db = db;
    }

    public async Task<RunningActivityDto> CreateActivityAsync(Guid userId, CreateRunningActivityRequest request, CancellationToken cancellationToken = default)
    {
        var distance = Math.Round(request.DistanceKm, 2);
        if (distance <= 0)
        {
            throw new ArgumentException("Quãng đường phải lớn hơn 0");
        }

        if (request.DurationSeconds <= 0)
        {
            throw new ArgumentException("Thời gian chạy phải lớn hơn 0");
        }

        // Calculate pace: minutes per km
        decimal? paceMinPerKm = null;
        if (distance > 0)
        {
            paceMinPerKm = Math.Round(((decimal)request.DurationSeconds / 60m) / distance, 2);
        }

        // Calculate calories: standard formula ~ 1.036 * weight (kg) * distance (km)
        // Check if user has weight in wellness logs or default to 65 kg
        var userWeight = await _db.WellnessDailyLogs
            .Where(l => l.Plan.UserId == userId && l.CurrentWeightKg.HasValue)
            .OrderByDescending(l => l.LogDate)
            .Select(l => l.CurrentWeightKg!.Value)
            .FirstOrDefaultAsync(cancellationToken);

        if (userWeight <= 0)
        {
            userWeight = 65m;
        }

        var calories = (int)Math.Round(userWeight * distance * 1.036m);
        if (calories <= 0) calories = (int)Math.Round(distance * 60m);

        var activityDate = request.ActivityDate ?? DateTime.UtcNow;

        var activity = new RunningActivity
        {
            Id = Guid.NewGuid(),
            UserId = userId,
            DistanceKm = distance,
            DurationSeconds = request.DurationSeconds,
            PaceMinPerKm = paceMinPerKm,
            CaloriesBurned = calories,
            ActivityDate = activityDate,
            Title = string.IsNullOrWhiteSpace(request.Title)
                ? (request.TrackingMode == "GPS" ? "Chạy bộ ngoài trời" : "Chạy bộ")
                : request.Title.Trim(),
            Notes = request.Notes?.Trim(),
            TrackingMode = string.IsNullOrWhiteSpace(request.TrackingMode) ? "GPS" : request.TrackingMode.Trim().ToUpperInvariant(),
            CreatedAt = DateTime.UtcNow
        };

        _db.RunningActivities.Add(activity);
        await _db.SaveChangesAsync(cancellationToken);

        return MapToDto(activity);
    }

    public async Task<PaginatedRunningActivitiesDto> GetActivitiesAsync(Guid userId, int page = 1, int pageSize = 20, int? month = null, int? year = null, CancellationToken cancellationToken = default)
    {
        if (page < 1) page = 1;
        if (pageSize < 1 || pageSize > 100) pageSize = 20;

        var query = _db.RunningActivities.AsNoTracking().Where(r => r.UserId == userId);

        if (year.HasValue)
        {
            query = query.Where(r => r.ActivityDate.Year == year.Value);
        }

        if (month.HasValue)
        {
            query = query.Where(r => r.ActivityDate.Month == month.Value);
        }

        var totalCount = await query.CountAsync(cancellationToken);

        var items = await query
            .OrderByDescending(r => r.ActivityDate)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync(cancellationToken);

        return new PaginatedRunningActivitiesDto
        {
            Items = items.Select(MapToDto).ToList(),
            TotalCount = totalCount,
            Page = page,
            PageSize = pageSize
        };
    }

    public async Task<RunningActivityDto?> GetActivityByIdAsync(Guid userId, Guid activityId, CancellationToken cancellationToken = default)
    {
        var activity = await _db.RunningActivities
            .AsNoTracking()
            .FirstOrDefaultAsync(r => r.Id == activityId && r.UserId == userId, cancellationToken);

        return activity == null ? null : MapToDto(activity);
    }

    public async Task<bool> DeleteActivityAsync(Guid userId, Guid activityId, CancellationToken cancellationToken = default)
    {
        var activity = await _db.RunningActivities
            .FirstOrDefaultAsync(r => r.Id == activityId && r.UserId == userId, cancellationToken);

        if (activity == null) return false;

        _db.RunningActivities.Remove(activity);
        await _db.SaveChangesAsync(cancellationToken);
        return true;
    }

    public async Task<RunningSummaryDto> GetSummaryAsync(Guid userId, CancellationToken cancellationToken = default)
    {
        var userRuns = _db.RunningActivities.AsNoTracking().Where(r => r.UserId == userId);

        var totalCount = await userRuns.CountAsync(cancellationToken);
        if (totalCount == 0)
        {
            return new RunningSummaryDto();
        }

        var totalDistance = await userRuns.SumAsync(r => r.DistanceKm, cancellationToken);
        var totalDuration = await userRuns.SumAsync(r => r.DurationSeconds, cancellationToken);
        var totalCalories = await userRuns.SumAsync(r => r.CaloriesBurned, cancellationToken);
        var longestRun = await userRuns.MaxAsync(r => (decimal?)r.DistanceKm, cancellationToken) ?? 0m;

        // Calculate this week's runs (Monday to Sunday)
        var now = DateTime.UtcNow;
        var diffToMonday = (7 + (int)now.DayOfWeek - (int)DayOfWeek.Monday) % 7;
        var startOfWeek = now.Date.AddDays(-diffToMonday);
        var startOfMonth = new DateTime(now.Year, now.Month, 1);

        var weekDistance = await userRuns
            .Where(r => r.ActivityDate >= startOfWeek)
            .SumAsync(r => (decimal?)r.DistanceKm, cancellationToken) ?? 0m;

        var monthDistance = await userRuns
            .Where(r => r.ActivityDate >= startOfMonth)
            .SumAsync(r => (decimal?)r.DistanceKm, cancellationToken) ?? 0m;

        // Average pace
        decimal? avgPace = null;
        string avgPaceFormatted = string.Empty;
        if (totalDistance > 0)
        {
            avgPace = Math.Round(((decimal)totalDuration / 60m) / totalDistance, 2);
            avgPaceFormatted = FormatPace(avgPace);
        }

        // Calculate streak (days with at least 1 run)
        var recentDates = await userRuns
            .Select(r => r.ActivityDate.Date)
            .Distinct()
            .OrderByDescending(d => d)
            .Take(60)
            .ToListAsync(cancellationToken);

        var streak = 0;
        var checkDate = now.Date;
        // If no run today, check if yesterday had run to continue streak
        if (!recentDates.Contains(checkDate))
        {
            checkDate = checkDate.AddDays(-1);
        }

        while (recentDates.Contains(checkDate))
        {
            streak++;
            checkDate = checkDate.AddDays(-1);
        }

        return new RunningSummaryDto
        {
            TotalDistanceKm = totalDistance,
            TotalDurationSeconds = totalDuration,
            TotalCalories = totalCalories,
            TotalRunsCount = totalCount,
            WeekDistanceKm = weekDistance,
            MonthDistanceKm = monthDistance,
            AveragePaceMinPerKm = avgPace,
            AveragePaceFormatted = avgPaceFormatted,
            LongestRunKm = longestRun,
            CurrentStreakDays = streak
        };
    }

    private static RunningActivityDto MapToDto(RunningActivity activity)
    {
        return new RunningActivityDto
        {
            Id = activity.Id,
            UserId = activity.UserId,
            DistanceKm = activity.DistanceKm,
            DurationSeconds = activity.DurationSeconds,
            PaceMinPerKm = activity.PaceMinPerKm,
            PaceFormatted = FormatPace(activity.PaceMinPerKm),
            CaloriesBurned = activity.CaloriesBurned,
            ActivityDate = activity.ActivityDate,
            Title = activity.Title,
            Notes = activity.Notes,
            TrackingMode = activity.TrackingMode,
            CreatedAt = activity.CreatedAt
        };
    }

    private static string FormatPace(decimal? paceMinPerKm)
    {
        if (!paceMinPerKm.HasValue || paceMinPerKm.Value <= 0 || paceMinPerKm.Value > 60)
        {
            return "--";
        }

        var minutes = (int)paceMinPerKm.Value;
        var seconds = (int)Math.Round((paceMinPerKm.Value - minutes) * 60m);
        if (seconds >= 60)
        {
            minutes++;
            seconds = 0;
        }

        return $"{minutes}'{seconds:D2}\"/km";
    }
}
