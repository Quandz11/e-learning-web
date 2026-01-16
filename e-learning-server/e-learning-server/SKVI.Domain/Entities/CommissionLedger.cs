namespace SKVI.Domain.Entities;

public class CommissionLedger
{
    public Guid Id { get; set; }
    public Guid CabinId { get; set; }
    public Guid OrderId { get; set; }
    public decimal Amount { get; set; }
    public string Status { get; set; } = "PENDING"; // PENDING, APPROVED, PAID
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    // Navigation properties
    public Cabin Cabin { get; set; } = null!;
    public Order Order { get; set; } = null!;
}
