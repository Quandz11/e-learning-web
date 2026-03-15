namespace SKVI.Application.DTOs.Referrals;

public class AdminCommissionSummaryDto
{
    public decimal TotalPending { get; set; }
    public decimal TotalPaid { get; set; }
    public int PendingLedgers { get; set; }
    public int PaidLedgers { get; set; }
    public int PendingCabins { get; set; }
    public int PayoutCount { get; set; }
}

public class AdminCommissionCabinItemDto
{
    public string CabinId { get; set; } = string.Empty;
    public string CabinName { get; set; } = string.Empty;
    public string ReferralCode { get; set; } = string.Empty;
    public string? OwnerName { get; set; }
    public string OwnerEmail { get; set; } = string.Empty;
    public decimal PendingAmount { get; set; }
    public int PendingLedgerCount { get; set; }
    public DateTime LastCommissionAt { get; set; }
}

public class AdminCommissionCabinPagedResultDto
{
    public List<AdminCommissionCabinItemDto> Items { get; set; } = new();
    public int Total { get; set; }
    public int Page { get; set; }
    public int PageSize { get; set; }
}

public class PayCabinCommissionRequestDto
{
    public string? BankName { get; set; }
    public string? BankAccount { get; set; }
}

public class PayCabinCommissionResponseDto
{
    public string PayoutId { get; set; } = string.Empty;
    public string CabinId { get; set; } = string.Empty;
    public decimal PaidAmount { get; set; }
    public int PaidLedgerCount { get; set; }
    public DateTime PaidAt { get; set; }
    public string? BankName { get; set; }
    public string? BankAccount { get; set; }
}
