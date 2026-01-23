namespace SKVI.Application.Interfaces;

public interface IBunnyStreamService
{
    Task<BunnyUploadResult> UploadVideoAsync(Stream fileStream, string fileName, string? title, CancellationToken cancellationToken = default);
    string GetPlaybackUrl(string bunnyVideoId);
    string GetEmbedUrl(string bunnyVideoId);
    Task<string> UploadImageAsync(Stream fileStream, string fileName, CancellationToken cancellationToken = default);
    Task UploadVideoThumbnailAsync(string bunnyVideoId, Stream fileStream, string fileName, CancellationToken cancellationToken = default);

    Task<BunnyGetVideoResponse> GetVideoAsync(string bunnyVideoId, CancellationToken cancellationToken = default);
}

public class BunnyGetVideoResponse
{
    public string Guid { get; set; } = string.Empty;
    public int Length { get; set; }
    public string Title { get; set; } = string.Empty;
}

public class BunnyUploadResult
{
    public string BunnyVideoId { get; set; } = string.Empty;
    public string LibraryId { get; set; } = string.Empty;
    public int? DurationSeconds { get; set; }
    public string PlaybackUrl { get; set; } = string.Empty;
}
