using SKVI.Domain.Entities;

namespace SKVI.Application.DTOs.Quiz;

public class QuizDto
{
    public Guid Id { get; set; }
    public string Title { get; set; } = string.Empty;
    public string? Description { get; set; }
    public bool IsActive { get; set; }
    public DateTime CreatedAt { get; set; }
    public List<QuizQuestionDto> Questions { get; set; } = new();
}

public class QuizQuestionDto
{
    public Guid Id { get; set; }
    public string Text { get; set; } = string.Empty;
    public QuestionType Type { get; set; }
    public int Order { get; set; }
    public bool IsRequired { get; set; }
    public List<QuizQuestionOptionDto> Options { get; set; } = new();
}

public class QuizQuestionOptionDto
{
    public Guid Id { get; set; }
    public string Text { get; set; } = string.Empty;
    public string? Value { get; set; }
    public int Order { get; set; }
}
