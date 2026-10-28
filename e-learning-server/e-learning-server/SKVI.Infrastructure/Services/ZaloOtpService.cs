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
private readonly ZaloTokenManager _tokens;
    private readonly HttpClient _httpClient;
    private readonly ZaloOtpSettings _settings;
    private readonly ILogger<ZaloOtpService> _logger;

    public ZaloOtpService(
        HttpClient httpClient,
        IOptions<ZaloOtpSettings> settings,
        ILogger<ZaloOtpService> logger,
        ZaloTokenManager tokens
    )
    {
        _tokens = tokens;
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


        var accessToken = await _tokens.GetAccessTokenAsync(
            cancellationToken: cancellationToken);

        var (statusCode, rawResponse) = await SendTemplateRequestAsync(
            path, payload, accessToken, cancellationToken);

        // Retry only when the HTTP status explicitly indicates
        // an authentication failure.
        if (statusCode == HttpStatusCode.Unauthorized ||
            statusCode == HttpStatusCode.Forbidden)
        {
            var previousToken = accessToken;

            accessToken = await _tokens.GetAccessTokenAsync(
                forceRefresh: true,
                previouslyUsedToken: previousToken,
                cancellationToken: cancellationToken);

            (statusCode, rawResponse) = await SendTemplateRequestAsync(
                path, payload, accessToken, cancellationToken);
        }

        if (statusCode != HttpStatusCode.OK)
        {
            _logger.LogError(
                "Zalo OTP HTTP error. Status={StatusCode}",
                (int)statusCode);

            throw new InvalidOperationException(
                "Không thể gửi OTP qua Zalo ở thời điểm hiện tại.");
        }

        var (errorCode, message) = ParseResponse(rawResponse);

        if (errorCode != 0)
        {
            _logger.LogError(
                "Zalo OTP API error. Code={ErrorCode}",
                errorCode);

            throw new InvalidOperationException(
                "Gửi OTP qua Zalo thất bại.");
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

}
