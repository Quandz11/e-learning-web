using SKVI.Domain.Common;
using SKVI.Domain.Enums;

namespace SKVI.Domain.Entities.Commission;

public class CommissionLedger : BaseEntity
{
    public Guid CabinId { get; set; }
    public Guid OrderId { get; set; }
    public decimal Amount { get; set; }
    public CommissionStatus Status { get; set; } = CommissionStatus.PENDING;
    
    // Navigation properties
    public Cabin.Cabin Cabin { get; set; } = null!;
    public Payment.Order Order { get; set; } = null!;
}
