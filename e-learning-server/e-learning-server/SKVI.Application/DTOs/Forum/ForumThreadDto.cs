namespace SKVI.Application.DTOs.Forum;

public class ForumPostDto
{
    public Guid Id { get; set; }
    public Guid ThreadId { get; set; }
    public Guid AuthorId { get; set; }
    public string AuthorName { get; set; } = string.Empty;
    public string? AuthorAvatarUrl { get; set; }
    public string Content { get; set; } = string.Empty;
    public DateTime CreatedAt { get; set; }
    public DateTime? UpdatedAt { get; set; }
}

public class CreateForumPostRequest
{
    public Guid ThreadId { get; set; }
    public string Content { get; set; } = string.Empty;
}

public class UpdateForumPostRequest
{
    public string Content { get; set; } = string.Empty;
}
