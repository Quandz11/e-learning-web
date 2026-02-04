using System.ComponentModel.DataAnnotations;

namespace SKVI.Application.DTOs.Notification;

public class CreateNotificationRequest
{
    [Required]
    public string Title { get; set; } = string.Empty;
    
    [Required]
    public string Content { get; set; } = string.Empty;
    
    // "USER", "ROLE", "ALL"
    [Required]
    public string TargetType { get; set; } = "USER"; 
    
    // Required if TargetType == "USER"
    public Guid? TargetUserId { get; set; }
    
    // Required if TargetType == "ROLE"
    public string? TargetRole { get; set; }
}
