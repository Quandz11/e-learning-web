using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SKVI.Application.DTOs.Auth;
using SKVI.Application.Services;

namespace SKVI.Controllers;

[ApiController]
[Authorize(Policy = "AdminOnly")]
[Route("api/admin/users/{userId:guid}/sessions")]
public class AdminUserSessionsController(UserSessionService sessions) : ControllerBase
{
    [HttpGet]
    public async Task<IActionResult> List(Guid userId) => Ok(await sessions.ListAsync(userId, null));

    [HttpPost("revoke")]
    public async Task<IActionResult> Revoke(Guid userId, RevokeSessionRequest request)
    {
        try {
            await sessions.RevokeAsync(userId, request.SessionId, null, "admin_revoked",
                Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!));
            return Ok(new { message = "Session revoked" });
        } catch (KeyNotFoundException) { return NotFound(new { message = "Session not found" }); }
    }

    [HttpPost("revoke-all")]
    public async Task<IActionResult> RevokeAll(Guid userId)
    {
        await sessions.RevokeAsync(userId, null, null, "admin_revoked",
            Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!));
        return Ok(new { message = "Sessions revoked" });
    }
}
