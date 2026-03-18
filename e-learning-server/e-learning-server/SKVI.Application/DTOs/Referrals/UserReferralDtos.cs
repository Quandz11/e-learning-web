namespace SKVI.Application.DTOs.Referrals;

public class UserReferralDto
{
    public Guid Id { get; set; }
    public Guid UserId { get; set; }
    public string ReferralCode { get; set; } = string.Empty;
    public string DiscountCode { get; set; } = string.Empty;
    public decimal DiscountPercent { get; set; }
    public bool IsActive { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime UpdatedAt { get; set; }
}

public class UserReferralStatsDto
{
    public int TotalInvites { get; set; }
    public int SuccessfulInvites { get; set; }
    public int PendingInvites { get; set; }
}

public class UserReferralOverviewDto
{
    public UserReferralDto Referral { get; set; } = new();
    public UserReferralStatsDto Stats { get; set; } = new();
}

public class AdminUserReferralItemDto
{
    public Guid Id { get; set; }
    public Guid UserId { get; set; }
    public string? UserName { get; set; }
    public string UserEmail { get; set; } = string.Empty;
    public string ReferralCode { get; set; } = string.Empty;
    public string DiscountCode { get; set; } = string.Empty;
    public decimal DiscountPercent { get; set; }
    public bool IsActive { get; set; }
    public int TotalInvites { get; set; }
    public int SuccessfulInvites { get; set; }
    public int PendingInvites { get; set; }
    public int ReferredPaidOrderCount { get; set; }
    public decimal ReferredPaidRevenue { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime UpdatedAt { get; set; }
}

public class AdminUpdateUserReferralRequest
{
    public string DiscountCode { get; set; } = string.Empty;
    public decimal DiscountPercent { get; set; }
    public bool IsActive { get; set; }
}

public class AdminBulkUpdateDiscountPercentRequest
{
    public List<Guid> ReferralIds { get; set; } = new();
    public decimal DiscountPercent { get; set; }
}

public class AdminBulkUpdateDiscountPercentResultDto
{
    public int RequestedCount { get; set; }
    public int UpdatedCount { get; set; }
    public decimal DiscountPercent { get; set; }
    public DateTime UpdatedAt { get; set; }
}
