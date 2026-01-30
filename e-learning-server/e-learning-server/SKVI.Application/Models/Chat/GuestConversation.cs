namespace SKVI.Application.Models.Chat;

public class GuestMessage
{
    public string Id { get; set; } = Guid.NewGuid().ToString();
    public string SenderId { get; set; } = string.Empty;
    public string SenderName { get; set; } = string.Empty;
    public string Content { get; set; } = string.Empty;
    public DateTime SentAt { get; set; } = DateTime.UtcNow;
    public bool IsFromGuest { get; set; }
}

public class GuestConversation
{
    public string GuestId { get; set; } = string.Empty;
    public List<GuestMessage> Messages { get; set; } = new();
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime LastActivity { get; set; } = DateTime.UtcNow;
    public bool IsActive { get; set; } = true;
    public string? LastMessage => Messages.LastOrDefault()?.Content;
    public int UnreadCount { get; set; } = 0;
}
