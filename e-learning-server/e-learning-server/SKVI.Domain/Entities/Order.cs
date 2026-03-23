namespace SKVI.Domain.Entities;

public class Order
{
    public Guid Id { get; set; }
    public Guid BuyerId { get; set; }
    public Guid? CabinId { get; set; }
    public Guid? WellnessPackageId { get; set; }
    public int? PayOSOrderCode { get; set; }
    public decimal TotalAmount { get; set; }
    public string Status { get; set; } = "PENDING"; // PENDING, PAID, FAILED, CANCELLED
    public string? LastPaymentStatus { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime? ExpiresAt { get; set; }
    public DateTime? PaidAt { get; set; }

    // Navigation properties
    public User Buyer { get; set; } = null!;
    public Cabin? Cabin { get; set; }
    public WellnessPackage? WellnessPackage { get; set; }
    public ICollection<OrderItem> OrderItems { get; set; } = new List<OrderItem>();
    public ICollection<PaymentTransaction> PaymentTransactions { get; set; } = new List<PaymentTransaction>();
    public ICollection<CommissionLedger> CommissionLedgers { get; set; } = new List<CommissionLedger>();
}
