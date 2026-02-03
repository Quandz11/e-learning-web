namespace SKVI.Domain.Entities;

public class LessonPart
{
    public Guid Id { get; set; }
    public Guid LessonId { get; set; }
    public string Title { get; set; } = string.Empty;
    public string Type { get; set; } = "Video"; // "Video", "Document", "Quiz", "Mixed"
    public int OrderIndex { get; set; }
    public bool IsPreview { get; set; }
    
    // Content Links
    public Guid? VideoId { get; set; }
    public Guid? DocumentId { get; set; }
    public string? Content { get; set; } // Rich Text content if needed

    // Navigation properties
    public Lesson Lesson { get; set; } = null!;
    public Video? Video { get; set; }
    public Document? Document { get; set; }
    
    // Tracking progress (part-level progress)
    public ICollection<LessonProgress> LessonProgresses { get; set; } = new List<LessonProgress>();
}
