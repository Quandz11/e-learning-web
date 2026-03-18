using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SKVI.Application.DTOs.Referrals;
using SKVI.Application.Interfaces;
using SKVI.Shared;

namespace e_learning_server.Controllers;

[ApiController]
[Route("api/admin/user-referrals")]
[Authorize(Roles = "ADMIN")]
public class AdminUserReferralsController : ControllerBase
{
    private readonly IUserReferralService _userReferralService;

    public AdminUserReferralsController(IUserReferralService userReferralService)
    {
        _userReferralService = userReferralService;
    }

    [HttpGet]
    public async Task<ActionResult<PagedResult<AdminUserReferralItemDto>>> GetPaged(
        [FromQuery] string? search,
        [FromQuery] bool? isActive,
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 20,
        CancellationToken cancellationToken = default)
    {
        var result = await _userReferralService.GetAdminPagedAsync(search, isActive, page, pageSize, cancellationToken);
        return Ok(result);
    }

    [HttpPut("{id:guid}")]
    public async Task<ActionResult<AdminUserReferralItemDto>> Update(
        Guid id,
        [FromBody] AdminUpdateUserReferralRequest request,
        CancellationToken cancellationToken = default)
    {
        try
        {
            var result = await _userReferralService.UpdateForAdminAsync(id, request, cancellationToken);
            return Ok(result);
        }
        catch (KeyNotFoundException ex)
        {
            return NotFound(new { message = ex.Message });
        }
        catch (ArgumentException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    [HttpPost("bulk-discount-percent")]
    public async Task<ActionResult<AdminBulkUpdateDiscountPercentResultDto>> BulkUpdateDiscountPercent(
        [FromBody] AdminBulkUpdateDiscountPercentRequest request,
        CancellationToken cancellationToken = default)
    {
        try
        {
            var result = await _userReferralService.BulkUpdateDiscountPercentForAdminAsync(request, cancellationToken);
            return Ok(result);
        }
        catch (KeyNotFoundException ex)
        {
            return NotFound(new { message = ex.Message });
        }
        catch (ArgumentException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    [HttpPost("{id:guid}/regenerate-discount")]
    public async Task<ActionResult<AdminUserReferralItemDto>> RegenerateDiscountCode(
        Guid id,
        CancellationToken cancellationToken = default)
    {
        try
        {
            var result = await _userReferralService.RegenerateDiscountCodeForAdminAsync(id, cancellationToken);
            return Ok(result);
        }
        catch (KeyNotFoundException ex)
        {
            return NotFound(new { message = ex.Message });
        }
    }
}
