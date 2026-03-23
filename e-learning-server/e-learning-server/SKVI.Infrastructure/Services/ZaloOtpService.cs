using System.Security.Cryptography;
using System.Text;
using System.Text.Json;
using System.Net.Http.Json;
using Microsoft.Extensions.Options;
using SKVI.Application.Interfaces;

namespace SKVI.Infrastructure.Services;

public class ZaloOtpService : IPhoneOtpSender
{
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

        if (string.IsNullOrWhiteSpace(_settings.AccessToken))
        {
            throw new InvalidOperationException("ZaloOtpSettings.AccessToken is missing.");
        }

        if (string.IsNullOrWhiteSpace(_settings.TemplateId))
        {
            throw new InvalidOperationException("ZaloOtpSettings.TemplateId is missing.");
        }

        var payload = BuildPayload(normalizedPhone, otpCode, purpose, trackingId);
        var path = _settings.UseHashPhone ? "/message/template/hashphone" : "/message/template";

        using var request = new HttpRequestMessage(HttpMethod.Post, path)
        {
            Content = JsonContent.Create(payload)
        };
        request.Headers.Add("access_token", _settings.AccessToken);

        using var response = await _httpClient.SendAsync(request, cancellationToken);
        var rawResponse = await response.Content.ReadAsStringAsync(cancellationToken);

        if (!response.IsSuccessStatusCode)
        {
            _logger.LogError(
                "Zalo OTP HTTP error. Status={StatusCode}. Body={Body}",
                (int)response.StatusCode,
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

    private object BuildPayload(string normalizedPhone, string otpCode, string purpose, string trackingId)
    {
        var templateData = new Dictionary<string, string>
        {
            [_settings.OtpFieldName] = otpCode,
            [_settings.PurposeFieldName] = purpose,
            [_settings.ExpireMinutesFieldName] = _settings.ExpireMinutes.ToString()
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

        var errorCode = root.TryGetProperty("error", out var errorProp)
            ? errorProp.GetInt32()
            : -1;

        var message = root.TryGetProperty("message", out var messageProp)
            ? messageProp.GetString()
            : null;

        return (errorCode, message);
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
