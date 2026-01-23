using Microsoft.AspNetCore.Http;
using SKVI.Application.DTOs.Videos;
using SKVI.Domain.Entities;

namespace SKVI.Application.Interfaces;

public interface IVideoService
{
    Task<VideoUploadResponse> UploadAsync(IFormFile file, string? title, CancellationToken cancellationToken = default);
    Task<Video?> GetByIdAsync(Guid id, CancellationToken cancellationToken = default);
    string? GetPlaybackUrl(Video? video);
    Task<string?> GetEmbedUrlAsync(Guid videoId, CancellationToken cancellationToken = default);
    Task<int> SyncDurationAsync(Guid videoId, CancellationToken cancellationToken = default);
    Task SetThumbnailAsync(Guid videoId, IFormFile file, CancellationToken cancellationToken = default);
}
