using SKVI.Domain.Common;
using SKVI.Domain.Enums;

namespace SKVI.Domain.Entities.Payment;

public class PaymentTransaction : BaseEntity
{
    public Guid OrderId { get; set; }
    public Guid PaymentMethodId { get; set; }
    public string? ProviderTransactionId { get; set; }
    public decimal Amount { get; set; }
    public PaymentStatus Status { get; set; } = PaymentStatus.INIT;
    public string? RawPayload { get; set; } // JSON payload for audit
    
    // Navigation properties
    public Order Order { get; set; } = null!;
    public PaymentMethod PaymentMethod { get; set; } = null!;
}
