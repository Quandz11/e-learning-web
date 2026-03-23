using System.Globalization;
using System.Net;
using System.Net.Http.Json;
using System.Security.Cryptography;
using System.Text;
using System.Text.Json;
using Microsoft.Extensions.Options;
using SKVI.Application.Interfaces;

namespace SKVI.Infrastructure.Services;

public class ZaloOtpService : IPhoneOtpSender
{
    private static readonly SemaphoreSlim RefreshLock = new(1, 1);
    private static bool _tokenStateInitialized;
    private static string _runtimeAccessToken = string.Empty;
    private static string _runtimeRefreshToken = string.Empty;
    private static DateTime? _accessTokenExpiresAtUtc;

    private readonly HttpClient _httpClient;
    private readonly ZaloOtpSettings _settings;
    private readonly ILogger<ZaloOtpService> _logger;

    public ZaloOtpService(
        HttpClient httpClient,
        IOptions<ZaloOtpSettings> settings,
        ILogger<ZaloOtpService> logger
    )
    {
        _httpClient = httpClient;
        _settings = settings.Value;
        _logger = logger;
    }

    public async Task SendOtpAsync(
        string normalizedPhone,
        string otpCode,
        string purpose,
        string trackingId,
        CancellationToken cancellationToken = default
    )
    {
        if (!_settings.Enabled)
        {
            _logger.LogInformation(
                "Zalo OTP disabled. OTP for {Phone} ({Purpose}) generated but not sent.",
                normalizedPhone,
                purpose
            );
            return;
        }

        if (string.IsNullOrWhiteSpace(_settings.TemplateId))
        {
            throw new InvalidOperationException("ZaloOtpSettings.TemplateId is missing.");
        }

        var payload = BuildPayload(normalizedPhone, otpCode, purpose, trackingId);
        var path = _settings.UseHashPhone ? "/message/template/hashphone" : "/message/template";

        var accessToken = await GetAccessTokenAsync(forceRefresh: false, cancellationToken);
        var (statusCode, rawResponse) = await SendTemplateRequestAsync(path, payload, accessToken, cancellationToken);

        if ((statusCode == HttpStatusCode.Unauthorized || statusCode == HttpStatusCode.Forbidden) && CanRefreshToken())
        {
            _logger.LogWarning("Zalo OTP request rejected with {StatusCode}. Attempting token refresh.", (int)statusCode);
            accessToken = await GetAccessTokenAsync(forceRefresh: true, cancellationToken);
            (statusCode, rawResponse) = await SendTemplateRequestAsync(path, payload, accessToken, cancellationToken);
        }

        if (statusCode != HttpStatusCode.OK)
        {
            _logger.LogError(
                "Zalo OTP HTTP error. Status={StatusCode}. Body={Body}",
                (int)statusCode,
                rawResponse
            );
            throw new InvalidOperationException("Không thể gửi OTP qua Zalo ở thời điểm hiện tại.");
        }

        var (errorCode, message) = ParseResponse(rawResponse);
        if (errorCode != 0)
        {
            _logger.LogError(
                "Zalo OTP API returned error. Error={ErrorCode}, Message={Message}, Body={Body}",
                errorCode,
                message,
                rawResponse
            );
            throw new InvalidOperationException(message ?? "Gửi OTP qua Zalo thất bại.");
        }
    }

    private async Task<(HttpStatusCode StatusCode, string RawResponse)> SendTemplateRequestAsync(
        string path,
        object payload,
        string accessToken,
        CancellationToken cancellationToken
    )
    {
        using var request = new HttpRequestMessage(HttpMethod.Post, path)
        {
            Content = JsonContent.Create(payload)
        };
        request.Headers.Add("access_token", accessToken);

        using var response = await _httpClient.SendAsync(request, cancellationToken);
        var rawResponse = await response.Content.ReadAsStringAsync(cancellationToken);
        return (response.StatusCode, rawResponse);
    }

    private async Task<string> GetAccessTokenAsync(bool forceRefresh, CancellationToken cancellationToken)
    {
        EnsureTokenStateInitialized();

        if (!forceRefresh && !ShouldRefreshAccessTokenSoon() && !string.IsNullOrWhiteSpace(_runtimeAccessToken))
        {
            return _runtimeAccessToken;
        }

        if (!CanRefreshToken())
        {
            if (!string.IsNullOrWhiteSpace(_runtimeAccessToken))
            {
                return _runtimeAccessToken;
            }

            throw new InvalidOperationException("ZaloOtpSettings.AccessToken is missing.");
        }

        await RefreshLock.WaitAsync(cancellationToken);
        try
        {
            EnsureTokenStateInitialized();

            if (!forceRefresh && !ShouldRefreshAccessTokenSoon() && !string.IsNullOrWhiteSpace(_runtimeAccessToken))
            {
                return _runtimeAccessToken;
            }

            await RefreshAccessTokenAsync(cancellationToken);

            if (string.IsNullOrWhiteSpace(_runtimeAccessToken))
            {
                throw new InvalidOperationException("Failed to refresh Zalo access token.");
            }

            return _runtimeAccessToken;
        }
        finally
        {
            RefreshLock.Release();
        }
    }

    private void EnsureTokenStateInitialized()
    {
        if (_tokenStateInitialized)
        {
            return;
        }

        _runtimeAccessToken = _settings.AccessToken?.Trim() ?? string.Empty;
        _runtimeRefreshToken = _settings.RefreshToken?.Trim() ?? string.Empty;

        if (_settings.AccessTokenExpiresInSeconds > 0)
        {
            _accessTokenExpiresAtUtc = DateTime.UtcNow.AddSeconds(_settings.AccessTokenExpiresInSeconds);
        }

        _tokenStateInitialized = true;
    }

    private bool CanRefreshToken()
    {
        return !string.IsNullOrWhiteSpace(_settings.TokenApiBaseUrl)
               && !string.IsNullOrWhiteSpace(_settings.RefreshPath)
               && (!string.IsNullOrWhiteSpace(_runtimeRefreshToken) || !string.IsNullOrWhiteSpace(_settings.RefreshToken))
               && !string.IsNullOrWhiteSpace(_settings.AppId)
               && !string.IsNullOrWhiteSpace(_settings.AppSecret);
    }

    private bool ShouldRefreshAccessTokenSoon()
    {
        if (_accessTokenExpiresAtUtc == null)
        {
            return false;
        }

        var bufferSeconds = Math.Max(0, _settings.RefreshBufferSeconds);
        return _accessTokenExpiresAtUtc.Value <= DateTime.UtcNow.AddSeconds(bufferSeconds);
    }

    private async Task RefreshAccessTokenAsync(CancellationToken cancellationToken)
    {
        var refreshToken = string.IsNullOrWhiteSpace(_runtimeRefreshToken)
            ? _settings.RefreshToken?.Trim() ?? string.Empty
            : _runtimeRefreshToken;

        if (string.IsNullOrWhiteSpace(refreshToken))
        {
            throw new InvalidOperationException("ZaloOtpSettings.RefreshToken is missing.");
        }

        var baseUrl = _settings.TokenApiBaseUrl.TrimEnd('/');
        var path = _settings.RefreshPath.StartsWith("/", StringComparison.Ordinal)
            ? _settings.RefreshPath
            : "/" + _settings.RefreshPath;

        var refreshUrl = $"{baseUrl}{path}";
        using var request = new HttpRequestMessage(HttpMethod.Post, refreshUrl)
        {
            Content = new FormUrlEncodedContent(new Dictionary<string, string>
            {
                ["app_id"] = _settings.AppId.Trim(),
                ["grant_type"] = "refresh_token",
                ["refresh_token"] = refreshToken,
                ["app_secret"] = _settings.AppSecret.Trim()
            })
        };

        request.Headers.TryAddWithoutValidation("secret_key", _settings.AppSecret.Trim());

        using var response = await _httpClient.SendAsync(request, cancellationToken);
        var rawResponse = await response.Content.ReadAsStringAsync(cancellationToken);

        if (!response.IsSuccessStatusCode)
        {
            _logger.LogError(
                "Failed to refresh Zalo access token. Status={StatusCode}. Body={Body}",
                (int)response.StatusCode,
                rawResponse
            );
            throw new InvalidOperationException("Không thể làm mới access token của Zalo.");
        }

        var tokenResponse = ParseRefreshTokenResponse(rawResponse);

        if (tokenResponse.ErrorCode != 0)
        {
            _logger.LogError(
                "Zalo refresh token API returned error. Error={ErrorCode}. Message={Message}. Body={Body}",
                tokenResponse.ErrorCode,
                tokenResponse.Message,
                rawResponse
            );
            throw new InvalidOperationException(tokenResponse.Message ?? "Không thể làm mới access token của Zalo.");
        }

        if (string.IsNullOrWhiteSpace(tokenResponse.AccessToken))
        {
            throw new InvalidOperationException("Zalo refresh response does not contain access token.");
        }

        _runtimeAccessToken = tokenResponse.AccessToken;
        if (!string.IsNullOrWhiteSpace(tokenResponse.RefreshToken))
        {
            _runtimeRefreshToken = tokenResponse.RefreshToken;
        }

        _accessTokenExpiresAtUtc = tokenResponse.ExpiresInSeconds > 0
            ? DateTime.UtcNow.AddSeconds(tokenResponse.ExpiresInSeconds)
            : null;

        _logger.LogInformation("Zalo access token refreshed successfully.");
    }

    private object BuildPayload(string normalizedPhone, string otpCode, string purpose, string trackingId)
    {
        var templateData = new Dictionary<string, string>
        {
            [_settings.OtpFieldName] = otpCode,
            [_settings.PurposeFieldName] = purpose,
            [_settings.ExpireMinutesFieldName] = _settings.ExpireMinutes.ToString(CultureInfo.InvariantCulture)
        };

        var payload = new Dictionary<string, object?>
        {
            ["template_id"] = _settings.TemplateId,
            ["template_data"] = templateData,
            ["tracking_id"] = string.IsNullOrWhiteSpace(_settings.TrackingPrefix)
                ? trackingId
                : $"{_settings.TrackingPrefix}_{trackingId}"
        };

        if (!string.IsNullOrWhiteSpace(_settings.Mode))
        {
            payload["mode"] = _settings.Mode.Trim();
        }

        if (!string.IsNullOrWhiteSpace(_settings.SendingMode))
        {
            payload["sending_mode"] = _settings.SendingMode.Trim();
        }

        if (_settings.UseHashPhone)
        {
            payload["hash_phone"] = ComputeSha256(normalizedPhone);
        }
        else
        {
            payload["phone"] = normalizedPhone;
        }

        return payload;
    }

    private static (int ErrorCode, string? Message) ParseResponse(string rawResponse)
    {
        using var document = JsonDocument.Parse(rawResponse);
        var root = document.RootElement;

        var errorCode = TryReadInt(root, "error", "error_code") ?? -1;
        var message = TryReadString(root, "message", "error_name", "error_description");

        return (errorCode, message);
    }

    private static RefreshTokenResponse ParseRefreshTokenResponse(string rawResponse)
    {
        using var document = JsonDocument.Parse(rawResponse);
        var root = document.RootElement;

        var body = TryReadObject(root, "data") ?? root;

        return new RefreshTokenResponse
        {
            AccessToken = TryReadString(body, "access_token", "accessToken")
                          ?? TryReadString(root, "access_token", "accessToken")
                          ?? string.Empty,
            RefreshToken = TryReadString(body, "refresh_token", "refreshToken")
                           ?? TryReadString(root, "refresh_token", "refreshToken"),
            ExpiresInSeconds = TryReadInt(body, "expires_in", "expiresIn")
                               ?? TryReadInt(root, "expires_in", "expiresIn")
                               ?? 0,
            ErrorCode = TryReadInt(root, "error", "error_code") ?? 0,
            Message = TryReadString(root, "message", "error_name", "error_description")
        };
    }

    private static JsonElement? TryReadObject(JsonElement element, string propertyName)
    {
        if (element.ValueKind != JsonValueKind.Object)
        {
            return null;
        }

        foreach (var property in element.EnumerateObject())
        {
            if (!string.Equals(property.Name, propertyName, StringComparison.OrdinalIgnoreCase))
            {
                continue;
            }

            if (property.Value.ValueKind == JsonValueKind.Object)
            {
                return property.Value;
            }

            break;
        }

        return null;
    }

    private static string? TryReadString(JsonElement element, params string[] propertyNames)
    {
        if (element.ValueKind != JsonValueKind.Object)
        {
            return null;
        }

        foreach (var propertyName in propertyNames)
        {
            foreach (var property in element.EnumerateObject())
            {
                if (!string.Equals(property.Name, propertyName, StringComparison.OrdinalIgnoreCase))
                {
                    continue;
                }

                if (property.Value.ValueKind == JsonValueKind.String)
                {
                    return property.Value.GetString();
                }

                if (property.Value.ValueKind == JsonValueKind.Number)
                {
                    return property.Value.GetRawText();
                }

                break;
            }
        }

        return null;
    }

    private static int? TryReadInt(JsonElement element, params string[] propertyNames)
    {
        var rawValue = TryReadString(element, propertyNames);
        if (string.IsNullOrWhiteSpace(rawValue))
        {
            return null;
        }

        return int.TryParse(rawValue, NumberStyles.Integer, CultureInfo.InvariantCulture, out var parsed)
            ? parsed
            : null;
    }

    private static string ComputeSha256(string value)
    {
        var hash = SHA256.HashData(Encoding.UTF8.GetBytes(value));
        var sb = new StringBuilder(hash.Length * 2);
        foreach (var b in hash)
        {
            sb.Append(b.ToString("x2"));
        }

        return sb.ToString();
    }

    private sealed class RefreshTokenResponse
    {
        public string AccessToken { get; init; } = string.Empty;
        public string? RefreshToken { get; init; }
        public int ExpiresInSeconds { get; init; }
        public int ErrorCode { get; init; }
        public string? Message { get; init; }
    }
}
