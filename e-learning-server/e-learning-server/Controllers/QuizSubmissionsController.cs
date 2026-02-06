using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SKVI.Application.DTOs.Quiz;
using SKVI.Application.Interfaces;
using System.Security.Claims;

namespace e_learning_server.Controllers;

[Route("api/[controller]")]
[ApiController]
public class QuizSubmissionsController : ControllerBase
{
    private readonly IQuizSubmissionService _submissionService;

    public QuizSubmissionsController(IQuizSubmissionService submissionService)
    {
        _submissionService = submissionService;
    }

    [HttpPost]
    public async Task<ActionResult<Guid>> SubmitQuiz(SubmitQuizRequest request)
    {
        var userIdString = User.FindFirstValue(ClaimTypes.NameIdentifier);
        Guid? userId = null;
        if (Guid.TryParse(userIdString, out Guid parsedId))
        {
            userId = parsedId;
        }

        var submissionId = await _submissionService.SubmitQuizAsync(request, userId);
        return Ok(submissionId);
    }

    [Authorize(Roles = "ADMIN")]
    [HttpGet("quiz/{quizId}")]
    public async Task<ActionResult<List<QuizSubmissionDto>>> GetSubmissions(Guid quizId)
    {
        var submissions = await _submissionService.GetSubmissionsAsync(quizId);
        return Ok(submissions);
    }
}
