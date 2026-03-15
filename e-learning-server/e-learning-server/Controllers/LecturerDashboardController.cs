using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SKVI.Application.DTOs.Dashboard;
using SKVI.Application.Interfaces;
using System.Security.Claims;

namespace e_learning_server.Controllers;

[ApiController]
[Route("api/lecturer/dashboard")]
[Authorize(Roles = "LECTURER")]
public class LecturerDashboardController : ControllerBase
{
    private readonly ILecturerDashboardService _lecturerDashboardService;
    private readonly ILogger<LecturerDashboardController> _logger;

    public LecturerDashboardController(ILecturerDashboardService lecturerDashboardService, ILogger<LecturerDashboardController> logger)
    {
        _lecturerDashboardService = lecturerDashboardService;
        _logger = logger;
    }

    /// <summary>
    /// Get lecturer dashboard statistics
    /// </summary>
    [HttpGet("stats")]
    public async Task<IActionResult> GetStats(CancellationToken cancellationToken = default)
    {
        try
        {
            var lecturerId = GetCurrentUserId();
            var stats = await _lecturerDashboardService.GetStatsAsync(lecturerId, cancellationToken);
            return Ok(stats);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error retrieving lecturer dashboard stats");
            return StatusCode(500, new { message = "Failed to retrieve dashboard statistics" });
        }
    }

    /// <summary>
    /// Get courses taught by lecturer with pagination
    /// </summary>
    [HttpGet("courses")]
    public async Task<IActionResult> GetCourses(
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 20,
        CancellationToken cancellationToken = default)
    {
        try
        {
            var lecturerId = GetCurrentUserId();
            var courses = await _lecturerDashboardService.GetCoursesAsync(lecturerId, page, pageSize, cancellationToken);
            return Ok(courses);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error retrieving courses");
            return StatusCode(500, new { message = "Failed to retrieve courses" });
        }
    }

    /// <summary>
    /// Get lessons for lecturer's courses
    /// </summary>
    [HttpGet("lessons")]
    public async Task<IActionResult> GetLessons(CancellationToken cancellationToken = default)
    {
        try
        {
            var lecturerId = GetCurrentUserId();
            var lessons = await _lecturerDashboardService.GetLessonsAsync(lecturerId, cancellationToken);
            return Ok(lessons);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error retrieving lessons");
            return StatusCode(500, new { message = "Failed to retrieve lessons" });
        }
    }

    /// <summary>
    /// Get pending quizzes that need grading
    /// </summary>
    [HttpGet("pending-quizzes")]
    public async Task<IActionResult> GetPendingQuizzes(CancellationToken cancellationToken = default)
    {
        try
        {
            var lecturerId = GetCurrentUserId();
            var quizzes = await _lecturerDashboardService.GetPendingQuizzesAsync(lecturerId, cancellationToken);
            return Ok(quizzes);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error retrieving pending quizzes");
            return StatusCode(500, new { message = "Failed to retrieve pending quizzes" });
        }
    }

    /// <summary>
    /// Get quiz submissions for a specific quiz
    /// </summary>
    [HttpGet("quizzes/{quizId}/submissions")]
    public async Task<IActionResult> GetQuizSubmissions(
        Guid quizId,
        [FromQuery] string? status = null,
        CancellationToken cancellationToken = default)
    {
        try
        {
            var submissions = await _lecturerDashboardService.GetQuizSubmissionsAsync(quizId, status, cancellationToken);
            return Ok(submissions);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error retrieving quiz submissions");
            return StatusCode(500, new { message = "Failed to retrieve quiz submissions" });
        }
    }

    /// <summary>
    /// Get all student progress for lecturer's courses
    /// </summary>
    [HttpGet("student-progress")]
    public async Task<IActionResult> GetStudentProgress(CancellationToken cancellationToken = default)
    {
        try
        {
            var lecturerId = GetCurrentUserId();
            var progress = await _lecturerDashboardService.GetStudentProgressAsync(lecturerId, cancellationToken);
            return Ok(progress);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error retrieving student progress");
            return StatusCode(500, new { message = "Failed to retrieve student progress" });
        }
    }

    /// <summary>
    /// Get specific student's progress detail
    /// </summary>
    [HttpGet("student-progress/{studentId}")]
    public async Task<IActionResult> GetStudentProgressDetail(Guid studentId, CancellationToken cancellationToken = default)
    {
        try
        {
            var lecturerId = GetCurrentUserId();
            var progress = await _lecturerDashboardService.GetStudentProgressDetailAsync(lecturerId, studentId, cancellationToken);
            if (progress == null)
                return NotFound();
            return Ok(progress);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error retrieving student progress detail");
            return StatusCode(500, new { message = "Failed to retrieve student progress detail" });
        }
    }

    /// <summary>
    /// Get course analytics and engagement data
    /// </summary>
    [HttpGet("analytics")]
    public async Task<IActionResult> GetAnalytics(CancellationToken cancellationToken = default)
    {
        try
        {
            var lecturerId = GetCurrentUserId();
            var analytics = await _lecturerDashboardService.GetAnalyticsAsync(lecturerId, cancellationToken);
            return Ok(analytics);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error retrieving analytics");
            return StatusCode(500, new { message = "Failed to retrieve analytics" });
        }
    }

    /// <summary>
    /// Get messages from students
    /// </summary>
    [HttpGet("messages")]
    public async Task<IActionResult> GetMessages(CancellationToken cancellationToken = default)
    {
        try
        {
            var lecturerId = GetCurrentUserId();
            var messages = await _lecturerDashboardService.GetMessagesAsync(lecturerId, cancellationToken);
            return Ok(messages);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error retrieving messages");
            return StatusCode(500, new { message = "Failed to retrieve messages" });
        }
    }

    /// <summary>
    /// Grade a quiz submission
    /// </summary>
    [HttpPost("quizzes/{submissionId}/grade")]
    public async Task<IActionResult> GradeQuizSubmission(string submissionId, GradeQuizSubmissionDto request, CancellationToken cancellationToken = default)
    {
        try
        {
            await _lecturerDashboardService.GradeQuizSubmissionAsync(submissionId, request, cancellationToken);
            return Ok(new { message = "Quiz graded successfully" });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error grading quiz submission");
            return StatusCode(500, new { message = "Failed to grade quiz submission" });
        }
    }

    /// <summary>
    /// Get Zoom class schedule - placeholder for future integration
    /// </summary>
    [HttpGet("zoom-schedule")]
    public async Task<IActionResult> GetZoomSchedule(CancellationToken cancellationToken = default)
    {
        try
        {
            var lecturerId = GetCurrentUserId();
            var schedule = await _lecturerDashboardService.GetZoomScheduleAsync(lecturerId, cancellationToken);
            return Ok(schedule);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error retrieving Zoom schedule");
            return StatusCode(500, new { message = "Failed to retrieve Zoom schedule" });
        }
    }

    private Guid GetCurrentUserId()
    {
        var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        return Guid.TryParse(userIdClaim, out var userId) ? userId : Guid.Empty;
    }
}
