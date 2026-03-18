namespace SKVI.Domain.Entities;

public class ReferralTransaction
{
    public Guid Id { get; set; }
    public Guid ReferrerUserId { get; set; }
    public Guid ReferredUserId { get; set; }
    public Guid UserReferralId { get; set; }
    public string ReferralCode { get; set; } = string.Empty;
    public string Status { get; set; } = "PENDING"; // PENDING, COMPLETED, CANCELLED
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime? CompletedAt { get; set; }

    public User ReferrerUser { get; set; } = null!;
    public User ReferredUser { get; set; } = null!;
    public UserReferral UserReferral { get; set; } = null!;
}
