using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SKVI.Application.DTOs.Referrals;
using SKVI.Application.Interfaces;
using System.Security.Claims;

namespace e_learning_server.Controllers;

[ApiController]
[Route("api/user/referral")]
[Authorize]
public class UserReferralController : ControllerBase
{
    private readonly IUserReferralService _userReferralService;

    public UserReferralController(IUserReferralService userReferralService)
    {
        _userReferralService = userReferralService;
    }

    [HttpGet("my-referral")]
    public async Task<ActionResult<UserReferralOverviewDto>> GetMyReferral(CancellationToken cancellationToken = default)
    {
        var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (string.IsNullOrEmpty(userId) || !Guid.TryParse(userId, out var userGuid))
        {
            return Unauthorized();
        }

        var result = await _userReferralService.GetOrCreateMyReferralAsync(userGuid, cancellationToken);
        return Ok(result);
    }

    [HttpPost("generate")]
    public async Task<ActionResult<UserReferralOverviewDto>> GenerateMyReferral(CancellationToken cancellationToken = default)
    {
        var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (string.IsNullOrEmpty(userId) || !Guid.TryParse(userId, out var userGuid))
        {
            return Unauthorized();
        }

        var result = await _userReferralService.GetOrCreateMyReferralAsync(userGuid, cancellationToken);
        return Ok(result);
    }
}
