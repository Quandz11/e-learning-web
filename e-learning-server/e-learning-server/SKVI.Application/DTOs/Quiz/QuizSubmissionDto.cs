using SKVI.Application.DTOs.Quiz;

namespace SKVI.Application.DTOs.Quiz;

public class QuizSubmissionDto
{
    public Guid Id { get; set; }
    public Guid QuizId { get; set; }
    public Guid? UserId { get; set; }
    public string? FullName { get; set; }
    public string? PhoneNumber { get; set; }
    public string? Email { get; set; }
    public DateTime SubmittedAt { get; set; }
    public List<QuizAnswerDto> Answers { get; set; } = new();
}

public class QuizAnswerDto
{
    public Guid Id { get; set; }
    public Guid QuestionId { get; set; }
    public string QuestionText { get; set; } = string.Empty;
    public string? TextValue { get; set; }
    public Guid? SelectedOptionId { get; set; }
    public string? SelectedOptionText { get; set; }
}
