using SKVI.Domain.Common;

namespace SKVI.Domain.Entities.Payment;

public class PaymentMethod : BaseEntity
{
    public string Code { get; set; } = string.Empty; // VNPAY, VIETQR, BANK, STRIPE
    public string Name { get; set; } = string.Empty;
    public bool IsActive { get; set; } = true;
    
    // Navigation properties
    public ICollection<PaymentTransaction> PaymentTransactions { get; set; } = new List<PaymentTransaction>();
}
