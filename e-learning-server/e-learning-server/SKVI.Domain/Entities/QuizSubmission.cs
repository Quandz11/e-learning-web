namespace SKVI.Domain.Entities;

public class QuizSubmission
{
    public Guid Id { get; set; }
    public Guid QuizId { get; set; }
    public Guid? UserId { get; set; } // Optional, can be anonymous
    
    // Contact Info (for Leads)
    public string? FullName { get; set; }
    public string? PhoneNumber { get; set; }
    public string? Email { get; set; }
    
    public DateTime SubmittedAt { get; set; } = DateTime.UtcNow;
    
    // Navigation properties
    public Quiz Quiz { get; set; } = null!;
    public User? User { get; set; }
    public ICollection<QuizAnswer> Answers { get; set; } = new List<QuizAnswer>();
}
