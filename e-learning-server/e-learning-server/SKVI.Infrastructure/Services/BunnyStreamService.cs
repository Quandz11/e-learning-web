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

    public BunnyStreamService(HttpClient httpClient, IOptions<BunnySettings> settings)
    {
        _httpClient = httpClient;
        _settings = settings.Value;

        _httpClient.BaseAddress ??= new Uri("https://video.bunnycdn.com");
        if (!_httpClient.DefaultRequestHeaders.Contains("AccessKey"))
        {
            _httpClient.DefaultRequestHeaders.Add("AccessKey", _settings.ApiKey);
        }
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
        var createResponse = await _httpClient.PostAsJsonAsync($"/library/{_settings.LibraryId}/videos", new { title = normalizedTitle }, cancellationToken);
        createResponse.EnsureSuccessStatusCode();

        var created = await createResponse.Content.ReadFromJsonAsync<BunnyCreateVideoResponse>(cancellationToken: cancellationToken);
        if (created == null || string.IsNullOrWhiteSpace(created.Guid))
        {
            throw new InvalidOperationException("Failed to create video on Bunny");
        }

        var videoId = created.Guid;

        // 2) Upload binary content
        using var content = new StreamContent(fileStream);
        content.Headers.ContentType = new MediaTypeHeaderValue("application/octet-stream");

        var uploadResponse = await _httpClient.PutAsync($"/library/{_settings.LibraryId}/videos/{videoId}", content, cancellationToken);
        uploadResponse.EnsureSuccessStatusCode();

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

    private class BunnyCreateVideoResponse
    {
        public string Guid { get; set; } = string.Empty;
        public int? Length { get; set; }
    }
}
