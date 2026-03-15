using Microsoft.EntityFrameworkCore;
using SKVI.Application.DTOs.Dashboard;
using SKVI.Application.Interfaces;
using SKVI.Infrastructure;

namespace SKVI.Application.Services;

public class LecturerDashboardService : ILecturerDashboardService
{
    private readonly ApplicationDbContext _context;
    private readonly ILogger<LecturerDashboardService> _logger;

    public LecturerDashboardService(ApplicationDbContext context, ILogger<LecturerDashboardService> logger)
    {
        _context = context;
        _logger = logger;
    }

    public async Task<LecturerDashboardStatsDto> GetStatsAsync(Guid lecturerId, CancellationToken cancellationToken = default)
    {
        try
        {
            var now = DateTime.UtcNow;
            var thirtyDaysAgo = now.AddDays(-30);

            // Get courses taught by this lecturer
            var lecturerCourses = await _context.Courses
                .Where(c => c.LecturerId == lecturerId)
                .ToListAsync(cancellationToken);

            var totalCoursesTeaching = lecturerCourses.Count;

            // Get total active students (enrolled in lecturer's courses)
            var totalStudentsActive = await _context.Enrollments
                .Where(e => lecturerCourses.Select(c => c.Id).Contains(e.CourseId) && e.CompletedAt == null)
                .Select(e => e.UserId)
                .Distinct()
                .CountAsync(cancellationToken);

            // Calculate average completion rate
            var enrollments = await _context.Enrollments
                .Where(e => lecturerCourses.Select(c => c.Id).Contains(e.CourseId))
                .ToListAsync(cancellationToken);

            var avgCompletionRate = enrollments.Count > 0
                ? (decimal)enrollments.Count(e => e.CompletedAt.HasValue) / enrollments.Count * 100
                : 0;

            // Calculate course revenue this month
            var courseRevenueThisMonth = lecturerCourses
                .Where(c => c.CreatedAt >= thirtyDaysAgo)
                .Sum(c => c.Price * enrollments.Count(e => e.CourseId == c.Id));

            // TODO: Calculate completion trend percentage vs last month
            var completionRateTrend = 0m;

            // TODO: Count unreviewedquizzes when quiz submission system is implemented
            var unreviewedQuizzes = 0;

            return new LecturerDashboardStatsDto
            {
                TotalCoursesTeaching = totalCoursesTeaching,
                TotalStudentsActive = totalStudentsActive,
                AverageCompletionRate = avgCompletionRate,
                CourseRevenueThisMonth = courseRevenueThisMonth,
                CompletionRateTrendPercentage = completionRateTrend,
                UnreviewedQuizzes = unreviewedQuizzes
            };
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error retrieving lecturer dashboard stats for lecturer {LecturerId}", lecturerId);
            throw;
        }
    }

    public async Task<List<LecturerCourseDto>> GetCoursesAsync(Guid lecturerId, int page = 1, int pageSize = 20, CancellationToken cancellationToken = default)
    {
        try
        {
            var courses = await _context.Courses
                .Where(c => c.LecturerId == lecturerId)
                .OrderByDescending(c => c.CreatedAt)
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .Select(c => new LecturerCourseDto
                {
                    Id = c.Id,
                    Title = c.Title,
                    Description = c.Description,
                    EnrolledStudents = c.Enrollments.Count,
                    CompletionRate = c.Enrollments.Count > 0
                        ? (decimal)c.Enrollments.Count(e => e.CompletedAt.HasValue) / c.Enrollments.Count * 100
                        : 0,
                    Rating = 0,
                    Revenue = c.Price * c.Enrollments.Count,
                    IsPublished = c.IsPublished,
                    CreatedAt = c.CreatedAt
                })
                .ToListAsync(cancellationToken);

            return courses;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error retrieving courses for lecturer {LecturerId}", lecturerId);
            throw;
        }
    }

    public async Task<List<LecturerLessonDto>> GetLessonsAsync(Guid lecturerId, CancellationToken cancellationToken = default)
    {
        // TODO: Implement when Lesson/LessonPart table has proper instructor tracking
        return await Task.FromResult(new List<LecturerLessonDto>());
    }

    public async Task<List<PendingQuizDto>> GetPendingQuizzesAsync(Guid lecturerId, CancellationToken cancellationToken = default)
    {
        // TODO: Implement when Quiz submission tracking is added
        return await Task.FromResult(new List<PendingQuizDto>());
    }

    public async Task<List<QuizSubmissionDto>> GetQuizSubmissionsAsync(Guid quizId, string? status = null, CancellationToken cancellationToken = default)
    {
        // TODO: Implement when QuizSubmission table is created
        return await Task.FromResult(new List<QuizSubmissionDto>());
    }

    public async Task<List<StudentProgressDto>> GetStudentProgressAsync(Guid lecturerId, CancellationToken cancellationToken = default)
    {
        try
        {
            // Get courses taught by lecturer
            var lecturerCourses = await _context.Courses
                .Where(c => c.LecturerId == lecturerId)
                .Select(c => c.Id)
                .ToListAsync(cancellationToken);

            // Get students enrolled in these courses
            var studentProgress = await _context.Enrollments
                .Where(e => lecturerCourses.Contains(e.CourseId))
                .GroupBy(e => e.UserId)
                .Select(g => new StudentProgressDto
                {
                    StudentId = g.Key,
                    Email = g.First().User!.Email,
                    FullName = g.First().User!.FullName,
                    CourseProgress = g.Select(e => new CourseProgressDetailDto
                    {
                        CourseId = e.CourseId,
                        CourseName = e.Course!.Title,
                        CompletionPercentage = e.CompletedAt.HasValue ? 100 : 0,  // Simplified
                        LessonsCompleted = 0,  // TODO: Track lesson completion
                        TotalLessons = e.Course!.CourseLessons.Count,
                        AverageQuizScore = null,  // TODO: Calculate from quiz submissions
                        EnrolledDate = e.EnrolledAt,
                        CompletedDate = e.CompletedAt
                    }).ToList()
                })
                .ToListAsync(cancellationToken);

            return studentProgress;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error retrieving student progress for lecturer {LecturerId}", lecturerId);
            throw;
        }
    }

    public async Task<StudentProgressDto?> GetStudentProgressDetailAsync(Guid lecturerId, Guid studentId, CancellationToken cancellationToken = default)
    {
        // Get the specific student's progress in lecturer's courses only
        var lecturerCourses = await _context.Courses
            .Where(c => c.LecturerId == lecturerId)
            .Select(c => c.Id)
            .ToListAsync(cancellationToken);

        var progress = await _context.Enrollments
            .Where(e => e.UserId == studentId && lecturerCourses.Contains(e.CourseId))
            .GroupBy(e => e.UserId)
            .Select(g => new StudentProgressDto
            {
                StudentId = g.Key,
                Email = g.First().User!.Email,
                FullName = g.First().User!.FullName,
                CourseProgress = g.Select(e => new CourseProgressDetailDto
                {
                    CourseId = e.CourseId,
                    CourseName = e.Course!.Title,
                    CompletionPercentage = e.CompletedAt.HasValue ? 100 : 0,
                    LessonsCompleted = 0,  // TODO
                    TotalLessons = e.Course!.CourseLessons.Count,
                    AverageQuizScore = null,  // TODO
                    EnrolledDate = e.EnrolledAt,
                    CompletedDate = e.CompletedAt
                }).ToList()
            })
            .FirstOrDefaultAsync(cancellationToken);

        return progress;
    }

    public async Task<LecturerAnalyticsDto> GetAnalyticsAsync(Guid lecturerId, CancellationToken cancellationToken = default)
    {
        // TODO: Implement with lesson engagement and drop-off data
        return await Task.FromResult(new LecturerAnalyticsDto());
    }

    public async Task<List<LecturerMessageDto>> GetMessagesAsync(Guid lecturerId, CancellationToken cancellationToken = default)
    {
        // TODO: Implement when messaging system is created
        return await Task.FromResult(new List<LecturerMessageDto>());
    }

    public async Task GradeQuizSubmissionAsync(string submissionId, GradeQuizSubmissionDto request, CancellationToken cancellationToken = default)
    {
        // TODO: Implement when QuizSubmission table is created
        await Task.CompletedTask;
    }

    public async Task<List<ZoomClassDto>> GetZoomScheduleAsync(Guid lecturerId, CancellationToken cancellationToken = default)
    {
        // TODO: Implement Zoom integration - placeholder for future
        return await Task.FromResult(new List<ZoomClassDto>());
    }
}
