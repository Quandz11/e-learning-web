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
            Duration = (int)Math.Ceiling((bunnyResult.DurationSeconds ?? 0) / 60.0),
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

    public async Task<string?> GetEmbedUrlAsync(Guid videoId, CancellationToken cancellationToken = default)
    {
        var video = await GetByIdAsync(videoId, cancellationToken);
        if (video == null || string.IsNullOrWhiteSpace(video.BunnyVideoId))
        {
            return null;
        }

        return _bunnyStreamService.GetEmbedUrl(video.BunnyVideoId);
    }
    public async Task<int> SyncDurationAsync(Guid videoId, CancellationToken cancellationToken = default)
    {
        var video = await _dbContext.Videos.FirstOrDefaultAsync(v => v.Id == videoId, cancellationToken);
        if (video == null)
        {
            throw new ArgumentException("Video not found", nameof(videoId));
        }

        if (string.IsNullOrWhiteSpace(video.BunnyVideoId))
        {
            throw new InvalidOperationException("Video does not have a Bunny Video ID");
        }

        var bunnyVideo = await _bunnyStreamService.GetVideoAsync(video.BunnyVideoId, cancellationToken);
        
        // Convert seconds to minutes (rounding up)
        // If duration is 0 (e.g. processing), keep it 0 or wait? Bunny returns 0 if processing.
        // Assuming user wants at least 1 min if valid.
        var durationMinutes = (int)Math.Ceiling(bunnyVideo.Length / 60.0);

        // Update duration if changed
        if (video.Duration != durationMinutes)
        {
            video.Duration = durationMinutes;
            await _dbContext.SaveChangesAsync(cancellationToken);
        }

        return video.Duration;
    }

    public async Task SetThumbnailAsync(Guid videoId, IFormFile file, CancellationToken cancellationToken = default)
    {
        if (file == null || file.Length == 0)
        {
            throw new ArgumentException("File is empty", nameof(file));
        }

        var video = await _dbContext.Videos.FirstOrDefaultAsync(v => v.Id == videoId, cancellationToken);
        if (video == null)
        {
            throw new ArgumentException("Video not found", nameof(videoId));
        }

        if (string.IsNullOrWhiteSpace(video.BunnyVideoId))
        {
            throw new InvalidOperationException("Video does not have a Bunny Video ID");
        }

        await using var stream = file.OpenReadStream();
        await _bunnyStreamService.UploadVideoThumbnailAsync(video.BunnyVideoId, stream, file.FileName, cancellationToken);
    }
}
