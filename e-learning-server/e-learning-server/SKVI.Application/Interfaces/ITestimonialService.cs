using SKVI.Application.DTOs.Testimonial;

namespace SKVI.Application.Interfaces;

public interface ITestimonialService
{
    Task<List<TestimonialDto>> GetAllAsync();
    Task<List<TestimonialDto>> GetActiveAsync();
    Task<TestimonialDto?> GetByIdAsync(Guid id);
    Task<TestimonialDto> CreateAsync(CreateTestimonialRequest request);
    Task<TestimonialDto> UpdateAsync(Guid id, UpdateTestimonialRequest request);
    Task<bool> DeleteAsync(Guid id);
}
