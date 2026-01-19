namespace SKVI.Infrastructure.VideoStreaming;

public class BunnySettings
{
    public string LibraryId { get; set; } = string.Empty;
    public string ApiKey { get; set; } = string.Empty;
    public string CdnBaseUrl { get; set; } = string.Empty;
    public string StorageZoneName { get; set; } = string.Empty;
    public string StorageApiKey { get; set; } = string.Empty;
    public string StorageBaseUrl { get; set; } = "https://storage.bunnycdn.com";
    public string StorageCdnBaseUrl { get; set; } = string.Empty;
}
