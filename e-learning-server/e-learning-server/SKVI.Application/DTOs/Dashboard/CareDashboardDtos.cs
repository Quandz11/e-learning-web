namespace SKVI.Application.DTOs.Dashboard;

public class CareDashboardStatsDto
{
    public int PendingTickets { get; set; }
    public decimal AverageSatisfactionScore { get; set; }  // 0-5
    public decimal AverageResponseTimeHours { get; set; }
    public int TotalCustomersThisMonth { get; set; }
    public decimal SatisfactionTrendPercentage { get; set; }  // vs last month
}

public class SupportTicketDto
{
    public string Id { get; set; } = string.Empty;
    public string CustomerName { get; set; } = string.Empty;
    public string CustomerEmail { get; set; } = string.Empty;
    public string Title { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
    public string Status { get; set; } = string.Empty;  // New, InProgress, Resolved, Closed
    public string Priority { get; set; } = string.Empty;  // Low, Medium, High, Urgent
    public DateTime CreatedAt { get; set; }
    public DateTime? UpdatedAt { get; set; }
    public string? AssignedTo { get; set; }
    public decimal? SatisfactionRating { get; set; }
}

public class CareCustomerDto
{
    public Guid Id { get; set; }
    public string Email { get; set; } = string.Empty;
    public string? FullName { get; set; }
    public string? Phone { get; set; }
    public int TotalTickets { get; set; }
    public int ResolvedTickets { get; set; }
    public decimal? AverageSatisfaction { get; set; }
    public bool IsEmailVerified { get; set; }
    public bool IsPhoneVerified { get; set; }
    public DateTime CreatedAt { get; set; }
}

public class CareChatMessageDto
{
    public string Id { get; set; } = string.Empty;
    public string TicketId { get; set; } = string.Empty;
    public string CustomerName { get; set; } = string.Empty;
    public string Message { get; set; } = string.Empty;
    public DateTime CreatedAt { get; set; }
    public bool IsRead { get; set; }
}

public class SatisfactionFeedbackDto
{
    public string Date { get; set; } = string.Empty;  // YYYY-MM-DD
    public decimal AverageScore { get; set; }
    public int Count { get; set; }
}

public class CreateSupportTicketDto
{
    public string CustomerEmail { get; set; } = string.Empty;
    public string Title { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
    public string Priority { get; set; } = "Medium";
}

public class UpdateSupportTicketDto
{
    public string Status { get; set; } = string.Empty;
    public string? AssignedTo { get; set; }
    public decimal? SatisfactionRating { get; set; }
}
