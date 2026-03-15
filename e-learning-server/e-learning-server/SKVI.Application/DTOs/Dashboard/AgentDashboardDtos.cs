namespace SKVI.Application.DTOs.Dashboard;

public class AgentDashboardStatsDto
{
    public decimal TotalSalesThisMonth { get; set; }
    public decimal CommissionPending { get; set; }
    public decimal CommissionReceived { get; set; }
    public int TotalActiveReferrals { get; set; }
    public int TotalStudentsFromReferral { get; set; }
    public decimal SalesGrowthPercentage { get; set; }  // vs last month
    public decimal CommissionGrowthPercentage { get; set; }
    public int LeaderboardRank { get; set; }
}

public class SalesDataDto
{
    public string Week { get; set; } = string.Empty;  // e.g., "Week 1", "Week 2"
    public decimal Amount { get; set; }
    public int CoursesSold { get; set; }
}

public class ReferralDto
{
    public string Id { get; set; } = string.Empty;
    public string ReferrerName { get; set; } = string.Empty;
    public string CustomerEmail { get; set; } = string.Empty;
    public string CustomerName { get; set; } = string.Empty;
    public string Status { get; set; } = string.Empty;  // Pending, Approved, Paid
    public decimal SalesAmount { get; set; }
    public decimal CommissionPercentage { get; set; }
    public decimal CommissionAmount { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime? ApprovedAt { get; set; }
    public DateTime? PaidAt { get; set; }
}

public class CommissionBreakdownDto
{
    public decimal EarningThisMonth { get; set; }
    public decimal PendingPayment { get; set; }
    public decimal TotalPaidLifetime { get; set; }
    public List<CommissionHistoryDto> History { get; set; } = new();
}

public class CommissionHistoryDto
{
    public string Id { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;  // e.g., "Course: Fasting 101"
    public decimal Amount { get; set; }
    public string Status { get; set; } = string.Empty;  // Earned, Pending, Paid
    public DateTime Date { get; set; }
}

public class AgentStudentDto
{
    public Guid Id { get; set; }
    public string Email { get; set; } = string.Empty;
    public string? FullName { get; set; }
    public int TotalCoursesEnrolled { get; set; }
    public int CoursesCompleted { get; set; }
    public decimal AverageCompletionRate { get; set; }
    public DateTime EnrolledDate { get; set; }
}

public class LeaderboardEntryDto
{
    public int Rank { get; set; }
    public string AgentName { get; set; } = string.Empty;
    public decimal TotalSales { get; set; }
    public int StudentsEnrolled { get; set; }
    public decimal Commission { get; set; }
    public bool IsCurrentAgent { get; set; }
    public decimal BonusThreshold { get; set; }
}

public class AgentReportDto
{
    public string Month { get; set; } = string.Empty;  // YYYY-MM
    public decimal TotalSales { get; set; }
    public int ReferralsCount { get; set; }
    public decimal CommissionEarned { get; set; }
    public List<SalesDataDto> SalesBreakdown { get; set; } = new();
}

public class GenerateReferralLinkRequestDto
{
    public string? CustomCode { get; set; }
}

public class ReferralLinkResponseDto
{
    public string Link { get; set; } = string.Empty;
    public string Code { get; set; } = string.Empty;
    public string CopyText { get; set; } = string.Empty;
    public DateTime CreatedAt { get; set; }
}
