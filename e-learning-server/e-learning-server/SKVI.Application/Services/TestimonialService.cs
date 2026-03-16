using Microsoft.EntityFrameworkCore;
using SKVI.Application.DTOs.Testimonial;
using SKVI.Application.Interfaces;
using SKVI.Domain.Entities;
using SKVI.Infrastructure;

namespace SKVI.Application.Services;

public class TestimonialService : ITestimonialService
{
    private readonly ApplicationDbContext _context;

    public TestimonialService(ApplicationDbContext context)
    {
        _context = context;
    }

    public async Task<List<TestimonialDto>> GetAllAsync()
    {
        var testimonials = await _context.Testimonials
            .OrderBy(t => t.Order)
            .ThenByDescending(t => t.CreatedAt)
            .ToListAsync();

        return testimonials.Select(MapToDto).ToList();
    }

    public async Task<List<TestimonialDto>> GetActiveAsync()
    {
        var testimonials = await _context.Testimonials
            .Where(t => t.IsActive)
            .OrderBy(t => t.Order)
            .ThenByDescending(t => t.CreatedAt)
            .ToListAsync();

        return testimonials.Select(MapToDto).ToList();
    }

    public async Task<TestimonialDto?> GetByIdAsync(Guid id)
    {
        var testimonial = await _context.Testimonials.FindAsync(id);
        return testimonial == null ? null : MapToDto(testimonial);
    }

    public async Task<TestimonialDto> CreateAsync(CreateTestimonialRequest request)
    {
        var testimonial = new Testimonial
        {
            Id = Guid.NewGuid(),
            Name = request.Name,
            Position = request.Position,
            Content = request.Content,
            AvatarUrl = request.AvatarUrl,
            VideoUrl = request.VideoUrl,
            ResultImageUrl = request.ResultImageUrl,
            Type = request.Type,
            Order = request.Order,
            IsActive = request.IsActive,
            CreatedAt = DateTime.UtcNow
        };

        _context.Testimonials.Add(testimonial);
        await _context.SaveChangesAsync();

        return MapToDto(testimonial);
    }

    public async Task<TestimonialDto> UpdateAsync(Guid id, UpdateTestimonialRequest request)
    {
        var testimonial = await _context.Testimonials.FindAsync(id);
        if (testimonial == null) throw new Exception("Testimonial not found");

        testimonial.Name = request.Name;
        testimonial.Position = request.Position;
        testimonial.Content = request.Content;
        testimonial.AvatarUrl = request.AvatarUrl;
        testimonial.VideoUrl = request.VideoUrl;
        testimonial.ResultImageUrl = request.ResultImageUrl;
        testimonial.Type = request.Type;
        testimonial.Order = request.Order;
        testimonial.IsActive = request.IsActive;

        await _context.SaveChangesAsync();
        return MapToDto(testimonial);
    }

    public async Task<bool> DeleteAsync(Guid id)
    {
        var testimonial = await _context.Testimonials.FindAsync(id);
        if (testimonial == null) return false;

        _context.Testimonials.Remove(testimonial);
        await _context.SaveChangesAsync();
        return true;
    }

    private static TestimonialDto MapToDto(Testimonial testimonial)
    {
        return new TestimonialDto
        {
            Id = testimonial.Id,
            Name = testimonial.Name,
            Position = testimonial.Position,
            Content = testimonial.Content,
            AvatarUrl = testimonial.AvatarUrl,
            VideoUrl = testimonial.VideoUrl,
            ResultImageUrl = testimonial.ResultImageUrl,
            Type = testimonial.Type,
            Order = testimonial.Order,
            IsActive = testimonial.IsActive,
            CreatedAt = testimonial.CreatedAt
        };
    }
}
