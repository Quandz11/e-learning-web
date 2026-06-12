using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SKVI.Application.DTOs.Wellness;
using SKVI.Application.Interfaces;

namespace e_learning_server.Controllers;

[ApiController]
[Route("api/admin/wellness-settings")]
[Authorize(Roles = "ADMIN")]
public class WellnessSettingsController : ControllerBase
{
    private readonly IWellnessSettingsService _wellnessSettingsService;

    public WellnessSettingsController(IWellnessSettingsService wellnessSettingsService)
    {
        _wellnessSettingsService = wellnessSettingsService;
    }

    [HttpGet]
    public async Task<IActionResult> GetSettings(CancellationToken cancellationToken)
    {
        var settings = await _wellnessSettingsService.GetAdminSettingsAsync(cancellationToken);
        return Ok(settings);
    }

    [HttpPut]
    public async Task<IActionResult> UpdateSettings(
        [FromBody] UpdateWellnessAdminSettingsRequest request,
        CancellationToken cancellationToken)
    {
        try
        {
            var actorUserId = GetUserId();
            var settings = await _wellnessSettingsService.UpdateSettingsAsync(actorUserId, request, cancellationToken);
            return Ok(settings);
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
        catch (Exception ex)
        {
            return StatusCode(500, new { message = ex.Message, inner = ex.InnerException?.Message, stack = ex.StackTrace });
        }
    }

    private Guid GetUserId()
    {
        var value = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        return Guid.TryParse(value, out var userId) ? userId : Guid.Empty;
    }
}
