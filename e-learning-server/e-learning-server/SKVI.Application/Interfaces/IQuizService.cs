using SKVI.Application.DTOs.Quiz;

namespace SKVI.Application.Interfaces;

public interface IQuizService
{
    Task<QuizDto?> GetActiveQuizAsync();
    Task<List<QuizDto>> GetAllQuizzesAsync();
    Task<QuizDto?> GetQuizByIdAsync(Guid id);
    Task<QuizDto> CreateQuizAsync(CreateQuizRequest request);
    Task<QuizDto> UpdateQuizAsync(Guid id, UpdateQuizRequest request);
    Task<bool> DeleteQuizAsync(Guid id);
}

public interface IQuizSubmissionService
{
    Task<Guid> SubmitQuizAsync(SubmitQuizRequest request, Guid? userId);
    Task<List<QuizSubmissionDto>> GetSubmissionsAsync(Guid quizId);
}
