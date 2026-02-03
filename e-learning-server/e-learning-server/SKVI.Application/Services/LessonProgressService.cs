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

    public async Task UpdateProgressAsync(Guid userId, Guid courseId, Guid lessonPartId, int watchedDuration)
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
            .FirstOrDefault(lp => lp.LessonPartId == lessonPartId);

        if (lessonProgress == null)
        {
            lessonProgress = new LessonProgress
            {
                Id = Guid.NewGuid(),
                EnrollmentId = enrollment.Id,
                LessonPartId = lessonPartId,
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

    public async Task MarkLessonCompleteAsync(Guid userId, Guid courseId, Guid lessonPartId)
    {
        // Start transaction for atomic progress update
        using var transaction = await _context.Database.BeginTransactionAsync();

        try
        {
            // Get enrollment with progress and course data
            var enrollment = await _context.Enrollments
                .Include(e => e.LessonProgress)
                .Include(e => e.Course)
                    .ThenInclude(c => c.CourseLessons)
                        .ThenInclude(cl => cl.Lesson)
                            .ThenInclude(l => l.LessonParts)
                .FirstOrDefaultAsync(e => e.UserId == userId && e.CourseId == courseId);

            if (enrollment == null)
            {
                throw new InvalidOperationException("User is not enrolled in this course");
            }

            // Get or create lesson progress
            // Handle potential duplicates (self-healing)
            var allProgressForPart = enrollment.LessonProgress
                .Where(lp => lp.LessonPartId == lessonPartId)
                .ToList();

            LessonProgress lessonProgress;

            if (allProgressForPart.Count == 0)
            {
                lessonProgress = new LessonProgress
                {
                    Id = Guid.NewGuid(),
                    EnrollmentId = enrollment.Id,
                    LessonPartId = lessonPartId,
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
                lessonProgress = allProgressForPart[0];
                
                // Update it
                if (!lessonProgress.IsCompleted)
                {
                    lessonProgress.IsCompleted = true;
                    lessonProgress.CompletedAt = DateTime.UtcNow;
                    lessonProgress.LastWatchedAt = DateTime.UtcNow;
                }

                // Delete duplicates if any
                if (allProgressForPart.Count > 1)
                {
                    _logger.LogWarning("Found {Count} duplicate progress records for User {UserId}, LessonPart {LessonPartId}. Cleaning up.", allProgressForPart.Count, userId, lessonPartId);
                    for (int i = 1; i < allProgressForPart.Count; i++)
                    {
                        _context.LessonProgresses.Remove(allProgressForPart[i]);
                        enrollment.LessonProgress.Remove(allProgressForPart[i]);
                    }
                }
            }

            // Calculate progress percentage
            // Flatten: Course -> CourseLesson -> Lesson -> LessonPart
            var totalParts = enrollment.Course.CourseLessons
                .Where(cl => cl.Lesson != null)
                .SelectMany(cl => cl.Lesson.LessonParts)
                .Count();

            var completedParts = enrollment.LessonProgress
                .Where(lp => lp.IsCompleted)
                .Select(lp => lp.LessonPartId)
                .Distinct()
                .Count();

            // Update progress percentage
            var progressPercentage = totalParts > 0 
                ? (int)Math.Floor((completedParts / (double)totalParts) * 100) 
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

            _logger.LogInformation("LessonPart {LessonPartId} marked complete for user {UserId}", lessonPartId, userId);
        }
        catch (Exception ex)
        {
            await transaction.RollbackAsync();
            _logger.LogError(ex, "Error marking lesson complete");
            throw;
        }
    }

    public async Task<LessonProgressDto?> GetLessonProgressAsync(Guid userId, Guid courseId, Guid lessonPartId)
    {
        var enrollment = await _context.Enrollments
            .AsNoTracking()
            .Include(e => e.LessonProgress)
            .Include(e => e.Course)
                .ThenInclude(c => c.CourseLessons)
                    .ThenInclude(cl => cl.Lesson)
                        .ThenInclude(l => l.LessonParts)
            .FirstOrDefaultAsync(e => e.UserId == userId && e.CourseId == courseId);

        if (enrollment == null)
        {
            return null;
        }

        var part = enrollment.Course.CourseLessons
            .Where(cl => cl.Lesson != null)
            .SelectMany(cl => cl.Lesson.LessonParts)
            .FirstOrDefault(p => p.Id == lessonPartId);

        if (part == null)
        {
            return null;
        }

        var progress = enrollment.LessonProgress.FirstOrDefault(lp => lp.LessonPartId == lessonPartId);

        return new LessonProgressDto
        {
            LessonPartId = lessonPartId.ToString(),
            LessonPartTitle = part.Title,
            IsCompleted = progress?.IsCompleted ?? false,
            WatchedDuration = progress?.WatchedDuration ?? 0,
            CompletedAt = progress?.CompletedAt,
            LastWatchedAt = progress?.LastWatchedAt ?? DateTime.MinValue
        };
    }
}
