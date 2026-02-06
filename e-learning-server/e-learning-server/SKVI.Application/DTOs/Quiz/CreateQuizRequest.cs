using SKVI.Domain.Entities;

namespace SKVI.Application.DTOs.Quiz;

public class CreateQuizRequest
{
    public string Title { get; set; } = string.Empty;
    public string? Description { get; set; }
    public bool IsActive { get; set; } = true;
    public List<CreateQuestionRequest> Questions { get; set; } = new();
}

public class UpdateQuizRequest : CreateQuizRequest 
{
    // inherited
}

public class CreateQuestionRequest
{
    public Guid? Id { get; set; } // Optional for update
    public string Text { get; set; } = string.Empty;
    public QuestionType Type { get; set; }
    public int Order { get; set; }
    public bool IsRequired { get; set; } = true;
    public List<CreateOptionRequest> Options { get; set; } = new();
}

public class CreateOptionRequest
{
    public Guid? Id { get; set; }
    public string Text { get; set; } = string.Empty;
    public string? Value { get; set; }
    public int Order { get; set; }
}
