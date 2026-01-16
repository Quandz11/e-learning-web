namespace SKVI.Domain.Entities;

public class Payout
{
    public Guid Id { get; set; }
    public Guid CabinId { get; set; }
    public decimal Amount { get; set; }
    public string? BankName { get; set; }
    public string? BankAccount { get; set; }
    public string Status { get; set; } = string.Empty;
    public DateTime? PaidAt { get; set; }

    // Navigation properties
    public Cabin Cabin { get; set; } = null!;
}
