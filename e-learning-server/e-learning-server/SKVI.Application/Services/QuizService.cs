using Microsoft.EntityFrameworkCore;
using SKVI.Application.DTOs.Quiz;
using SKVI.Application.Interfaces;
using SKVI.Domain.Entities;
using SKVI.Infrastructure;

namespace SKVI.Application.Services;

public class QuizService : IQuizService
{
    private readonly ApplicationDbContext _context;

    public QuizService(ApplicationDbContext context)
    {
        _context = context;
    }

    public async Task<QuizDto?> GetActiveQuizAsync()
    {
        var quiz = await _context.Quizzes
            .Include(q => q.Questions)
            .ThenInclude(q => q.Options)
            .Where(q => q.IsActive)
            .OrderByDescending(q => q.CreatedAt)
            .FirstOrDefaultAsync();

        if (quiz == null) return null;

        return MapToDto(quiz);
    }

    public async Task<List<QuizDto>> GetAllQuizzesAsync()
    {
        var quizzes = await _context.Quizzes
            .Include(q => q.Questions)
            .ThenInclude(q => q.Options)
            .OrderByDescending(q => q.CreatedAt)
            .ToListAsync();

        return quizzes.Select(MapToDto).ToList();
    }

    public async Task<QuizDto?> GetQuizByIdAsync(Guid id)
    {
        var quiz = await _context.Quizzes
            .Include(q => q.Questions)
            .ThenInclude(q => q.Options)
            .FirstOrDefaultAsync(q => q.Id == id);

        if (quiz == null) return null;
        return MapToDto(quiz);
    }

    public async Task<QuizDto> CreateQuizAsync(CreateQuizRequest request)
    {
        var quiz = new Quiz
        {
            Id = Guid.NewGuid(),
            Title = request.Title,
            Description = request.Description,
            IsActive = request.IsActive,
            CreatedAt = DateTime.UtcNow
        };

        foreach (var qRequest in request.Questions)
        {
            var question = new QuizQuestion
            {
                Id = Guid.NewGuid(),
                QuizId = quiz.Id,
                Text = qRequest.Text,
                Type = qRequest.Type,
                Order = qRequest.Order,
                IsRequired = qRequest.IsRequired
            };

            foreach (var oRequest in qRequest.Options)
            {
                question.Options.Add(new QuizQuestionOption
                {
                    Id = Guid.NewGuid(),
                    QuestionId = question.Id,
                    Text = oRequest.Text,
                    Value = oRequest.Value,
                    Order = oRequest.Order
                });
            }

            quiz.Questions.Add(question);
        }
        
        // If this new quiz is active, de-activate others? Or allow multiple active? 
        // User asked for "THE QUiz", so maybe only 1 active. But for now allow multiple.
        
        _context.Quizzes.Add(quiz);
        await _context.SaveChangesAsync();

        return MapToDto(quiz);
    }

    public async Task<QuizDto> UpdateQuizAsync(Guid id, UpdateQuizRequest request)
    {
        var quiz = await _context.Quizzes
            .Include(q => q.Questions)
            .ThenInclude(q => q.Options)
            .FirstOrDefaultAsync(q => q.Id == id);

        if (quiz == null) throw new Exception("Quiz not found");

        quiz.Title = request.Title;
        quiz.Description = request.Description;
        quiz.IsActive = request.IsActive;

        // Delete existing questions and options explicitly to avoid tracking issues
        var existingQuestions = quiz.Questions.ToList();
        foreach (var question in existingQuestions)
        {
            var existingOptions = question.Options.ToList();
            foreach (var option in existingOptions)
            {
                _context.QuizQuestionOptions.Remove(option);
            }
            _context.QuizQuestions.Remove(question);
        }
        
        // Save deletions first
        await _context.SaveChangesAsync();

        // Now add new questions
        foreach (var qRequest in request.Questions)
        {
            var question = new QuizQuestion
            {
                Id = Guid.NewGuid(),
                QuizId = quiz.Id,
                Text = qRequest.Text,
                Type = qRequest.Type,
                Order = qRequest.Order,
                IsRequired = qRequest.IsRequired,
                Options = new List<QuizQuestionOption>()
            };

            foreach (var oRequest in qRequest.Options)
            {
                question.Options.Add(new QuizQuestionOption
                {
                    Id = Guid.NewGuid(),
                    QuestionId = question.Id,
                    Text = oRequest.Text,
                    Value = oRequest.Value,
                    Order = oRequest.Order
                });
            }
            
            _context.QuizQuestions.Add(question);
        }

        await _context.SaveChangesAsync();
        
        // Reload quiz with new questions
        quiz = await _context.Quizzes
            .Include(q => q.Questions)
            .ThenInclude(q => q.Options)
            .FirstOrDefaultAsync(q => q.Id == id);
            
        return MapToDto(quiz!);
    }

    public async Task<bool> DeleteQuizAsync(Guid id)
    {
        var quiz = await _context.Quizzes.FindAsync(id);
        if (quiz == null) return false;

        _context.Quizzes.Remove(quiz);
        await _context.SaveChangesAsync();
        return true;
    }

    private static QuizDto MapToDto(Quiz quiz)
    {
        return new QuizDto
        {
            Id = quiz.Id,
            Title = quiz.Title,
            Description = quiz.Description,
            IsActive = quiz.IsActive,
            CreatedAt = quiz.CreatedAt,
            Questions = quiz.Questions.OrderBy(q => q.Order).Select(q => new QuizQuestionDto
            {
                Id = q.Id,
                Text = q.Text,
                Type = q.Type,
                Order = q.Order,
                IsRequired = q.IsRequired,
                Options = q.Options.OrderBy(o => o.Order).Select(o => new QuizQuestionOptionDto
                {
                    Id = o.Id,
                    Text = o.Text,
                    Value = o.Value,
                    Order = o.Order
                }).ToList()
            }).ToList()
        };
    }
}
