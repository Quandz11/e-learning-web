using System.Net.Http.Headers;
using System.Net.Http.Json;
using Microsoft.Extensions.Options;
using SKVI.Application.Interfaces;
using SKVI.Infrastructure.VideoStreaming;

namespace SKVI.Infrastructure.Services;

public class BunnyStreamService : IBunnyStreamService
{
    private readonly HttpClient _httpClient;
    private readonly BunnySettings _settings;

    private const string AccessKeyHeader = "AccessKey";

    public BunnyStreamService(HttpClient httpClient, IOptions<BunnySettings> settings)
    {
        _httpClient = httpClient;
        _settings = settings.Value;

        _httpClient.BaseAddress ??= new Uri("https://video.bunnycdn.com");
        _httpClient.DefaultRequestHeaders.Accept.Clear();
        _httpClient.DefaultRequestHeaders.Accept.Add(new MediaTypeWithQualityHeaderValue("application/json"));
    }

    public async Task<BunnyUploadResult> UploadVideoAsync(Stream fileStream, string fileName, string? title, CancellationToken cancellationToken = default)
    {
        if (fileStream == null || fileStream.Length == 0)
        {
            throw new ArgumentException("File stream is empty", nameof(fileStream));
        }

        var normalizedTitle = string.IsNullOrWhiteSpace(title)
            ? Path.GetFileNameWithoutExtension(fileName)
            : title.Trim();

        // 1) Create video entry
        using var createRequest = new HttpRequestMessage(HttpMethod.Post, $"/library/{_settings.LibraryId}/videos")
        {
            Content = JsonContent.Create(new { title = normalizedTitle })
        };

        var createResponse = await SendWithAccessKeyAsync(createRequest, _settings.ApiKey, cancellationToken);

        var created = await createResponse.Content.ReadFromJsonAsync<BunnyCreateVideoResponse>(cancellationToken: cancellationToken);
        if (created == null || string.IsNullOrWhiteSpace(created.Guid))
        {
            throw new InvalidOperationException("Failed to create video on Bunny");
        }

        var videoId = created.Guid;

        // 2) Upload binary content
        using var content = new StreamContent(fileStream);
        content.Headers.ContentType = new MediaTypeHeaderValue("application/octet-stream");

        using var uploadRequest = new HttpRequestMessage(HttpMethod.Put, $"/library/{_settings.LibraryId}/videos/{videoId}")
        {
            Content = content
        };

        var uploadResponse = await SendWithAccessKeyAsync(uploadRequest, _settings.ApiKey, cancellationToken);

        return new BunnyUploadResult
        {
            BunnyVideoId = videoId,
            LibraryId = _settings.LibraryId,
            DurationSeconds = created.Length,
            PlaybackUrl = GetPlaybackUrl(videoId)
        };
    }

    public string GetPlaybackUrl(string bunnyVideoId)
    {
        if (string.IsNullOrWhiteSpace(_settings.CdnBaseUrl))
        {
            throw new InvalidOperationException("Bunny CDN base URL is not configured");
        }

        return $"{_settings.CdnBaseUrl.TrimEnd('/')}/{bunnyVideoId}/playlist.m3u8";
    }

    public string GetEmbedUrl(string bunnyVideoId)
    {
        if (string.IsNullOrWhiteSpace(_settings.LibraryId))
        {
            throw new InvalidOperationException("Bunny Library ID is not configured");
        }

        if (string.IsNullOrWhiteSpace(_settings.VideoTokenKey))
        {
            throw new InvalidOperationException("Bunny Video Token Key is not configured");
        }

        // Generate expiration timestamp (24 hours from now)
        var expirationTimestamp = DateTimeOffset.UtcNow.AddHours(24).ToUnixTimeSeconds();

        // Generate token: SHA256(VideoTokenKey + BunnyVideoId + ExpirationTimestamp)
        var tokenString = $"{_settings.VideoTokenKey}{bunnyVideoId}{expirationTimestamp}";
        var token = ComputeSha256Hash(tokenString);

        // Return signed embed URL with token and expiration
        return $"https://iframe.mediadelivery.net/embed/{_settings.LibraryId}/{bunnyVideoId}?token={token}&expires={expirationTimestamp}";
    }

    private static string ComputeSha256Hash(string input)
    {
        using var sha256 = System.Security.Cryptography.SHA256.Create();
        var bytes = System.Text.Encoding.UTF8.GetBytes(input);
        var hash = sha256.ComputeHash(bytes);
        return Convert.ToHexString(hash).ToLowerInvariant();
    }

    public async Task<string> UploadImageAsync(Stream fileStream, string fileName, CancellationToken cancellationToken = default)
    {
        if (fileStream == null || fileStream.Length == 0)
        {
            throw new ArgumentException("File stream is empty", nameof(fileStream));
        }

        if (string.IsNullOrWhiteSpace(_settings.StorageZoneName) || string.IsNullOrWhiteSpace(_settings.StorageApiKey))
        {
            throw new InvalidOperationException("Bunny storage settings are not configured");
        }

        var safeFileName = $"{Guid.NewGuid():N}{Path.GetExtension(fileName)}";
        var uploadUrl = $"{_settings.StorageBaseUrl.TrimEnd('/')}/{_settings.StorageZoneName}/thumbnails/{safeFileName}";

        using var content = new StreamContent(fileStream);
        content.Headers.ContentType = new MediaTypeHeaderValue("application/octet-stream");

        using var request = new HttpRequestMessage(HttpMethod.Put, uploadUrl)
        {
            Content = content
        };

        var response = await SendWithAccessKeyAsync(request, _settings.StorageApiKey, cancellationToken);

        if (string.IsNullOrWhiteSpace(_settings.StorageCdnBaseUrl))
        {
            throw new InvalidOperationException("Bunny storage CDN base URL is not configured");
        }

        return $"{_settings.StorageCdnBaseUrl.TrimEnd('/')}/thumbnails/{safeFileName}";
    }

    public async Task<string> UploadDocumentAsync(Stream fileStream, string fileName, CancellationToken cancellationToken = default)
    {
        if (fileStream == null || fileStream.Length == 0)
        {
            throw new ArgumentException("File stream is empty", nameof(fileStream));
        }

        if (string.IsNullOrWhiteSpace(_settings.StorageZoneName) || string.IsNullOrWhiteSpace(_settings.StorageApiKey))
        {
            throw new InvalidOperationException("Bunny storage settings are not configured");
        }

        var safeFileName = $"{Guid.NewGuid():N}{Path.GetExtension(fileName)}";
        var documentFolder = string.IsNullOrWhiteSpace(_settings.DocumentFolder) ? "documents" : _settings.DocumentFolder;
        var uploadUrl = $"{_settings.StorageBaseUrl.TrimEnd('/')}/{_settings.StorageZoneName}/{documentFolder}/{safeFileName}";

        using var content = new StreamContent(fileStream);
        content.Headers.ContentType = new MediaTypeHeaderValue("application/pdf");

        using var request = new HttpRequestMessage(HttpMethod.Put, uploadUrl)
        {
            Content = content
        };

        var response = await SendWithAccessKeyAsync(request, _settings.StorageApiKey, cancellationToken);

        if (string.IsNullOrWhiteSpace(_settings.StorageCdnBaseUrl))
        {
            throw new InvalidOperationException("Bunny storage CDN base URL is not configured");
        }

        return $"{_settings.StorageCdnBaseUrl.TrimEnd('/')}/{documentFolder}/{safeFileName}";
    }

    private async Task<HttpResponseMessage> SendWithAccessKeyAsync(HttpRequestMessage request, string apiKey, CancellationToken cancellationToken)
    {
        request.Headers.Remove(AccessKeyHeader);
        request.Headers.Add(AccessKeyHeader, apiKey);

        var response = await _httpClient.SendAsync(request, cancellationToken);
        if (!response.IsSuccessStatusCode)
        {
            var body = await response.Content.ReadAsStringAsync(cancellationToken);
            throw new InvalidOperationException($"Bunny API error ({(int)response.StatusCode}): {body}");
        }

        return response;
    }

    public async Task UploadVideoThumbnailAsync(string bunnyVideoId, Stream fileStream, string fileName, CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(bunnyVideoId))
        {
            throw new ArgumentException("Video id is required", nameof(bunnyVideoId));
        }

        if (fileStream == null || fileStream.Length == 0)
        {
            throw new ArgumentException("File stream is empty", nameof(fileStream));
        }

        using var content = new MultipartFormDataContent();

        var streamContent = new StreamContent(fileStream);
        streamContent.Headers.ContentType = new MediaTypeHeaderValue(GetImageContentType(fileName));

        // Bunny expects multipart key "thumbnail"
        content.Add(streamContent, "thumbnail", fileName);

        using var request = new HttpRequestMessage(HttpMethod.Post, $"/library/{_settings.LibraryId}/videos/{bunnyVideoId}/thumbnail")
        {
            Content = content
        };

        await SendWithAccessKeyAsync(request, _settings.ApiKey, cancellationToken);
    }

    private static string GetImageContentType(string fileName)
    {
        var ext = Path.GetExtension(fileName)?.ToLowerInvariant();
        return ext switch
        {
            ".jpg" or ".jpeg" => "image/jpeg",
            ".png" => "image/png",
            ".webp" => "image/webp",
            ".gif" => "image/gif",
            _ => "application/octet-stream"
        };
    }

    public async Task<BunnyGetVideoResponse> GetVideoAsync(string bunnyVideoId, CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(bunnyVideoId))
        {
            throw new ArgumentException("Video id is required", nameof(bunnyVideoId));
        }

        using var request = new HttpRequestMessage(HttpMethod.Get, $"/library/{_settings.LibraryId}/videos/{bunnyVideoId}");
        var response = await SendWithAccessKeyAsync(request, _settings.ApiKey, cancellationToken);

        var video = await response.Content.ReadFromJsonAsync<BunnyGetVideoResponse>(cancellationToken: cancellationToken);
        if (video == null)
        {
            throw new InvalidOperationException("Failed to retrieve video details from Bunny");
        }

        return video;
    }

    private class BunnyCreateVideoResponse
    {
        public string Guid { get; set; } = string.Empty;
        public int? Length { get; set; }
    }
}
