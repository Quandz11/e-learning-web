namespace SKVI.Domain.Entities;

public enum QuestionType
{
    Text = 0,
    MultipleChoice = 1,
    SingleChoice = 2,
    LongText = 3
}

public class QuizQuestion
{
    public Guid Id { get; set; }
    public Guid QuizId { get; set; }
    public string Text { get; set; } = string.Empty;
    public QuestionType Type { get; set; }
    public int Order { get; set; }
    public bool IsRequired { get; set; } = true;

    // Navigation properties
    public Quiz Quiz { get; set; } = null!;
    public ICollection<QuizQuestionOption> Options { get; set; } = new List<QuizQuestionOption>();
}
