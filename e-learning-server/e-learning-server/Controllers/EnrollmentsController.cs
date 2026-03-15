using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SKVI.Application.DTOs.Enrollment;
using SKVI.Application.Interfaces;
using System.Security.Claims;

namespace e_learning_server.Controllers;

[ApiController]
[Route("api/enrollments")]
[Authorize]
public class EnrollmentsController : ControllerBase
{
    private readonly IEnrollmentService _enrollmentService;
    private readonly ILessonProgressService _lessonProgressService;
    private readonly ILogger<EnrollmentsController> _logger;

    public EnrollmentsController(
        IEnrollmentService enrollmentService,
        ILessonProgressService lessonProgressService,
        ILogger<EnrollmentsController> logger)
    {
        _enrollmentService = enrollmentService;
        _lessonProgressService = lessonProgressService;
        _logger = logger;
    }

    private Guid GetUserId()
    {
        var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (string.IsNullOrEmpty(userIdClaim) || !Guid.TryParse(userIdClaim, out var userId))
        {
            throw new UnauthorizedAccessException("Invalid user ID");
        }
        return userId;
    }

    /// <summary>
    /// Enroll in a course (free courses only for now)
    /// </summary>
    [HttpPost]
    public async Task<IActionResult> EnrollInCourse([FromBody] EnrollmentRequest request)
    {
        try
        {
            var userId = GetUserId();
            var enrollment = await _enrollmentService.EnrollInCourseAsync(userId, request.CourseId);
            return Ok(enrollment);
        }
        catch (ArgumentException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error enrolling user in course");
            return StatusCode(500, new { message = "Failed to enroll in course" });
        }
    }

    /// <summary>
    /// Check if user is enrolled in a course
    /// </summary>
    [HttpGet("check/{courseId}")]
    public async Task<IActionResult> CheckEnrollment(string courseId)
    {
        try
        {
            if (!Guid.TryParse(courseId, out var courseGuid))
            {
                return BadRequest(new { message = "Invalid course ID" });
            }

            var userId = GetUserId();
            var isEnrolled = await _enrollmentService.IsEnrolledAsync(userId, courseGuid);
            return Ok(new { isEnrolled });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error checking enrollment");
            return StatusCode(500, new { message = "Failed to check enrollment" });
        }
    }

    /// <summary>
    /// Get all user enrollments
    /// </summary>
    [HttpGet]
    public async Task<IActionResult> GetUserEnrollments()
    {
        try
        {
            var userId = GetUserId();
            var enrollments = await _enrollmentService.GetUserEnrollmentsAsync(userId);
            return Ok(enrollments);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error fetching enrollments");
            return StatusCode(500, new { message = "Failed to fetch enrollments" });
        }
    }

    /// <summary>
    /// Get progress for a specific course
    /// </summary>
    [HttpGet("{courseId}/progress")]
    public async Task<IActionResult> GetCourseProgress(string courseId)
    {
        try
        {
            if (!Guid.TryParse(courseId, out var courseGuid))
            {
                return BadRequest(new { message = "Invalid course ID" });
            }

            var userId = GetUserId();
            var progress = await _enrollmentService.GetCourseProgressAsync(userId, courseGuid);
            return Ok(progress);
        }
        catch (InvalidOperationException ex)
        {
            return NotFound(new { message = ex.Message });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error fetching course progress");
            return StatusCode(500, new { message = "Failed to fetch progress" });
        }
    }

    /// <summary>
    /// Update lesson progress (watch time)
    /// </summary>
    [HttpPost("{courseId}/lessons/{lessonPartId}/progress")]
    public async Task<IActionResult> UpdateLessonProgress(
        string courseId,
        string lessonPartId,
        [FromBody] UpdateProgressRequest request)
    {
        try
        {
            if (!Guid.TryParse(courseId, out var courseGuid) || !Guid.TryParse(lessonPartId, out var lessonPartGuid))
            {
                return BadRequest(new { message = "Invalid course or lesson part ID" });
            }

            if (request.WatchedDuration < 0)
            {
                return BadRequest(new { message = "Watched duration must be non-negative" });
            }

            var userId = GetUserId();
            await _lessonProgressService.UpdateProgressAsync(userId, courseGuid, lessonPartGuid, request.WatchedDuration);
            return Ok(new { message = "Progress updated" });
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error updating lesson progress");
            return StatusCode(500, new { message = "Failed to update progress" });
        }
    }

    /// <summary>
    /// Mark lesson as complete
    /// </summary>
    [HttpPost("{courseId}/lessons/{lessonPartId}/complete")]
    public async Task<IActionResult> MarkLessonComplete(string courseId, string lessonPartId)
    {
        try
        {
            if (!Guid.TryParse(courseId, out var courseGuid) || !Guid.TryParse(lessonPartId, out var lessonPartGuid))
            {
                return BadRequest(new { message = "Invalid course or lesson part ID" });
            }

            var userId = GetUserId();
            await _lessonProgressService.MarkLessonCompleteAsync(userId, courseGuid, lessonPartGuid);
            return Ok(new { message = "Lesson marked as complete" });
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error marking lesson complete");
            return StatusCode(500, new { message = "Failed to mark lesson complete" });
        }
    }

    /// <summary>
    /// Update last accessed time for a course
    /// </summary>
    [HttpPut("{courseId}/access")]
    public async Task<IActionResult> UpdateLastAccessed(string courseId)
    {
        try
        {
            if (!Guid.TryParse(courseId, out var courseGuid))
            {
                return BadRequest(new { message = "Invalid course ID" });
            }

            var userId = GetUserId();
            await _enrollmentService.UpdateLastAccessedAsync(userId, courseGuid);
            return Ok(new { message = "Last accessed updated" });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error updating last accessed");
            return StatusCode(500, new { message = "Failed to update" });
        }
    }
}
