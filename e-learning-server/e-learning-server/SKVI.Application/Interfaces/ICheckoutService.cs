using SKVI.Application.DTOs.Payments;

namespace SKVI.Application.Interfaces;

public interface ICheckoutService
{
    Task<CheckoutResponse> CreateCheckoutAsync(Guid userId, CheckoutRequest request, CancellationToken cancellationToken = default);
    Task<ReferralPreviewResponse?> PreviewReferralAsync(string referralCode, CancellationToken cancellationToken = default);
    Task<IReadOnlyList<UserOrderSummaryDto>> GetUserOrdersAsync(Guid userId, CancellationToken cancellationToken = default);
    Task<OrderStatusResponse?> GetOrderStatusAsync(Guid userId, Guid orderId, bool refreshFromProvider, CancellationToken cancellationToken = default);
    Task<OrderStatusResponse?> GetOrderStatusByCodeAsync(Guid userId, int orderCode, bool refreshFromProvider, CancellationToken cancellationToken = default);
    Task HandlePayOSWebhookAsync(PayOSWebhookRequest request, CancellationToken cancellationToken = default);
    Task ConfirmWebhookUrlAsync(CancellationToken cancellationToken = default);
}
