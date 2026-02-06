using Microsoft.EntityFrameworkCore;
using SKVI.Application.DTOs.Quiz;
using SKVI.Application.Interfaces;
using SKVI.Domain.Entities;
using SKVI.Infrastructure;

namespace SKVI.Application.Services;

public class QuizSubmissionService : IQuizSubmissionService
{
    private readonly ApplicationDbContext _context;

    public QuizSubmissionService(ApplicationDbContext context)
    {
        _context = context;
    }

    public async Task<Guid> SubmitQuizAsync(SubmitQuizRequest request, Guid? userId)
    {
        var submission = new QuizSubmission
        {
            Id = Guid.NewGuid(),
            QuizId = request.QuizId,
            UserId = userId,
            SubmittedAt = DateTime.UtcNow,
            FullName = request.FullName,
            PhoneNumber = request.PhoneNumber,
            Email = request.Email
        };

        foreach (var answerRequest in request.Answers)
        {
            var answer = new QuizAnswer
            {
                Id = Guid.NewGuid(),
                SubmissionId = submission.Id,
                QuestionId = answerRequest.QuestionId,
                TextValue = answerRequest.TextValue,
                SelectedOptionId = answerRequest.SelectedOptionId
            };
            submission.Answers.Add(answer);
        }

        _context.QuizSubmissions.Add(submission);
        await _context.SaveChangesAsync();

        return submission.Id;
    }

    public async Task<List<QuizSubmissionDto>> GetSubmissionsAsync(Guid quizId)
    {
        var submissions = await _context.QuizSubmissions
            .Include(s => s.Answers)
            .ThenInclude(a => a.Question)
            .Include(s => s.Answers)
            .ThenInclude(a => a.SelectedOption)
            .Where(s => s.QuizId == quizId)
            .OrderByDescending(s => s.SubmittedAt)
            .ToListAsync();

        return submissions.Select(s => new QuizSubmissionDto
        {
            Id = s.Id,
            QuizId = s.QuizId,
            UserId = s.UserId,
            FullName = s.FullName,
            PhoneNumber = s.PhoneNumber,
            Email = s.Email,
            SubmittedAt = s.SubmittedAt,
            Answers = s.Answers.Select(a => new QuizAnswerDto
            {
                Id = a.Id,
                QuestionId = a.QuestionId,
                QuestionText = a.Question.Text,
                TextValue = a.TextValue,
                SelectedOptionId = a.SelectedOptionId,
                SelectedOptionText = a.SelectedOption?.Text
            }).ToList()
        }).ToList();
    }
}
