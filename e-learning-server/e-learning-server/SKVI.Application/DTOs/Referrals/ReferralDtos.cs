namespace SKVI.Application.DTOs.Referrals;

public class ReferralItemDto
{
    public string Id { get; set; } = string.Empty;
    public string Name { get; set; } = string.Empty;
    public string ReferralCode { get; set; } = string.Empty;
    public string OwnerUserId { get; set; } = string.Empty;
    public string? OwnerName { get; set; }
    public string OwnerEmail { get; set; } = string.Empty;
    public decimal CommissionRate { get; set; }
    public decimal WalletBalance { get; set; }
    public bool IsActive { get; set; }
    public DateTime CreatedAt { get; set; }
}

public class ReferralPagedResultDto
{
    public List<ReferralItemDto> Items { get; set; } = new();
    public int Total { get; set; }
    public int Page { get; set; }
    public int PageSize { get; set; }
}

public class CreateReferralRequest
{
    public string Name { get; set; } = string.Empty;
    public string OwnerUserId { get; set; } = string.Empty;
    public string ReferralCode { get; set; } = string.Empty;
    public decimal CommissionRate { get; set; }
    public bool IsActive { get; set; } = true;
}

public class UpdateReferralRequest
{
    public string Name { get; set; } = string.Empty;
    public string OwnerUserId { get; set; } = string.Empty;
    public string ReferralCode { get; set; } = string.Empty;
    public decimal CommissionRate { get; set; }
    public bool IsActive { get; set; }
}