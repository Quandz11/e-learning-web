using System.Text.RegularExpressions;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using SKVI.Application.DTOs.Referrals;
using SKVI.Domain.Entities;
using SKVI.Infrastructure;

namespace e_learning_server.Controllers;

[ApiController]
[Route("api/admin/referrals")]
[Authorize(Roles = "ADMIN")]
public class AdminReferralsController : ControllerBase
{
    private static readonly Regex ReferralCodeRegex = new("^[A-Z0-9_-]{4,24}$", RegexOptions.Compiled);

    private readonly ApplicationDbContext _context;
    private readonly ILogger<AdminReferralsController> _logger;

    public AdminReferralsController(ApplicationDbContext context, ILogger<AdminReferralsController> logger)
    {
        _context = context;
        _logger = logger;
    }

    [HttpGet]
    public async Task<ActionResult<ReferralPagedResultDto>> GetAll(
        [FromQuery] string? search,
        [FromQuery] bool? isActive,
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 20,
        CancellationToken cancellationToken = default)
    {
        var safePage = Math.Max(1, page);
        var safePageSize = Math.Clamp(pageSize, 1, 100);

        var query = _context.Cabins
            .AsNoTracking()
            .AsQueryable();

        if (isActive.HasValue)
        {
            query = query.Where(c => c.IsActive == isActive.Value);
        }

        if (!string.IsNullOrWhiteSpace(search))
        {
            var keyword = search.Trim().ToUpper();
            query = query.Where(c =>
                c.Name.ToUpper().Contains(keyword) ||
                (c.ReferralCode != null && c.ReferralCode.ToUpper().Contains(keyword)) ||
                c.OwnerUser.Email.ToUpper().Contains(keyword) ||
                (c.OwnerUser.FullName != null && c.OwnerUser.FullName.ToUpper().Contains(keyword)));
        }

        var total = await query.CountAsync(cancellationToken);
        var items = await query
            .OrderByDescending(c => c.CreatedAt)
            .Skip((safePage - 1) * safePageSize)
            .Take(safePageSize)
            .Select(c => new ReferralItemDto
            {
                Id = c.Id.ToString(),
                Name = c.Name,
                ReferralCode = c.ReferralCode ?? string.Empty,
                OwnerUserId = c.OwnerUserId.ToString(),
                OwnerName = c.OwnerUser.FullName,
                OwnerEmail = c.OwnerUser.Email,
                CommissionRate = c.CommissionRate,
                WalletBalance = c.WalletBalance,
                IsActive = c.IsActive,
                CreatedAt = c.CreatedAt
            })
            .ToListAsync(cancellationToken);

        return Ok(new ReferralPagedResultDto
        {
            Items = items,
            Total = total,
            Page = safePage,
            PageSize = safePageSize
        });
    }

    [HttpGet("{id:guid}")]
    public async Task<ActionResult<ReferralItemDto>> GetById(Guid id, CancellationToken cancellationToken = default)
    {
        var cabin = await _context.Cabins
            .AsNoTracking()
            .Include(c => c.OwnerUser)
            .FirstOrDefaultAsync(c => c.Id == id, cancellationToken);

        if (cabin == null)
        {
            return NotFound(new { message = "Referral not found" });
        }

        return Ok(MapToDto(cabin));
    }

    [HttpPost]
    public async Task<ActionResult<ReferralItemDto>> Create([FromBody] CreateReferralRequest request, CancellationToken cancellationToken = default)
    {
        try
        {
            var ownerId = ParseOwnerId(request.OwnerUserId);
            var normalizedCode = NormalizeReferralCode(request.ReferralCode);

            await EnsureOwnerExistsAsync(ownerId, cancellationToken);
            await EnsureReferralCodeAvailableAsync(normalizedCode, null, cancellationToken);
            EnsureCommissionRateValid(request.CommissionRate);

            var cabin = new Cabin
            {
                Id = Guid.NewGuid(),
                Name = request.Name.Trim(),
                OwnerUserId = ownerId,
                ReferralCode = normalizedCode,
                CommissionRate = request.CommissionRate,
                WalletBalance = 0,
                IsActive = request.IsActive,
                CreatedAt = DateTime.UtcNow
            };

            _context.Cabins.Add(cabin);
            await _context.SaveChangesAsync(cancellationToken);

            var created = await _context.Cabins
                .AsNoTracking()
                .Include(c => c.OwnerUser)
                .FirstAsync(c => c.Id == cabin.Id, cancellationToken);

            return CreatedAtAction(nameof(GetById), new { id = cabin.Id }, MapToDto(created));
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
            _logger.LogError(ex, "Failed to create referral");
            return StatusCode(500, new { message = "Failed to create referral" });
        }
    }

    [HttpPut("{id:guid}")]
    public async Task<ActionResult<ReferralItemDto>> Update(Guid id, [FromBody] UpdateReferralRequest request, CancellationToken cancellationToken = default)
    {
        var cabin = await _context.Cabins.FirstOrDefaultAsync(c => c.Id == id, cancellationToken);
        if (cabin == null)
        {
            return NotFound(new { message = "Referral not found" });
        }

        try
        {
            var ownerId = ParseOwnerId(request.OwnerUserId);
            var normalizedCode = NormalizeReferralCode(request.ReferralCode);

            await EnsureOwnerExistsAsync(ownerId, cancellationToken);
            await EnsureReferralCodeAvailableAsync(normalizedCode, id, cancellationToken);
            EnsureCommissionRateValid(request.CommissionRate);

            cabin.Name = request.Name.Trim();
            cabin.OwnerUserId = ownerId;
            cabin.ReferralCode = normalizedCode;
            cabin.CommissionRate = request.CommissionRate;
            cabin.IsActive = request.IsActive;

            await _context.SaveChangesAsync(cancellationToken);

            var updated = await _context.Cabins
                .AsNoTracking()
                .Include(c => c.OwnerUser)
                .FirstAsync(c => c.Id == cabin.Id, cancellationToken);

            return Ok(MapToDto(updated));
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
            _logger.LogError(ex, "Failed to update referral {ReferralId}", id);
            return StatusCode(500, new { message = "Failed to update referral" });
        }
    }

    [HttpDelete("{id:guid}")]
    public async Task<IActionResult> Deactivate(Guid id, CancellationToken cancellationToken = default)
    {
        var cabin = await _context.Cabins.FirstOrDefaultAsync(c => c.Id == id, cancellationToken);
        if (cabin == null)
        {
            return NotFound(new { message = "Referral not found" });
        }

        cabin.IsActive = false;
        cabin.ReferralCode = null;
        await _context.SaveChangesAsync(cancellationToken);

        return NoContent();
    }

    private static ReferralItemDto MapToDto(Cabin cabin)
    {
        return new ReferralItemDto
        {
            Id = cabin.Id.ToString(),
            Name = cabin.Name,
            ReferralCode = cabin.ReferralCode ?? string.Empty,
            OwnerUserId = cabin.OwnerUserId.ToString(),
            OwnerName = cabin.OwnerUser.FullName,
            OwnerEmail = cabin.OwnerUser.Email,
            CommissionRate = cabin.CommissionRate,
            WalletBalance = cabin.WalletBalance,
            IsActive = cabin.IsActive,
            CreatedAt = cabin.CreatedAt
        };
    }

    private static Guid ParseOwnerId(string ownerUserId)
    {
        if (!Guid.TryParse(ownerUserId, out var ownerId))
        {
            throw new ArgumentException("Owner user id is invalid.");
        }

        return ownerId;
    }

    private static void EnsureCommissionRateValid(decimal rate)
    {
        if (rate < 0 || rate > 100)
        {
            throw new ArgumentException("Commission rate must be between 0 and 100.");
        }
    }

    private static string NormalizeReferralCode(string referralCode)
    {
        if (string.IsNullOrWhiteSpace(referralCode))
        {
            throw new ArgumentException("Referral code is required.");
        }

        var normalized = referralCode.Trim().ToUpperInvariant();
        if (!ReferralCodeRegex.IsMatch(normalized))
        {
            throw new ArgumentException("Referral code must be 4-24 chars and only contain A-Z, 0-9, _ or -.");
        }

        return normalized;
    }

    private async Task EnsureOwnerExistsAsync(Guid ownerUserId, CancellationToken cancellationToken)
    {
        var owner = await _context.Users
            .AsNoTracking()
            .FirstOrDefaultAsync(u => u.Id == ownerUserId && !u.IsDeleted, cancellationToken);

        if (owner == null)
        {
            throw new InvalidOperationException("Owner user not found.");
        }

        if (!string.Equals(owner.Role, "CABIN_OWNER", StringComparison.OrdinalIgnoreCase) &&
            !string.Equals(owner.Role, "ADMIN", StringComparison.OrdinalIgnoreCase))
        {
            throw new InvalidOperationException("Owner user must have CABIN_OWNER or ADMIN role.");
        }
    }

    private async Task EnsureReferralCodeAvailableAsync(string referralCode, Guid? currentCabinId, CancellationToken cancellationToken)
    {
        var exists = await _context.Cabins
            .AsNoTracking()
            .AnyAsync(c =>
                c.ReferralCode != null &&
                c.ReferralCode.ToUpper() == referralCode &&
                (!currentCabinId.HasValue || c.Id != currentCabinId.Value), cancellationToken);

        if (exists)
        {
            throw new InvalidOperationException("Referral code already exists.");
        }
    }
}