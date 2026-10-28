using Microsoft.EntityFrameworkCore.Storage;
using System.Data;
using System.Data.Common;
using System.Text.Json;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Options;
using SKVI.Domain.Entities;

namespace SKVI.Infrastructure.Services;

public sealed class ZaloTokenManager
{
    private readonly ApplicationDbContext _db;
    private readonly ZaloTokenEncryption _encryption;
    private readonly ZaloOtpSettings _settings;
    private readonly HttpClient _httpClient;
    private readonly ILogger<ZaloTokenManager> _logger;

    public ZaloTokenManager(
        ApplicationDbContext db,
        ZaloTokenEncryption encryption,
        IOptions<ZaloOtpSettings> settings,
        HttpClient httpClient,
        ILogger<ZaloTokenManager> logger)
    {
        _db = db;
        _encryption = encryption;
        _settings = settings.Value;
        _httpClient = httpClient;
        _logger = logger;
    }

    public async Task<string> GetAccessTokenAsync(
        bool forceRefresh = false,
        string? previouslyUsedToken = null,
        CancellationToken cancellationToken = default)
    {
        // Transaction-level SQL lock protects token rotation
        // across multiple API instances sharing the same database.
        await using var transaction = await _db.Database
            .BeginTransactionAsync(cancellationToken);

        await AcquireLockAsync(cancellationToken);

        var token = await _db.ZaloOAuthTokens
            .SingleOrDefaultAsync(cancellationToken);

        if (token == null)
        {
            if (string.IsNullOrWhiteSpace(_settings.AccessToken) ||
                string.IsNullOrWhiteSpace(_settings.RefreshToken))
            {
                throw new InvalidOperationException(
                    "Zalo OAuth tokens are not initialized.");
            }

            token = new ZaloOAuthToken
            {

                AccessTokenEncrypted = _encryption.Encrypt(
                    _settings.AccessToken.Trim()),
                RefreshTokenEncrypted = _encryption.Encrypt(
                    _settings.RefreshToken.Trim()),
                AccessTokenExpiresAtUtc =
                    _settings.AccessTokenExpiresInSeconds > 0
                        ? DateTime.UtcNow.AddSeconds(
                            _settings.AccessTokenExpiresInSeconds)
                        : null,
                UpdatedAtUtc = DateTime.UtcNow
            };

            _db.ZaloOAuthTokens.Add(token);
            await _db.SaveChangesAsync(cancellationToken);

            _logger.LogInformation(
                "Initial Zalo OAuth tokens stored in database.");
        }

        var currentAccessToken = _encryption.Decrypt(
            token.AccessTokenEncrypted);

        var expiresSoon =
            (!token.AccessTokenExpiresAtUtc.HasValue ||
            token.AccessTokenExpiresAtUtc.Value <=
                DateTime.UtcNow.AddSeconds(
                    Math.Max(0, _settings.RefreshBufferSeconds)));

        // Another instance may already have refreshed the token.
        var anotherInstanceRefreshed =
            forceRefresh &&
            previouslyUsedToken != null &&
            !string.Equals(
                currentAccessToken,
                previouslyUsedToken,
                StringComparison.Ordinal);

        var shouldRefresh =
            !anotherInstanceRefreshed &&
            (expiresSoon || forceRefresh);

        if (shouldRefresh)
        {
            var refreshToken = _encryption.Decrypt(
                token.RefreshTokenEncrypted);

            var refreshed = await RefreshFromZaloAsync(
                refreshToken, cancellationToken);

            // Do not replace the stored refresh token unless
            // Zalo returned a complete valid token pair.
            token.AccessTokenEncrypted =
                _encryption.Encrypt(refreshed.AccessToken);

            token.RefreshTokenEncrypted =
                _encryption.Encrypt(refreshed.RefreshToken);

            token.AccessTokenExpiresAtUtc =
                refreshed.ExpiresInSeconds > 0
                    ? DateTime.UtcNow.AddSeconds(
                        refreshed.ExpiresInSeconds)
                    : null;

            token.UpdatedAtUtc = DateTime.UtcNow;

            await _db.SaveChangesAsync(cancellationToken);

            currentAccessToken = refreshed.AccessToken;

            _logger.LogInformation(
                "Zalo OAuth tokens refreshed and saved.");
        }

        await transaction.CommitAsync(cancellationToken);

        return currentAccessToken;
    }

    private async Task AcquireLockAsync(
        CancellationToken cancellationToken)
    {
        var connection = _db.Database.GetDbConnection();

        await using var command = connection.CreateCommand();
        command.Transaction =
            _db.Database.CurrentTransaction!.GetDbTransaction();

        command.CommandText = """
            DECLARE @result int;

            EXEC @result = sp_getapplock
                @Resource = N'SKVI_ZALO_OAUTH_TOKEN_REFRESH',
                @LockMode = 'Exclusive',
                @LockOwner = 'Transaction',
                @LockTimeout = 30000;

            SELECT @result;
            """;

        var result = await command.ExecuteScalarAsync(
            cancellationToken);

        if (result == null || Convert.ToInt32(result) < 0)
        {
            throw new InvalidOperationException(
                "Unable to acquire Zalo OAuth SQL lock.");
        }
    }

    private async Task<RefreshResult> RefreshFromZaloAsync(
        string refreshToken,
        CancellationToken cancellationToken)
    {
        if (string.IsNullOrWhiteSpace(_settings.AppId) ||
            string.IsNullOrWhiteSpace(_settings.AppSecret))
        {
            throw new InvalidOperationException(
                "Zalo AppId or AppSecret is missing.");
        }

        var baseUrl = _settings.TokenApiBaseUrl.TrimEnd('/');
        var path = "/" + _settings.RefreshPath.TrimStart('/');

        using var request = new HttpRequestMessage(
            HttpMethod.Post, baseUrl + path);

        request.Headers.TryAddWithoutValidation(
            "secret_key", _settings.AppSecret.Trim());

        request.Content = new FormUrlEncodedContent(
            new Dictionary<string, string>
            {
                ["app_id"] = _settings.AppId.Trim(),
                ["grant_type"] = "refresh_token",
                ["refresh_token"] = refreshToken
            });

        using var response = await _httpClient.SendAsync(
            request, cancellationToken);

        var body = await response.Content.ReadAsStringAsync(
            cancellationToken);

        if (!response.IsSuccessStatusCode)
        {
            _logger.LogError(
                "Zalo OAuth refresh failed. HTTP={Status}",
                (int)response.StatusCode);

            throw new InvalidOperationException(
                "Zalo OAuth refresh HTTP request failed.");
        }

        using var document = JsonDocument.Parse(body);
        var root = document.RootElement;

        var error = ReadInt(root, "error") ??
                    ReadInt(root, "error_code") ?? 0;

        if (error != 0)
        {
            _logger.LogError(
                "Zalo OAuth refresh returned error {Error}",
                error);

            throw new InvalidOperationException(
                $"Zalo OAuth refresh error: {error}");
        }

        var data = root;

        if (root.TryGetProperty("data", out var nested) &&
            nested.ValueKind == JsonValueKind.Object)
        {
            data = nested;
        }

        var accessToken = ReadString(data, "access_token");
        var newRefreshToken = ReadString(data, "refresh_token");

        var expiresIn = ReadInt(data, "expires_in") ?? 0;

        if (string.IsNullOrWhiteSpace(accessToken) ||
            string.IsNullOrWhiteSpace(newRefreshToken) ||
            expiresIn <= 0)
        {
            throw new InvalidOperationException(
                "Zalo refresh response is missing token fields.");
        }

        return new RefreshResult(
            accessToken, newRefreshToken, expiresIn);
    }

    private static string? ReadString(
        JsonElement element, string name)
    {
        if (element.ValueKind != JsonValueKind.Object ||
            !element.TryGetProperty(name, out var value))
            return null;

        return value.ValueKind == JsonValueKind.String
            ? value.GetString()
            : null;
    }

    private static int? ReadInt(
        JsonElement element, string name)
    {
        if (element.ValueKind != JsonValueKind.Object ||
            !element.TryGetProperty(name, out var value))
            return null;

        if (value.ValueKind == JsonValueKind.Number &&
            value.TryGetInt32(out var number))
            return number;

        if (value.ValueKind == JsonValueKind.String &&
            int.TryParse(value.GetString(), out var parsed))
            return parsed;

        return null;
    }

    private sealed record RefreshResult(
        string AccessToken,
        string RefreshToken,
        int ExpiresInSeconds);
}
