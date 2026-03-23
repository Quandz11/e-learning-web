using System.Text.Json;

namespace SKVI.Application.DTOs.Payments;

public class CheckoutRequest
{
    public List<string> CourseIds { get; set; } = new();
    public string? WellnessPackageCode { get; set; }
    public string? ReferralCode { get; set; }
}

public class ReferralPreviewResponse
{
    public string ReferralCode { get; set; } = string.Empty;
    public string CabinId { get; set; } = string.Empty;
    public string CabinName { get; set; } = string.Empty;
    public string OwnerUserId { get; set; } = string.Empty;
    public string OwnerName { get; set; } = string.Empty;
}

public class CheckoutItemDto
{
    public string CourseId { get; set; } = string.Empty;
    public string Title { get; set; } = string.Empty;
    public decimal Price { get; set; }
    public bool IsFree { get; set; }
    public string ItemType { get; set; } = "COURSE";
    public string? WellnessPackageCode { get; set; }
}

public class PaymentInstructionDto
{
    public string? BankBin { get; set; }
    public string? BankName { get; set; }
    public string? BankShortName { get; set; }
    public string? AccountNumber { get; set; }
    public string? AccountName { get; set; }
    public string? TransferContent { get; set; }
    public decimal Amount { get; set; }
}

public class CheckoutResponse
{
    public string OrderId { get; set; } = string.Empty;
    public int? PayOSOrderCode { get; set; }
    public decimal TotalAmount { get; set; }
    public string Status { get; set; } = "PENDING";
    public bool RequiresPayment { get; set; }
    public string? CheckoutUrl { get; set; }
    public string? QrCode { get; set; }
    public string? PaymentLinkId { get; set; }
    public PaymentInstructionDto? PaymentInstruction { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime? ExpiresAt { get; set; }
    public List<CheckoutItemDto> Items { get; set; } = new();
}

public class UserOrderSummaryDto
{
    public string OrderId { get; set; } = string.Empty;
    public int? PayOSOrderCode { get; set; }
    public decimal TotalAmount { get; set; }
    public string Status { get; set; } = "PENDING";
    public string? LastPaymentStatus { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime? PaidAt { get; set; }
    public List<CheckoutItemDto> Items { get; set; } = new();
}

public class OrderStatusResponse
{
    public string OrderId { get; set; } = string.Empty;
    public int? PayOSOrderCode { get; set; }
    public decimal TotalAmount { get; set; }
    public string Status { get; set; } = "PENDING";
    public string? LastPaymentStatus { get; set; }
    public bool IsPaid { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime? PaidAt { get; set; }
    public string? PaymentLinkId { get; set; }
    public string? CheckoutUrl { get; set; }
    public string? QrCode { get; set; }
    public PaymentInstructionDto? PaymentInstruction { get; set; }
    public List<CheckoutItemDto> Items { get; set; } = new();
}

public class PayOSWebhookRequest
{
    public string Code { get; set; } = string.Empty;
    public string Desc { get; set; } = string.Empty;
    public bool Success { get; set; }
    public JsonElement Data { get; set; }
    public string Signature { get; set; } = string.Empty;
}

public class PayOSCreatePaymentLinkRequest
{
    public int OrderCode { get; set; }
    public int Amount { get; set; }
    public string Description { get; set; } = string.Empty;
    public List<PayOSItemRequest> Items { get; set; } = new();
    public string CancelUrl { get; set; } = string.Empty;
    public string ReturnUrl { get; set; } = string.Empty;
    public int ExpiredAt { get; set; }
    public string Signature { get; set; } = string.Empty;
}

public class PayOSItemRequest
{
    public string Name { get; set; } = string.Empty;
    public int Quantity { get; set; }
    public int Price { get; set; }
}

public class PayOSApiResponse<T>
{
    public string Code { get; set; } = string.Empty;
    public string Desc { get; set; } = string.Empty;
    public T? Data { get; set; }
    public string? Signature { get; set; }
}

public class PayOSCreatePaymentLinkData
{
    public int OrderCode { get; set; }
    public int Amount { get; set; }
    public string Status { get; set; } = string.Empty;
    public string? PaymentLinkId { get; set; }
    public string? CheckoutUrl { get; set; }
    public string? QrCode { get; set; }
    public string? Bin { get; set; }
    public string? AccountNumber { get; set; }
    public string? AccountName { get; set; }
    public string? Description { get; set; }
    public string? Currency { get; set; }
}

public class PayOSPaymentLinkInfoData
{
    public string? Id { get; set; }
    public int OrderCode { get; set; }
    public int Amount { get; set; }
    public int AmountPaid { get; set; }
    public int AmountRemaining { get; set; }
    public string Status { get; set; } = string.Empty;
    public DateTime CreatedAt { get; set; }
    public DateTime? CanceledAt { get; set; }
    public string? CancellationReason { get; set; }
    public string? QrCode { get; set; }
    public string? CheckoutUrl { get; set; }
    public string? Bin { get; set; }
    public string? AccountNumber { get; set; }
    public string? AccountName { get; set; }
    public string? Description { get; set; }
    public string? Currency { get; set; }
    public string? Name { get; set; }
    public string? ShortName { get; set; }
}

public class PayOSConfirmWebhookRequest
{
    public string WebhookUrl { get; set; } = string.Empty;
}

public class PayOSConfirmWebhookData
{
    public string? WebhookUrl { get; set; }
    public string? AccountNumber { get; set; }
    public string? AccountName { get; set; }
    public string? Name { get; set; }
    public string? ShortName { get; set; }
}
