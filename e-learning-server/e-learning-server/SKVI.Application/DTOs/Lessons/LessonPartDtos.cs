using System.ComponentModel.DataAnnotations;

namespace SKVI.Application.DTOs.Lessons;

public class CreateLessonPartRequest
{
    [Required]
    public string Title { get; set; } = string.Empty;
    
    public string Type { get; set; } = "Video"; // Video, Document, etc.
    
    public int OrderIndex { get; set; }
    
    public bool IsPreview { get; set; }
    
    // Content references
    public Guid? VideoId { get; set; }
    
    public Guid? DocumentId { get; set; }
    
    public string? Content { get; set; }
}

public class UpdateLessonPartRequest : CreateLessonPartRequest
{
}
