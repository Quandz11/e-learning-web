using SKVI.Application.DTOs.Lessons;

namespace SKVI.Application.Interfaces;

public interface ILessonService
{
    Task<IReadOnlyList<LessonDto>> GetAllAsync(CancellationToken cancellationToken = default);
    Task<LessonDto> GetByIdAsync(Guid id, CancellationToken cancellationToken = default);
    Task<LessonDto> CreateAsync(CreateLessonRequest request, CancellationToken cancellationToken = default);
    Task<LessonDto> UpdateAsync(Guid id, UpdateLessonRequest request, CancellationToken cancellationToken = default);
    Task DeleteAsync(Guid id, CancellationToken cancellationToken = default);
    
    // Part Management
    Task<LessonDto> AddPartAsync(Guid lessonId, CreateLessonPartRequest request, CancellationToken cancellationToken = default);
    Task<LessonDto> UpdatePartAsync(Guid lessonId, Guid partId, UpdateLessonPartRequest request, CancellationToken cancellationToken = default);
    Task<LessonDto> DeletePartAsync(Guid lessonId, Guid partId, CancellationToken cancellationToken = default);
    Task<LessonDto> ReorderPartsAsync(Guid lessonId, List<Guid> partIds, CancellationToken cancellationToken = default);
}
