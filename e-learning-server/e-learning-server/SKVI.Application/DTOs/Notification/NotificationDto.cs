namespace SKVI.Application.DTOs.Notification;

public class NotificationDto
{
    public Guid Id { get; set; }
    public string Title { get; set; } = string.Empty;
    public string? Content { get; set; }
    public bool IsRead { get; set; }
    public DateTime CreatedAt { get; set; }
}
