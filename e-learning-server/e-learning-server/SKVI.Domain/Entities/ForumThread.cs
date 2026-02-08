namespace SKVI.Domain.Entities;

public class ForumThread
{
    public Guid Id { get; set; }
    public Guid CategoryId { get; set; }
    public Guid AuthorId { get; set; }
    public string Title { get; set; } = string.Empty;
    public string Content { get; set; } = string.Empty;
    public int ViewCount { get; set; } = 0;
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime? UpdatedAt { get; set; }
    public DateTime? LastPostAt { get; set; }

    // Navigation properties
    public ForumCategory Category { get; set; } = null!;
    public User Author { get; set; } = null!;
    public ICollection<ForumPost> Posts { get; set; } = new List<ForumPost>();
}
