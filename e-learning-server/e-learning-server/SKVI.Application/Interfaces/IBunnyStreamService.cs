namespace SKVI.Application.Interfaces;

public interface IBunnyStreamService
{
    Task<BunnyUploadResult> UploadVideoAsync(Stream fileStream, string fileName, string? title, CancellationToken cancellationToken = default);
    string GetPlaybackUrl(string bunnyVideoId);
}

public class BunnyUploadResult
{
    public string BunnyVideoId { get; set; } = string.Empty;
    public string LibraryId { get; set; } = string.Empty;
    public int? DurationSeconds { get; set; }
    public string PlaybackUrl { get; set; } = string.Empty;
}
