namespace SKVI.Domain.Entities;

public class QuizQuestionOption
{
    public Guid Id { get; set; }
    public Guid QuestionId { get; set; }
    public string Text { get; set; } = string.Empty;
    public string? Value { get; set; } // Optional internal value
    public int Order { get; set; }

    // Navigation properties
    public QuizQuestion Question { get; set; } = null!;
}
