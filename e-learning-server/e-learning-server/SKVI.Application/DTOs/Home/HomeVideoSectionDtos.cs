namespace SKVI.Application.DTOs.Home;

public class HomeVideoSectionDto
{
    public Guid Id { get; set; }
    public string ContentHtml { get; set; } = string.Empty;
    public string VideoType { get; set; } = "bunny"; // "bunny" or "youtube"
    
    // For bunny stream
    public Guid? VideoId { get; set; }
    public string? BunnyVideoId { get; set; }
    
    // For youtube/other iframe
    public string? VideoUrl { get; set; }
    
    public DateTime UpdatedAt { get; set; }
}

public class UpdateHomeVideoSectionDto
{
    public string ContentHtml { get; set; } = string.Empty;
    public string VideoType { get; set; } = "bunny";
    
    public Guid? VideoId { get; set; }
    public string? VideoUrl { get; set; }
}
