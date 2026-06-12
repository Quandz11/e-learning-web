using System.Net;
using System.Text.Json;
using Microsoft.Extensions.Caching.Memory;
using Microsoft.EntityFrameworkCore;
using SKVI.Application.DTOs.Wellness;
using SKVI.Application.Interfaces;
using SKVI.Application.Models;
using SKVI.Domain.Entities;
using SKVI.Infrastructure;

namespace SKVI.Application.Services;

public class WellnessService : IWellnessService
{
    private const int FixedMealServings = 1;
    private const string FixedMealGoal = "LOW_CARB_STANDARD";
    private const string FixedMealDietaryPreference = "LOW_CARB";

    private const string PlanStatusScheduled = "SCHEDULED";
    private const string PlanStatusActive = "ACTIVE";
    private const string PlanStatusCompleted = "COMPLETED";
    private const string PlanStatusArchived = "ARCHIVED";
    private static readonly TimeSpan DashboardCacheTtl = TimeSpan.FromSeconds(20);

    private static readonly Dictionary<string, string> TimezoneAliases = new(StringComparer.OrdinalIgnoreCase)
    {
        ["Asia/Ho_Chi_Minh"] = "SE Asia Standard Time",
        ["Asia/Bangkok"] = "SE Asia Standard Time",
        ["SE Asia Standard Time"] = "Asia/Ho_Chi_Minh"
    };

    private static readonly HashSet<string> AllowedResourceTypes =
    [
        "MEDITATION",
        "BREATHING",
        "WORKOUT"
    ];

    private static readonly IReadOnlyList<(string ResourceType, string Title, string Url, string Description, int Weight)> DefaultResources =
    [
        ("MEDITATION", "Meditation 10m - Breath Focus", "https://www.youtube.com/watch?v=inpok4MKVLM", "Guided meditation for breath focus and calm.", 2),
        ("MEDITATION", "Body Scan Meditation", "https://www.youtube.com/watch?v=ihO02wUzgkc", "Short body scan to release stress.", 1),
        ("MEDITATION", "Morning Mindfulness", "https://www.youtube.com/watch?v=ZToicYcHIOU", "Start the day with mindful awareness.", 1),
        ("BREATHING", "Box Breathing 4-4-4-4", "https://www.youtube.com/watch?v=FJJazKtH_9I", "Regulate stress with box breathing.", 2),
        ("BREATHING", "4-7-8 Breathing", "https://www.youtube.com/watch?v=YRPh_GaiL8s", "Nervous-system calming breathing pattern.", 2),
        ("BREATHING", "Coherent Breathing 5m", "https://www.youtube.com/watch?v=tybOi4hjZFQ", "Slow rhythmic breathing for focus.", 1),
        ("WORKOUT", "Low Impact HIIT 12m", "https://www.youtube.com/watch?v=ml6cT4AZdqI", "Quick full-body no-equipment session.", 2),
        ("WORKOUT", "Morning Mobility 10m", "https://www.youtube.com/watch?v=VaoV1PrYft4", "Joint mobility and activation routine.", 1),
        ("WORKOUT", "Core Strength 15m", "https://www.youtube.com/watch?v=AnYl6Nk9GOA", "Core workout suitable for home training.", 1)
    ];

    private readonly ApplicationDbContext _dbContext;
    private readonly IMemoryCache _memoryCache;
    private readonly IWellnessEncryptionService _encryptionService;
    private readonly IWellnessRateLimiter _rateLimiter;
    private readonly IWellnessAccessService _wellnessAccessService;
    private readonly IGeminiService _geminiService;
    private readonly ILogger<WellnessService> _logger;

    public WellnessService(
        ApplicationDbContext dbContext,
        IMemoryCache memoryCache,
        IWellnessEncryptionService encryptionService,
        IWellnessRateLimiter rateLimiter,
        IWellnessAccessService wellnessAccessService,
        IGeminiService geminiService,
        ILogger<WellnessService> logger)
    {
        _dbContext = dbContext;
        _memoryCache = memoryCache;
        _encryptionService = encryptionService;
        _rateLimiter = rateLimiter;
        _wellnessAccessService = wellnessAccessService;
        _geminiService = geminiService;
        _logger = logger;
    }

    public async Task<WellnessDashboardDto> GetDashboardAsync(Guid userId, CancellationToken cancellationToken = default)
    {
        var cacheKey = BuildDashboardCacheKey(userId);
        if (_memoryCache.TryGetValue<WellnessDashboardDto>(cacheKey, out var cached) && cached != null)
        {
            return cached;
        }

        var dashboard = await GetDashboardInternalAsync(userId, cancellationToken);
        _memoryCache.Set(cacheKey, dashboard, new MemoryCacheEntryOptions
        {
            AbsoluteExpirationRelativeToNow = DashboardCacheTtl
        });

        return dashboard;
    }

    private async Task<WellnessDashboardDto> GetDashboardInternalAsync(Guid userId, CancellationToken cancellationToken)
    {
        var plan = await _dbContext.WellnessPlans
            .Where(p => p.UserId == userId && p.Status != PlanStatusArchived)
            .OrderByDescending(p => p.UpdatedAt)
            .FirstOrDefaultAsync(cancellationToken);

        var accessEvaluation = await _wellnessAccessService.EvaluateAccessAsync(
            userId,
            null,
            cancellationToken);
        var access = accessEvaluation.Access;

        if (plan == null)
        {
            return new WellnessDashboardDto
            {
                CheckoutConfig = accessEvaluation.CheckoutConfig,
                Access = access
            };
        }

        var utcNow = DateTime.UtcNow;
        var localNow = ConvertUtcToLocal(utcNow, plan.Timezone);
        var localDate = localNow.Date;

        var statusChanged = RefreshPlanStatus(plan, utcNow, localDate);
        if (!access.IsUnlocked)
        {
            if (statusChanged)
            {
                await _dbContext.SaveChangesAsync(cancellationToken);
            }

            return new WellnessDashboardDto
            {
                Plan = MapPlan(plan, localDate),
                UpgradeSuggestion = BuildUpgradeSuggestion(plan, localDate, 0),
                CheckoutConfig = accessEvaluation.CheckoutConfig,
                Access = access
            };
        }

        await EnsureDefaultResourcePoolAsync(cancellationToken);
        var previousUpgradeLevel = plan.UpgradeSuggestionLevel;

        var todayLog = await _dbContext.WellnessDailyLogs
            .FirstOrDefaultAsync(l => l.PlanId == plan.Id && l.LogDate == localDate, cancellationToken);
        var todayResources = await GetOrCreateResourceSetAsync(plan, localDate, cancellationToken);
        var todayInsight = await GetOrCreateInsightAsync(plan, localDate, todayLog, cancellationToken);
        var todayTasks = await SyncAndGetTodayTasksAsync(plan, localDate, cancellationToken);
        var fastingStatus = BuildFastingStatus(plan, localNow);
        var weightProgress = BuildWeightProgress(plan, todayLog?.CurrentWeightKg);
        var upgradeSuggestion = BuildUpgradeSuggestion(plan, localDate, weightProgress.ProgressPercent);

        plan.UpgradeSuggestionLevel = upgradeSuggestion.Level;

        if (!string.Equals(previousUpgradeLevel, plan.UpgradeSuggestionLevel, StringComparison.Ordinal))
        {
            plan.UpdatedAt = utcNow;
        }

        if (statusChanged || !string.Equals(previousUpgradeLevel, plan.UpgradeSuggestionLevel, StringComparison.Ordinal))
        {
            await _dbContext.SaveChangesAsync(cancellationToken);
        }

        return new WellnessDashboardDto
        {
            Plan = MapPlan(plan, localDate),
            TodayLog = todayLog == null ? null : MapDailyLog(todayLog, plan.Timezone),
            FastingStatus = fastingStatus,
            TodayResources = todayResources,
            TodayInsight = todayInsight,
            TodayTasks = todayTasks,
            WeightProgress = weightProgress,
            UpgradeSuggestion = upgradeSuggestion,
            CheckoutConfig = accessEvaluation.CheckoutConfig,
            Access = access
        };
    }

    public async Task<WellnessPlanDto> UpsertPlanAsync(Guid userId, UpsertWellnessPlanRequest request, CancellationToken cancellationToken = default)
    {
        var packageType = NormalizePackageType(request.PackageType);
        var accessEvaluation = await _wellnessAccessService.EvaluateAccessAsync(userId, packageType, cancellationToken);
        if (!accessEvaluation.Access.IsUnlocked)
        {
            var code = string.IsNullOrWhiteSpace(accessEvaluation.Access.ReasonCode)
                ? "WELLNESS_PACKAGE_REQUIRED"
                : accessEvaluation.Access.ReasonCode;
            var message = string.IsNullOrWhiteSpace(accessEvaluation.Access.Message)
                ? "You need a wellness package to create this plan."
                : accessEvaluation.Access.Message;
            throw new WellnessAccessException(code, message);
        }

        var selectedPackage = accessEvaluation.CheckoutConfig.Packages
            .FirstOrDefault(p => string.Equals(p.Code, packageType, StringComparison.OrdinalIgnoreCase));
        
        // If free mode and no package found, default to a sensible duration
        if (selectedPackage == null && !accessEvaluation.CheckoutConfig.IsPersonalizedRoadmapPaid)
        {
            selectedPackage = accessEvaluation.CheckoutConfig.Packages.FirstOrDefault() 
                ?? new WellnessCheckoutPackageDto { Code = "FREE", DurationDays = 30 };
        }

        if (selectedPackage == null)
        {
            throw new InvalidOperationException("Selected package is not configured.");
        }

        ValidateFastingHours(request.FastingHours, request.EatingHours);

        var utcNow = DateTime.UtcNow;
        var timezone = NormalizeTimezone(request.Timezone);
        var startDate = request.StartDate.Date;
        var endDate = ResolvePlanEndDate(selectedPackage.DurationDays, startDate, request.EndDate?.Date);

        if (endDate < startDate)
        {
            throw new InvalidOperationException("End date must be after start date.");
        }
        WellnessPhasePlanner.ValidateScheduleDuration(startDate, endDate);
        var phaseBreakdown = WellnessPhasePlanner.BuildPhaseBreakdown(startDate, endDate);

        var activePlans = await _dbContext.WellnessPlans
            .Where(p => p.UserId == userId && (p.Status == PlanStatusActive || p.Status == PlanStatusScheduled))
            .OrderByDescending(p => p.UpdatedAt)
            .ToListAsync(cancellationToken);

        var plan = activePlans.FirstOrDefault();
        if (plan == null)
        {
            plan = new WellnessPlan
            {
                UserId = userId,
                CreatedAt = utcNow
            };
            _dbContext.WellnessPlans.Add(plan);
        }

        foreach (var sibling in activePlans.Where(p => p.Id != plan.Id))
        {
            sibling.Status = PlanStatusArchived;
            sibling.UpdatedAt = utcNow;
        }

        plan.PackageType = packageType;
        plan.StartDate = startDate;
        plan.EndDate = endDate;
        plan.FastingHours = request.FastingHours;
        plan.EatingHours = request.EatingHours;
        plan.DailyFastStartMinuteOfDay = request.DailyFastStartMinuteOfDay;
        plan.Timezone = timezone;
        plan.StartWeightKg = request.StartWeightKg;
        plan.TargetWeightKg = request.TargetWeightKg;
        plan.LatestWeightKg ??= request.StartWeightKg;
        plan.UpdatedAt = utcNow;

        var localNowDate = ConvertUtcToLocal(utcNow, timezone).Date;
        RefreshPlanStatus(plan, utcNow, localNowDate);

        await EnsureDefaultResourcePoolAsync(cancellationToken);

        await WriteAuditLogAsync(
            userId,
            "WELLNESS_PLAN_UPSERT",
            nameof(WellnessPlan),
            plan.Id,
            new
            {
                plan.PackageType,
                plan.StartDate,
                plan.EndDate,
                plan.FastingHours,
                plan.EatingHours,
                plan.DailyFastStartMinuteOfDay,
                plan.Timezone,
                plan.StartWeightKg,
                plan.TargetWeightKg,
                phaseBreakdown.PreparationDays,
                phaseBreakdown.FastingDays,
                phaseBreakdown.RefeedDays
            });

        await _dbContext.SaveChangesAsync(cancellationToken);
        InvalidateDashboardCache(userId);

        return MapPlan(plan, localNowDate);
    }

    public async Task<WellnessPlanDto> UpdateScheduleAsync(Guid userId, Guid planId, UpdateWellnessScheduleRequest request, CancellationToken cancellationToken = default)
    {
        ValidateFastingHours(request.FastingHours, request.EatingHours);

        var plan = await GetOwnedPlanAsync(userId, planId, cancellationToken);
        await EnsureAnyWellnessAccessAsync(userId, cancellationToken);
        var utcNow = DateTime.UtcNow;
        var nextStartDate = request.StartDate.Date;
        var nextEndDate = request.EndDate.Date;
        if (nextEndDate < nextStartDate)
        {
            throw new InvalidOperationException("Schedule is invalid.");
        }
        WellnessPhasePlanner.ValidateScheduleDuration(nextStartDate, nextEndDate);
        var phaseBreakdown = WellnessPhasePlanner.BuildPhaseBreakdown(nextStartDate, nextEndDate);

        plan.StartDate = nextStartDate;
        plan.EndDate = nextEndDate;
        plan.FastingHours = request.FastingHours;
        plan.EatingHours = request.EatingHours;
        plan.DailyFastStartMinuteOfDay = request.DailyFastStartMinuteOfDay;
        plan.UpdatedAt = utcNow;

        var localNowDate = ConvertUtcToLocal(utcNow, plan.Timezone).Date;
        RefreshPlanStatus(plan, utcNow, localNowDate);

        await WriteAuditLogAsync(
            userId,
            "WELLNESS_SCHEDULE_UPDATE",
            nameof(WellnessPlan),
            plan.Id,
            new
            {
                plan.StartDate,
                plan.EndDate,
                plan.FastingHours,
                plan.EatingHours,
                plan.DailyFastStartMinuteOfDay,
                phaseBreakdown.PreparationDays,
                phaseBreakdown.FastingDays,
                phaseBreakdown.RefeedDays
            });

        await _dbContext.SaveChangesAsync(cancellationToken);
        InvalidateDashboardCache(userId);
        return MapPlan(plan, localNowDate);
    }

    public async Task<WellnessDailyLogDto> UpsertDailyLogAsync(Guid userId, Guid planId, UpsertWellnessDailyLogRequest request, CancellationToken cancellationToken = default)
    {
        var plan = await GetOwnedPlanAsync(userId, planId, cancellationToken);
        await EnsureAnyWellnessAccessAsync(userId, cancellationToken);
        var localLogDate = request.LogDate.Date;

        if (localLogDate < plan.StartDate.Date || localLogDate > plan.EndDate.Date)
        {
            // Allowed - no longer throwing an error for logs outside range.
        }

        var log = await _dbContext.WellnessDailyLogs
            .FirstOrDefaultAsync(l => l.PlanId == plan.Id && l.LogDate == localLogDate, cancellationToken);

        var utcNow = DateTime.UtcNow;
        if (log == null)
        {
            log = new WellnessDailyLog
            {
                PlanId = plan.Id,
                LogDate = localLogDate
            };

            _dbContext.WellnessDailyLogs.Add(log);
        }

        log.AteAtUtc = request.AteAtLocal.HasValue
            ? ConvertLocalToUtc(request.AteAtLocal.Value, plan.Timezone)
            : null;
        log.WaterMl = request.WaterMl;
        log.WorkoutMinutes = request.WorkoutMinutes;
        log.WorkoutType = (request.WorkoutType ?? string.Empty).Trim();
        log.CurrentWeightKg = request.CurrentWeightKg;
        log.NotesEncrypted = _encryptionService.Encrypt((request.Notes ?? string.Empty).Trim());
        log.UpdatedAt = utcNow;

        if (request.CurrentWeightKg.HasValue)
        {
            plan.LatestWeightKg = request.CurrentWeightKg.Value;
        }

        plan.UpdatedAt = utcNow;

        await WriteAuditLogAsync(
            userId,
            "WELLNESS_DAILY_LOG_UPSERT",
            nameof(WellnessDailyLog),
            log.Id,
            new
            {
                log.LogDate,
                log.WaterMl,
                log.WorkoutMinutes,
                log.WorkoutType,
                log.CurrentWeightKg,
                HasAteTime = log.AteAtUtc.HasValue
            });

        await _dbContext.SaveChangesAsync(cancellationToken);
        InvalidateDashboardCache(userId);
        return MapDailyLog(log, plan.Timezone);
    }

    public async Task<List<WellnessCalendarDayDto>> GetCalendarAsync(Guid userId, Guid planId, CancellationToken cancellationToken = default)
    {
        var plan = await GetOwnedPlanAsync(userId, planId, cancellationToken);
        await EnsureAnyWellnessAccessAsync(userId, cancellationToken);
        var localToday = ConvertUtcToLocal(DateTime.UtcNow, plan.Timezone).Date;

        var loggedDates = await _dbContext.WellnessDailyLogs
            .Where(l => l.PlanId == plan.Id)
            .Select(l => l.LogDate)
            .ToListAsync(cancellationToken);

        var loggedSet = loggedDates
            .Select(d => d.Date)
            .ToHashSet();

        var days = new List<WellnessCalendarDayDto>();
        for (var date = plan.StartDate.Date; date <= plan.EndDate.Date; date = date.AddDays(1))
        {
            days.Add(new WellnessCalendarDayDto
            {
                Date = date,
                IsToday = date == localToday,
                IsInPlanRange = true,
                HasLog = loggedSet.Contains(date)
            });
        }

        return days;
    }

    public async Task<WellnessCoachReplyDto> AskMoodCoachAsync(Guid userId, Guid planId, WellnessCoachMoodRequest request, CancellationToken cancellationToken = default)
    {
        var plan = await GetOwnedPlanAsync(userId, planId, cancellationToken);
        await EnsureAnyWellnessAccessAsync(userId, cancellationToken);

        if (!_rateLimiter.TryConsume(userId, $"wellness:mood:{plan.Id:N}", 20, TimeSpan.FromHours(1), out var retryAfter))
        {
            var retryMinutes = Math.Max(1, (int)Math.Ceiling(retryAfter.TotalMinutes));
            throw new InvalidOperationException($"Too many mood requests. Retry after {retryMinutes} minutes.");
        }

        var localNow = ConvertUtcToLocal(DateTime.UtcNow, plan.Timezone);
        var userMessage = BuildMoodMessage(request, localNow);
        var fallback = BuildMoodFallback(request);
        var aiReply = await ExecuteAiPromptAsync(BuildMoodPrompt(plan, request, localNow), fallback);

        _dbContext.WellnessCoachMessages.Add(new WellnessCoachMessage
        {
            PlanId = plan.Id,
            Role = "USER",
            MessageType = "MOOD",
            ContentEncrypted = _encryptionService.Encrypt(userMessage),
            CreatedAt = DateTime.UtcNow
        });

        _dbContext.WellnessCoachMessages.Add(new WellnessCoachMessage
        {
            PlanId = plan.Id,
            Role = "MODEL",
            MessageType = "MOOD",
            ContentEncrypted = _encryptionService.Encrypt(aiReply),
            CreatedAt = DateTime.UtcNow
        });

        await WriteAuditLogAsync(
            userId,
            "WELLNESS_COACH_MOOD",
            nameof(WellnessPlan),
            plan.Id,
            new { request.Mood, request.Energy, request.Hunger, request.Thirst, request.Stress, request.SleepHours });

        await _dbContext.SaveChangesAsync(cancellationToken);
        InvalidateDashboardCache(userId);

        return new WellnessCoachReplyDto
        {
            Reply = aiReply,
            CreatedAt = DateTime.UtcNow
        };
    }

    public async Task<WellnessMealSuggestionDto> GenerateMealSuggestionAsync(Guid userId, Guid planId, WellnessCoachMealRequest request, CancellationToken cancellationToken = default)
    {
        var plan = await GetOwnedPlanAsync(userId, planId, cancellationToken);
        await EnsureAnyWellnessAccessAsync(userId, cancellationToken);

        if (!_rateLimiter.TryConsume(userId, $"wellness:meal:{plan.Id:N}", 10, TimeSpan.FromHours(1), out var retryAfter))
        {
            var retryMinutes = Math.Max(1, (int)Math.Ceiling(retryAfter.TotalMinutes));
            throw new InvalidOperationException($"Too many meal requests. Retry after {retryMinutes} minutes.");
        }

        var ingredients = request.Ingredients
            .Where(i => !string.IsNullOrWhiteSpace(i))
            .Select(i => i.Trim())
            .Distinct(StringComparer.OrdinalIgnoreCase)
            .Take(20)
            .ToList();

        if (ingredients.Count == 0)
        {
            throw new InvalidOperationException("At least one ingredient is required.");
        }

        var normalizedMealRequest = new WellnessCoachMealRequest
        {
            Ingredients = ingredients,
            Servings = FixedMealServings,
            Goal = FixedMealGoal,
            DietaryPreference = FixedMealDietaryPreference
        };

        var ingredientText = string.Join(", ", ingredients);
        var fallbackMenu = BuildMealFallback(ingredientText);
        var aiMenu = await ExecuteAiPromptAsync(BuildMealPrompt(plan, ingredientText, normalizedMealRequest), fallbackMenu);
        var nutritionNotes = BuildNutritionNotes();

        var suggestion = new WellnessMealSuggestion
        {
            PlanId = plan.Id,
            IngredientsEncrypted = _encryptionService.Encrypt(ingredientText),
            Servings = normalizedMealRequest.Servings,
            SuggestedMenuEncrypted = _encryptionService.Encrypt(aiMenu),
            NutritionNotesEncrypted = _encryptionService.Encrypt(nutritionNotes),
            CreatedAt = DateTime.UtcNow
        };

        _dbContext.WellnessMealSuggestions.Add(suggestion);

        await WriteAuditLogAsync(
            userId,
            "WELLNESS_MEAL_GENERATE",
            nameof(WellnessMealSuggestion),
            suggestion.Id,
            new
            {
                suggestion.Servings,
                DietaryPreference = FixedMealDietaryPreference,
                MealMode = FixedMealGoal,
                IngredientCount = ingredients.Count
            });

        await _dbContext.SaveChangesAsync(cancellationToken);
        InvalidateDashboardCache(userId);

        return new WellnessMealSuggestionDto
        {
            Ingredients = ingredientText,
            Servings = suggestion.Servings,
            Menu = aiMenu,
            NutritionNotes = nutritionNotes,
            CreatedAt = suggestion.CreatedAt
        };
    }

    public async Task<WellnessWeightProgressDto> GetWeightProgressAsync(Guid userId, Guid planId, CancellationToken cancellationToken = default)
    {
        var plan = await GetOwnedPlanAsync(userId, planId, cancellationToken);
        await EnsureAnyWellnessAccessAsync(userId, cancellationToken);
        return BuildWeightProgress(plan, plan.LatestWeightKg);
    }

    public async Task<WellnessDailyTaskDto> CompleteTaskAsync(Guid userId, Guid planId, Guid taskId, CancellationToken cancellationToken = default)
    {
        var plan = await GetOwnedPlanAsync(userId, planId, cancellationToken);
        await EnsureAnyWellnessAccessAsync(userId, cancellationToken);

        var task = await _dbContext.WellnessDailyTasks
            .Include(t => t.Lesson)
            .FirstOrDefaultAsync(t => t.Id == taskId && t.WellnessPlanId == planId, cancellationToken);

        if (task == null)
        {
            throw new InvalidOperationException("Task not found.");
        }

        task.IsCompleted = true;
        task.CompletedAt = DateTime.UtcNow;
        
        await WriteAuditLogAsync(
            userId,
            "WELLNESS_TASK_COMPLETE",
            nameof(WellnessDailyTask),
            task.Id,
            new { task.TaskDate, task.LessonId });

        await _dbContext.SaveChangesAsync(cancellationToken);
        InvalidateDashboardCache(userId);

        return new WellnessDailyTaskDto
        {
            Id = task.Id,
            TaskDate = task.TaskDate,
            LessonId = task.LessonId ?? Guid.Empty,
            LessonTitle = task.Lesson?.Title ?? string.Empty,
            Description = "Complete your roadmap lesson.",
            IsCompleted = task.IsCompleted,
            CompletedAt = task.CompletedAt,
            SortOrder = task.SortOrder
        };
    }

    public async Task<WellnessProgressTimelineDto> GetProgressTimelineAsync(
        Guid userId,
        Guid planId,
        int days = 30,
        bool includeFuture = false,
        CancellationToken cancellationToken = default)
    {
        var plan = await GetOwnedPlanAsync(userId, planId, cancellationToken);
        await EnsureAnyWellnessAccessAsync(userId, cancellationToken);

        var requestedDays = Math.Clamp(days, 7, 180);
        var localToday = ConvertUtcToLocal(DateTime.UtcNow, plan.Timezone).Date;
        DateTime fromDate;
        DateTime toDate;

        if (includeFuture)
        {
            fromDate = localToday;
            if (fromDate < plan.StartDate.Date)
            {
                fromDate = plan.StartDate.Date;
            }

            if (fromDate > plan.EndDate.Date)
            {
                fromDate = plan.EndDate.Date;
            }

            toDate = fromDate.AddDays(requestedDays - 1);
            if (toDate > plan.EndDate.Date)
            {
                toDate = plan.EndDate.Date;
            }
        }
        else
        {
            fromDate = localToday.AddDays(-(requestedDays - 1));
            if (fromDate < plan.StartDate.Date)
            {
                fromDate = plan.StartDate.Date;
            }

            toDate = localToday;
            if (toDate > plan.EndDate.Date)
            {
                toDate = plan.EndDate.Date;
            }
        }

        if (toDate < fromDate)
        {
            toDate = fromDate;
        }

        var logs = await _dbContext.WellnessDailyLogs
            .AsNoTracking()
            .Where(l => l.PlanId == plan.Id && l.LogDate >= fromDate && l.LogDate <= toDate)
            .OrderBy(l => l.LogDate)
            .ToListAsync(cancellationToken);
        var phaseBreakdown = WellnessPhasePlanner.BuildPhaseBreakdown(plan.StartDate.Date, plan.EndDate.Date);
        var logsByDate = logs
            .GroupBy(log => log.LogDate.Date)
            .ToDictionary(group => group.Key, group => group.OrderByDescending(log => log.UpdatedAt).First());

        var items = new List<WellnessProgressTimelineItemDto>();
        for (var date = fromDate; date <= toDate; date = date.AddDays(1))
        {
            logsByDate.TryGetValue(date, out var log);
            var hasCheckin = log != null && (
                log.WaterMl > 0
                || log.WorkoutMinutes > 0
                || log.CurrentWeightKg.HasValue
                || !string.IsNullOrWhiteSpace(log.WorkoutType));

            var phase = WellnessPhasePlanner.ResolvePhaseForDate(date, plan.StartDate.Date, phaseBreakdown);
            items.Add(new WellnessProgressTimelineItemDto
            {
                LogDate = date,
                CurrentWeightKg = log?.CurrentWeightKg,
                WaterMl = log?.WaterMl ?? 0,
                WorkoutMinutes = log?.WorkoutMinutes ?? 0,
                WorkoutType = log?.WorkoutType ?? string.Empty,
                HasCheckin = hasCheckin,
                Phase = phase.Phase,
                PhaseDayIndex = phase.DayIndex,
                PhaseTotalDays = phase.TotalDays
            });
        }

        var latestWeight = items
            .Where(i => i.CurrentWeightKg.HasValue)
            .Select(i => i.CurrentWeightKg)
            .LastOrDefault();
        var loggedItems = items.Where(i => i.HasCheckin).ToList();

        return new WellnessProgressTimelineDto
        {
            FromDate = fromDate,
            ToDate = toDate,
            RequestedDays = requestedDays,
            LoggedDays = loggedItems.Count,
            LatestWeightKg = latestWeight ?? plan.LatestWeightKg,
            AverageWaterMl = loggedItems.Count == 0 ? 0 : (int)Math.Round(loggedItems.Average(i => i.WaterMl)),
            TotalWorkoutMinutes = loggedItems.Sum(i => i.WorkoutMinutes),
            Items = items
        };
    }

    public async Task<List<WellnessResourceItemDto>> GetResourcesAsync(CancellationToken cancellationToken = default)
    {
        await EnsureDefaultResourcePoolAsync(cancellationToken);

        var resources = await _dbContext.WellnessResources
            .AsNoTracking()
            .OrderBy(r => r.ResourceType)
            .ThenByDescending(r => r.IsActive)
            .ThenBy(r => r.Title)
            .ToListAsync(cancellationToken);

        return resources.Select(MapResource).ToList();
    }

    public async Task<WellnessResourceItemDto> CreateResourceAsync(Guid actorUserId, WellnessResourceUpsertRequest request, CancellationToken cancellationToken = default)
    {
        var resourceType = NormalizeResourceType(request.ResourceType);
        var normalizedUrl = ValidateResourceUrl(request.Url);

        var resource = new WellnessResource
        {
            ResourceType = resourceType,
            Title = (request.Title ?? string.Empty).Trim(),
            Url = normalizedUrl,
            Description = (request.Description ?? string.Empty).Trim(),
            IsActive = request.IsActive,
            RotationWeight = Math.Clamp(request.RotationWeight, 1, 100),
            CreatedAt = DateTime.UtcNow,
            UpdatedAt = DateTime.UtcNow
        };

        _dbContext.WellnessResources.Add(resource);

        await WriteAuditLogAsync(
            actorUserId,
            "WELLNESS_RESOURCE_CREATE",
            nameof(WellnessResource),
            resource.Id,
            new { resource.ResourceType, resource.Title, resource.Url, resource.IsActive, resource.RotationWeight });

        await _dbContext.SaveChangesAsync(cancellationToken);
        return MapResource(resource);
    }

    public async Task<WellnessResourceItemDto> UpdateResourceAsync(Guid actorUserId, Guid resourceId, WellnessResourceUpsertRequest request, CancellationToken cancellationToken = default)
    {
        var resource = await _dbContext.WellnessResources
            .FirstOrDefaultAsync(r => r.Id == resourceId, cancellationToken)
            ?? throw new InvalidOperationException("Resource not found.");

        resource.ResourceType = NormalizeResourceType(request.ResourceType);
        resource.Title = (request.Title ?? string.Empty).Trim();
        resource.Url = ValidateResourceUrl(request.Url);
        resource.Description = (request.Description ?? string.Empty).Trim();
        resource.IsActive = request.IsActive;
        resource.RotationWeight = Math.Clamp(request.RotationWeight, 1, 100);
        resource.UpdatedAt = DateTime.UtcNow;

        await WriteAuditLogAsync(
            actorUserId,
            "WELLNESS_RESOURCE_UPDATE",
            nameof(WellnessResource),
            resource.Id,
            new { resource.ResourceType, resource.Title, resource.Url, resource.IsActive, resource.RotationWeight });

        await _dbContext.SaveChangesAsync(cancellationToken);
        return MapResource(resource);
    }

    private async Task<WellnessPlan> GetOwnedPlanAsync(Guid userId, Guid planId, CancellationToken cancellationToken)
    {
        var plan = await _dbContext.WellnessPlans
            .FirstOrDefaultAsync(p => p.Id == planId && p.UserId == userId, cancellationToken);

        if (plan == null)
        {
            throw new InvalidOperationException("Plan not found.");
        }

        return plan;
    }

    private async Task EnsureDefaultResourcePoolAsync(CancellationToken cancellationToken)
    {
        var activeCounts = await _dbContext.WellnessResources
            .Where(r => r.IsActive)
            .GroupBy(r => r.ResourceType)
            .Select(g => new { ResourceType = g.Key, Count = g.Count() })
            .ToListAsync(cancellationToken);

        var countMap = activeCounts.ToDictionary(k => k.ResourceType, v => v.Count, StringComparer.OrdinalIgnoreCase);
        var missingTypes = AllowedResourceTypes.Where(type => !countMap.TryGetValue(type, out var count) || count <= 0).ToList();
        if (missingTypes.Count == 0)
        {
            return;
        }

        foreach (var item in DefaultResources.Where(r => missingTypes.Contains(r.ResourceType, StringComparer.OrdinalIgnoreCase)))
        {
            _dbContext.WellnessResources.Add(new WellnessResource
            {
                ResourceType = item.ResourceType,
                Title = item.Title,
                Url = item.Url,
                Description = item.Description,
                IsActive = true,
                RotationWeight = item.Weight,
                CreatedAt = DateTime.UtcNow,
                UpdatedAt = DateTime.UtcNow
            });
        }
    }

    private async Task<WellnessResourceSetDto> GetOrCreateResourceSetAsync(WellnessPlan plan, DateTime assignmentDate, CancellationToken cancellationToken)
    {
        var assignment = await _dbContext.WellnessResourceAssignments
            .Include(a => a.MeditationResource)
            .Include(a => a.BreathingResource)
            .Include(a => a.WorkoutResource)
            .FirstOrDefaultAsync(a => a.PlanId == plan.Id && a.AssignmentDate == assignmentDate, cancellationToken);

        if (assignment != null)
        {
            return new WellnessResourceSetDto
            {
                Meditation = MapResource(assignment.MeditationResource),
                Breathing = MapResource(assignment.BreathingResource),
                Workout = MapResource(assignment.WorkoutResource),
                SelectionStrategy = assignment.SelectionStrategy
            };
        }

        var meditation = await PickResourceAsync(plan.Id, assignmentDate, "MEDITATION", cancellationToken);
        var breathing = await PickResourceAsync(plan.Id, assignmentDate, "BREATHING", cancellationToken);
        var workout = await PickResourceAsync(plan.Id, assignmentDate, "WORKOUT", cancellationToken);

        assignment = new WellnessResourceAssignment
        {
            PlanId = plan.Id,
            AssignmentDate = assignmentDate,
            MeditationResourceId = meditation.Id,
            BreathingResourceId = breathing.Id,
            WorkoutResourceId = workout.Id,
            SelectionStrategy = "ROTATION_RANDOM",
            CreatedAt = DateTime.UtcNow,
            MeditationResource = meditation,
            BreathingResource = breathing,
            WorkoutResource = workout
        };

        _dbContext.WellnessResourceAssignments.Add(assignment);

        return new WellnessResourceSetDto
        {
            Meditation = MapResource(meditation),
            Breathing = MapResource(breathing),
            Workout = MapResource(workout),
            SelectionStrategy = assignment.SelectionStrategy
        };
    }

    private async Task<WellnessResource> PickResourceAsync(Guid planId, DateTime assignmentDate, string resourceType, CancellationToken cancellationToken)
    {
        var resources = await _dbContext.WellnessResources
            .Where(r => r.IsActive && r.ResourceType == resourceType)
            .OrderByDescending(r => r.RotationWeight)
            .ThenBy(r => r.CreatedAt)
            .ToListAsync(cancellationToken);

        if (resources.Count == 0)
        {
            throw new InvalidOperationException($"No active resources configured for {resourceType}.");
        }

        var previousResourceId = resourceType switch
        {
            "MEDITATION" => await _dbContext.WellnessResourceAssignments.Where(a => a.PlanId == planId && a.AssignmentDate < assignmentDate).OrderByDescending(a => a.AssignmentDate).Select(a => a.MeditationResourceId).FirstOrDefaultAsync(cancellationToken),
            "BREATHING" => await _dbContext.WellnessResourceAssignments.Where(a => a.PlanId == planId && a.AssignmentDate < assignmentDate).OrderByDescending(a => a.AssignmentDate).Select(a => a.BreathingResourceId).FirstOrDefaultAsync(cancellationToken),
            _ => await _dbContext.WellnessResourceAssignments.Where(a => a.PlanId == planId && a.AssignmentDate < assignmentDate).OrderByDescending(a => a.AssignmentDate).Select(a => a.WorkoutResourceId).FirstOrDefaultAsync(cancellationToken)
        };

        if (previousResourceId != Guid.Empty && resources.Count > 1)
        {
            var previousIndex = resources.FindIndex(r => r.Id == previousResourceId);
            if (previousIndex >= 0)
            {
                var random = new Random(HashCode.Combine(planId, assignmentDate, resourceType));
                var step = random.Next(1, Math.Min(3, resources.Count));
                return resources[(previousIndex + step) % resources.Count];
            }
        }

        var totalWeight = resources.Sum(r => Math.Max(1, r.RotationWeight));
        var weightedRandom = new Random(HashCode.Combine("weighted", planId, assignmentDate, resourceType));
        var ticket = weightedRandom.Next(1, totalWeight + 1);
        var cumulative = 0;

        foreach (var resource in resources)
        {
            cumulative += Math.Max(1, resource.RotationWeight);
            if (ticket <= cumulative)
            {
                return resource;
            }
        }

        return resources[^1];
    }

    private async Task<WellnessInsightDto> GetOrCreateInsightAsync(
        WellnessPlan plan,
        DateTime insightDate,
        WellnessDailyLog? todayLog,
        CancellationToken cancellationToken)
    {
        var insight = await _dbContext.WellnessInsights
            .FirstOrDefaultAsync(i => i.PlanId == plan.Id && i.InsightDate == insightDate, cancellationToken);

        if (insight != null)
        {
            return MapInsight(insight);
        }

        var localNow = ConvertUtcToLocal(DateTime.UtcNow, plan.Timezone);
        var fasting = BuildFastingStatus(plan, localNow);
        var fallback = BuildFallbackInsight(todayLog, fasting);

        var aiRaw = await ExecuteAiPromptAsync(
            BuildInsightPrompt(plan, todayLog, fasting),
            fallback.Summary + Environment.NewLine + fallback.Risks + Environment.NewLine + fallback.Tip);

        var parsed = ParseInsight(aiRaw, fallback);

        insight = new WellnessInsight
        {
            PlanId = plan.Id,
            InsightDate = insightDate,
            SummaryEncrypted = _encryptionService.Encrypt(parsed.Summary),
            TipEncrypted = _encryptionService.Encrypt(parsed.Tip),
            RisksEncrypted = _encryptionService.Encrypt(parsed.Risks),
            GeneratedBy = parsed.GeneratedBy,
            CreatedAt = DateTime.UtcNow
        };

        _dbContext.WellnessInsights.Add(insight);
        plan.LastInsightAt = DateTime.UtcNow;

        return new WellnessInsightDto
        {
            Id = insight.Id,
            InsightDate = insight.InsightDate,
            Summary = parsed.Summary,
            Tip = parsed.Tip,
            Risks = parsed.Risks,
            GeneratedBy = parsed.GeneratedBy
        };
    }

    private async Task<string> ExecuteAiPromptAsync(string prompt, string fallback)
    {
        try
        {
            var response = await _geminiService.ChatAsync(prompt);
            if (string.IsNullOrWhiteSpace(response))
            {
                return fallback;
            }

            return response.Trim();
        }
        catch (Exception ex)
        {
            _logger.LogWarning(ex, "Wellness AI prompt failed, using fallback response.");
            return fallback;
        }
    }

    private static string BuildMoodPrompt(WellnessPlan plan, WellnessCoachMoodRequest request, DateTime localNow)
    {
        return string.Join(
            Environment.NewLine,
            [
                "You are a wellness fasting coach for Vietnamese users.",
                "Respond in concise Vietnamese, practical and empathetic, max 120 words.",
                "Output only final answer without markdown.",
                $"Plan package: {plan.PackageType}",
                $"Fasting/eating windows: {plan.FastingHours}/{plan.EatingHours}",
                $"Current local time: {localNow:yyyy-MM-dd HH:mm}",
                $"Mood={request.Mood}, Energy={request.Energy}, Hunger={request.Hunger}, Thirst={request.Thirst}, Stress={request.Stress}, SleepHours={request.SleepHours}",
                $"Notes: {request.Notes}",
                "Give: 1 encouragement sentence + 2 immediate actions + 1 warning sign to watch."
            ]);
    }

    private static string BuildMoodFallback(WellnessCoachMoodRequest request)
    {
        var action1 = "Uống 300-500ml nước ấm, đi bộ chậm 5 phút và thở chậm 4-4-6.";
        var action2 = "Nếu đói cao, dừng 10 phút để reset nhận thức trước khi quyết định ăn.";
        return $"Bạn đang ở trạng thái mood {request.Mood}, năng lượng {request.Energy}. {action1} {action2} Nếu mệt, giảm cường độ vận động hôm nay và ngủ sớm hơn.";
    }

    private static string BuildMealPrompt(WellnessPlan plan, string ingredients, WellnessCoachMealRequest request)
    {
        return string.Join(
            Environment.NewLine,
            [
                "You are a nutrition coach for intermittent fasting users.",
                "Respond in Vietnamese with full diacritics (Unicode), never remove accents.",
                "No markdown table. Keep under 180 words.",
                $"Plan package: {plan.PackageType}",
                $"Ingredients: {ingredients}",
                $"Servings: {request.Servings}",
                $"DietaryPreference: {request.DietaryPreference}",
                "Fixed nutrition mode: low-carb, ưu tiên đạm sạch, rau xanh, chất béo tốt; hạn chế tinh bột nhanh.",
                "Provide sections exactly: Món ăn đề xuất, Định lượng nguyên liệu, Cách chế biến nhanh, Ghi chú dinh dưỡng."
            ]);
    }

    private static string BuildMealFallback(string ingredients)
    {
        var servings = FixedMealServings;
        const string goal = "ít tinh bột cân bằng";
        const string dietaryPreference = "ít tinh bột";

        return
            $"Món ăn đề xuất: Bowl áp chảo với {ingredients}. " +
            $"Định lượng: chia cho {servings} khẩu phần, ưu tiên 1/2 rau xanh, 1/2 đạm sạch, thêm chất béo tốt vừa đủ và hạn chế tinh bột nhanh. " +
            $"Cách chế biến nhanh: hấp/luộc + áp chảo 10-12 phút, hạn chế chiên ngập dầu. " +
            $"Ghi chú: điều chỉnh gia vị nhẹ, ưu tiên {goal} theo chế độ {dietaryPreference}.";
    }

    private static string BuildNutritionNotes()
    {
        const string goal = "ít tinh bột cân bằng";
        const string dietaryPreference = "ít tinh bột";

        return $"Tập trung đủ đạm, đủ chất xơ và bù nước. Ưu tiên thực phẩm ít chế biến, hạn chế tinh bột nhanh và đường tinh luyện. Định hướng: {goal}, chế độ {dietaryPreference}.";
    }

    private static string BuildInsightPrompt(WellnessPlan plan, WellnessDailyLog? todayLog, WellnessFastingStatusDto fastingStatus)
    {
        return string.Join(
            Environment.NewLine,
            [
                "You are an intermittent fasting assistant.",
                "Return 3 lines exactly:",
                "Summary: ...",
                "Risks: ...",
                "Tip: ...",
                "Each line <= 120 chars in Vietnamese.",
                $"Plan: {plan.PackageType}, fasting/eating={plan.FastingHours}/{plan.EatingHours}",
                $"Today log: water={todayLog?.WaterMl ?? 0}, workout={todayLog?.WorkoutMinutes ?? 0}, workoutType={todayLog?.WorkoutType}, weight={todayLog?.CurrentWeightKg}",
                $"Fasting state={fastingStatus.State}, remainingMinutes={fastingStatus.RemainingMinutes}, progress={fastingStatus.ProgressPercent:F0}%"
            ]);
    }

    private static (string Summary, string Risks, string Tip) BuildFallbackInsight(WellnessDailyLog? todayLog, WellnessFastingStatusDto fasting)
    {
        var summary = todayLog == null
            ? "Hôm nay bạn chưa cập nhật log. Hãy bắt đầu bằng nước + trạng thái hiện tại."
            : $"Bạn đã cập nhật {todayLog.WaterMl}ml nước và {todayLog.WorkoutMinutes} phút tập luyện.";

        var risks = todayLog != null && todayLog.WaterMl < 1500
            ? "Nguy cơ thiếu nước, dễ mệt và khó tập trung vào cuối khung nhịn."
            : "Theo dõi tín hiệu mệt, choáng váng, hoa mắt nếu kéo dài khung nhịn.";

        var tip = fasting.State == "FASTING"
            ? "Còn đói thì dùng nhịp thở 4-4-6 trong 2 phút, uống nước ấm, đợi 10 phút rồi đánh giá lại."
            : "Đang trong khung ăn, ưu tiên đạm + rau trước, ăn chậm để không vượt mục tiêu.";

        return (summary, risks, tip);
    }

    private static (string Summary, string Risks, string Tip, string GeneratedBy) ParseInsight(string aiRaw, (string Summary, string Risks, string Tip) fallback)
    {
        if (string.IsNullOrWhiteSpace(aiRaw))
        {
            return (fallback.Summary, fallback.Risks, fallback.Tip, "SYSTEM");
        }

        var lines = aiRaw
            .Split(['\r', '\n'], StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries)
            .ToList();

        var summary = ExtractByPrefix(lines, "Summary:") ?? fallback.Summary;
        var risks = ExtractByPrefix(lines, "Risks:") ?? fallback.Risks;
        var tip = ExtractByPrefix(lines, "Tip:") ?? fallback.Tip;

        return (summary, risks, tip, "AI");
    }

    private static string? ExtractByPrefix(IEnumerable<string> lines, string prefix)
    {
        foreach (var line in lines)
        {
            if (line.StartsWith(prefix, StringComparison.OrdinalIgnoreCase))
            {
                return line[prefix.Length..].Trim();
            }
        }

        return null;
    }

    private WellnessFastingStatusDto BuildFastingStatus(WellnessPlan plan, DateTime localNow)
    {
        var cycleDurationHours = plan.FastingHours + plan.EatingHours;
        if (cycleDurationHours <= 0) cycleDurationHours = 24;

        var planStartLocal = plan.StartDate.Date.AddMinutes(plan.DailyFastStartMinuteOfDay);
        DateTime fastingStart;
        DateTime fastingEnd;

        if (localNow < planStartLocal)
        {
            fastingStart = planStartLocal;
            fastingEnd = planStartLocal.AddHours(plan.FastingHours);
        }
        else
        {
            var totalElapsedHours = (localNow - planStartLocal).TotalHours;
            var cycleIndex = (int)Math.Floor(totalElapsedHours / cycleDurationHours);
            fastingStart = planStartLocal.AddHours(cycleIndex * cycleDurationHours);
            fastingEnd = fastingStart.AddHours(plan.FastingHours);
        }

        var isFasting = localNow < fastingEnd;
        if (isFasting)
        {
            var elapsed = localNow - fastingStart;
            var duration = fastingEnd - fastingStart;
            var percent = duration.TotalSeconds <= 0
                ? 0
                : Math.Clamp(elapsed.TotalSeconds / duration.TotalSeconds * 100, 0, 100);
            var remaining = fastingEnd - localNow;

            return new WellnessFastingStatusDto
            {
                State = "FASTING",
                WindowStartLocal = fastingStart,
                WindowEndLocal = fastingEnd,
                CurrentTimeLocal = localNow,
                ProgressPercent = Math.Round(percent, 2),
                RemainingMinutes = Math.Max(0, (int)Math.Ceiling(remaining.TotalMinutes)),
                Label = "NHIN -> AN"
            };
        }

        var eatingStart = fastingEnd;
        var eatingEnd = eatingStart.AddHours(plan.EatingHours);
        var eatingElapsed = localNow - eatingStart;
        var eatingDuration = eatingEnd - eatingStart;
        var eatingPercent = eatingDuration.TotalSeconds <= 0
            ? 0
            : Math.Clamp(eatingElapsed.TotalSeconds / eatingDuration.TotalSeconds * 100, 0, 100);
        var eatingRemaining = eatingEnd - localNow;

        return new WellnessFastingStatusDto
        {
            State = "EATING",
            WindowStartLocal = eatingStart,
            WindowEndLocal = eatingEnd,
            CurrentTimeLocal = localNow,
            ProgressPercent = Math.Round(eatingPercent, 2),
            RemainingMinutes = Math.Max(0, (int)Math.Ceiling(eatingRemaining.TotalMinutes)),
            Label = "AN -> NHIN"
        };
    }

    private static WellnessWeightProgressDto BuildWeightProgress(WellnessPlan plan, decimal? latestWeight)
    {
        var current = latestWeight ?? plan.LatestWeightKg ?? plan.StartWeightKg;
        var start = plan.StartWeightKg;
        var target = plan.TargetWeightKg;

        double percent;
        if (start > target)
        {
            var total = (double)(start - target);
            var done = (double)(start - current);
            percent = total <= 0 ? 100 : Math.Clamp(done / total * 100, 0, 100);
        }
        else if (start < target)
        {
            var total = (double)(target - start);
            var done = (double)(current - start);
            percent = total <= 0 ? 100 : Math.Clamp(done / total * 100, 0, 100);
        }
        else
        {
            percent = 100;
        }

        return new WellnessWeightProgressDto
        {
            StartWeightKg = start,
            CurrentWeightKg = current,
            TargetWeightKg = target,
            ProgressPercent = Math.Round(percent, 2)
        };
    }

    private static WellnessUpgradeSuggestionDto BuildUpgradeSuggestion(WellnessPlan plan, DateTime localDate, double progressPercent)
    {
        var totalDays = Math.Max(1, (plan.EndDate.Date - plan.StartDate.Date).Days + 1);
        var daysLeft = Math.Max(0, (plan.EndDate.Date - localDate).Days + 1);

        if (totalDays <= 7)
        {
            return new WellnessUpgradeSuggestionDto
            {
                Level = "HIGH",
                Title = "Upgrade package",
                Message = "Your current package is short-term. Upgrade for longer tracking, coaching, and meal guidance.",
                SuggestedPackage = plan.PackageType,
                CtaPath = "/pricing"
            };
        }

        if (daysLeft <= Math.Max(3, totalDays / 5))
        {
            return new WellnessUpgradeSuggestionDto
            {
                Level = "MEDIUM",
                Title = "Renew package",
                Message = "Your plan is nearing the end. Renew to keep tracking momentum and avoid interruption.",
                SuggestedPackage = plan.PackageType,
                CtaPath = "/pricing"
            };
        }

        if (progressPercent < 35)
        {
            return new WellnessUpgradeSuggestionDto
            {
                Level = "MEDIUM",
                Title = "Need stronger guidance",
                Message = "Progress is below target. Consider upgrading for tighter daily coaching and meal optimization.",
                SuggestedPackage = plan.PackageType,
                CtaPath = "/pricing"
            };
        }

        return new WellnessUpgradeSuggestionDto
        {
            Level = "LOW",
            Title = "Optional upgrade",
            Message = "You are on track. Upgrade if you want extra content and advanced recommendations.",
            SuggestedPackage = plan.PackageType,
            CtaPath = "/pricing"
        };
    }

    private static WellnessPlanDto MapPlan(WellnessPlan plan, DateTime localDate)
    {
        var phaseBreakdown = WellnessPhasePlanner.BuildPhaseBreakdown(plan.StartDate.Date, plan.EndDate.Date);
        var totalDays = phaseBreakdown.TotalDays;
        var elapsed = Math.Clamp((localDate - plan.StartDate.Date).Days + 1, 0, totalDays);

        return new WellnessPlanDto
        {
            Id = plan.Id,
            PackageType = plan.PackageType,
            StartDate = plan.StartDate,
            EndDate = plan.EndDate,
            FastingHours = plan.FastingHours,
            EatingHours = plan.EatingHours,
            DailyFastStartMinuteOfDay = plan.DailyFastStartMinuteOfDay,
            Timezone = plan.Timezone,
            StartWeightKg = plan.StartWeightKg,
            TargetWeightKg = plan.TargetWeightKg,
            LatestWeightKg = plan.LatestWeightKg,
            Status = plan.Status,
            TotalDays = totalDays,
            ElapsedDays = elapsed,
            PreparationDays = phaseBreakdown.PreparationDays,
            FastingDays = phaseBreakdown.FastingDays,
            RefeedDays = phaseBreakdown.RefeedDays,
            CreatedAt = plan.CreatedAt
        };
    }

    private static string BuildDashboardCacheKey(Guid userId)
    {
        return $"wellness:dashboard:{userId:N}";
    }

    private async Task EnsureAnyWellnessAccessAsync(Guid userId, CancellationToken cancellationToken)
    {
        var evaluation = await _wellnessAccessService.EvaluateAccessAsync(userId, null, cancellationToken);
        if (evaluation.Access.IsUnlocked)
        {
            return;
        }

        var code = string.IsNullOrWhiteSpace(evaluation.Access.ReasonCode)
            ? "WELLNESS_PACKAGE_REQUIRED"
            : evaluation.Access.ReasonCode;
        var message = string.IsNullOrWhiteSpace(evaluation.Access.Message)
            ? "You need to purchase a wellness package to activate this feature."
            : evaluation.Access.Message;

        throw new WellnessAccessException(code, message);
    }

    private void InvalidateDashboardCache(Guid userId)
    {
        _memoryCache.Remove(BuildDashboardCacheKey(userId));
    }

    private WellnessDailyLogDto MapDailyLog(WellnessDailyLog log, string timezone)
    {
        return new WellnessDailyLogDto
        {
            Id = log.Id,
            LogDate = log.LogDate,
            AteAtLocal = log.AteAtUtc.HasValue ? ConvertUtcToLocal(log.AteAtUtc.Value, timezone) : null,
            WaterMl = log.WaterMl,
            WorkoutMinutes = log.WorkoutMinutes,
            WorkoutType = log.WorkoutType,
            CurrentWeightKg = log.CurrentWeightKg,
            Notes = _encryptionService.Decrypt(log.NotesEncrypted)
        };
    }

    private WellnessResourceItemDto MapResource(WellnessResource resource)
    {
        return new WellnessResourceItemDto
        {
            Id = resource.Id,
            ResourceType = resource.ResourceType,
            Title = resource.Title,
            Url = resource.Url,
            Description = resource.Description
        };
    }

    private WellnessInsightDto MapInsight(WellnessInsight insight)
    {
        return new WellnessInsightDto
        {
            Id = insight.Id,
            InsightDate = insight.InsightDate,
            Summary = _encryptionService.Decrypt(insight.SummaryEncrypted),
            Tip = _encryptionService.Decrypt(insight.TipEncrypted),
            Risks = _encryptionService.Decrypt(insight.RisksEncrypted),
            GeneratedBy = insight.GeneratedBy
        };
    }

    private static string BuildMoodMessage(WellnessCoachMoodRequest request, DateTime localNow)
    {
        return $"{localNow:yyyy-MM-dd HH:mm} | mood={request.Mood}; energy={request.Energy}; hunger={request.Hunger}; thirst={request.Thirst}; stress={request.Stress}; sleep={request.SleepHours}; notes={request.Notes}";
    }

    private static void ValidateFastingHours(int fastingHours, int eatingHours)
    {
        if (fastingHours < 0 || eatingHours < 0)
        {
            throw new InvalidOperationException("Hours must be non-negative.");
        }

        // Support up to 21 days (504 hours)
        if (fastingHours > 504)
        {
            throw new InvalidOperationException("Fasting hours cannot exceed 21 days.");
        }

        // Relax eating hours check: allow 0 for OMAD or extended fasts
        if (eatingHours > 12)
        {
            throw new InvalidOperationException("Eating window cannot exceed 12 hours.");
        }

        // For regular Intermittent Fasting (fasting < 24), we enforce the 24h cycle
        // If fasting is 24 or more, it's an extended fast and doesn't follow a daily cycle
        if (fastingHours < 24 && (fastingHours + eatingHours) != 24)
        {
            throw new InvalidOperationException("Standard intermittent fasting cycle must be exactly 24 hours.");
        }
    }

    private static string NormalizePackageType(string packageType)
    {
        var value = (packageType ?? string.Empty).Trim().ToUpperInvariant();
        if (string.IsNullOrWhiteSpace(value))
        {
            throw new InvalidOperationException("Package type is required.");
        }

        if (value.Length < 3 || value.Length > 32)
        {
            throw new InvalidOperationException("Package type is invalid.");
        }

        foreach (var character in value)
        {
            if (!char.IsLetterOrDigit(character) && character != '_')
            {
                throw new InvalidOperationException("Package type is invalid.");
            }
        }

        return value;
    }

    private static DateTime ResolvePlanEndDate(int packageDurationDays, DateTime startDate, DateTime? requestedEndDate)
    {
        var defaultDays = Math.Clamp(packageDurationDays, 1, 3650);
        var maxAllowedEndDate = startDate.AddDays(defaultDays - 1);

        if (!requestedEndDate.HasValue)
        {
            return maxAllowedEndDate;
        }

        var endDate = requestedEndDate.Value.Date;
        if (endDate < startDate)
        {
            throw new InvalidOperationException("End date must be after start date.");
        }

        return endDate <= maxAllowedEndDate ? endDate : maxAllowedEndDate;
    }

    private static string NormalizeTimezone(string timezone)
    {
        var candidate = string.IsNullOrWhiteSpace(timezone)
            ? "Asia/Ho_Chi_Minh"
            : timezone.Trim();

        if (TryResolveTimeZone(candidate, out _))
        {
            return candidate;
        }

        if (TimezoneAliases.TryGetValue(candidate, out var mapped) && TryResolveTimeZone(mapped, out _))
        {
            return mapped;
        }

        return "UTC";
    }

    private static bool TryResolveTimeZone(string timezone, out TimeZoneInfo zone)
    {
        try
        {
            zone = TimeZoneInfo.FindSystemTimeZoneById(timezone);
            return true;
        }
        catch
        {
            zone = TimeZoneInfo.Utc;
            return false;
        }
    }

    private static TimeZoneInfo ResolveTimezoneInfo(string timezone)
    {
        if (TryResolveTimeZone(timezone, out var zone))
        {
            return zone;
        }

        if (TimezoneAliases.TryGetValue(timezone, out var mapped) && TryResolveTimeZone(mapped, out zone))
        {
            return zone;
        }

        return TimeZoneInfo.Utc;
    }

    private static DateTime ConvertUtcToLocal(DateTime utcDateTime, string timezone)
    {
        var utc = DateTime.SpecifyKind(utcDateTime, DateTimeKind.Utc);
        return TimeZoneInfo.ConvertTimeFromUtc(utc, ResolveTimezoneInfo(timezone));
    }

    private static DateTime ConvertLocalToUtc(DateTime localDateTime, string timezone)
    {
        var unspecified = DateTime.SpecifyKind(localDateTime, DateTimeKind.Unspecified);
        return TimeZoneInfo.ConvertTimeToUtc(unspecified, ResolveTimezoneInfo(timezone));
    }

    private static bool RefreshPlanStatus(WellnessPlan plan, DateTime utcNow, DateTime localDate)
    {
        var nextStatus = localDate < plan.StartDate.Date
            ? PlanStatusScheduled
            : localDate > plan.EndDate.Date
                ? PlanStatusCompleted
                : PlanStatusActive;

        if (string.Equals(plan.Status, nextStatus, StringComparison.Ordinal))
        {
            return false;
        }

        plan.Status = nextStatus;
        plan.UpdatedAt = utcNow;
        return true;
    }

    private static string NormalizeResourceType(string resourceType)
    {
        var normalized = (resourceType ?? string.Empty).Trim().ToUpperInvariant();
        if (!AllowedResourceTypes.Contains(normalized))
        {
            throw new InvalidOperationException("Invalid resource type.");
        }

        return normalized;
    }

    private static string ValidateResourceUrl(string url)
    {
        if (!Uri.TryCreate(url, UriKind.Absolute, out var uri))
        {
            throw new InvalidOperationException("Resource URL is invalid.");
        }

        if (!string.Equals(uri.Scheme, Uri.UriSchemeHttps, StringComparison.OrdinalIgnoreCase))
        {
            throw new InvalidOperationException("Resource URL must use HTTPS.");
        }

        if (uri.IsLoopback || string.Equals(uri.Host, "localhost", StringComparison.OrdinalIgnoreCase))
        {
            throw new InvalidOperationException("Loopback URL is not allowed.");
        }

        if (IPAddress.TryParse(uri.Host, out var ipAddress) && IsPrivateIp(ipAddress))
        {
            throw new InvalidOperationException("Private network URL is not allowed.");
        }

        return uri.ToString();
    }

    private static bool IsPrivateIp(IPAddress ipAddress)
    {
        var bytes = ipAddress.MapToIPv4().GetAddressBytes();

        return bytes[0] == 10
               || bytes[0] == 127
               || (bytes[0] == 172 && bytes[1] >= 16 && bytes[1] <= 31)
               || (bytes[0] == 192 && bytes[1] == 168)
               || (bytes[0] == 169 && bytes[1] == 254)
               || bytes[0] == 0;
    }

    private async Task<List<WellnessDailyTaskDto>> SyncAndGetTodayTasksAsync(WellnessPlan plan, DateTime localDate, CancellationToken cancellationToken)
    {
        // Calculate day index relative to plan start date
        var dayIndex = (localDate - plan.StartDate.Date).Days + 1;
        if (dayIndex < 1)
        {
            return []; // Plan hasn't started yet
        }

        var todayTasks = await _dbContext.WellnessDailyTasks
            .Include(t => t.Lesson)
                .ThenInclude(l => l.CourseLessons)
            .Where(t => t.WellnessPlanId == plan.Id && t.TaskDate == localDate)
            .OrderBy(t => t.SortOrder)
            .ToListAsync(cancellationToken);

        // If tasks are already generated for today, return them
        if (todayTasks.Count > 0)
        {
            return todayTasks.Select(t => new WellnessDailyTaskDto
            {
                Id = t.Id,
                TaskDate = t.TaskDate,
                LessonId = t.LessonId ?? Guid.Empty,
                CourseId = t.Lesson?.CourseLessons.FirstOrDefault()?.CourseId,
                LessonTitle = t.Lesson?.Title ?? string.Empty,
                Description = "Complete your roadmap lesson.",
                IsCompleted = t.IsCompleted,
                CompletedAt = t.CompletedAt,
                SortOrder = t.SortOrder
            }).ToList();
        }

        // Fetch package lessons configured by admin for this specific day index
        var packageLessons = await _dbContext.WellnessPackageLessons
            .Where(l => l.WellnessPackage.Code == plan.PackageType && l.DayIndex == dayIndex)
            .Include(l => l.Lesson)
                .ThenInclude(l => l.CourseLessons)
            .OrderBy(l => l.SortOrder)
            .ToListAsync(cancellationToken);

        if (packageLessons.Count == 0)
        {
            return [];
        }

        var newTasks = new List<WellnessDailyTask>();
        foreach (var pkgLesson in packageLessons)
        {
            var task = new WellnessDailyTask
            {
                Id = Guid.NewGuid(),
                WellnessPlanId = plan.Id,
                LessonId = pkgLesson.LessonId,
                TaskDate = localDate,
                DayIndex = dayIndex,
                Title = pkgLesson.Lesson?.Title ?? "Bài học Wellness",
                SortOrder = pkgLesson.SortOrder,
                IsCompleted = false,
                CreatedAt = DateTime.UtcNow
            };
            newTasks.Add(task);
            _dbContext.WellnessDailyTasks.Add(task);
        }

        await _dbContext.SaveChangesAsync(cancellationToken);

        return newTasks.Select((t, i) => new WellnessDailyTaskDto
        {
            Id = t.Id,
            TaskDate = t.TaskDate,
            LessonId = t.LessonId ?? Guid.Empty,
            CourseId = packageLessons[i].Lesson?.CourseLessons.FirstOrDefault()?.CourseId,
            LessonTitle = packageLessons[i].Lesson?.Title ?? string.Empty,
            Description = "Complete your roadmap lesson.",
            IsCompleted = t.IsCompleted,
            CompletedAt = t.CompletedAt,
            SortOrder = t.SortOrder
        }).ToList();
    }

    private Task WriteAuditLogAsync(Guid userId, string action, string targetTable, Guid? targetId, object metadata)
    {
        _dbContext.AuditLogs.Add(new AuditLog
        {
            Id = Guid.NewGuid(),
            UserId = userId,
            Action = action,
            TargetTable = targetTable,
            TargetId = targetId,
            Metadata = JsonSerializer.Serialize(metadata),
            CreatedAt = DateTime.UtcNow
        });

        return Task.CompletedTask;
    }
}

