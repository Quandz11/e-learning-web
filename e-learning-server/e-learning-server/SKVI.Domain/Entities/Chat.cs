namespace SKVI.Domain.Entities;

public class Chat
{
    public Guid Id { get; set; }
    public Guid? StudentId { get; set; }
    public Guid? CareId { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    // Navigation properties
    public ICollection<ChatMessage> Messages { get; set; } = new List<ChatMessage>();
}
