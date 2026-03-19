using Microsoft.EntityFrameworkCore;
using SKVI.Application.DTOs.Ai;
using SKVI.Application.Interfaces;
using SKVI.Domain.Entities;
using SKVI.Infrastructure;

namespace SKVI.Application.Services
{
    public interface IStudyPlanService
    {
        Task<UserStudyPlanDto> InitializePlanAsync(Guid userId, InitializeStudyPlanRequest request);
        Task<UserStudyPlanDto?> GetActivePlanAsync(Guid userId);
        Task<StudyPlanDashboardDto?> GetDashboardAsync(Guid userId);
        Task<List<DailyStudyTaskDto>> GetTodayTasksAsync(Guid planId);
        Task<DailyStudyTaskDto> SubmitTaskResultAsync(Guid taskId, SubmitStudyTaskResultRequest request);
        Task<DailyStudyCheckInDto> SubmitDailyCheckInAsync(Guid userId, DailyStudyCheckInRequest request);
        Task<string> ChatDirectlyAsync(Guid userId, string prompt);
        Task<List<AiChatMessage>> GetChatHistoryAsync(Guid userId);
    }

    public class StudyPlanService : IStudyPlanService
    {
        private const string ActivePlanStatus = "ACTIVE";
        private const string CompletedPlanStatus = "COMPLETED";
        private const string PlannedTaskStatus = "PLANNED";
        private const string CompletedTaskStatus = "COMPLETED";
        private const string SkippedTaskStatus = "SKIPPED";

        private readonly ApplicationDbContext _dbContext;
        private readonly IGeminiService _geminiService;
        private readonly INotificationService _notificationService;
        private readonly ILessonProgressService _lessonProgressService;
        private readonly ILogger<StudyPlanService> _logger;

        public StudyPlanService(
            ApplicationDbContext dbContext,
            IGeminiService geminiService,
            INotificationService notificationService,
            ILessonProgressService lessonProgressService,
            ILogger<StudyPlanService> logger)
        {
            _dbContext = dbContext;
            _geminiService = geminiService;
            _notificationService = notificationService;
            _lessonProgressService = lessonProgressService;
            _logger = logger;
        }

        public async Task<UserStudyPlanDto> InitializePlanAsync(Guid userId, InitializeStudyPlanRequest request)
        {
            if (string.IsNullOrWhiteSpace(request.Goal))
            {
                throw new InvalidOperationException("Goal is required.");
            }

            if (string.IsNullOrWhiteSpace(request.CurrentKnowledge))
            {
                throw new InvalidOperationException("Current knowledge is required.");
            }

            var activePlans = await _dbContext.UserStudyPlans
                .Where(p => p.UserId == userId && (p.Status == ActivePlanStatus || p.Status == "Active"))
                .ToListAsync();

            foreach (var activePlan in activePlans)
            {
                activePlan.Status = CompletedPlanStatus;
            }

            Course? primaryCourse = null;
            if (request.PrimaryCourseId.HasValue)
            {
                primaryCourse = await _dbContext.Courses
                    .AsNoTracking()
                    .FirstOrDefaultAsync(c => c.Id == request.PrimaryCourseId.Value);
            }

            var newPlan = new UserStudyPlan
            {
                UserId = userId,
                Goal = request.Goal.Trim(),
                CurrentKnowledgeLevel = request.CurrentKnowledge.Trim(),
                Motivation = request.Motivation.Trim(),
                TimeBudgetMinutesPerDay = Math.Clamp(request.TimeBudgetMinutesPerDay, 15, 240),
                PreferredStudyTime = request.PreferredStudyTime.Trim(),
                Constraints = request.Constraints.Trim(),
                PrimaryCourseId = primaryCourse?.Id,
                Status = ActivePlanStatus,
                LatestGuidanceMessage = "Bắt đầu với nhịp độ vừa phải. Hoàn thành đúng các việc hôm nay trước khi tăng tải.",
                PlanVersion = 1
            };

            _dbContext.UserStudyPlans.Add(newPlan);

            var learningQueue = await BuildLearningQueueAsync(userId, newPlan.PrimaryCourseId, []);
            var initialTasks = BuildTasksForDates(newPlan, learningQueue, DateTime.UtcNow.Date, 3);

            foreach (var task in initialTasks)
            {
                _dbContext.DailyStudyTasks.Add(task);
            }

            newPlan.LatestGuidanceMessage = await GenerateCoachMessageAsync(
                newPlan,
                "Học viên vừa khởi tạo lộ trình cá nhân hóa.",
                "Tập trung hoàn thành các việc ưu tiên trong hôm nay, ghi lại điểm khó và giữ nhịp đều mỗi ngày.");

            _dbContext.AiChatMessages.Add(new AiChatMessage
            {
                UserId = userId,
                Role = "model",
                Content = newPlan.LatestGuidanceMessage
            });

            await _dbContext.SaveChangesAsync();

            newPlan.PrimaryCourse = primaryCourse;
            return MapPlan(newPlan);
        }

        public async Task<UserStudyPlanDto?> GetActivePlanAsync(Guid userId)
        {
            var plan = await GetActivePlanEntityAsync(userId);
            return plan == null ? null : MapPlan(plan);
        }

        public async Task<StudyPlanDashboardDto?> GetDashboardAsync(Guid userId)
        {
            var plan = await GetActivePlanEntityAsync(userId);
            if (plan == null)
            {
                return null;
            }

            await EnsureUpcomingTasksAsync(plan);
            var syncedWithCourseProgress = await SyncTasksFromCourseProgressAsync(plan);
            if (syncedWithCourseProgress)
            {
                plan.PlanVersion += 1;
            }

            var todayTasks = await GetTodayTaskEntitiesAsync(plan.Id);
            var latestCheckIn = await _dbContext.DailyStudyCheckIns
                .Where(c => c.PlanId == plan.Id)
                .OrderByDescending(c => c.CheckInDate)
                .ThenByDescending(c => c.CreatedAt)
                .FirstOrDefaultAsync();

            var openSupportAlerts = await _dbContext.StudentSupportAlerts
                .CountAsync(a => a.PlanId == plan.Id && a.Status == "OPEN");

            plan.CurrentStreakDays = await CalculateCurrentStreakAsync(plan.Id);
            await _dbContext.SaveChangesAsync();

            return new StudyPlanDashboardDto
            {
                Plan = MapPlan(plan),
                TodayTasks = todayTasks.Select(MapTask).ToList(),
                LatestCheckIn = latestCheckIn == null ? null : MapCheckIn(latestCheckIn),
                OpenSupportAlerts = openSupportAlerts,
                GuidanceMessage = latestCheckIn?.CoachAdvice
                    ?? todayTasks.FirstOrDefault(t => !string.IsNullOrWhiteSpace(t.AiAdvice))?.AiAdvice
                    ?? plan.LatestGuidanceMessage
            };
        }

        public async Task<List<DailyStudyTaskDto>> GetTodayTasksAsync(Guid planId)
        {
            var plan = await _dbContext.UserStudyPlans.FirstOrDefaultAsync(p => p.Id == planId);
            if (plan == null)
            {
                return [];
            }

            if (await SyncTasksFromCourseProgressAsync(plan))
            {
                await _dbContext.SaveChangesAsync();
            }

            var tasks = await GetTodayTaskEntitiesAsync(planId);
            return tasks.Select(MapTask).ToList();
        }

        public async Task<DailyStudyTaskDto> SubmitTaskResultAsync(Guid taskId, SubmitStudyTaskResultRequest request)
        {
            var task = await _dbContext.DailyStudyTasks
                .Include(t => t.Plan)
                    .ThenInclude(p => p.PrimaryCourse)
                .Include(t => t.RelatedCourse)
                .Include(t => t.RelatedLessonPart)
                    .ThenInclude(lp => lp!.Lesson)
                .FirstOrDefaultAsync(t => t.Id == taskId);

            if (task == null)
            {
                throw new InvalidOperationException("Task not found.");
            }

            task.IsCompleted = request.IsCompleted;
            task.Status = request.IsCompleted ? CompletedTaskStatus : SkippedTaskStatus;
            task.UserFeedback = request.Feedback?.Trim() ?? string.Empty;
            task.ActualMinutesSpent = request.ActualMinutesSpent;
            task.DifficultyRating = request.DifficultyRating;
            task.ConfidenceRating = request.ConfidenceRating;
            task.NeedsSupport = request.NeedsSupport;
            task.CompletedAt = request.IsCompleted ? DateTime.UtcNow : null;
            await SyncCourseProgressFromTaskAsync(task);

            var recentSummary = await BuildRecentTaskSummaryAsync(task.PlanId);
            var fallbackAdvice = request.IsCompleted
                ? "Bạn đang giữ nhịp tốt. Hãy chốt lại điều học được và chuyển sang việc tiếp theo."
                : "Không sao khi chưa xong. Hãy giảm tải, chia nhỏ việc học và nêu rõ điểm đang bị kẹt.";

            task.AiAdvice = await GenerateCoachMessageAsync(
                task.Plan,
                $"Học viên vừa cập nhật task '{task.Title}'. Kết quả: {(request.IsCompleted ? "hoàn thành" : "chưa hoàn thành")}. " +
                $"Feedback: {task.UserFeedback}. Difficulty: {task.DifficultyRating}. Confidence: {task.ConfidenceRating}. " +
                $"Tóm tắt gần đây: {recentSummary}",
                fallbackAdvice);

            task.Plan.LatestGuidanceMessage = task.AiAdvice;
            task.Plan.PlanVersion += 1;
            task.Plan.CurrentStreakDays = await CalculateCurrentStreakAsync(task.PlanId);

            var taskAlert = BuildTaskAlert(task);
            if (taskAlert != null)
            {
                await CreateSupportAlertAsync(task.Plan, taskAlert.Value.Severity, taskAlert.Value.Reason, "TASK_RESULT", task.Id, null);
            }

            await EnsureUpcomingTasksAsync(task.Plan);
            await _dbContext.SaveChangesAsync();

            return MapTask(task);
        }

        public async Task<DailyStudyCheckInDto> SubmitDailyCheckInAsync(Guid userId, DailyStudyCheckInRequest request)
        {
            var plan = await GetActivePlanEntityAsync(userId);
            if (plan == null)
            {
                throw new InvalidOperationException("No active study plan.");
            }

            var today = DateTime.UtcNow.Date;
            var checkIn = await _dbContext.DailyStudyCheckIns
                .FirstOrDefaultAsync(c => c.PlanId == plan.Id && c.CheckInDate == today);

            if (checkIn == null)
            {
                checkIn = new DailyStudyCheckIn
                {
                    PlanId = plan.Id,
                    CheckInDate = today
                };
                _dbContext.DailyStudyCheckIns.Add(checkIn);
            }

            checkIn.MoodScore = request.MoodScore;
            checkIn.EnergyScore = request.EnergyScore;
            checkIn.ConfidenceScore = request.ConfidenceScore;
            checkIn.ActualMinutesSpentToday = request.ActualMinutesSpentToday;
            checkIn.MinutesAvailableTomorrow = Math.Clamp(request.MinutesAvailableTomorrow, 15, 240);
            checkIn.Notes = request.Notes?.Trim() ?? string.Empty;
            checkIn.NeedsSupport = request.NeedsSupport;

            plan.TimeBudgetMinutesPerDay = checkIn.MinutesAvailableTomorrow;
            plan.LastCheckInDate = today;
            plan.PlanVersion += 1;

            var recentSummary = await BuildRecentTaskSummaryAsync(plan.Id);
            checkIn.CoachAdvice = await GenerateCoachMessageAsync(
                plan,
                $"Check-in cuối ngày của học viên. Mood={checkIn.MoodScore}, Energy={checkIn.EnergyScore}, Confidence={checkIn.ConfidenceScore}, " +
                $"ActualMinutes={checkIn.ActualMinutesSpentToday}, TomorrowBudget={checkIn.MinutesAvailableTomorrow}, Notes={checkIn.Notes}. " +
                $"Tóm tắt task: {recentSummary}",
                "Hãy giữ khối lượng vừa sức vào ngày mai, ưu tiên một việc quan trọng nhất trước rồi mới mở rộng.");

            plan.LatestGuidanceMessage = checkIn.CoachAdvice;
            plan.CurrentStreakDays = await CalculateCurrentStreakAsync(plan.Id);

            var checkInAlert = BuildCheckInAlert(checkIn);
            if (checkInAlert != null)
            {
                await CreateSupportAlertAsync(plan, checkInAlert.Value.Severity, checkInAlert.Value.Reason, "CHECK_IN", null, checkIn.Id);
            }

            await EnsureUpcomingTasksAsync(plan);
            await _dbContext.SaveChangesAsync();

            return MapCheckIn(checkIn);
        }

        public async Task<string> ChatDirectlyAsync(Guid userId, string prompt)
        {
            var userPrompt = prompt?.Trim();
            if (string.IsNullOrWhiteSpace(userPrompt))
            {
                throw new InvalidOperationException("Prompt is required.");
            }

            var plan = await GetActivePlanEntityAsync(userId);
            var contextSummary = plan == null
                ? "Học viên chưa có lộ trình cá nhân hóa."
                : $"Mục tiêu: {plan.Goal}. Nền tảng: {plan.CurrentKnowledgeLevel}. " +
                  $"Động lực: {plan.Motivation}. Hạn chế: {plan.Constraints}. " +
                  $"Khối lượng/ngày: {plan.TimeBudgetMinutesPerDay} phút. " +
                  $"Tóm tắt gần đây: {await BuildRecentTaskSummaryAsync(plan.Id)}";

            _dbContext.AiChatMessages.Add(new AiChatMessage
            {
                UserId = userId,
                Role = "user",
                Content = userPrompt
            });
            await _dbContext.SaveChangesAsync();

            var response = await GenerateCoachMessageAsync(
                plan,
                $"Tin nhắn từ học viên: {userPrompt}. Context: {contextSummary}",
                "Hãy tiếp tục theo đúng việc ưu tiên hôm nay. Nếu bị kẹt, hãy mô tả rõ phần đang chưa hiểu để mình gợi ý cụ thể hơn.");

            _dbContext.AiChatMessages.Add(new AiChatMessage
            {
                UserId = userId,
                Role = "model",
                Content = response
            });
            await _dbContext.SaveChangesAsync();

            return response;
        }

        public async Task<List<AiChatMessage>> GetChatHistoryAsync(Guid userId)
        {
            return await _dbContext.AiChatMessages
                .Where(m => m.UserId == userId)
                .OrderBy(m => m.CreatedAt)
                .ToListAsync();
        }

        private async Task<UserStudyPlan?> GetActivePlanEntityAsync(Guid userId)
        {
            return await _dbContext.UserStudyPlans
                .Include(p => p.PrimaryCourse)
                .FirstOrDefaultAsync(p => p.UserId == userId && (p.Status == ActivePlanStatus || p.Status == "Active"));
        }

        private async Task<List<DailyStudyTask>> GetTodayTaskEntitiesAsync(Guid planId)
        {
            var today = DateTime.UtcNow.Date;
            return await _dbContext.DailyStudyTasks
                .Where(t => t.PlanId == planId && t.TaskDate.Date <= today)
                .Include(t => t.RelatedCourse)
                .Include(t => t.RelatedLessonPart)
                    .ThenInclude(lp => lp!.Lesson)
                .OrderBy(t => t.TaskDate)
                .ThenBy(t => t.IsCompleted)
                .ThenBy(t => t.SortOrder)
                .ToListAsync();
        }

        private async Task<bool> SyncTasksFromCourseProgressAsync(UserStudyPlan plan)
        {
            var completedLessonParts = await _dbContext.LessonProgresses
                .Where(lp => lp.IsCompleted && lp.Enrollment.UserId == plan.UserId)
                .Select(lp => new { lp.LessonPartId, lp.CompletedAt })
                .ToListAsync();

            if (completedLessonParts.Count == 0)
            {
                return false;
            }

            var completedByPartId = completedLessonParts
                .GroupBy(lp => lp.LessonPartId)
                .ToDictionary(
                    group => group.Key,
                    group => group
                        .OrderByDescending(item => item.CompletedAt ?? DateTime.MinValue)
                        .Select(item => item.CompletedAt)
                        .FirstOrDefault());

            var tasksToSync = await _dbContext.DailyStudyTasks
                .Where(t => t.PlanId == plan.Id && t.RelatedLessonPartId.HasValue && !t.IsCompleted)
                .ToListAsync();

            var changed = false;
            foreach (var task in tasksToSync)
            {
                var lessonPartId = task.RelatedLessonPartId!.Value;
                if (!completedByPartId.TryGetValue(lessonPartId, out var completedAt))
                {
                    continue;
                }

                task.IsCompleted = true;
                task.Status = CompletedTaskStatus;
                task.CompletedAt ??= completedAt ?? DateTime.UtcNow;
                task.ActualMinutesSpent ??= task.EstimatedMinutes;
                changed = true;
            }

            return changed;
        }

        private async Task SyncCourseProgressFromTaskAsync(DailyStudyTask task)
        {
            if (!task.IsCompleted || !task.RelatedCourseId.HasValue || !task.RelatedLessonPartId.HasValue)
            {
                return;
            }

            try
            {
                await _lessonProgressService.MarkLessonCompleteAsync(
                    task.Plan.UserId,
                    task.RelatedCourseId.Value,
                    task.RelatedLessonPartId.Value);
            }
            catch (Exception ex)
            {
                _logger.LogWarning(
                    ex,
                    "Failed to sync lesson progress from study task. TaskId={TaskId}, UserId={UserId}, CourseId={CourseId}, LessonPartId={LessonPartId}",
                    task.Id,
                    task.Plan.UserId,
                    task.RelatedCourseId,
                    task.RelatedLessonPartId);
            }
        }

        private async Task EnsureUpcomingTasksAsync(UserStudyPlan plan)
        {
            var today = DateTime.UtcNow.Date;
            var plannedFutureDates = await _dbContext.DailyStudyTasks
                .Where(t => t.PlanId == plan.Id && t.TaskDate.Date > today && t.Status == PlannedTaskStatus)
                .Select(t => t.TaskDate.Date)
                .Distinct()
                .OrderBy(d => d)
                .ToListAsync();

            if (plannedFutureDates.Count >= 2)
            {
                return;
            }

            var assignedPartIds = await _dbContext.DailyStudyTasks
                .Where(t => t.PlanId == plan.Id && t.RelatedLessonPartId.HasValue && t.Status != SkippedTaskStatus)
                .Select(t => t.RelatedLessonPartId!.Value)
                .ToListAsync();

            var learningQueue = await BuildLearningQueueAsync(plan.UserId, plan.PrimaryCourseId, assignedPartIds);
            var startDate = plannedFutureDates.Count == 0
                ? today.AddDays(1)
                : plannedFutureDates[^1].AddDays(1);
            var generatedTasks = BuildTasksForDates(plan, learningQueue, startDate, Math.Max(1, 2 - plannedFutureDates.Count));

            foreach (var task in generatedTasks)
            {
                _dbContext.DailyStudyTasks.Add(task);
            }
        }

        private async Task<List<LearningQueueItem>> BuildLearningQueueAsync(Guid userId, Guid? primaryCourseId, IReadOnlyCollection<Guid> excludedLessonPartIds)
        {
            var now = DateTime.UtcNow;
            var enrollments = await _dbContext.Enrollments
                .Where(e => e.UserId == userId &&
                    e.Status == "ACTIVE" &&
                    (e.AccessExpiresAt == null || e.AccessExpiresAt > now))
                .Include(e => e.Course)
                    .ThenInclude(c => c.CourseLessons)
                        .ThenInclude(cl => cl.Lesson)
                            .ThenInclude(l => l.LessonParts)
                .Include(e => e.LessonProgress)
                .ToListAsync();

            var queue = new List<LearningQueueItem>();
            foreach (var enrollment in enrollments
                .OrderBy(e => primaryCourseId.HasValue && e.CourseId == primaryCourseId.Value ? 0 : 1)
                .ThenByDescending(e => e.LastAccessedAt))
            {
                var completedPartIds = enrollment.LessonProgress
                    .Where(lp => lp.IsCompleted)
                    .Select(lp => lp.LessonPartId)
                    .ToHashSet();

                foreach (var courseLesson in enrollment.Course.CourseLessons.OrderBy(cl => cl.OrderIndex))
                {
                    foreach (var lessonPart in courseLesson.Lesson.LessonParts.OrderBy(lp => lp.OrderIndex))
                    {
                        if (completedPartIds.Contains(lessonPart.Id) || excludedLessonPartIds.Contains(lessonPart.Id))
                        {
                            continue;
                        }

                        queue.Add(new LearningQueueItem(
                            enrollment.CourseId,
                            enrollment.Course.Title,
                            lessonPart.Id,
                            courseLesson.Lesson.Title,
                            lessonPart.Title,
                            NormalizeTaskType(lessonPart.Type),
                            EstimateMinutes(lessonPart.Type)));
                    }
                }
            }

            return queue;
        }

        private List<DailyStudyTask> BuildTasksForDates(UserStudyPlan plan, List<LearningQueueItem> learningQueue, DateTime startDate, int dayCount)
        {
            var tasks = new List<DailyStudyTask>();
            var queueIndex = 0;

            for (var dayOffset = 0; dayOffset < dayCount; dayOffset++)
            {
                var targetDate = startDate.AddDays(dayOffset).Date;
                var remainingBudget = Math.Max(15, plan.TimeBudgetMinutesPerDay);
                var sortOrder = 1;

                while (queueIndex < learningQueue.Count)
                {
                    var item = learningQueue[queueIndex];
                    var estimated = Math.Min(Math.Max(item.EstimatedMinutes, 10), Math.Max(remainingBudget, 10));

                    if (sortOrder > 1 && remainingBudget < 15)
                    {
                        break;
                    }

                    if (sortOrder > 1 && estimated > remainingBudget)
                    {
                        break;
                    }

                    tasks.Add(new DailyStudyTask
                    {
                        PlanId = plan.Id,
                        TaskDate = targetDate,
                        Title = $"{item.CourseTitle}: {item.PartTitle}",
                        Content = $"Hoàn thành phần \"{item.PartTitle}\" trong bài \"{item.LessonTitle}\" của khóa \"{item.CourseTitle}\". " +
                                  "Tóm tắt lại 2 ý chính và ghi chú điều bạn còn vướng.",
                        TaskType = item.TaskType,
                        EstimatedMinutes = estimated,
                        SortOrder = sortOrder++,
                        Status = PlannedTaskStatus,
                        RelatedCourseId = item.CourseId,
                        RelatedLessonPartId = item.LessonPartId,
                        ReflectionPrompt = $"Sau khi học xong, hãy tự trả lời: phần nào của \"{item.PartTitle}\" bạn hiểu chắc nhất và phần nào cần hỗ trợ thêm?"
                    });

                    remainingBudget -= estimated;
                    queueIndex++;

                    if (remainingBudget < 15)
                    {
                        break;
                    }
                }

                if (!tasks.Any(t => t.TaskDate == targetDate))
                {
                    tasks.Add(CreateFallbackTask(plan, targetDate, sortOrder));
                }
            }

            return tasks;
        }

        private static DailyStudyTask CreateFallbackTask(UserStudyPlan plan, DateTime targetDate, int sortOrder)
        {
            return new DailyStudyTask
            {
                PlanId = plan.Id,
                TaskDate = targetDate,
                Title = "Phiên học trọng tâm cá nhân",
                Content = $"Dành {plan.TimeBudgetMinutesPerDay} phút để ôn lại mục tiêu \"{plan.Goal}\" và viết ra 3 điều bạn đã hiểu thêm từ kiến thức hiện có: {plan.CurrentKnowledgeLevel}.",
                TaskType = "REFLECTION",
                EstimatedMinutes = plan.TimeBudgetMinutesPerDay,
                SortOrder = sortOrder,
                Status = PlannedTaskStatus,
                ReflectionPrompt = "Bạn đang tiến gần mục tiêu ở điểm nào và cần hỗ trợ ở điểm nào?"
            };
        }

        private async Task<string> BuildRecentTaskSummaryAsync(Guid planId)
        {
            var recentTasks = await _dbContext.DailyStudyTasks
                .Where(t => t.PlanId == planId)
                .OrderByDescending(t => t.TaskDate)
                .ThenByDescending(t => t.CreatedAt)
                .Take(5)
                .Select(t => new
                {
                    t.Title,
                    t.Status,
                    t.UserFeedback,
                    t.DifficultyRating,
                    t.ConfidenceRating
                })
                .ToListAsync();

            if (recentTasks.Count == 0)
            {
                return "Chưa có lịch sử task.";
            }

            return string.Join(" | ", recentTasks.Select(t =>
                $"{t.Title}: status={t.Status}, feedback={TrimForPrompt(t.UserFeedback)}, difficulty={t.DifficultyRating}, confidence={t.ConfidenceRating}"));
        }

        private async Task<int> CalculateCurrentStreakAsync(Guid planId)
        {
            var completedTaskDates = await _dbContext.DailyStudyTasks
                .Where(t => t.PlanId == planId && t.IsCompleted)
                .Select(t => t.TaskDate.Date)
                .Distinct()
                .ToListAsync();

            var checkInDates = await _dbContext.DailyStudyCheckIns
                .Where(c => c.PlanId == planId)
                .Select(c => c.CheckInDate.Date)
                .Distinct()
                .ToListAsync();

            var activeDates = completedTaskDates
                .Concat(checkInDates)
                .Distinct()
                .ToHashSet();

            if (activeDates.Count == 0)
            {
                return 0;
            }

            var cursor = activeDates.Contains(DateTime.UtcNow.Date) ? DateTime.UtcNow.Date : DateTime.UtcNow.Date.AddDays(-1);
            var streak = 0;
            while (activeDates.Contains(cursor))
            {
                streak++;
                cursor = cursor.AddDays(-1);
            }

            return streak;
        }

        private async Task<string> GenerateCoachMessageAsync(UserStudyPlan? plan, string situation, string fallback)
        {
            try
            {
                var prompt =
                    "Bạn là coach học tập cá nhân cho học viên e-learning. " +
                    "Hãy trả lời ngắn gọn bằng tiếng Việt, thực tế, không lan man, tập trung vào hành động tiếp theo.\n" +
                    $"Mục tiêu: {plan?.Goal ?? "Chưa xác định"}\n" +
                    $"Nền tảng hiện tại: {plan?.CurrentKnowledgeLevel ?? "Chưa rõ"}\n" +
                    $"Động lực: {TrimForPrompt(plan?.Motivation)}\n" +
                    $"Ràng buộc: {TrimForPrompt(plan?.Constraints)}\n" +
                    $"Ngân sách học/ngày: {plan?.TimeBudgetMinutesPerDay ?? 45} phút\n" +
                    $"Tình huống: {situation}\n" +
                    "Trả lời 2-3 câu, ưu tiên lời khuyên có thể làm ngay trong ngày tới.";

                var response = await _geminiService.ChatAsync(prompt);
                return string.IsNullOrWhiteSpace(response) ? fallback : response.Trim();
            }
            catch
            {
                return fallback;
            }
        }

        private async Task CreateSupportAlertAsync(
            UserStudyPlan plan,
            string severity,
            string reason,
            string sourceType,
            Guid? taskId,
            Guid? checkInId)
        {
            var duplicateExists = await _dbContext.StudentSupportAlerts.AnyAsync(a =>
                a.PlanId == plan.Id &&
                a.Status == "OPEN" &&
                a.SourceType == sourceType &&
                a.DailyStudyTaskId == taskId &&
                a.DailyStudyCheckInId == checkInId);

            if (duplicateExists)
            {
                return;
            }

            var alert = new StudentSupportAlert
            {
                UserId = plan.UserId,
                PlanId = plan.Id,
                DailyStudyTaskId = taskId,
                DailyStudyCheckInId = checkInId,
                Severity = severity,
                Reason = reason,
                Status = "OPEN",
                SourceType = sourceType
            };

            _dbContext.StudentSupportAlerts.Add(alert);

            var user = await _dbContext.Users
                .AsNoTracking()
                .FirstOrDefaultAsync(u => u.Id == plan.UserId);

            var studentName = string.IsNullOrWhiteSpace(user?.FullName) ? user?.Email ?? plan.UserId.ToString() : user.FullName;
            await _notificationService.SendToRoleAsync("CARE", $"Cần hỗ trợ học viên: {studentName}", reason);

            if (plan.PrimaryCourseId.HasValue)
            {
                var lecturerId = await _dbContext.Courses
                    .Where(c => c.Id == plan.PrimaryCourseId.Value)
                    .Select(c => c.LecturerId)
                    .FirstOrDefaultAsync();

                if (lecturerId != Guid.Empty)
                {
                    await _notificationService.SendToUserAsync(lecturerId, $"Học viên cần hỗ trợ: {studentName}", reason);
                }
            }
        }

        private static (string Severity, string Reason)? BuildTaskAlert(DailyStudyTask task)
        {
            if (task.NeedsSupport)
            {
                return ("HIGH", $"Học viên đã chủ động yêu cầu hỗ trợ sau task \"{task.Title}\".");
            }

            if (!task.IsCompleted && task.DifficultyRating >= 4)
            {
                return ("HIGH", $"Học viên chưa hoàn thành task \"{task.Title}\" và đánh giá độ khó cao.");
            }

            if (task.ConfidenceRating.HasValue && task.ConfidenceRating <= 2)
            {
                return ("MEDIUM", $"Học viên hoàn thành task \"{task.Title}\" nhưng mức tự tin đang thấp.");
            }

            return null;
        }

        private static (string Severity, string Reason)? BuildCheckInAlert(DailyStudyCheckIn checkIn)
        {
            if (checkIn.NeedsSupport)
            {
                return ("HIGH", "Học viên đã yêu cầu hỗ trợ trực tiếp trong check-in.");
            }

            if (checkIn.ConfidenceScore <= 2 && checkIn.MoodScore <= 2)
            {
                return ("HIGH", "Check-in cho thấy mức tự tin và tinh thần của học viên đang thấp.");
            }

            if (checkIn.EnergyScore <= 2 || checkIn.ConfidenceScore <= 2)
            {
                return ("MEDIUM", "Check-in cho thấy học viên đang hụt năng lượng hoặc thiếu tự tin.");
            }

            return null;
        }

        private static string NormalizeTaskType(string? taskType)
        {
            if (string.IsNullOrWhiteSpace(taskType))
            {
                return "STUDY";
            }

            return taskType.Trim().ToUpperInvariant() switch
            {
                "VIDEO" => "VIDEO",
                "DOCUMENT" => "DOCUMENT",
                "QUIZ" => "QUIZ",
                "MIXED" => "PRACTICE",
                _ => "STUDY"
            };
        }

        private static int EstimateMinutes(string? lessonPartType)
        {
            return NormalizeTaskType(lessonPartType) switch
            {
                "VIDEO" => 25,
                "DOCUMENT" => 20,
                "QUIZ" => 15,
                "PRACTICE" => 30,
                _ => 20
            };
        }

        private static string TrimForPrompt(string? text)
        {
            if (string.IsNullOrWhiteSpace(text))
            {
                return "Không có";
            }

            var normalized = text.Trim();
            return normalized.Length <= 300 ? normalized : normalized[..300];
        }

        private static UserStudyPlanDto MapPlan(UserStudyPlan plan)
        {
            return new UserStudyPlanDto
            {
                Id = plan.Id,
                Goal = plan.Goal,
                CurrentKnowledgeLevel = plan.CurrentKnowledgeLevel,
                Motivation = plan.Motivation,
                TimeBudgetMinutesPerDay = plan.TimeBudgetMinutesPerDay,
                PreferredStudyTime = plan.PreferredStudyTime,
                Constraints = plan.Constraints,
                PrimaryCourseId = plan.PrimaryCourseId,
                PrimaryCourseTitle = plan.PrimaryCourse?.Title ?? string.Empty,
                CurrentStreakDays = plan.CurrentStreakDays,
                LastCheckInDate = plan.LastCheckInDate,
                LatestGuidanceMessage = plan.LatestGuidanceMessage,
                Status = plan.Status,
                PlanVersion = plan.PlanVersion,
                CreatedAt = plan.CreatedAt
            };
        }

        private static DailyStudyTaskDto MapTask(DailyStudyTask task)
        {
            return new DailyStudyTaskDto
            {
                Id = task.Id,
                TaskDate = task.TaskDate,
                Title = task.Title,
                Content = task.Content,
                TaskType = task.TaskType,
                EstimatedMinutes = task.EstimatedMinutes,
                SortOrder = task.SortOrder,
                Status = task.Status,
                RelatedCourseId = task.RelatedCourseId,
                RelatedCourseTitle = task.RelatedCourse?.Title ?? string.Empty,
                RelatedLessonPartId = task.RelatedLessonPartId,
                RelatedLessonTitle = task.RelatedLessonPart?.Lesson?.Title ?? string.Empty,
                ReflectionPrompt = task.ReflectionPrompt,
                IsCompleted = task.IsCompleted,
                UserFeedback = task.UserFeedback,
                AiAdvice = task.AiAdvice,
                ActualMinutesSpent = task.ActualMinutesSpent,
                DifficultyRating = task.DifficultyRating,
                ConfidenceRating = task.ConfidenceRating,
                NeedsSupport = task.NeedsSupport,
                CompletedAt = task.CompletedAt
            };
        }

        private static DailyStudyCheckInDto MapCheckIn(DailyStudyCheckIn checkIn)
        {
            return new DailyStudyCheckInDto
            {
                Id = checkIn.Id,
                CheckInDate = checkIn.CheckInDate,
                MoodScore = checkIn.MoodScore,
                EnergyScore = checkIn.EnergyScore,
                ConfidenceScore = checkIn.ConfidenceScore,
                ActualMinutesSpentToday = checkIn.ActualMinutesSpentToday,
                MinutesAvailableTomorrow = checkIn.MinutesAvailableTomorrow,
                Notes = checkIn.Notes,
                NeedsSupport = checkIn.NeedsSupport,
                CoachAdvice = checkIn.CoachAdvice
            };
        }

        private sealed record LearningQueueItem(
            Guid CourseId,
            string CourseTitle,
            Guid LessonPartId,
            string LessonTitle,
            string PartTitle,
            string TaskType,
            int EstimatedMinutes);
    }
}
