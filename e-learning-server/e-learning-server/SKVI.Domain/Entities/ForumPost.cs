namespace SKVI.Domain.Entities;

public class ForumPost
{
    public Guid Id { get; set; }
    public Guid ThreadId { get; set; }
    public Guid AuthorId { get; set; }
    public string Content { get; set; } = string.Empty;
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime? UpdatedAt { get; set; }

    // Navigation properties
    public ForumThread Thread { get; set; } = null!;
    public User Author { get; set; } = null!;
}
