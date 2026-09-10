using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using SKVI.Application.DTOs.Articles;
using SKVI.Application.DTOs.Categories;
using SKVI.Application.DTOs.Courses;
using SKVI.Application.DTOs.Enrollment;
using SKVI.Application.DTOs.Mobile;
using SKVI.Application.DTOs.Testimonial;
using SKVI.Application.Interfaces;
using SKVI.Infrastructure;
using System.Security.Claims;

namespace e_learning_server.Controllers;

[ApiController]
[Route("api/mobile")]
public class MobileController : ControllerBase
{
    private readonly ApplicationDbContext _db;
    private readonly ICourseService _courseService;
    private readonly IEnrollmentService _enrollmentService;
    private readonly ICategoryService _categoryService;
    private readonly IArticleService _articleService;
    private readonly ITestimonialService _testimonialService;
    private readonly ILogger<MobileController> _logger;

    public MobileController(
        ApplicationDbContext db,
        ICourseService courseService,
        IEnrollmentService enrollmentService,
        ICategoryService categoryService,
        IArticleService articleService,
        ITestimonialService testimonialService,
        ILogger<MobileController> logger)
    {
        _db = db;
        _courseService = courseService;
        _enrollmentService = enrollmentService;
        _categoryService = categoryService;
        _articleService = articleService;
        _testimonialService = testimonialService;
        _logger = logger;
    }

    private Guid? GetOptionalUserId()
    {
        var claim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (string.IsNullOrEmpty(claim) || !Guid.TryParse(claim, out var userId))
        {
            return null;
        }
        return userId;
    }

    private Guid GetRequiredUserId()
    {
        var userId = GetOptionalUserId();
        if (!userId.HasValue)
        {
            throw new UnauthorizedAccessException("User is not authenticated");
        }
        return userId.Value;
    }

    /// <summary>
    /// Aggregated mobile home feed payload in a single round-trip request.
    /// </summary>
    [HttpGet("home-feed")]
    [AllowAnonymous]
    public async Task<IActionResult> GetHomeFeed(CancellationToken cancellationToken)
    {
        try
        {
            var userId = GetOptionalUserId();

            // Run queries
            var courses = await _courseService.GetAllAsync(true, cancellationToken);
            var categories = await _categoryService.GetActiveAsync(cancellationToken);
            var articlesResult = await _articleService.GetAllArticlesPaginatedAsync(1, 4, false);
            var testimonials = await _testimonialService.GetActiveAsync();

            var enrollments = userId.HasValue
                ? await _enrollmentService.GetUserEnrollmentsAsync(userId.Value)
                : new List<EnrollmentResponse>();

            var response = new MobileHomeFeedDto
            {
                FeaturedCourses = courses.ToList(),
                MyEnrollments = enrollments.ToList(),
                Categories = categories.ToList(),
                RecentArticles = articlesResult.Items.ToList(),
                Testimonials = testimonials.ToList()
            };

            return Ok(response);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error assembling mobile home feed");
            return StatusCode(500, new { message = "Error loading mobile home feed", details = ex.Message });
        }
    }

    /// <summary>
    /// Aggregated study progress summary for the current user.
    /// </summary>
    [HttpGet("learning/progress-summary")]
    [Authorize]
    public async Task<IActionResult> GetLearningProgressSummary(CancellationToken cancellationToken)
    {
        try
        {
            var userId = GetRequiredUserId();

            var enrollments = await _db.Enrollments
                .Where(e => e.UserId == userId && e.Status == "ACTIVE")
                .Include(e => e.Course)
                    .ThenInclude(c => c.CourseLessons)
                        .ThenInclude(cl => cl.Lesson)
                            .ThenInclude(l => l.LessonParts)
                .Include(e => e.LessonProgress)
                .ToListAsync(cancellationToken);

            int totalLessons = 0;
            int completedLessons = 0;
            int totalSecondsWatched = 0;

            foreach (var enrollment in enrollments)
            {
                var lessonPartIds = enrollment.Course.CourseLessons
                    .SelectMany(cl => cl.Lesson.LessonParts)
                    .Select(lp => lp.Id)
                    .Distinct()
                    .ToList();

                totalLessons += lessonPartIds.Count;

                var progressList = enrollment.LessonProgress
                    .Where(lp => lessonPartIds.Contains(lp.LessonPartId))
                    .ToList();

                completedLessons += progressList.Count(p => p.IsCompleted);
                totalSecondsWatched += progressList.Sum(p => p.WatchedDuration);
            }

            double overallProgress = totalLessons > 0
                ? Math.Round((double)completedLessons / totalLessons * 100, 1)
                : 0;

            // Calculate 7-day stats (Mon -> Sun of current week)
            var now = DateTime.UtcNow;
            var daysFromMonday = ((int)now.DayOfWeek + 6) % 7;
            var startOfWeek = now.Date.AddDays(-daysFromMonday);

            var weekDayNames = new[] { "T2", "T3", "T4", "T5", "T6", "T7", "CN" };
            var weeklyStats = new List<DailyStudyTimeDto>();

            var allProgresses = enrollments
                .SelectMany(e => e.LessonProgress)
                .Where(p => p.LastWatchedAt >= startOfWeek)
                .ToList();

            for (int i = 0; i < 7; i++)
            {
                var dayDate = startOfWeek.AddDays(i);
                var daySeconds = allProgresses
                    .Where(p => p.LastWatchedAt.Date == dayDate)
                    .Sum(p => p.WatchedDuration);

                weeklyStats.Add(new DailyStudyTimeDto
                {
                    DayOfWeek = weekDayNames[i],
                    DayIndex = i,
                    MinutesLearned = Math.Max(0, (int)Math.Ceiling(daySeconds / 60.0)),
                    GoalMinutes = 30,
                    IsToday = dayDate == now.Date
                });
            }

            // Streak calculation
            int streakDays = 0;
            var checkDate = now.Date;
            while (true)
            {
                bool hasActivity = enrollments
                    .SelectMany(e => e.LessonProgress)
                    .Any(p => p.LastWatchedAt.Date == checkDate && p.WatchedDuration > 0);

                if (hasActivity)
                {
                    streakDays++;
                    checkDate = checkDate.AddDays(-1);
                }
                else
                {
                    if (checkDate == now.Date)
                    {
                        checkDate = checkDate.AddDays(-1);
                        continue;
                    }
                    break;
                }
            }

            var summary = new MobileLearningProgressDto
            {
                OverallProgressPercent = overallProgress,
                TotalMinutesLearned = (int)Math.Ceiling(totalSecondsWatched / 60.0),
                CompletedLessonsCount = completedLessons,
                TotalEnrolledCoursesCount = enrollments.Count,
                CurrentStreakDays = Math.Max(streakDays, enrollments.Count > 0 ? 1 : 0),
                WeeklyStudyStats = weeklyStats
            };

            return Ok(summary);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error calculating learning progress summary");
            return StatusCode(500, new { message = "Error calculating progress", details = ex.Message });
        }
    }

    /// <summary>
    /// Get course details with user enrollment status and progress in one payload.
    /// </summary>
    [HttpGet("courses/{id:guid}")]
    [AllowAnonymous]
    public async Task<IActionResult> GetCourseDetail(Guid id, CancellationToken cancellationToken)
    {
        try
        {
            var course = await _courseService.GetByIdAsync(id, cancellationToken);
            var userId = GetOptionalUserId();

            bool isEnrolled = false;
            double progressPercent = 0;
            Guid? lastAccessedLessonPartId = null;
            var completedLessonPartIds = new List<Guid>();

            if (userId.HasValue)
            {
                var enrollment = await _db.Enrollments
                    .Include(e => e.LessonProgress)
                    .FirstOrDefaultAsync(e => e.UserId == userId.Value && e.CourseId == id && e.Status == "ACTIVE", cancellationToken);

                if (enrollment != null)
                {
                    isEnrolled = true;
                    var totalParts = course.Lessons.SelectMany(l => l.Parts).Count();
                    var completedParts = enrollment.LessonProgress.Where(lp => lp.IsCompleted).Select(lp => lp.LessonPartId).ToList();
                    completedLessonPartIds = completedParts;

                    if (totalParts > 0)
                    {
                        progressPercent = Math.Round((double)completedParts.Count / totalParts * 100, 1);
                    }

                    var lastWatched = enrollment.LessonProgress
                        .OrderByDescending(lp => lp.LastWatchedAt)
                        .FirstOrDefault();

                    lastAccessedLessonPartId = lastWatched?.LessonPartId;
                }
            }

            return Ok(new MobileCourseDetailDto
            {
                Course = course,
                IsEnrolled = isEnrolled,
                ProgressPercent = progressPercent,
                LastAccessedLessonPartId = lastAccessedLessonPartId,
                CompletedLessonPartIds = completedLessonPartIds
            });
        }
        catch (KeyNotFoundException)
        {
            return NotFound(new { message = "Course not found" });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error getting mobile course detail");
            return StatusCode(500, new { message = "Error loading course detail", details = ex.Message });
        }
    }
}
