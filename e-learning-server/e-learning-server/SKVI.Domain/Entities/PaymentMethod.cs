namespace SKVI.Domain.Entities;

public class PaymentMethod
{
    public Guid Id { get; set; }
    public string Code { get; set; } = string.Empty; // VNPAY, VIETQR, BANK, STRIPE
    public string Name { get; set; } = string.Empty;
    public bool IsActive { get; set; } = true;
}
