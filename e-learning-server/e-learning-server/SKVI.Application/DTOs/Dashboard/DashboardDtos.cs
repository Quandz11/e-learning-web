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
