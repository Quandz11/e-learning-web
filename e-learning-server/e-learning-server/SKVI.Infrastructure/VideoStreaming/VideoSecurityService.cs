using System.Security.Cryptography;
using System.Text;

namespace SKVI.Infrastructure.VideoStreaming;

public interface IVideoSecurityService
{
    string GenerateSignedUrl(string videoId, int expirationMinutes = 30);
    string GenerateEmbedUrl(string videoId);
}

public class VideoSecurityService : IVideoSecurityService
{
    private readonly BunnySettings _settings;

    public VideoSecurityService(BunnySettings settings)
    {
        _settings = settings;
    }

    public string GenerateSignedUrl(string videoId, int expirationMinutes = 30)
    {
        var expirationTime = DateTimeOffset.UtcNow.AddMinutes(expirationMinutes).ToUnixTimeSeconds();
        var tokenPath = $"/{videoId}/";
        
        // Create signature: base64(sha256(token_security_key + tokenPath + expirationTime))
        var signatureData = $"{_settings.VideoTokenKey}{tokenPath}{expirationTime}";
        var signature = ComputeSha256Hash(signatureData);
        var base64Signature = Convert.ToBase64String(Encoding.UTF8.GetBytes(signature))
            .Replace("\n", "")
            .Replace("+", "-")
            .Replace("/", "_")
            .Replace("=", "");

        // Generate signed URL
        var playlistUrl = $"{_settings.CdnBaseUrl}/bcdn_token={base64Signature}&expires={expirationTime}&token_path={Uri.EscapeDataString(tokenPath)}/{videoId}/playlist.m3u8";
        
        return playlistUrl;
    }

    public string GenerateEmbedUrl(string videoId)
    {
        // Bunny.net player embed URL doesn't need signing
        return $"https://iframe.mediadelivery.net/embed/{_settings.LibraryId}/{videoId}";
    }

    private string ComputeSha256Hash(string rawData)
    {
        using (SHA256 sha256Hash = SHA256.Create())
        {
            byte[] bytes = sha256Hash.ComputeHash(Encoding.UTF8.GetBytes(rawData));
            StringBuilder builder = new StringBuilder();
            for (int i = 0; i < bytes.Length; i++)
            {
                builder.Append(bytes[i].ToString("x2"));
            }
            return builder.ToString();
        }
    }
}
