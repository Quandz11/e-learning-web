namespace SKVI.Domain.Entities;

public class Cabin
{
    public Guid Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public Guid OwnerUserId { get; set; }
    public decimal CommissionRate { get; set; }
    public decimal WalletBalance { get; set; } = 0;
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public bool IsActive { get; set; } = true;

    // Navigation properties
    public User OwnerUser { get; set; } = null!;
    public ICollection<Lead> Leads { get; set; } = new List<Lead>();
    public ICollection<CommissionLedger> CommissionLedgers { get; set; } = new List<CommissionLedger>();
    public ICollection<Payout> Payouts { get; set; } = new List<Payout>();
}
