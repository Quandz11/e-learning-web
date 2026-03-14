using SKVI.Application.DTOs.WhyChooseUs;

namespace SKVI.Application.Interfaces;

public interface IWhyChooseUsService
{
    Task<List<WhyChooseUsItemDto>> GetAllAsync();
    Task<List<WhyChooseUsItemDto>> GetActiveAsync();
    Task<WhyChooseUsItemDto?> GetByIdAsync(Guid id);
    Task<WhyChooseUsItemDto> CreateAsync(CreateWhyChooseUsItemRequest request);
    Task<WhyChooseUsItemDto> UpdateAsync(Guid id, UpdateWhyChooseUsItemRequest request);
    Task<bool> DeleteAsync(Guid id);
}
