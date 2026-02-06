namespace SKVI.Domain.Entities;

public class Testimonial
{
    public Guid Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public string? Position { get; set; }
    public string Content { get; set; } = string.Empty;
    public string? AvatarUrl { get; set; }
    public int Order { get; set; }
    public bool IsActive { get; set; } = true;
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
}
