using SKVI.Application.DTOs.Courses;

namespace SKVI.Application.Interfaces;

public interface ICourseService
{
    Task<IReadOnlyList<CourseResponse>> GetAllAsync(bool? isPublished, CancellationToken cancellationToken = default);
    Task<CourseResponse> GetByIdAsync(Guid id, CancellationToken cancellationToken = default);
    Task<CourseResponse> CreateAsync(CreateCourseRequest request, CancellationToken cancellationToken = default);
    Task<CourseResponse> UpdateAsync(Guid id, UpdateCourseRequest request, CancellationToken cancellationToken = default);
    Task DeleteAsync(Guid id, CancellationToken cancellationToken = default);
}
