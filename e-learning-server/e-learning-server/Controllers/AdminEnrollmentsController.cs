using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SKVI.Application.DTOs.Enrollment;
using SKVI.Application.Interfaces;

namespace e_learning_server.Controllers;

[ApiController]
[Route("api/admin/users/{userId}/enrollments")]
[Authorize(Roles = "ADMIN")]
public class AdminEnrollmentsController : ControllerBase
{
    private readonly IEnrollmentService _enrollmentService;
    private readonly ILogger<AdminEnrollmentsController> _logger;

    public AdminEnrollmentsController(IEnrollmentService enrollmentService, ILogger<AdminEnrollmentsController> logger)
    {
        _enrollmentService = enrollmentService;
        _logger = logger;
    }

    /// <summary>
    /// [ADMIN] List all enrollments (any status) for a specific user
    /// GET /api/admin/users/{userId}/enrollments
    /// </summary>
    [HttpGet]
    public async Task<IActionResult> GetUserEnrollments(string userId)
    {
        if (!Guid.TryParse(userId, out var userGuid))
            return BadRequest(new { message = "Invalid user ID" });

        try
        {
            var enrollments = await _enrollmentService.AdminGetUserEnrollmentsAsync(userGuid);
            return Ok(enrollments);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error getting enrollments for user {UserId}", userId);
            return StatusCode(500, new { message = "Failed to retrieve enrollments" });
        }
    }

    /// <summary>
    /// [ADMIN] Manually add enrollment for a user (sets Status = ACTIVE)
    /// POST /api/admin/users/{userId}/enrollments
    /// Body: { courseId: "..." }
    /// </summary>
    [HttpPost]
    public async Task<IActionResult> AddEnrollment(string userId, [FromBody] AdminAddEnrollmentRequest request)
    {
        if (!Guid.TryParse(userId, out var userGuid))
            return BadRequest(new { message = "Invalid user ID" });

        try
        {
            var enrollment = await _enrollmentService.AdminAddEnrollmentAsync(userGuid, request.CourseId);
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
            _logger.LogError(ex, "Error adding enrollment for user {UserId}", userId);
            return StatusCode(500, new { message = "Failed to add enrollment" });
        }
    }

    /// <summary>
    /// [ADMIN] Remove enrollment for a user
    /// DELETE /api/admin/users/{userId}/enrollments/{courseId}
    /// </summary>
    [HttpDelete("{courseId}")]
    public async Task<IActionResult> RemoveEnrollment(string userId, string courseId)
    {
        if (!Guid.TryParse(userId, out var userGuid))
            return BadRequest(new { message = "Invalid user ID" });

        if (!Guid.TryParse(courseId, out var courseGuid))
            return BadRequest(new { message = "Invalid course ID" });

        try
        {
            await _enrollmentService.AdminRemoveEnrollmentAsync(userGuid, courseGuid);
            return NoContent();
        }
        catch (InvalidOperationException ex)
        {
            return NotFound(new { message = ex.Message });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error removing enrollment for user {UserId}, course {CourseId}", userId, courseId);
            return StatusCode(500, new { message = "Failed to remove enrollment" });
        }
    }

    /// <summary>
    /// [ADMIN] Set enrollment status (ACTIVE / INACTIVE)
    /// PATCH /api/admin/users/{userId}/enrollments/{enrollmentId}/status
    /// Body: { status: "ACTIVE" | "INACTIVE" }
    /// </summary>
    [HttpPatch("{enrollmentId}/status")]
    public async Task<IActionResult> SetEnrollmentStatus(
        string userId,
        string enrollmentId,
        [FromBody] AdminSetEnrollmentStatusRequest request)
    {
        if (!Guid.TryParse(enrollmentId, out var enrollmentGuid))
            return BadRequest(new { message = "Invalid enrollment ID" });

        try
        {
            var result = await _enrollmentService.AdminSetEnrollmentStatusAsync(enrollmentGuid, request.Status);
            return Ok(result);
        }
        catch (ArgumentException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
        catch (InvalidOperationException ex)
        {
            return NotFound(new { message = ex.Message });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error setting enrollment status for enrollment {EnrollmentId}", enrollmentId);
            return StatusCode(500, new { message = "Failed to update enrollment status" });
        }
    }
}
