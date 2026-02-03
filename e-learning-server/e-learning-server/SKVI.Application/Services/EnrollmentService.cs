using Microsoft.EntityFrameworkCore;
using SKVI.Application.DTOs.Enrollment;
using SKVI.Application.Interfaces;
using SKVI.Domain.Entities;
using SKVI.Infrastructure;

namespace SKVI.Application.Services;

public class EnrollmentService : IEnrollmentService
{
    private readonly ApplicationDbContext _context;
    private readonly INotificationService _notificationService;
    private readonly ILogger<EnrollmentService> _logger;

    public EnrollmentService(ApplicationDbContext context, INotificationService notificationService, ILogger<EnrollmentService> logger)
    {
        _context = context;
        _notificationService = notificationService;
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

        // --- Notification Trigger ---
        try
        {
            var studentName = await _context.Users
                .Where(u => u.Id == userId)
                .Select(u => u.FullName ?? u.Email)
                .FirstOrDefaultAsync() ?? "A new student";

            // Notify Lecturer
            if (!string.IsNullOrEmpty(course.LecturerId.ToString()))
            {
                await _notificationService.NotifyUserAsync(
                    course.LecturerId.ToString(), 
                    "New Student Enrollment", 
                    $"{studentName} has enrolled in your course: {course.Title}", 
                    "enrollment", 
                    new { courseId = course.Id, userId });
            }

            // Notify Admins
            await _notificationService.NotifyAdminsAsync(
                "New Enrollment", 
                $"{studentName} enrolled in {course.Title}", 
                "enrollment", 
                new { courseId = course.Id, userId });
        }
        catch (Exception ex)
        {
            // Don't fail the enrollment if notification fails
            _logger.LogError(ex, "Error sending enrollment notifications");
        }

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
                .ThenInclude(c => c.CourseLessons)
                    .ThenInclude(cl => cl.Lesson)
                        .ThenInclude(l => l.LessonParts)
            .FirstOrDefaultAsync(e => e.UserId == userId && e.CourseId == courseId);

        if (enrollment == null)
        {
            throw new InvalidOperationException("Enrollment not found");
        }

        // Get all lessons (parts) via Flattening
        var allParts = enrollment.Course.CourseLessons
            .Where(cl => cl.Lesson != null)
            .SelectMany(cl => cl.Lesson.LessonParts)
            .ToList();

        // Calculate progress percentage
        var totalParts = allParts.Count;
        var completedParts = enrollment.LessonProgress
            .Where(lp => lp.IsCompleted)
            .Select(lp => lp.LessonPartId)
            .Distinct()
            .Count();
        
        var calculatedPercentage = totalParts > 0 
            ? (int)Math.Floor((completedParts / (double)totalParts) * 100) 
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
        var lessonProgressDtos = allParts.Select(part =>
        {
            var progress = enrollment.LessonProgress.FirstOrDefault(lp => lp.LessonPartId == part.Id);
            return new LessonProgressDto
            {
                LessonPartId = part.Id.ToString(),
                LessonPartTitle = part.Title,
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
            CompletedLessons = completedParts,
            TotalLessons = totalParts,
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
