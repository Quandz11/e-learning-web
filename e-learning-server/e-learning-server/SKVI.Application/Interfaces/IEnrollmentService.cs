using SKVI.Application.DTOs.Enrollment;

namespace SKVI.Application.Interfaces;

public interface IEnrollmentService
{
    Task<EnrollmentResponse> EnrollInCourseAsync(Guid userId, string courseIdStr);
    Task<bool> IsEnrolledAsync(Guid userId, Guid courseId);
    Task<List<EnrollmentResponse>> GetUserEnrollmentsAsync(Guid userId);
    Task<CourseProgressResponse> GetCourseProgressAsync(Guid userId, Guid courseId);
    Task UpdateLastAccessedAsync(Guid userId, Guid courseId);

    // Admin methods
    Task<List<AdminEnrollmentResponse>> AdminGetUserEnrollmentsAsync(Guid userId);
    Task<AdminEnrollmentResponse> AdminAddEnrollmentAsync(Guid userId, AdminAddEnrollmentRequest request);
    Task AdminRemoveEnrollmentAsync(Guid userId, Guid courseId);
    Task<AdminEnrollmentResponse> AdminSetEnrollmentStatusAsync(Guid enrollmentId, string status);
}

public interface ILessonProgressService
{
    Task UpdateProgressAsync(Guid userId, Guid courseId, Guid lessonId, int watchedDuration);
    Task MarkLessonCompleteAsync(Guid userId, Guid courseId, Guid lessonId);
    Task<LessonProgressDto?> GetLessonProgressAsync(Guid userId, Guid courseId, Guid lessonId);
}
