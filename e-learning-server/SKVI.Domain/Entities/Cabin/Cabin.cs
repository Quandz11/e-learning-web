using SKVI.Domain.Common;
using SKVI.Domain.Entities.Auth;

namespace SKVI.Domain.Entities.Cabin;

public class Cabin : BaseEntity
{
    public string Name { get; set; } = string.Empty;
    public Guid OwnerUserId { get; set; }
    public decimal CommissionRate { get; set; }
    public decimal WalletBalance { get; set; } = 0;
    public bool IsActive { get; set; } = true;
    
    // Navigation properties
    public User Owner { get; set; } = null!;
    public ICollection<Entities.Lead.Lead> Leads { get; set; } = new List<Entities.Lead.Lead>();
    public ICollection<Commission.CommissionLedger> CommissionLedgers { get; set; } = new List<Commission.CommissionLedger>();
}
