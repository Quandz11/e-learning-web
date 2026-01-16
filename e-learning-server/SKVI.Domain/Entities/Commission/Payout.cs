using SKVI.Domain.Common;

namespace SKVI.Domain.Entities.Commission;

public class Payout : BaseEntity
{
    public Guid CabinId { get; set; }
    public decimal Amount { get; set; }
    public string BankName { get; set; } = string.Empty;
    public string BankAccount { get; set; } = string.Empty;
    public string Status { get; set; } = "PENDING";
    public DateTime? PaidAt { get; set; }
    
    // Navigation properties
    public Cabin.Cabin Cabin { get; set; } = null!;
}
