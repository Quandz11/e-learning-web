namespace SKVI.Application.DTOs.Quiz;

public class SubmitQuizRequest
{
    public Guid QuizId { get; set; }
    
    // Contact Info
    public string? FullName { get; set; }
    public string? PhoneNumber { get; set; }
    public string? Email { get; set; }
    
    public List<SubmitAnswerRequest> Answers { get; set; } = new();
}

public class SubmitAnswerRequest
{
    public Guid QuestionId { get; set; }
    public string? TextValue { get; set; }
    public Guid? SelectedOptionId { get; set; }
}
