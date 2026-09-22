namespace SKVI.Application.DTOs.Dashboard;

public class DashboardStatsDto
{
    public int TotalStudents { get; set; }
    public decimal TotalRevenue { get; set; }
    public decimal AgentRevenue { get; set; }
    public int ActiveCourses { get; set; }
    public decimal StudentGrowthPercentage { get; set; }
    public decimal RevenueGrowthPercentage { get; set; }
    public decimal AgentRevenueGrowthPercentage { get; set; }
    public decimal CoursesGrowthPercentage { get; set; }
}

public class RecentOrderDto
{
    public string Id { get; set; } = string.Empty;
    public string Student { get; set; } = string.Empty;
    public string? AvatarUrl { get; set; }
    public string? Initials { get; set; }
    public string Course { get; set; } = string.Empty;
    public decimal Amount { get; set; }
    public string FormattedAmount { get; set; } = string.Empty;
    public string Status { get; set; } = "paid"; // paid, pending, failed
    public DateTime Date { get; set; }
    public string FormattedDate { get; set; } = string.Empty;
}

public class TopAgentDto
{
    public string Id { get; set; } = string.Empty;
    public string Name { get; set; } = string.Empty;
    public string? AvatarUrl { get; set; }
    public decimal Revenue { get; set; }
    public string FormattedRevenue { get; set; } = string.Empty;
    public int OrderCount { get; set; }
    public int Rank { get; set; }
    public double Percentage { get; set; }
}

