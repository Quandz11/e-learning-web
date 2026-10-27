using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SKVI.Application.DTOs.Running;
using SKVI.Application.Interfaces;

namespace e_learning_server.Controllers;

[ApiController]
[Route("api/running")]
[Authorize]
public class RunningController : ControllerBase
{
    private readonly IRunningService _runningService;

    public RunningController(IRunningService runningService)
    {
        _runningService = runningService;
    }

    [HttpPost("activities")]
    public async Task<IActionResult> CreateActivity([FromBody] CreateRunningActivityRequest request, CancellationToken cancellationToken)
    {
        var userId = GetUserId();
        if (userId == Guid.Empty) return Unauthorized();

        try
        {
            var activity = await _runningService.CreateActivityAsync(userId, request, cancellationToken);
            return Ok(activity);
        }
        catch (ArgumentException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    [HttpGet("activities")]
    public async Task<IActionResult> GetActivities(
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 20,
        [FromQuery] int? month = null,
        [FromQuery] int? year = null,
        CancellationToken cancellationToken = default)
    {
        var userId = GetUserId();
        if (userId == Guid.Empty) return Unauthorized();

        var result = await _runningService.GetActivitiesAsync(userId, page, pageSize, month, year, cancellationToken);
        return Ok(result);
    }

    [HttpGet("activities/{id:guid}")]
    public async Task<IActionResult> GetActivityById(Guid id, CancellationToken cancellationToken)
    {
        var userId = GetUserId();
        if (userId == Guid.Empty) return Unauthorized();

        var activity = await _runningService.GetActivityByIdAsync(userId, id, cancellationToken);
        if (activity == null) return NotFound(new { message = "Buổi chạy không tồn tại." });

        return Ok(activity);
    }

    [HttpDelete("activities/{id:guid}")]
    public async Task<IActionResult> DeleteActivity(Guid id, CancellationToken cancellationToken)
    {
        var userId = GetUserId();
        if (userId == Guid.Empty) return Unauthorized();

        var success = await _runningService.DeleteActivityAsync(userId, id, cancellationToken);
        if (!success) return NotFound(new { message = "Không tìm thấy buổi chạy cần xóa." });

        return Ok(new { message = "Đã xóa buổi chạy thành công." });
    }

    [HttpGet("summary")]
    public async Task<IActionResult> GetSummary(CancellationToken cancellationToken)
    {
        var userId = GetUserId();
        if (userId == Guid.Empty) return Unauthorized();

        var summary = await _runningService.GetSummaryAsync(userId, cancellationToken);
        return Ok(summary);
    }

    private Guid GetUserId()
    {
        var value = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        return Guid.TryParse(value, out var userId) ? userId : Guid.Empty;
    }
}
