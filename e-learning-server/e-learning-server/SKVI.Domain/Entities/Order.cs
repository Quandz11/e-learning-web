namespace SKVI.Domain.Entities;

public class Order
{
    public Guid Id { get; set; }
    public Guid BuyerId { get; set; }
    public decimal TotalAmount { get; set; }
    public string Status { get; set; } = "PENDING"; // PENDING, PAID, FAILED, CANCELLED
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime? PaidAt { get; set; }

    // Navigation properties
    public User Buyer { get; set; } = null!;
    public ICollection<OrderItem> OrderItems { get; set; } = new List<OrderItem>();
    public ICollection<PaymentTransaction> PaymentTransactions { get; set; } = new List<PaymentTransaction>();
    public ICollection<CommissionLedger> CommissionLedgers { get; set; } = new List<CommissionLedger>();
}
