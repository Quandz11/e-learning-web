namespace SKVI.Application.DTOs.Leads;

public class LeadRegistrationDto
{
    public string Id { get; set; } = string.Empty;
    public string FullName { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public string Phone { get; set; } = string.Empty;
    public string Goal { get; set; } = string.Empty;
    public string Status { get; set; } = "NEW";
    public string Source { get; set; } = string.Empty;
    public string? AssignedCareId { get; set; }
    public string? AssignedCareName { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime UpdatedAt { get; set; }
}

public class LeadRegistrationPagedResultDto
{
    public List<LeadRegistrationDto> Items { get; set; } = new();
    public int Total { get; set; }
    public int Page { get; set; }
    public int PageSize { get; set; }
}

public class CreateLeadRegistrationRequest
{
    public string FullName { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public string Phone { get; set; } = string.Empty;
    public string Goal { get; set; } = string.Empty;
    public string? Source { get; set; }
}

public class UpdateLeadRegistrationRequest
{
    public string? FullName { get; set; }
    public string? Email { get; set; }
    public string? Phone { get; set; }
    public string? Goal { get; set; }
    public string? Status { get; set; }
    public string? AssignedCareId { get; set; }
}
