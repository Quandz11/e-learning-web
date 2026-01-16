using SKVI.Domain.Common;
using SKVI.Domain.Entities.Auth;
using SKVI.Domain.Entities.Commission;
using SKVI.Domain.Enums;

namespace SKVI.Domain.Entities.Payment;

public class Order : BaseEntity
{
    public Guid BuyerId { get; set; }
    public decimal TotalAmount { get; set; }
    public OrderStatus Status { get; set; } = OrderStatus.PENDING;
    public DateTime? PaidAt { get; set; }
    
    // Navigation properties
    public User Buyer { get; set; } = null!;
    public ICollection<OrderItem> OrderItems { get; set; } = new List<OrderItem>();
    public ICollection<PaymentTransaction> PaymentTransactions { get; set; } = new List<PaymentTransaction>();
    public ICollection<CommissionLedger> CommissionLedgers { get; set; } = new List<CommissionLedger>();
}
