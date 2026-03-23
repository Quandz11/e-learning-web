using System.Security.Cryptography;
using System.Text;
using Microsoft.Extensions.Options;
using SKVI.Application.Interfaces;

namespace SKVI.Infrastructure.Services;

public class WellnessEncryptionService : IWellnessEncryptionService
{
    private readonly byte[] _key;

    public WellnessEncryptionService(IOptions<WellnessSecuritySettings> settings)
    {
        var configured = settings.Value.EncryptionKey?.Trim() ?? string.Empty;
        if (string.IsNullOrWhiteSpace(configured))
        {
            configured = "wellness-default-dev-key-change-me";
        }

        _key = BuildKey(configured);
    }

    public string Encrypt(string plainText)
    {
        if (string.IsNullOrEmpty(plainText))
        {
            return string.Empty;
        }

        using var aes = Aes.Create();
        aes.Key = _key;
        aes.Mode = CipherMode.CBC;
        aes.Padding = PaddingMode.PKCS7;
        aes.GenerateIV();

        using var encryptor = aes.CreateEncryptor(aes.Key, aes.IV);
        var plainBytes = Encoding.UTF8.GetBytes(plainText);
        var cipherBytes = encryptor.TransformFinalBlock(plainBytes, 0, plainBytes.Length);

        var payload = new byte[aes.IV.Length + cipherBytes.Length];
        Buffer.BlockCopy(aes.IV, 0, payload, 0, aes.IV.Length);
        Buffer.BlockCopy(cipherBytes, 0, payload, aes.IV.Length, cipherBytes.Length);
        return Convert.ToBase64String(payload);
    }

    public string Decrypt(string cipherText)
    {
        if (string.IsNullOrWhiteSpace(cipherText))
        {
            return string.Empty;
        }

        try
        {
            var payload = Convert.FromBase64String(cipherText);
            using var aes = Aes.Create();
            aes.Key = _key;
            aes.Mode = CipherMode.CBC;
            aes.Padding = PaddingMode.PKCS7;

            var iv = new byte[16];
            var cipherBytes = new byte[payload.Length - iv.Length];
            Buffer.BlockCopy(payload, 0, iv, 0, iv.Length);
            Buffer.BlockCopy(payload, iv.Length, cipherBytes, 0, cipherBytes.Length);

            using var decryptor = aes.CreateDecryptor(aes.Key, iv);
            var plainBytes = decryptor.TransformFinalBlock(cipherBytes, 0, cipherBytes.Length);
            return Encoding.UTF8.GetString(plainBytes);
        }
        catch
        {
            return string.Empty;
        }
    }

    private static byte[] BuildKey(string configuredKey)
    {
        try
        {
            var raw = Convert.FromBase64String(configuredKey);
            if (raw.Length == 32)
            {
                return raw;
            }
        }
        catch
        {
            // fall through
        }

        var normalized = configuredKey.Length >= 32
            ? configuredKey[..32]
            : configuredKey.PadRight(32, '0');
        return Encoding.UTF8.GetBytes(normalized);
    }
}

