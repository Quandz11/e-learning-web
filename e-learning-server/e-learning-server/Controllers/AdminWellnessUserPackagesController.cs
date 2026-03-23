using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SKVI.Application.DTOs.Wellness;
using SKVI.Application.Interfaces;

namespace e_learning_server.Controllers;

[ApiController]
[Route("api/admin/users/{userId:guid}/wellness-packages")]
[Authorize(Roles = "ADMIN")]
public class AdminWellnessUserPackagesController : ControllerBase
{
    private readonly IWellnessSettingsService _wellnessSettingsService;

    public AdminWellnessUserPackagesController(IWellnessSettingsService wellnessSettingsService)
    {
        _wellnessSettingsService = wellnessSettingsService;
    }

    [HttpGet]
    public async Task<IActionResult> GetUserPackages(Guid userId, CancellationToken cancellationToken = default)
    {
        var rows = await _wellnessSettingsService.GetUserPackagesAsync(userId, cancellationToken);
        return Ok(rows);
    }

    [HttpPost]
    public async Task<IActionResult> GrantPackage(
        Guid userId,
        [FromBody] GrantWellnessUserPackageRequest request,
        CancellationToken cancellationToken = default)
    {
        try
        {
            var actorUserId = GetUserId();
            var row = await _wellnessSettingsService.GrantPackageToUserAsync(actorUserId, userId, request, cancellationToken);
            return Ok(row);
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    [HttpPatch("{userPackageId:guid}")]
    public async Task<IActionResult> UpdateAssignment(
        Guid userId,
        Guid userPackageId,
        [FromBody] UpdateWellnessUserPackageRequest request,
        CancellationToken cancellationToken = default)
    {
        try
        {
            var actorUserId = GetUserId();
            var row = await _wellnessSettingsService.UpdateUserPackageAsync(
                actorUserId,
                userId,
                userPackageId,
                request,
                cancellationToken);

            return Ok(row);
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
}

