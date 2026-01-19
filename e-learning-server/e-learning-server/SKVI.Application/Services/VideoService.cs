using Microsoft.AspNetCore.Http;
using Microsoft.EntityFrameworkCore;
using SKVI.Application.DTOs.Videos;
using SKVI.Application.Interfaces;
using SKVI.Domain.Entities;
using SKVI.Infrastructure;

namespace SKVI.Application.Services;

public class VideoService : IVideoService
{
    private readonly ApplicationDbContext _dbContext;
    private readonly IBunnyStreamService _bunnyStreamService;

    public VideoService(ApplicationDbContext dbContext, IBunnyStreamService bunnyStreamService)
    {
        _dbContext = dbContext;
        _bunnyStreamService = bunnyStreamService;
    }

    public async Task<VideoUploadResponse> UploadAsync(IFormFile file, string? title, CancellationToken cancellationToken = default)
    {
        if (file == null || file.Length == 0)
        {
            throw new ArgumentException("File is empty", nameof(file));
        }

        await using var stream = file.OpenReadStream();
        var bunnyResult = await _bunnyStreamService.UploadVideoAsync(stream, file.FileName, title, cancellationToken);

        var video = new Video
        {
            Id = Guid.NewGuid(),
            BunnyLibraryId = bunnyResult.LibraryId,
            BunnyVideoId = bunnyResult.BunnyVideoId,
            Duration = bunnyResult.DurationSeconds ?? 0,
            CreatedAt = DateTime.UtcNow
        };

        _dbContext.Videos.Add(video);
        await _dbContext.SaveChangesAsync(cancellationToken);

        return new VideoUploadResponse
        {
            VideoId = video.Id,
            BunnyVideoId = bunnyResult.BunnyVideoId,
            PlaylistUrl = bunnyResult.PlaybackUrl,
            Duration = video.Duration
        };
    }

    public async Task<Video?> GetByIdAsync(Guid id, CancellationToken cancellationToken = default)
    {
        return await _dbContext.Videos.FirstOrDefaultAsync(v => v.Id == id, cancellationToken);
    }

    public string? GetPlaybackUrl(Video? video)
    {
        if (video == null || string.IsNullOrWhiteSpace(video.BunnyVideoId))
        {
            return null;
        }

        return _bunnyStreamService.GetPlaybackUrl(video.BunnyVideoId);
    }
}
