using System.ComponentModel.DataAnnotations;

namespace SKVI.Application.DTOs.Lessons;

public class LessonDto
{
    public Guid Id { get; set; }
    public string Title { get; set; } = string.Empty;
    public string? Description { get; set; }
    public string? ThumbnailUrl { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime? UpdatedAt { get; set; }
    public List<LessonPartDto> Parts { get; set; } = new();
}

public class LessonPartDto
{
    public Guid Id { get; set; }
    public string Title { get; set; } = string.Empty;
    public string Type { get; set; } = "Video";
    public int OrderIndex { get; set; }
    public bool IsPreview { get; set; }
    
    // Content details
    public Guid? VideoId { get; set; }
    public double VideoDuration { get; set; }
    public string? PlaybackUrl { get; set; }
    
    public Guid? DocumentId { get; set; }
    public string? DocumentUrl { get; set; }
    public string? DocumentFileName { get; set; }
    
    public string? Content { get; set; }
}

public class CreateLessonRequest
{
    [Required]
    public string Title { get; set; } = string.Empty;
    public string? Description { get; set; }
    public string? ThumbnailUrl { get; set; }
}

public class UpdateLessonRequest
{
    [Required]
    public string Title { get; set; } = string.Empty;
    public string? Description { get; set; }
    public string? ThumbnailUrl { get; set; }
}
