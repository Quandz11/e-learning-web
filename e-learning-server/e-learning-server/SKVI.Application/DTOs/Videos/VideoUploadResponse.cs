namespace SKVI.Application.DTOs.Videos;

public class VideoUploadResponse
{
    public Guid VideoId { get; set; }
    public string BunnyVideoId { get; set; } = string.Empty;
    public string PlaylistUrl { get; set; } = string.Empty;
    public int Duration { get; set; }
}
