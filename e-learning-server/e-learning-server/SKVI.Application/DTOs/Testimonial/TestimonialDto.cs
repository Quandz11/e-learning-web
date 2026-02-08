using SKVI.Domain.Enums;

namespace SKVI.Application.DTOs.Testimonial;

public class TestimonialDto
{
    public Guid Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public string? Position { get; set; }
    public string Content { get; set; } = string.Empty;
    public string? AvatarUrl { get; set; }
    public string? VideoUrl { get; set; }
    public TestimonialType Type { get; set; }
    public int Order { get; set; }
    public bool IsActive { get; set; }
    public DateTime CreatedAt { get; set; }
}

public class CreateTestimonialRequest
{
    public string Name { get; set; } = string.Empty;
    public string? Position { get; set; }
    public string Content { get; set; } = string.Empty;
    public string? AvatarUrl { get; set; }
    public string? VideoUrl { get; set; }
    public TestimonialType Type { get; set; } = TestimonialType.Text;
    public int Order { get; set; }
    public bool IsActive { get; set; } = true;
}

public class UpdateTestimonialRequest
{
    public string Name { get; set; } = string.Empty;
    public string? Position { get; set; }
    public string Content { get; set; } = string.Empty;
    public string? AvatarUrl { get; set; }
    public string? VideoUrl { get; set; }
    public TestimonialType Type { get; set; }
    public int Order { get; set; }
    public bool IsActive { get; set; }
}
