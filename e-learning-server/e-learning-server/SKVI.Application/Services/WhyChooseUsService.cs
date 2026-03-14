using Microsoft.EntityFrameworkCore;
using SKVI.Application.DTOs.WhyChooseUs;
using SKVI.Application.Interfaces;
using SKVI.Domain.Entities;
using SKVI.Infrastructure;

namespace SKVI.Application.Services;

public class WhyChooseUsService : IWhyChooseUsService
{
    private readonly ApplicationDbContext _context;

    public WhyChooseUsService(ApplicationDbContext context)
    {
        _context = context;
    }

    public async Task<List<WhyChooseUsItemDto>> GetAllAsync()
    {
        var items = await _context.WhyChooseUsItems
            .OrderBy(x => x.Order)
            .ThenByDescending(x => x.CreatedAt)
            .ToListAsync();

        return items.Select(MapToDto).ToList();
    }

    public async Task<List<WhyChooseUsItemDto>> GetActiveAsync()
    {
        var items = await _context.WhyChooseUsItems
            .Where(x => x.IsActive)
            .OrderBy(x => x.Order)
            .ThenByDescending(x => x.CreatedAt)
            .ToListAsync();

        return items.Select(MapToDto).ToList();
    }

    public async Task<WhyChooseUsItemDto?> GetByIdAsync(Guid id)
    {
        var item = await _context.WhyChooseUsItems.FindAsync(id);
        return item == null ? null : MapToDto(item);
    }

    public async Task<WhyChooseUsItemDto> CreateAsync(CreateWhyChooseUsItemRequest request)
    {
        var item = new WhyChooseUsItem
        {
            Id = Guid.NewGuid(),
            Icon = request.Icon,
            Title = request.Title,
            Description = request.Description,
            Order = request.Order,
            IsActive = request.IsActive,
            CreatedAt = DateTime.UtcNow
        };

        _context.WhyChooseUsItems.Add(item);
        await _context.SaveChangesAsync();

        return MapToDto(item);
    }

    public async Task<WhyChooseUsItemDto> UpdateAsync(Guid id, UpdateWhyChooseUsItemRequest request)
    {
        var item = await _context.WhyChooseUsItems.FindAsync(id);
        if (item == null) throw new Exception("WhyChooseUs item not found");

        item.Icon = request.Icon;
        item.Title = request.Title;
        item.Description = request.Description;
        item.Order = request.Order;
        item.IsActive = request.IsActive;

        await _context.SaveChangesAsync();
        return MapToDto(item);
    }

    public async Task<bool> DeleteAsync(Guid id)
    {
        var item = await _context.WhyChooseUsItems.FindAsync(id);
        if (item == null) return false;

        _context.WhyChooseUsItems.Remove(item);
        await _context.SaveChangesAsync();
        return true;
    }

    private static WhyChooseUsItemDto MapToDto(WhyChooseUsItem item)
    {
        return new WhyChooseUsItemDto
        {
            Id = item.Id,
            Icon = item.Icon,
            Title = item.Title,
            Description = item.Description,
            Order = item.Order,
            IsActive = item.IsActive,
            CreatedAt = item.CreatedAt
        };
    }
}
