using Microsoft.EntityFrameworkCore;
using SKVI.Application.DTOs.Home;
using SKVI.Application.Interfaces;
using SKVI.Domain.Entities;
using SKVI.Infrastructure;

namespace SKVI.Application.Services;

public class HomeVideoSectionService : IHomeVideoSectionService
{
    private readonly ApplicationDbContext _context;

    public HomeVideoSectionService(ApplicationDbContext context)
    {
        _context = context;
    }

    public async Task<HomeVideoSectionDto?> GetHomeVideoSectionAsync()
    {
        return await _context.HomeVideoSections
            .Include(h => h.Video)
            .Select(h => new HomeVideoSectionDto
            {
                Id = h.Id,
                ContentHtml = h.ContentHtml,
                VideoType = h.VideoType,
                VideoId = h.VideoId,
                BunnyVideoId = h.Video != null ? h.Video.BunnyVideoId : null,
                VideoUrl = h.VideoUrl,
                UpdatedAt = h.UpdatedAt
            })
            .FirstOrDefaultAsync();
    }

    public async Task<HomeVideoSectionDto> UpdateHomeVideoSectionAsync(UpdateHomeVideoSectionDto dto)
    {
        var section = await _context.HomeVideoSections.FirstOrDefaultAsync();

        if (section == null)
        {
            section = new HomeVideoSection
            {
                Id = Guid.NewGuid(),
                ContentHtml = dto.ContentHtml,
                VideoType = dto.VideoType,
                VideoId = dto.VideoId,
                VideoUrl = dto.VideoUrl,
                UpdatedAt = DateTime.UtcNow
            };
            _context.HomeVideoSections.Add(section);
        }
        else
        {
            section.ContentHtml = dto.ContentHtml;
            section.VideoType = dto.VideoType;
            section.VideoId = dto.VideoId;
            section.VideoUrl = dto.VideoUrl;
            section.UpdatedAt = DateTime.UtcNow;
        }

        await _context.SaveChangesAsync();

        return (await GetHomeVideoSectionAsync())!;
    }
}
