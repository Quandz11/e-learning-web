namespace SKVI.Domain.Entities;

public class QuizAnswer
{
    public Guid Id { get; set; }
    public Guid SubmissionId { get; set; }
    public Guid QuestionId { get; set; }
    
    // For text answers
    public string? TextValue { get; set; }
    
    // For choice answers
    public Guid? SelectedOptionId { get; set; }
    
    // Navigation properties
    public QuizSubmission Submission { get; set; } = null!;
    public QuizQuestion Question { get; set; } = null!;
    public QuizQuestionOption? SelectedOption { get; set; }
}
