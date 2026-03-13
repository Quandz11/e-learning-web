namespace SKVI.Domain.Entities;

public class HomeVideoSection
{
    public Guid Id { get; set; }
    
    // Nửa trái
    public string ContentHtml { get; set; } = string.Empty;
    
    // Nửa phải
    public string VideoType { get; set; } = "bunney"; // "bunny" or "youtube"
    
    // For bunny stream
    public Guid? VideoId { get; set; }
    public Video? Video { get; set; }
    
    // For youtube/other iframe
    public string? VideoUrl { get; set; }
    
    public DateTime UpdatedAt { get; set; }
}
