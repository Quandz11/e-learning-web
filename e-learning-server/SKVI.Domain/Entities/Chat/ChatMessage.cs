using SKVI.Domain.Common;
using SKVI.Domain.Entities.Auth;

namespace SKVI.Domain.Entities.Chat;

public class ChatMessage : BaseEntity
{
    public Guid ChatId { get; set; }
    public Guid SenderId { get; set; }
    public string Message { get; set; } = string.Empty;
    
    // Navigation properties
    public Chat Chat { get; set; } = null!;
    public User Sender { get; set; } = null!;
}
