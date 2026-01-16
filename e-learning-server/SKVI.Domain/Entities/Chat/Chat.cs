using SKVI.Domain.Common;
using SKVI.Domain.Entities.Auth;

namespace SKVI.Domain.Entities.Chat;

public class Chat : BaseEntity
{
    public Guid StudentId { get; set; }
    public Guid CareId { get; set; }
    
    // Navigation properties
    public User Student { get; set; } = null!;
    public User Care { get; set; } = null!;
    public ICollection<ChatMessage> Messages { get; set; } = new List<ChatMessage>();
}
