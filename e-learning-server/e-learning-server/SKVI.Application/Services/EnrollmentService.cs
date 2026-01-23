using Microsoft.EntityFrameworkCore;
using SKVI.Application.DTOs.Enrollment;
using SKVI.Application.Interfaces;
using SKVI.Domain.Entities;
using SKVI.Infrastructure;

namespace SKVI.Application.Services;

public class EnrollmentService : IEnrollmentService
{
    private readonly ApplicationDbContext _context;
    private readonly ILogger<EnrollmentService> _logger;

    public EnrollmentService(ApplicationDbContext context, ILogger<EnrollmentService> logger)
    {
        _context = context;
        _logger = logger;
    }

    public async Task<EnrollmentResponse> EnrollInCourseAsync(Guid userId, string courseIdStr)
    {
        if (!Guid.TryParse(courseIdStr, out var courseId))
        {
            throw new ArgumentException("Invalid course ID format");
        }

        // Check if course exists and is published
        var course = await _context.Courses
            .AsNoTracking()
            .FirstOrDefaultAsync(c => c.Id == courseId && c.IsPublished);

        if (course == null)
        {
            throw new InvalidOperationException("Course not found or not published");
        }

        // For now, only allow free course enrollment (payment will be implemented later)
        if (!course.IsFree)
        {
            throw new InvalidOperationException("This course requires payment. Please purchase the course first.");
        }

        // Check if already enrolled (unique index will prevent duplicates, but check proactively)
        var existingEnrollment = await _context.Enrollments
            .AsNoTracking()
            .FirstOrDefaultAsync(e => e.UserId == userId && e.CourseId == courseId);

        if (existingEnrollment != null)
        {
            // Return existing enrollment
            return new EnrollmentResponse
            {
                Id = existingEnrollment.Id.ToString(),
                CourseId = course.Id.ToString(),
                CourseTitle = course.Title,
                EnrolledAt = existingEnrollment.EnrolledAt,
                ProgressPercentage = existingEnrollment.ProgressPercentage,
                CompletedAt = existingEnrollment.CompletedAt,
                LastAccessedAt = existingEnrollment.LastAccessedAt
            };
        }

        // Create new enrollment
        var enrollment = new Enrollment
        {
            Id = Guid.NewGuid(),
            UserId = userId,
            CourseId = courseId,
            EnrolledAt = DateTime.UtcNow,
            LastAccessedAt = DateTime.UtcNow,
            ProgressPercentage = 0
        };

        _context.Enrollments.Add(enrollment);
        await _context.SaveChangesAsync();

        _logger.LogInformation("User {UserId} enrolled in course {CourseId}", userId, courseId);

        return new EnrollmentResponse
        {
            Id = enrollment.Id.ToString(),
            CourseId = course.Id.ToString(),
            CourseTitle = course.Title,
            EnrolledAt = enrollment.EnrolledAt,
            ProgressPercentage = enrollment.ProgressPercentage,
            CompletedAt = enrollment.CompletedAt,
            LastAccessedAt = enrollment.LastAccessedAt
        };
    }

    public async Task<bool> IsEnrolledAsync(Guid userId, Guid courseId)
    {
        // Optimized: Use Any() which stops at first match
        return await _context.Enrollments
            .AsNoTracking()
            .AnyAsync(e => e.UserId == userId && e.CourseId == courseId);
    }

    public async Task<List<EnrollmentResponse>> GetUserEnrollmentsAsync(Guid userId)
    {
        // Optimized: Use Include to avoid N+1 queries
        var enrollments = await _context.Enrollments
            .AsNoTracking()
            .Include(e => e.Course)
            .Where(e => e.UserId == userId)
            .OrderByDescending(e => e.LastAccessedAt)
            .Select(e => new EnrollmentResponse
            {
                Id = e.Id.ToString(),
                CourseId = e.CourseId.ToString(),
                CourseTitle = e.Course.Title,
                EnrolledAt = e.EnrolledAt,
                ProgressPercentage = e.ProgressPercentage,
                CompletedAt = e.CompletedAt,
                LastAccessedAt = e.LastAccessedAt
            })
            .ToListAsync();

        return enrollments;
    }

    public async Task<CourseProgressResponse> GetCourseProgressAsync(Guid userId, Guid courseId)
    {
        // Get enrollment with lesson progress (optimized with Include)
        var enrollment = await _context.Enrollments
            .Include(e => e.LessonProgress)
            .Include(e => e.Course)
                .ThenInclude(c => c.CourseSections)
                .ThenInclude(s => s.CourseLessons)
            .FirstOrDefaultAsync(e => e.UserId == userId && e.CourseId == courseId);

        if (enrollment == null)
        {
            throw new InvalidOperationException("Enrollment not found");
        }

        // Get all lessons from all sections
        var allLessons = enrollment.Course.CourseSections
            .SelectMany(s => s.CourseLessons)
            .ToList();

        // Calculate progress percentage
        var totalLessons = allLessons.Count;
        var completedLessons = enrollment.LessonProgress
            .Where(lp => lp.IsCompleted)
            .Select(lp => lp.LessonId)
            .Distinct()
            .Count();
        
        var calculatedPercentage = totalLessons > 0 
            ? (int)Math.Floor((completedLessons / (double)totalLessons) * 100) 
            : 0;

        // Sync with DB if different (e.g. new lessons added)
        if (enrollment.ProgressPercentage != calculatedPercentage)
        {
            enrollment.ProgressPercentage = calculatedPercentage;
            // Also check if completed status needs to change
            if (calculatedPercentage < 100 && enrollment.CompletedAt != null)
            {
                enrollment.CompletedAt = null; // Revert completion if new lessons added
            }
            else if (calculatedPercentage == 100 && enrollment.CompletedAt == null)
            {
                enrollment.CompletedAt = DateTime.UtcNow;
            }
            
            await _context.SaveChangesAsync();
        }

        // Map lesson progress
        var lessonProgressDtos = allLessons.Select(lesson =>
        {
            var progress = enrollment.LessonProgress.FirstOrDefault(lp => lp.LessonId == lesson.Id);
            return new LessonProgressDto
            {
                LessonId = lesson.Id.ToString(),
                LessonTitle = lesson.Title,
                IsCompleted = progress?.IsCompleted ?? false,
                WatchedDuration = progress?.WatchedDuration ?? 0,
                CompletedAt = progress?.CompletedAt,
                LastWatchedAt = progress?.LastWatchedAt ?? DateTime.MinValue
            };
        }).ToList();

        return new CourseProgressResponse
        {
            EnrollmentId = enrollment.Id.ToString(),
            ProgressPercentage = calculatedPercentage,
            CompletedLessons = completedLessons,
            TotalLessons = totalLessons,
            CompletedAt = enrollment.CompletedAt,
            LessonProgress = lessonProgressDtos
        };
    }

    public async Task UpdateLastAccessedAsync(Guid userId, Guid courseId)
    {
        var enrollment = await _context.Enrollments
            .FirstOrDefaultAsync(e => e.UserId == userId && e.CourseId == courseId);

        if (enrollment != null)
        {
            enrollment.LastAccessedAt = DateTime.UtcNow;
            await _context.SaveChangesAsync();
        }
    }
}
