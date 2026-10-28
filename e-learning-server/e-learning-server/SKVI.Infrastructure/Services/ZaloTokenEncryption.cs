using System.Security.Cryptography;
using System.Text;

namespace SKVI.Infrastructure.Services;

public sealed class ZaloTokenEncryption
{
    private readonly byte[] _key;

    public ZaloTokenEncryption(IConfiguration configuration)
    {
        var encodedKey = configuration["ZaloTokenEncryption:Key"];

        if (string.IsNullOrWhiteSpace(encodedKey))
            throw new InvalidOperationException(
                "ZaloTokenEncryption:Key is missing.");

        try
        {
            _key = Convert.FromBase64String(encodedKey);
        }
        catch (FormatException ex)
        {
            throw new InvalidOperationException(
                "ZaloTokenEncryption:Key must be Base64.", ex);
        }

        if (_key.Length != 32)
            throw new InvalidOperationException(
                "ZaloTokenEncryption:Key must contain 32 bytes.");
    }

    public string Encrypt(string plaintext)
    {
        if (string.IsNullOrEmpty(plaintext))
            throw new ArgumentException("Token cannot be empty.");

        byte[] nonce = RandomNumberGenerator.GetBytes(12);
        byte[] tag = new byte[16];
        byte[] plaintextBytes = Encoding.UTF8.GetBytes(plaintext);
        byte[] ciphertext = new byte[plaintextBytes.Length];

        using (var aes = new AesGcm(_key, 16))
        {
            aes.Encrypt(nonce, plaintextBytes, ciphertext, tag);
        }

        byte[] result = new byte[1 + nonce.Length + tag.Length + ciphertext.Length];

        result[0] = 1;

        Buffer.BlockCopy(nonce, 0, result, 1, nonce.Length);
        Buffer.BlockCopy(tag, 0, result, 13, tag.Length);
        Buffer.BlockCopy(ciphertext, 0, result, 29, ciphertext.Length);

        return Convert.ToBase64String(result);
    }

    public string Decrypt(string encryptedToken)
    {
        byte[] data = Convert.FromBase64String(encryptedToken);

        if (data.Length < 30 || data[0] != 1)
            throw new CryptographicException(
                "Invalid encrypted token format.");

        byte[] nonce = data.AsSpan(1, 12).ToArray();
        byte[] tag = data.AsSpan(13, 16).ToArray();
        byte[] ciphertext = data.AsSpan(29).ToArray();
        byte[] plaintext = new byte[ciphertext.Length];

        using (var aes = new AesGcm(_key, 16))
        {
            aes.Decrypt(nonce, ciphertext, tag, plaintext);
        }

        return Encoding.UTF8.GetString(plaintext);
    }
}
