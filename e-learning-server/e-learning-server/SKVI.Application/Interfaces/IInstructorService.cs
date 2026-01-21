using SKVI.Application.DTOs.Instructors;
using SKVI.Shared;

namespace SKVI.Application.Interfaces;

public interface IInstructorService
{
    Task<PagedResult<InstructorDto>> GetPagedAsync(string? search, string? status, int page, int pageSize, CancellationToken cancellationToken = default);
    Task<InstructorDetailDto> GetByIdAsync(Guid id, CancellationToken cancellationToken = default);
    Task<InstructorStatsDto> GetStatsAsync(Guid id, CancellationToken cancellationToken = default);
    Task<IReadOnlyList<InstructorCourseDto>> GetCoursesAsync(Guid id, CancellationToken cancellationToken = default);
    Task<InstructorDto> CreateAsync(CreateInstructorRequest request, CancellationToken cancellationToken = default);
    Task<InstructorDto> UpdateAsync(Guid id, UpdateInstructorRequest request, CancellationToken cancellationToken = default);
    Task DeleteAsync(Guid id, CancellationToken cancellationToken = default);
}
