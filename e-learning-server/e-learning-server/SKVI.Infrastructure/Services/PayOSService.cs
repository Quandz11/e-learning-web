using System.Security.Cryptography;
using System.Text;
using System.Text.Encodings.Web;
using System.Text.Json;
using System.Text.Json.Serialization;
using Microsoft.Extensions.Options;
using SKVI.Application.DTOs.Payments;
using SKVI.Application.Interfaces;

namespace SKVI.Infrastructure.Services;

public class PayOSService : IPayOSService
{
    private static readonly JsonSerializerOptions JsonOptions = new()
    {
        PropertyNameCaseInsensitive = true,
        PropertyNamingPolicy = JsonNamingPolicy.CamelCase,
        DefaultIgnoreCondition = JsonIgnoreCondition.WhenWritingNull,
        Encoder = JavaScriptEncoder.UnsafeRelaxedJsonEscaping
    };

    private readonly HttpClient _httpClient;
    private readonly PayOSSettings _settings;

    public PayOSService(HttpClient httpClient, IOptions<PayOSSettings> settings)
    {
        _httpClient = httpClient;
        _settings = settings.Value;
    }

    public string CreatePaymentRequestSignature(int amount, string cancelUrl, string description, int orderCode, string returnUrl)
    {
        var data = $"amount={amount}&cancelUrl={cancelUrl}&description={description}&orderCode={orderCode}&returnUrl={returnUrl}";
        return ComputeHmacSha256(data, _settings.ChecksumKey);
    }

    public bool VerifyWebhookSignature(JsonElement webhookData, string signature)
    {
        if (string.IsNullOrWhiteSpace(signature) || webhookData.ValueKind != JsonValueKind.Object)
        {
            return false;
        }

        var dataString = BuildSignatureDataString(webhookData);
        var calculatedSignature = ComputeHmacSha256(dataString, _settings.ChecksumKey);

        var providedBytes = Encoding.UTF8.GetBytes(signature.ToLowerInvariant());
        var calculatedBytes = Encoding.UTF8.GetBytes(calculatedSignature.ToLowerInvariant());

        return CryptographicOperations.FixedTimeEquals(providedBytes, calculatedBytes);
    }

    public async Task<PayOSCreatePaymentLinkData> CreatePaymentLinkAsync(PayOSCreatePaymentLinkRequest request, CancellationToken cancellationToken = default)
    {
        var response = await SendAsync<PayOSCreatePaymentLinkData>(
            HttpMethod.Post,
            "/v2/payment-requests",
            request,
            cancellationToken);

        return response;
    }

    public async Task<PayOSPaymentLinkInfoData> GetPaymentLinkInfoAsync(string idOrOrderCode, CancellationToken cancellationToken = default)
    {
        var path = $"/v2/payment-requests/{Uri.EscapeDataString(idOrOrderCode)}";
        return await SendAsync<PayOSPaymentLinkInfoData>(HttpMethod.Get, path, null, cancellationToken);
    }

    public async Task<PayOSPaymentLinkInfoData> CancelPaymentLinkAsync(string idOrOrderCode, string? cancellationReason, CancellationToken cancellationToken = default)
    {
        var path = $"/v2/payment-requests/{Uri.EscapeDataString(idOrOrderCode)}/cancel";
        var payload = new { cancellationReason = cancellationReason ?? "Cancelled by merchant" };

        return await SendAsync<PayOSPaymentLinkInfoData>(HttpMethod.Post, path, payload, cancellationToken);
    }

    public async Task<PayOSConfirmWebhookData> ConfirmWebhookUrlAsync(string webhookUrl, CancellationToken cancellationToken = default)
    {
        var payload = new PayOSConfirmWebhookRequest { WebhookUrl = webhookUrl };
        return await SendAsync<PayOSConfirmWebhookData>(HttpMethod.Post, "/confirm-webhook", payload, cancellationToken);
    }

    private async Task<T> SendAsync<T>(HttpMethod method, string path, object? payload, CancellationToken cancellationToken)
    {
        using var request = new HttpRequestMessage(method, path);
        request.Headers.TryAddWithoutValidation("x-client-id", _settings.ClientId);
        request.Headers.TryAddWithoutValidation("x-api-key", _settings.ApiKey);

        if (payload != null)
        {
            request.Content = new StringContent(JsonSerializer.Serialize(payload, JsonOptions), Encoding.UTF8, "application/json");
        }

        using var response = await _httpClient.SendAsync(request, cancellationToken);
        var responseContent = await response.Content.ReadAsStringAsync(cancellationToken);

        if (!response.IsSuccessStatusCode)
        {
            throw new InvalidOperationException($"PayOS API error ({(int)response.StatusCode}): {responseContent}");
        }

        var result = JsonSerializer.Deserialize<PayOSApiResponse<T>>(responseContent, JsonOptions);
        if (result == null)
        {
            throw new InvalidOperationException("PayOS API returned an empty response.");
        }

        if (result.Code != "00" || result.Data == null)
        {
            throw new InvalidOperationException($"PayOS API returned failure code {result.Code}: {result.Desc}");
        }

        return result.Data;
    }

    private static string BuildSignatureDataString(JsonElement data)
    {
        var properties = data
            .EnumerateObject()
            .OrderBy(p => p.Name, StringComparer.Ordinal)
            .Select(p => $"{p.Name}={NormalizeValue(p.Value)}");

        return string.Join("&", properties);
    }

    private static string NormalizeValue(JsonElement value)
    {
        return value.ValueKind switch
        {
            JsonValueKind.Undefined => string.Empty,
            JsonValueKind.Null => string.Empty,
            JsonValueKind.String => value.GetString() ?? string.Empty,
            JsonValueKind.Number => value.GetRawText(),
            JsonValueKind.True => "true",
            JsonValueKind.False => "false",
            JsonValueKind.Object => JsonSerializer.Serialize(ToSortedObject(value), JsonOptions),
            JsonValueKind.Array => JsonSerializer.Serialize(ToSortedArray(value), JsonOptions),
            _ => value.GetRawText()
        };
    }

    private static SortedDictionary<string, object?> ToSortedObject(JsonElement value)
    {
        var dict = new SortedDictionary<string, object?>(StringComparer.Ordinal);
        foreach (var property in value.EnumerateObject())
        {
            dict[property.Name] = ToPlainValue(property.Value);
        }

        return dict;
    }

    private static List<object?> ToSortedArray(JsonElement value)
    {
        var result = new List<object?>();
        foreach (var element in value.EnumerateArray())
        {
            result.Add(ToPlainValue(element));
        }

        return result;
    }

    private static object? ToPlainValue(JsonElement value)
    {
        return value.ValueKind switch
        {
            JsonValueKind.Undefined => string.Empty,
            JsonValueKind.Null => string.Empty,
            JsonValueKind.String => value.GetString() ?? string.Empty,
            JsonValueKind.Number => value.GetRawText(),
            JsonValueKind.True => true,
            JsonValueKind.False => false,
            JsonValueKind.Object => ToSortedObject(value),
            JsonValueKind.Array => ToSortedArray(value),
            _ => value.GetRawText()
        };
    }

    private static string ComputeHmacSha256(string data, string secret)
    {
        var keyBytes = Encoding.UTF8.GetBytes(secret);
        var dataBytes = Encoding.UTF8.GetBytes(data);

        using var hmac = new HMACSHA256(keyBytes);
        var hash = hmac.ComputeHash(dataBytes);
        return Convert.ToHexString(hash).ToLowerInvariant();
    }
}
