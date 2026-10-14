using System.Security.Cryptography;
using System.Text;

namespace SKVI.Infrastructure.VideoStreaming;

public interface IVideoSecurityService
{
    string GenerateSignedUrl(string videoId, int expirationMinutes = 120);
    string GenerateEmbedUrl(string videoId);
}

public class VideoSecurityService : IVideoSecurityService
{
    private readonly BunnySettings _settings;

    public VideoSecurityService(BunnySettings settings)
    {
        _settings = settings;
    }

    public string GenerateSignedUrl(string videoId, int expirationMinutes = 120)
    {
        var expirationTime = DateTimeOffset.UtcNow.AddMinutes(expirationMinutes).ToUnixTimeSeconds();
        
        // Path to the playlist
        var path = $"/{videoId}/playlist.m3u8";
        
        // Create signature: sha256_hex(token_key + path + expiration)
        var hashInput = $"{_settings.VideoTokenKey}{path}{expirationTime}";
        var hashBytes = SHA256.HashData(Encoding.UTF8.GetBytes(hashInput));
        
        // Convert to hex string (lowercase)
        var signature = BitConverter.ToString(hashBytes).Replace("-", "").ToLower();

        // Generate signed URL
        var playlistUrl = $"{_settings.CdnBaseUrl}{path}?token={signature}&expires={expirationTime}";
        
        return playlistUrl;
    }

    public string GenerateEmbedUrl(string videoId)
    {
        // Generate signed embed URL with token authentication
        // Per Bunny Stream docs: SHA256_HEX(token_security_key + video_id + expiration)
        var expirationTime = DateTimeOffset.UtcNow.AddHours(24).ToUnixTimeSeconds();
        
        // Create hash input: security_key + videoId + expires
        var hashInput = $"{_settings.VideoTokenKey}{videoId}{expirationTime}";
        var hashBytes = SHA256.HashData(Encoding.UTF8.GetBytes(hashInput));
        
        // Convert to hex string (lowercase)
        var signature = BitConverter.ToString(hashBytes).Replace("-", "").ToLower();
        
        // Generate signed embed URL
        return $"https://iframe.mediadelivery.net/embed/{_settings.LibraryId}/{videoId}?token={signature}&expires={expirationTime}";
    }
}
