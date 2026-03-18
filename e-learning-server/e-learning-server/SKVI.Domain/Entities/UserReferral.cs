namespace SKVI.Domain.Entities;

public class UserReferral
{
    public Guid Id { get; set; }
    public Guid UserId { get; set; }
    public string ReferralCode { get; set; } = string.Empty;
    public string DiscountCode { get; set; } = string.Empty;
    public decimal DiscountPercent { get; set; } = 5;
    public bool IsActive { get; set; } = true;
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;

    public User User { get; set; } = null!;
    public ICollection<ReferralTransaction> ReferralTransactions { get; set; } = new List<ReferralTransaction>();
}
