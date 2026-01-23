using Microsoft.EntityFrameworkCore;
using SKVI.Application.DTOs.Enrollment;
using SKVI.Application.Interfaces;
using SKVI.Domain.Entities;
using SKVI.Infrastructure;

namespace SKVI.Application.Services;

public class LessonProgressService : ILessonProgressService
{
    private readonly ApplicationDbContext _context;
    private readonly ILogger<LessonProgressService> _logger;

    public LessonProgressService(ApplicationDbContext context, ILogger<LessonProgressService> logger)
    {
        _context = context;
        _logger = logger;
    }

    public async Task UpdateProgressAsync(Guid userId, Guid courseId, Guid lessonId, int watchedDuration)
    {
        // Get or create enrollment
        var enrollment = await _context.Enrollments
            .Include(e => e.LessonProgress)
            .FirstOrDefaultAsync(e => e.UserId == userId && e.CourseId == courseId);

        if (enrollment == null)
        {
            throw new InvalidOperationException("User is not enrolled in this course");
        }

        // Get or create lesson progress
        var lessonProgress = enrollment.LessonProgress
            .FirstOrDefault(lp => lp.LessonId == lessonId);

        if (lessonProgress == null)
        {
            lessonProgress = new LessonProgress
            {
                Id = Guid.NewGuid(),
                EnrollmentId = enrollment.Id,
                LessonId = lessonId,
                WatchedDuration = watchedDuration,
                LastWatchedAt = DateTime.UtcNow,
                IsCompleted = false
            };
            _context.LessonProgresses.Add(lessonProgress);
        }
        else
        {
            // Update watched duration (only if greater to prevent going backwards)
            if (watchedDuration > lessonProgress.WatchedDuration)
            {
                lessonProgress.WatchedDuration = watchedDuration;
            }
            lessonProgress.LastWatchedAt = DateTime.UtcNow;
        }

        // Update enrollment last accessed
        enrollment.LastAccessedAt = DateTime.UtcNow;

        await _context.SaveChangesAsync();
    }

    public async Task MarkLessonCompleteAsync(Guid userId, Guid courseId, Guid lessonId)
    {
        // Start transaction for atomic progress update
        using var transaction = await _context.Database.BeginTransactionAsync();

        try
        {
            // Get enrollment with progress and course data
            var enrollment = await _context.Enrollments
                .Include(e => e.LessonProgress)
                .Include(e => e.Course)
                    .ThenInclude(c => c.CourseSections)
                    .ThenInclude(s => s.CourseLessons)
                .FirstOrDefaultAsync(e => e.UserId == userId && e.CourseId == courseId);

            if (enrollment == null)
            {
                throw new InvalidOperationException("User is not enrolled in this course");
            }

            // Get or create lesson progress
            // Handle potential duplicates (self-healing)
            var allProgressForLesson = enrollment.LessonProgress
                .Where(lp => lp.LessonId == lessonId)
                .ToList();

            LessonProgress lessonProgress;

            if (allProgressForLesson.Count == 0)
            {
                lessonProgress = new LessonProgress
                {
                    Id = Guid.NewGuid(),
                    EnrollmentId = enrollment.Id,
                    LessonId = lessonId,
                    IsCompleted = true,
                    CompletedAt = DateTime.UtcNow,
                    LastWatchedAt = DateTime.UtcNow,
                    WatchedDuration = 0
                };
                _context.LessonProgresses.Add(lessonProgress);
                // Manually add to the collection so the count below is correct
                enrollment.LessonProgress.Add(lessonProgress);
            }
            else
            {
                // Use the first one
                lessonProgress = allProgressForLesson[0];
                
                // Update it
                if (!lessonProgress.IsCompleted)
                {
                    lessonProgress.IsCompleted = true;
                    lessonProgress.CompletedAt = DateTime.UtcNow;
                    lessonProgress.LastWatchedAt = DateTime.UtcNow;
                }

                // Delete duplicates if any
                if (allProgressForLesson.Count > 1)
                {
                    _logger.LogWarning("Found {Count} duplicate progress records for User {UserId}, Lesson {LessonId}. Cleaning up.", allProgressForLesson.Count, userId, lessonId);
                    for (int i = 1; i < allProgressForLesson.Count; i++)
                    {
                        _context.LessonProgresses.Remove(allProgressForLesson[i]);
                        enrollment.LessonProgress.Remove(allProgressForLesson[i]);
                    }
                }
            }

            // Calculate progress percentage (Robust calculation)
            var totalLessons = enrollment.Course.CourseSections
                .SelectMany(s => s.CourseLessons)
                .Count();

            var completedLessons = enrollment.LessonProgress
                .Where(lp => lp.IsCompleted)
                .Select(lp => lp.LessonId)
                .Distinct()
                .Count();

            // Update progress percentage
            var progressPercentage = totalLessons > 0 
                ? (int)Math.Floor((completedLessons / (double)totalLessons) * 100) 
                : 0;

            enrollment.ProgressPercentage = progressPercentage;
            enrollment.LastAccessedAt = DateTime.UtcNow;

            // Mark course as completed if 100%
            if (progressPercentage == 100 && enrollment.CompletedAt == null)
            {
                enrollment.CompletedAt = DateTime.UtcNow;
                _logger.LogInformation("User {UserId} completed course {CourseId}", userId, courseId);
            }

            await _context.SaveChangesAsync();
            await transaction.CommitAsync();

            _logger.LogInformation("Lesson {LessonId} marked complete for user {UserId}", lessonId, userId);
        }
        catch (Exception ex)
        {
            await transaction.RollbackAsync();
            _logger.LogError(ex, "Error marking lesson complete");
            throw;
        }
    }

    public async Task<LessonProgressDto?> GetLessonProgressAsync(Guid userId, Guid courseId, Guid lessonId)
    {
        var enrollment = await _context.Enrollments
            .AsNoTracking()
            .Include(e => e.LessonProgress)
            .Include(e => e.Course)
                .ThenInclude(c => c.CourseSections)
                .ThenInclude(s => s.CourseLessons)
            .FirstOrDefaultAsync(e => e.UserId == userId && e.CourseId == courseId);

        if (enrollment == null)
        {
            return null;
        }

        var lesson = enrollment.Course.CourseSections
            .SelectMany(s => s.CourseLessons)
            .FirstOrDefault(l => l.Id == lessonId);

        if (lesson == null)
        {
            return null;
        }

        var progress = enrollment.LessonProgress.FirstOrDefault(lp => lp.LessonId == lessonId);

        return new LessonProgressDto
        {
            LessonId = lessonId.ToString(),
            LessonTitle = lesson.Title,
            IsCompleted = progress?.IsCompleted ?? false,
            WatchedDuration = progress?.WatchedDuration ?? 0,
            CompletedAt = progress?.CompletedAt,
            LastWatchedAt = progress?.LastWatchedAt ?? DateTime.MinValue
        };
    }
}
