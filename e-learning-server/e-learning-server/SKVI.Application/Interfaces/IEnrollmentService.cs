using SKVI.Application.DTOs.Enrollment;

namespace SKVI.Application.Interfaces;

public interface IEnrollmentService
{
    Task<EnrollmentResponse> EnrollInCourseAsync(Guid userId, string courseIdStr);
    Task<bool> IsEnrolledAsync(Guid userId, Guid courseId);
    Task<List<EnrollmentResponse>> GetUserEnrollmentsAsync(Guid userId);
    Task<CourseProgressResponse> GetCourseProgressAsync(Guid userId, Guid courseId);
    Task UpdateLastAccessedAsync(Guid userId, Guid courseId);
}

public interface ILessonProgressService
{
    Task UpdateProgressAsync(Guid userId, Guid courseId, Guid lessonId, int watchedDuration);
    Task MarkLessonCompleteAsync(Guid userId, Guid courseId, Guid lessonId);
    Task<LessonProgressDto?> GetLessonProgressAsync(Guid userId, Guid courseId, Guid lessonId);
}
