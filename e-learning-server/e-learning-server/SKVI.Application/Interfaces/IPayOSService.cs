using System.Text.Json;
using SKVI.Application.DTOs.Payments;

namespace SKVI.Application.Interfaces;

public interface IPayOSService
{
    string CreatePaymentRequestSignature(int amount, string cancelUrl, string description, int orderCode, string returnUrl);
    bool VerifyWebhookSignature(JsonElement webhookData, string signature);
    Task<PayOSCreatePaymentLinkData> CreatePaymentLinkAsync(PayOSCreatePaymentLinkRequest request, CancellationToken cancellationToken = default);
    Task<PayOSPaymentLinkInfoData> GetPaymentLinkInfoAsync(string idOrOrderCode, CancellationToken cancellationToken = default);
    Task<PayOSPaymentLinkInfoData> CancelPaymentLinkAsync(string idOrOrderCode, string? cancellationReason, CancellationToken cancellationToken = default);
    Task<PayOSConfirmWebhookData> ConfirmWebhookUrlAsync(string webhookUrl, CancellationToken cancellationToken = default);
}
