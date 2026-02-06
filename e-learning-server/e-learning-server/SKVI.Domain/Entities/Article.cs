namespace SKVI.Domain.Entities;

public class Article
{
    public Guid Id { get; set; }
    public string Title { get; set; } = string.Empty;
    public string Slug { get; set; } = string.Empty;
    public string Content { get; set; } = string.Empty; // HTML content
    public string? Excerpt { get; set; }
    public string? FeaturedImageUrl { get; set; }
    public Guid? CategoryId { get; set; }
    public Guid AuthorId { get; set; }
    public bool IsPublished { get; set; } = false;
    public DateTime? PublishedAt { get; set; }
    public int ViewCount { get; set; } = 0;
    public string? MetaDescription { get; set; }
    public string? MetaKeywords { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;

    // Navigation properties
    public ArticleCategory? Category { get; set; }
    public User Author { get; set; } = null!;
}
