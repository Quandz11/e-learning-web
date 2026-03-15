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

        var now = DateTime.UtcNow;

        // Check if course exists and is published
        var course = await _context.Courses
            .AsNoTracking()
            .FirstOrDefaultAsync(c => c.Id == courseId && c.IsPublished);

        if (course == null)
        {
            throw new InvalidOperationException("Course not found or not published");
        }

        // Only free courses can be enrolled directly; paid courses require purchase
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
                CourseThumbnail = course.ThumbnailUrl,
                EnrolledAt = existingEnrollment.EnrolledAt,
                ProgressPercentage = existingEnrollment.ProgressPercentage,
                CompletedAt = existingEnrollment.CompletedAt,
                LastAccessedAt = existingEnrollment.LastAccessedAt,
                AccessDurationDays = existingEnrollment.AccessDurationDays,
                AccessExpiresAt = existingEnrollment.AccessExpiresAt,
                IsExpired = IsEnrollmentExpired(existingEnrollment, now),
                Status = existingEnrollment.Status
            };
        }

        var accessDurationDays = NormalizeDurationDays(course.DefaultAccessDurationDays);

        // Create new enrollment — free courses are ACTIVE immediately
        var enrollment = new Enrollment
        {
            Id = Guid.NewGuid(),
            UserId = userId,
            CourseId = courseId,
            EnrolledAt = now,
            LastAccessedAt = now,
            ProgressPercentage = 0,
            Status = "ACTIVE",
            SourceType = "FREE",
            AccessDurationDays = accessDurationDays,
            AccessExpiresAt = CalculateAccessExpiresAt(now, accessDurationDays)
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
                await _notificationService.SendToUserAsync(
                    course.LecturerId, 
                    "New Student Enrollment", 
                    $"{studentName} has enrolled in your course: {course.Title}");
            }

            // Notify Admins
            await _notificationService.SendToRoleAsync(
                "ADMIN", 
                "New Enrollment", 
                $"{studentName} enrolled in {course.Title}");
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
            CourseThumbnail = course.ThumbnailUrl,
            EnrolledAt = enrollment.EnrolledAt,
            ProgressPercentage = enrollment.ProgressPercentage,
            CompletedAt = enrollment.CompletedAt,
            LastAccessedAt = enrollment.LastAccessedAt,
            AccessDurationDays = enrollment.AccessDurationDays,
            AccessExpiresAt = enrollment.AccessExpiresAt,
            IsExpired = IsEnrollmentExpired(enrollment, now),
            Status = enrollment.Status
        };
    }

    public async Task<bool> IsEnrolledAsync(Guid userId, Guid courseId)
    {
        // Only ACTIVE enrollments grant access
        var now = DateTime.UtcNow;
        return await _context.Enrollments
            .AsNoTracking()
            .AnyAsync(e =>
                e.UserId == userId
                && e.CourseId == courseId
                && e.Status == "ACTIVE"
                && (e.AccessExpiresAt == null || e.AccessExpiresAt > now));
    }

    public async Task<List<EnrollmentResponse>> GetUserEnrollmentsAsync(Guid userId)
    {
        // Only return ACTIVE enrollments to user-facing endpoints
        var now = DateTime.UtcNow;
        var enrollments = await _context.Enrollments
            .Include(e => e.Course)
                .ThenInclude(c => c.CourseLessons)
                    .ThenInclude(cl => cl.Lesson)
                        .ThenInclude(l => l.LessonParts)
            .Include(e => e.LessonProgress)
            .Where(e => e.UserId == userId && e.Status == "ACTIVE")
            .OrderByDescending(e => e.LastAccessedAt)
            .AsSplitQuery()
            .ToListAsync();

        var hasChanges = false;
        var responses = new List<EnrollmentResponse>(enrollments.Count);

        foreach (var enrollment in enrollments)
        {
            var calculation = CalculateEnrollmentProgress(enrollment);
            if (ApplyCalculatedProgress(enrollment, calculation))
            {
                hasChanges = true;
            }

            responses.Add(new EnrollmentResponse
            {
                Id = enrollment.Id.ToString(),
                CourseId = enrollment.CourseId.ToString(),
                CourseTitle = enrollment.Course.Title,
                CourseThumbnail = enrollment.Course.ThumbnailUrl,
                EnrolledAt = enrollment.EnrolledAt,
                ProgressPercentage = enrollment.ProgressPercentage,
                CompletedAt = enrollment.CompletedAt,
                LastAccessedAt = enrollment.LastAccessedAt,
                AccessDurationDays = enrollment.AccessDurationDays,
                AccessExpiresAt = enrollment.AccessExpiresAt,
                IsExpired = IsEnrollmentExpired(enrollment, now),
                Status = enrollment.Status
            });
        }

        if (hasChanges)
        {
            await _context.SaveChangesAsync();
        }

        return responses;
    }

    // ─── Admin Methods ────────────────────────────────────────────────────────

    public async Task<List<AdminEnrollmentResponse>> AdminGetUserEnrollmentsAsync(Guid userId)
    {
        return await _context.Enrollments
            .AsNoTracking()
            .Include(e => e.Course)
            .Include(e => e.User)
            .Where(e => e.UserId == userId)
            .OrderByDescending(e => e.EnrolledAt)
            .Select(e => new AdminEnrollmentResponse
            {
                Id = e.Id.ToString(),
                CourseId = e.CourseId.ToString(),
                CourseTitle = e.Course.Title,
                CourseThumbnail = e.Course.ThumbnailUrl,
                UserId = e.UserId.ToString(),
                UserEmail = e.User.Email,
                UserFullName = e.User.FullName,
                EnrolledAt = e.EnrolledAt,
                ProgressPercentage = e.ProgressPercentage,
                CompletedAt = e.CompletedAt,
                LastAccessedAt = e.LastAccessedAt,
                AccessDurationDays = e.AccessDurationDays,
                AccessExpiresAt = e.AccessExpiresAt,
                Status = e.Status
            })
            .ToListAsync();
    }

    public async Task<AdminEnrollmentResponse> AdminAddEnrollmentAsync(Guid userId, AdminAddEnrollmentRequest request)
    {
        if (!Guid.TryParse(request.CourseId, out var courseId))
            throw new ArgumentException("Invalid course ID format");

        var course = await _context.Courses
            .AsNoTracking()
            .FirstOrDefaultAsync(c => c.Id == courseId)
            ?? throw new InvalidOperationException("Course not found");

        var user = await _context.Users
            .AsNoTracking()
            .FirstOrDefaultAsync(u => u.Id == userId)
            ?? throw new InvalidOperationException("User not found");

        var now = DateTime.UtcNow;
        var accessDurationDays = ResolveAccessDurationDays(request.AccessDurationDays, course.DefaultAccessDurationDays);
        var accessExpiresAt = CalculateAccessExpiresAt(now, accessDurationDays);

        var existing = await _context.Enrollments
            .FirstOrDefaultAsync(e => e.UserId == userId && e.CourseId == courseId);

        if (existing != null)
        {
            // Re-grant access window from now when admin manually adds again.
            existing.Status = "ACTIVE";
            existing.LastAccessedAt = now;
            existing.AccessDurationDays = accessDurationDays;
            existing.AccessExpiresAt = accessExpiresAt;
            await _context.SaveChangesAsync();
            return new AdminEnrollmentResponse
            {
                Id = existing.Id.ToString(), CourseId = course.Id.ToString(),
                CourseTitle = course.Title, CourseThumbnail = course.ThumbnailUrl,
                UserId = userId.ToString(), UserEmail = user.Email, UserFullName = user.FullName,
                EnrolledAt = existing.EnrolledAt, ProgressPercentage = existing.ProgressPercentage,
                CompletedAt = existing.CompletedAt, LastAccessedAt = existing.LastAccessedAt,
                AccessDurationDays = existing.AccessDurationDays,
                AccessExpiresAt = existing.AccessExpiresAt,
                Status = existing.Status
            };
        }

        var enrollment = new Enrollment
        {
            Id = Guid.NewGuid(),
            UserId = userId,
            CourseId = courseId,
            EnrolledAt = now,
            LastAccessedAt = now,
            ProgressPercentage = 0,
            Status = "ACTIVE",
            SourceType = "ADMIN",
            AccessDurationDays = accessDurationDays,
            AccessExpiresAt = accessExpiresAt
        };
        _context.Enrollments.Add(enrollment);
        await _context.SaveChangesAsync();

        _logger.LogInformation("Admin manually added enrollment: User {UserId} → Course {CourseId}", userId, courseId);

        return new AdminEnrollmentResponse
        {
            Id = enrollment.Id.ToString(), CourseId = course.Id.ToString(),
            CourseTitle = course.Title, CourseThumbnail = course.ThumbnailUrl,
            UserId = userId.ToString(), UserEmail = user.Email, UserFullName = user.FullName,
            EnrolledAt = enrollment.EnrolledAt, ProgressPercentage = 0,
            CompletedAt = null, LastAccessedAt = enrollment.LastAccessedAt,
            AccessDurationDays = enrollment.AccessDurationDays,
            AccessExpiresAt = enrollment.AccessExpiresAt,
            Status = enrollment.Status
        };
    }

    public async Task AdminRemoveEnrollmentAsync(Guid userId, Guid courseId)
    {
        var enrollment = await _context.Enrollments
            .FirstOrDefaultAsync(e => e.UserId == userId && e.CourseId == courseId)
            ?? throw new InvalidOperationException("Enrollment not found");

        _context.Enrollments.Remove(enrollment);
        await _context.SaveChangesAsync();
        _logger.LogInformation("Admin removed enrollment: User {UserId} → Course {CourseId}", userId, courseId);
    }

    public async Task<AdminEnrollmentResponse> AdminSetEnrollmentStatusAsync(Guid enrollmentId, string status)
    {
        if (status != "ACTIVE" && status != "INACTIVE")
            throw new ArgumentException("Status must be ACTIVE or INACTIVE");

        var enrollment = await _context.Enrollments
            .Include(e => e.Course)
            .Include(e => e.User)
            .FirstOrDefaultAsync(e => e.Id == enrollmentId)
            ?? throw new InvalidOperationException("Enrollment not found");

        enrollment.Status = status;
        await _context.SaveChangesAsync();
        _logger.LogInformation("Admin set enrollment {EnrollmentId} status to {Status}", enrollmentId, status);

        return new AdminEnrollmentResponse
        {
            Id = enrollment.Id.ToString(), CourseId = enrollment.CourseId.ToString(),
            CourseTitle = enrollment.Course.Title, CourseThumbnail = enrollment.Course.ThumbnailUrl,
            UserId = enrollment.UserId.ToString(), UserEmail = enrollment.User.Email,
            UserFullName = enrollment.User.FullName,
            EnrolledAt = enrollment.EnrolledAt, ProgressPercentage = enrollment.ProgressPercentage,
            CompletedAt = enrollment.CompletedAt, LastAccessedAt = enrollment.LastAccessedAt,
            AccessDurationDays = enrollment.AccessDurationDays,
            AccessExpiresAt = enrollment.AccessExpiresAt,
            Status = enrollment.Status
        };
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

        var now = DateTime.UtcNow;
        if (enrollment.Status != "ACTIVE")
        {
            throw new UnauthorizedAccessException("Enrollment is inactive");
        }

        if (IsEnrollmentExpired(enrollment, now))
        {
            throw new UnauthorizedAccessException("Enrollment expired");
        }

        var calculation = CalculateEnrollmentProgress(enrollment);

        if (ApplyCalculatedProgress(enrollment, calculation))
        {
            await _context.SaveChangesAsync();
        }

        // Map lesson progress
        var lessonProgressDtos = calculation.AllParts.Select(part =>
        {
            calculation.ProgressByPartId.TryGetValue(part.Id, out var progress);

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
            ProgressPercentage = calculation.ProgressPercentage,
            CompletedParts = calculation.CompletedParts,
            TotalParts = calculation.TotalParts,
            CompletedAt = enrollment.CompletedAt,
            AccessDurationDays = enrollment.AccessDurationDays,
            AccessExpiresAt = enrollment.AccessExpiresAt,
            IsExpired = IsEnrollmentExpired(enrollment, now),
            PartProgress = lessonProgressDtos
        };
    }

    private static bool IsEnrollmentExpired(Enrollment enrollment, DateTime utcNow)
    {
        return enrollment.AccessExpiresAt.HasValue && enrollment.AccessExpiresAt.Value <= utcNow;
    }

    private static bool IsEnrollmentAccessible(Enrollment enrollment, DateTime utcNow)
    {
        return enrollment.Status == "ACTIVE" && !IsEnrollmentExpired(enrollment, utcNow);
    }

    private static int? ResolveAccessDurationDays(int? requestedDurationDays, int? courseDefaultDurationDays)
    {
        if (requestedDurationDays.HasValue)
        {
            if (requestedDurationDays.Value <= 0)
            {
                throw new ArgumentException("Access duration days must be greater than zero");
            }

            return requestedDurationDays.Value;
        }

        return NormalizeDurationDays(courseDefaultDurationDays);
    }

    private static int? NormalizeDurationDays(int? durationDays)
    {
        if (!durationDays.HasValue)
        {
            return null;
        }

        return durationDays.Value > 0 ? durationDays.Value : null;
    }

    private static DateTime? CalculateAccessExpiresAt(DateTime accessStartAtUtc, int? accessDurationDays)
    {
        return accessDurationDays.HasValue
            ? accessStartAtUtc.AddDays(accessDurationDays.Value)
            : null;
    }

    private static EnrollmentProgressCalculation CalculateEnrollmentProgress(Enrollment enrollment)
    {
        var allParts = enrollment.Course.CourseLessons
            .Where(cl => cl.Lesson != null)
            .OrderBy(cl => cl.OrderIndex)
            .SelectMany(cl => cl.Lesson.LessonParts.OrderBy(part => part.OrderIndex))
            .GroupBy(part => part.Id)
            .Select(group => group.First())
            .ToList();

        var currentPartIds = allParts
            .Select(part => part.Id)
            .ToHashSet();

        var progressByPartId = enrollment.LessonProgress
            .Where(lp => currentPartIds.Contains(lp.LessonPartId))
            .GroupBy(lp => lp.LessonPartId)
            .ToDictionary(
                group => group.Key,
                group => group
                    .OrderByDescending(lp => lp.IsCompleted)
                    .ThenByDescending(lp => lp.CompletedAt ?? DateTime.MinValue)
                    .ThenByDescending(lp => lp.LastWatchedAt)
                    .ThenByDescending(lp => lp.WatchedDuration)
                    .First());

        var completedParts = progressByPartId.Values
            .Count(lp => lp.IsCompleted);

        var totalParts = allParts.Count;
        var progressPercentage = totalParts > 0
            ? (int)Math.Floor((completedParts / (double)totalParts) * 100)
            : 0;

        DateTime? completedAt = progressPercentage == 100
            ? enrollment.CompletedAt ?? DateTime.UtcNow
            : null;

        return new EnrollmentProgressCalculation(
            allParts,
            progressByPartId,
            completedParts,
            totalParts,
            progressPercentage,
            completedAt);
    }

    private static bool ApplyCalculatedProgress(Enrollment enrollment, EnrollmentProgressCalculation calculation)
    {
        var isChanged = false;

        if (enrollment.ProgressPercentage != calculation.ProgressPercentage)
        {
            enrollment.ProgressPercentage = calculation.ProgressPercentage;
            isChanged = true;
        }

        if (enrollment.CompletedAt != calculation.CompletedAt)
        {
            enrollment.CompletedAt = calculation.CompletedAt;
            isChanged = true;
        }

        return isChanged;
    }

    private sealed record EnrollmentProgressCalculation(
        List<LessonPart> AllParts,
        Dictionary<Guid, LessonProgress> ProgressByPartId,
        int CompletedParts,
        int TotalParts,
        int ProgressPercentage,
        DateTime? CompletedAt);

    public async Task UpdateLastAccessedAsync(Guid userId, Guid courseId)
    {
        var enrollment = await _context.Enrollments
            .FirstOrDefaultAsync(e => e.UserId == userId && e.CourseId == courseId);

        var now = DateTime.UtcNow;
        if (enrollment != null && IsEnrollmentAccessible(enrollment, now))
        {
            enrollment.LastAccessedAt = now;
            await _context.SaveChangesAsync();
        }
    }
}
