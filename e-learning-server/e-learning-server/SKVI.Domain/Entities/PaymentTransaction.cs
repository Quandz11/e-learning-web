using System.Text.Json;

namespace SKVI.Domain.Entities;

public class PaymentTransaction
{
    public Guid Id { get; set; }
    public Guid OrderId { get; set; }
    public Guid PaymentMethodId { get; set; }
    public string Provider { get; set; } = "PAYOS";
    public string? ProviderTransactionId { get; set; }
    public string? PaymentLinkId { get; set; }
    public string? Reference { get; set; }
    public decimal Amount { get; set; }
    public string Status { get; set; } = "INIT"; // INIT, SUCCESS, FAILED
    public string? RawPayload { get; set; } // Stored as JSON string
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime? WebhookProcessedAt { get; set; }

    // Navigation properties
    public Order Order { get; set; } = null!;
    public PaymentMethod PaymentMethod { get; set; } = null!;
}
