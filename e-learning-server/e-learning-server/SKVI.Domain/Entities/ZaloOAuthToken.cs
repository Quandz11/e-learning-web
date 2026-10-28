namespace SKVI.Domain.Entities;

public class ZaloOAuthToken
{
    public int Id { get; set; }

    public string AccessTokenEncrypted { get; set; } = string.Empty;
    public string RefreshTokenEncrypted { get; set; } = string.Empty;

    public DateTime? AccessTokenExpiresAtUtc { get; set; }
    public DateTime UpdatedAtUtc { get; set; } = DateTime.UtcNow;

    public byte[] RowVersion { get; set; } = Array.Empty<byte>();
}
