using Microsoft.EntityFrameworkCore;
using SKVI.Application.DTOs.Lessons;
using SKVI.Application.Interfaces;
using SKVI.Domain.Entities;
using SKVI.Infrastructure;

namespace SKVI.Application.Services;

public class LessonService : ILessonService
{
    private readonly ApplicationDbContext _context;
    private readonly IBunnyStreamService _bunnyStreamService;

    public LessonService(ApplicationDbContext context, IBunnyStreamService bunnyStreamService)
    {
        _context = context;
        _bunnyStreamService = bunnyStreamService;
    }

    public async Task<IReadOnlyList<LessonDto>> GetAllAsync(CancellationToken cancellationToken = default)
    {
        var lessons = await _context.Lessons
            .Include(l => l.Category)
            .Include(l => l.LessonParts)
                .ThenInclude(p => p.Video)
            .Include(l => l.LessonParts)
                .ThenInclude(p => p.Document)
            .OrderByDescending(l => l.CreatedAt)
            .AsNoTracking()
            .ToListAsync(cancellationToken);

        return lessons.Select(MapToDto).ToList();
    }

    public async Task<LessonDto> GetByIdAsync(Guid id, CancellationToken cancellationToken = default)
    {
        var lesson = await _context.Lessons
            .Include(l => l.Category)
            .Include(l => l.LessonParts)
                .ThenInclude(p => p.Video)
            .Include(l => l.LessonParts)
                .ThenInclude(p => p.Document)
            .AsNoTracking()
            .FirstOrDefaultAsync(l => l.Id == id, cancellationToken);

        if (lesson == null)
        {
            throw new KeyNotFoundException("Lesson not found");
        }

        return MapToDto(lesson);
    }

    public async Task<LessonDto> CreateAsync(CreateLessonRequest request, CancellationToken cancellationToken = default)
    {
        var lesson = new Lesson
        {
            Id = Guid.NewGuid(),
            Title = request.Title,
            Description = request.Description,
            ThumbnailUrl = request.ThumbnailUrl,
            CategoryId = request.CategoryId,
            CreatedAt = DateTime.UtcNow
        };

        _context.Lessons.Add(lesson);
        await _context.SaveChangesAsync(cancellationToken);

        return MapToDto(lesson);
    }

    public async Task<LessonDto> UpdateAsync(Guid id, UpdateLessonRequest request, CancellationToken cancellationToken = default)
    {
        var lesson = await _context.Lessons.FirstOrDefaultAsync(l => l.Id == id, cancellationToken);
        
        if (lesson == null)
        {
            throw new KeyNotFoundException("Lesson not found");
        }

        lesson.Title = request.Title;
        lesson.Description = request.Description;
        lesson.ThumbnailUrl = request.ThumbnailUrl;
        lesson.CategoryId = request.CategoryId;
        lesson.UpdatedAt = DateTime.UtcNow;

        await _context.SaveChangesAsync(cancellationToken);
        
        // Reload to get parts for DTO
        return await GetByIdAsync(id, cancellationToken);
    }

    public async Task DeleteAsync(Guid id, CancellationToken cancellationToken = default)
    {
        var lesson = await _context.Lessons
            .Include(l => l.LessonParts)
            .FirstOrDefaultAsync(l => l.Id == id, cancellationToken);
        
        if (lesson == null)
        {
            throw new KeyNotFoundException("Lesson not found");
        }

        var lessonPartIds = lesson.LessonParts.Select(part => part.Id).ToList();
        if (lessonPartIds.Count > 0)
        {
            var tasksUsingParts = await _context.DailyStudyTasks
                .Where(task => task.RelatedLessonPartId.HasValue && lessonPartIds.Contains(task.RelatedLessonPartId.Value))
                .ToListAsync(cancellationToken);

            foreach (var task in tasksUsingParts)
            {
                task.RelatedLessonPartId = null;
            }

            if (tasksUsingParts.Count > 0)
            {
                await _context.SaveChangesAsync(cancellationToken);
            }
        }

        _context.Lessons.Remove(lesson);
        await _context.SaveChangesAsync(cancellationToken);
    }

    public async Task<LessonDto> AddPartAsync(Guid lessonId, CreateLessonPartRequest request, CancellationToken cancellationToken = default)
    {
        var lesson = await _context.Lessons.FirstOrDefaultAsync(l => l.Id == lessonId, cancellationToken);
        if (lesson == null) throw new KeyNotFoundException("Lesson not found");

        var part = new LessonPart
        {
            Id = Guid.NewGuid(),
            LessonId = lessonId,
            Title = request.Title,
            Type = request.Type,
            OrderIndex = request.OrderIndex,
            IsPreview = request.IsPreview,
            VideoId = request.VideoId,
            DocumentId = request.DocumentId,
            Content = request.Content
        };

        _context.LessonParts.Add(part);
        await _context.SaveChangesAsync(cancellationToken);

        return await GetByIdAsync(lessonId, cancellationToken);
    }

    public async Task<LessonDto> UpdatePartAsync(Guid lessonId, Guid partId, UpdateLessonPartRequest request, CancellationToken cancellationToken = default)
    {
        var part = await _context.LessonParts.FirstOrDefaultAsync(p => p.Id == partId && p.LessonId == lessonId, cancellationToken);
        if (part == null) throw new KeyNotFoundException("Lesson part not found");

        part.Title = request.Title;
        part.Type = request.Type;
        part.OrderIndex = request.OrderIndex;
        part.IsPreview = request.IsPreview;
        part.VideoId = request.VideoId;
        part.DocumentId = request.DocumentId;
        part.Content = request.Content;

        await _context.SaveChangesAsync(cancellationToken);

        return await GetByIdAsync(lessonId, cancellationToken);
    }

    public async Task<LessonDto> DeletePartAsync(Guid lessonId, Guid partId, CancellationToken cancellationToken = default)
    {
        var part = await _context.LessonParts.FirstOrDefaultAsync(p => p.Id == partId && p.LessonId == lessonId, cancellationToken);
        if (part == null) throw new KeyNotFoundException("Lesson part not found");

        var tasksUsingPart = await _context.DailyStudyTasks
            .Where(task => task.RelatedLessonPartId == partId)
            .ToListAsync(cancellationToken);

        foreach (var task in tasksUsingPart)
        {
            task.RelatedLessonPartId = null;
        }

        if (tasksUsingPart.Count > 0)
        {
            await _context.SaveChangesAsync(cancellationToken);
        }

        _context.LessonParts.Remove(part);
        await _context.SaveChangesAsync(cancellationToken);

        return await GetByIdAsync(lessonId, cancellationToken);
    }

    public async Task<LessonDto> ReorderPartsAsync(Guid lessonId, List<Guid> partIds, CancellationToken cancellationToken = default)
    {
        var parts = await _context.LessonParts.Where(p => p.LessonId == lessonId).ToListAsync(cancellationToken);
        
        for (int i = 0; i < partIds.Count; i++)
        {
            var part = parts.FirstOrDefault(p => p.Id == partIds[i]);
            if (part != null)
            {
                part.OrderIndex = i;
            }
        }

        await _context.SaveChangesAsync(cancellationToken);
        return await GetByIdAsync(lessonId, cancellationToken);
    }

    private LessonDto MapToDto(Lesson lesson)
    {
        var dto = new LessonDto
        {
            Id = lesson.Id,
            Title = lesson.Title,
            Description = lesson.Description,
            ThumbnailUrl = lesson.ThumbnailUrl,
            CategoryId = lesson.CategoryId,
            CategoryName = lesson.Category?.Name,
            CreatedAt = lesson.CreatedAt,
            UpdatedAt = lesson.UpdatedAt,
            Parts = new List<LessonPartDto>()
        };

        if (lesson.LessonParts != null)
        {
            foreach (var part in lesson.LessonParts.OrderBy(p => p.OrderIndex))
            {
                var playbackUrl = part.Video != null && !string.IsNullOrWhiteSpace(part.Video.BunnyVideoId)
                     ? _bunnyStreamService.GetPlaybackUrl(part.Video.BunnyVideoId)
                     : null;

                dto.Parts.Add(new LessonPartDto
                {
                    Id = part.Id,
                    Title = part.Title,
                    Type = part.Type,
                    OrderIndex = part.OrderIndex,
                    IsPreview = part.IsPreview,
                    VideoId = part.VideoId,
                    VideoDuration = part.Video?.Duration ?? 0,
                    PlaybackUrl = playbackUrl,
                    DocumentId = part.DocumentId,
                    DocumentUrl = part.Document?.BunnyStoragePath,
                    Content = part.Content
                });
            }
        }

        return dto;
    }
}
