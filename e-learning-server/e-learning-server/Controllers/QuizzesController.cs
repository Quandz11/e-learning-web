using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SKVI.Application.DTOs.Quiz;
using SKVI.Application.Interfaces;

namespace e_learning_server.Controllers;

[Route("api/[controller]")]
[ApiController]
public class QuizzesController : ControllerBase
{
    private readonly IQuizService _quizService;

    public QuizzesController(IQuizService quizService)
    {
        _quizService = quizService;
    }

    [HttpGet("active")]
    public async Task<ActionResult<QuizDto>> GetActiveQuiz()
    {
        var quiz = await _quizService.GetActiveQuizAsync();
        if (quiz == null) return NotFound();
        return Ok(quiz);
    }

    [Authorize(Roles = "ADMIN")]
    [HttpGet]
    public async Task<ActionResult<List<QuizDto>>> GetAllQuizzes()
    {
        var quizzes = await _quizService.GetAllQuizzesAsync();
        return Ok(quizzes);
    }

    [HttpGet("{id}")]
    public async Task<ActionResult<QuizDto>> GetQuizById(Guid id)
    {
        var quiz = await _quizService.GetQuizByIdAsync(id);
        if (quiz == null) return NotFound();
        return Ok(quiz);
    }

    [Authorize(Roles = "ADMIN")]
    [HttpPost]
    public async Task<ActionResult<QuizDto>> CreateQuiz(CreateQuizRequest request)
    {
        var quiz = await _quizService.CreateQuizAsync(request);
        return CreatedAtAction(nameof(GetQuizById), new { id = quiz.Id }, quiz);
    }

    [Authorize(Roles = "ADMIN")]
    [HttpPut("{id}")]
    public async Task<ActionResult<QuizDto>> UpdateQuiz(Guid id, UpdateQuizRequest request)
    {
        try 
        {
            var quiz = await _quizService.UpdateQuizAsync(id, request);
            return Ok(quiz);
        }
        catch (Exception ex)
        {
             return BadRequest(ex.Message);
        }
    }

    [Authorize(Roles = "ADMIN")]
    [HttpDelete("{id}")]
    public async Task<ActionResult> DeleteQuiz(Guid id)
    {
        var success = await _quizService.DeleteQuizAsync(id);
        if (!success) return NotFound();
        return NoContent();
    }
}
