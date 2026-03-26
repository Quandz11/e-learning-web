using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SKVI.Application.DTOs.Wellness;
using SKVI.Application.Interfaces;
using SKVI.Application.Models;

namespace e_learning_server.Controllers;

[ApiController]
[Route("api/wellness")]
[Authorize]
public class WellnessController : ControllerBase
{
    private readonly IWellnessService _wellnessService;
    private readonly IWellnessSettingsService _wellnessSettingsService;

    public WellnessController(
        IWellnessService wellnessService,
        IWellnessSettingsService wellnessSettingsService)
    {
        _wellnessService = wellnessService;
        _wellnessSettingsService = wellnessSettingsService;
    }

    [HttpGet("checkout-config")]
    [AllowAnonymous]
    public async Task<IActionResult> GetCheckoutConfig(CancellationToken cancellationToken)
    {
        var config = await _wellnessSettingsService.GetCheckoutConfigAsync(cancellationToken);
        return Ok(config);
    }

    [HttpGet("dashboard")]
    public async Task<IActionResult> GetDashboard(CancellationToken cancellationToken)
    {
        var userId = GetUserId();
        var dashboard = await _wellnessService.GetDashboardAsync(userId, cancellationToken);
        return Ok(dashboard);
    }

    [HttpPost("plan")]
    public async Task<IActionResult> UpsertPlan([FromBody] UpsertWellnessPlanRequest request, CancellationToken cancellationToken)
    {
        try
        {
            var userId = GetUserId();
            var plan = await _wellnessService.UpsertPlanAsync(userId, request, cancellationToken);
            return Ok(plan);
        }
        catch (WellnessAccessException ex)
        {
            return PackageForbidden(ex.Code, ex.Message);
        }
        catch (UnauthorizedAccessException ex)
        {
            return PackageForbidden("WELLNESS_PACKAGE_REQUIRED", ex.Message);
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    [HttpPut("plan/{planId:guid}/schedule")]
    public async Task<IActionResult> UpdateSchedule(Guid planId, [FromBody] UpdateWellnessScheduleRequest request, CancellationToken cancellationToken)
    {
        try
        {
            var userId = GetUserId();
            var plan = await _wellnessService.UpdateScheduleAsync(userId, planId, request, cancellationToken);
            return Ok(plan);
        }
        catch (WellnessAccessException ex)
        {
            return PackageForbidden(ex.Code, ex.Message);
        }
        catch (UnauthorizedAccessException ex)
        {
            return PackageForbidden("WELLNESS_PACKAGE_REQUIRED", ex.Message);
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    [HttpPut("plan/{planId:guid}/daily-log")]
    public async Task<IActionResult> UpsertDailyLog(Guid planId, [FromBody] UpsertWellnessDailyLogRequest request, CancellationToken cancellationToken)
    {
        try
        {
            var userId = GetUserId();
            var log = await _wellnessService.UpsertDailyLogAsync(userId, planId, request, cancellationToken);
            return Ok(log);
        }
        catch (WellnessAccessException ex)
        {
            return PackageForbidden(ex.Code, ex.Message);
        }
        catch (UnauthorizedAccessException ex)
        {
            return PackageForbidden("WELLNESS_PACKAGE_REQUIRED", ex.Message);
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    [HttpGet("plan/{planId:guid}/calendar")]
    public async Task<IActionResult> GetCalendar(Guid planId, CancellationToken cancellationToken)
    {
        try
        {
            var userId = GetUserId();
            var data = await _wellnessService.GetCalendarAsync(userId, planId, cancellationToken);
            return Ok(data);
        }
        catch (WellnessAccessException ex)
        {
            return PackageForbidden(ex.Code, ex.Message);
        }
        catch (UnauthorizedAccessException ex)
        {
            return PackageForbidden("WELLNESS_PACKAGE_REQUIRED", ex.Message);
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    [HttpPost("plan/{planId:guid}/coach/mood")]
    public async Task<IActionResult> AskMoodCoach(Guid planId, [FromBody] WellnessCoachMoodRequest request, CancellationToken cancellationToken)
    {
        try
        {
            var userId = GetUserId();
            var reply = await _wellnessService.AskMoodCoachAsync(userId, planId, request, cancellationToken);
            return Ok(reply);
        }
        catch (WellnessAccessException ex)
        {
            return PackageForbidden(ex.Code, ex.Message);
        }
        catch (UnauthorizedAccessException ex)
        {
            return PackageForbidden("WELLNESS_PACKAGE_REQUIRED", ex.Message);
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    [HttpPost("plan/{planId:guid}/coach/meal")]
    public async Task<IActionResult> GenerateMeal(Guid planId, [FromBody] WellnessCoachMealRequest request, CancellationToken cancellationToken)
    {
        try
        {
            var userId = GetUserId();
            var meal = await _wellnessService.GenerateMealSuggestionAsync(userId, planId, request, cancellationToken);
            return Ok(meal);
        }
        catch (WellnessAccessException ex)
        {
            return PackageForbidden(ex.Code, ex.Message);
        }
        catch (UnauthorizedAccessException ex)
        {
            return PackageForbidden("WELLNESS_PACKAGE_REQUIRED", ex.Message);
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    [HttpGet("plan/{planId:guid}/weight-progress")]
    public async Task<IActionResult> GetWeightProgress(Guid planId, CancellationToken cancellationToken)
    {
        try
        {
            var userId = GetUserId();
            var progress = await _wellnessService.GetWeightProgressAsync(userId, planId, cancellationToken);
            return Ok(progress);
        }
        catch (WellnessAccessException ex)
        {
            return PackageForbidden(ex.Code, ex.Message);
        }
        catch (UnauthorizedAccessException ex)
        {
            return PackageForbidden("WELLNESS_PACKAGE_REQUIRED", ex.Message);
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    [HttpGet("plan/{planId:guid}/progress-timeline")]
    public async Task<IActionResult> GetProgressTimeline(Guid planId, [FromQuery] int days = 30, [FromQuery] bool includeFuture = false, CancellationToken cancellationToken = default)
    {
        try
        {
            var userId = GetUserId();
            var timeline = await _wellnessService.GetProgressTimelineAsync(userId, planId, days, includeFuture, cancellationToken);
            return Ok(timeline);
        }
        catch (WellnessAccessException ex)
        {
            return PackageForbidden(ex.Code, ex.Message);
        }
        catch (UnauthorizedAccessException ex)
        {
            return PackageForbidden("WELLNESS_PACKAGE_REQUIRED", ex.Message);
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    [HttpGet("resources")]
    public async Task<IActionResult> GetResources(CancellationToken cancellationToken)
    {
        var resources = await _wellnessService.GetResourcesAsync(cancellationToken);
        return Ok(resources);
    }

    [HttpPost("resources")]
    [Authorize(Roles = "ADMIN")]
    public async Task<IActionResult> CreateResource([FromBody] WellnessResourceUpsertRequest request, CancellationToken cancellationToken)
    {
        try
        {
            var userId = GetUserId();
            var resource = await _wellnessService.CreateResourceAsync(userId, request, cancellationToken);
            return Ok(resource);
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    [HttpPut("resources/{resourceId:guid}")]
    [Authorize(Roles = "ADMIN")]
    public async Task<IActionResult> UpdateResource(Guid resourceId, [FromBody] WellnessResourceUpsertRequest request, CancellationToken cancellationToken)
    {
        try
        {
            var userId = GetUserId();
            var resource = await _wellnessService.UpdateResourceAsync(userId, resourceId, request, cancellationToken);
            return Ok(resource);
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    private Guid GetUserId()
    {
        var value = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        return Guid.TryParse(value, out var userId) ? userId : Guid.Empty;
    }

    private IActionResult PackageForbidden(string code, string message)
    {
        return StatusCode(403, new
        {
            code,
            message
        });
    }
}
