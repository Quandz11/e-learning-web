using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using SKVI.Application.DTOs.Referrals;
using SKVI.Domain.Entities;
using SKVI.Infrastructure;

namespace e_learning_server.Controllers;

[ApiController]
[Route("api/admin/commissions")]
[Authorize(Roles = "ADMIN")]
public class AdminCommissionsController : ControllerBase
{
    private readonly ApplicationDbContext _context;
    private readonly ILogger<AdminCommissionsController> _logger;

    public AdminCommissionsController(ApplicationDbContext context, ILogger<AdminCommissionsController> logger)
    {
        _context = context;
        _logger = logger;
    }

    [HttpGet("summary")]
    public async Task<ActionResult<AdminCommissionSummaryDto>> GetSummary(CancellationToken cancellationToken = default)
    {
        var totalPending = await _context.CommissionLedgers
            .AsNoTracking()
            .Where(x => x.Status == "PENDING" || x.Status == "APPROVED")
            .Select(x => (decimal?)x.Amount)
            .SumAsync(cancellationToken) ?? 0m;

        var totalPaid = await _context.CommissionLedgers
            .AsNoTracking()
            .Where(x => x.Status == "PAID")
            .Select(x => (decimal?)x.Amount)
            .SumAsync(cancellationToken) ?? 0m;

        var pendingLedgers = await _context.CommissionLedgers
            .AsNoTracking()
            .CountAsync(x => x.Status == "PENDING" || x.Status == "APPROVED", cancellationToken);

        var paidLedgers = await _context.CommissionLedgers
            .AsNoTracking()
            .CountAsync(x => x.Status == "PAID", cancellationToken);

        var pendingCabins = await _context.CommissionLedgers
            .AsNoTracking()
            .Where(x => x.Status == "PENDING" || x.Status == "APPROVED")
            .Select(x => x.CabinId)
            .Distinct()
            .CountAsync(cancellationToken);

        var payoutCount = await _context.Payouts
            .AsNoTracking()
            .CountAsync(cancellationToken);

        return Ok(new AdminCommissionSummaryDto
        {
            TotalPending = totalPending,
            TotalPaid = totalPaid,
            PendingLedgers = pendingLedgers,
            PaidLedgers = paidLedgers,
            PendingCabins = pendingCabins,
            PayoutCount = payoutCount
        });
    }

    [HttpGet("cabins")]
    public async Task<ActionResult<AdminCommissionCabinPagedResultDto>> GetPendingCabins(
        [FromQuery] string? search,
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 20,
        CancellationToken cancellationToken = default)
    {
        var safePage = Math.Max(1, page);
        var safePageSize = Math.Clamp(pageSize, 1, 100);

        var query =
            from ledger in _context.CommissionLedgers.AsNoTracking()
            join cabin in _context.Cabins.AsNoTracking() on ledger.CabinId equals cabin.Id
            join owner in _context.Users.AsNoTracking() on cabin.OwnerUserId equals owner.Id
            where ledger.Status == "PENDING" || ledger.Status == "APPROVED"
            select new
            {
                ledger.CabinId,
                ledger.Amount,
                ledger.CreatedAt,
                cabin.Name,
                cabin.ReferralCode,
                owner.FullName,
                owner.Email
            };

        if (!string.IsNullOrWhiteSpace(search))
        {
            var keyword = search.Trim().ToUpper();
            query = query.Where(x =>
                x.Name.ToUpper().Contains(keyword) ||
                (x.ReferralCode != null && x.ReferralCode.ToUpper().Contains(keyword)) ||
                x.Email.ToUpper().Contains(keyword) ||
                (x.FullName != null && x.FullName.ToUpper().Contains(keyword)));
        }

        var groupedQuery = query
            .GroupBy(x => new
            {
                x.CabinId,
                x.Name,
                x.ReferralCode,
                x.FullName,
                x.Email
            })
            .Select(group => new AdminCommissionCabinItemDto
            {
                CabinId = group.Key.CabinId.ToString(),
                CabinName = group.Key.Name,
                ReferralCode = group.Key.ReferralCode ?? string.Empty,
                OwnerName = group.Key.FullName,
                OwnerEmail = group.Key.Email,
                PendingAmount = group.Sum(x => x.Amount),
                PendingLedgerCount = group.Count(),
                LastCommissionAt = group.Max(x => x.CreatedAt)
            });

        var total = await groupedQuery.CountAsync(cancellationToken);

        var items = await groupedQuery
            .OrderByDescending(x => x.PendingAmount)
            .ThenByDescending(x => x.LastCommissionAt)
            .Skip((safePage - 1) * safePageSize)
            .Take(safePageSize)
            .ToListAsync(cancellationToken);

        return Ok(new AdminCommissionCabinPagedResultDto
        {
            Items = items,
            Total = total,
            Page = safePage,
            PageSize = safePageSize
        });
    }

    [HttpPost("cabins/{cabinId:guid}/pay")]
    public async Task<ActionResult<PayCabinCommissionResponseDto>> PayCabinCommission(
        Guid cabinId,
        [FromBody] PayCabinCommissionRequestDto? request,
        CancellationToken cancellationToken = default)
    {
        var cabin = await _context.Cabins.FirstOrDefaultAsync(c => c.Id == cabinId, cancellationToken);
        if (cabin == null)
        {
            return NotFound(new { message = "Cabin not found." });
        }

        var ledgers = await _context.CommissionLedgers
            .Where(x => x.CabinId == cabinId && (x.Status == "PENDING" || x.Status == "APPROVED"))
            .ToListAsync(cancellationToken);

        if (ledgers.Count == 0)
        {
            return BadRequest(new { message = "No pending commission found for this cabin." });
        }

        var paidAmount = ledgers.Sum(x => x.Amount);
        var paidLedgerCount = ledgers.Count;
        var paidAt = DateTime.UtcNow;

        foreach (var ledger in ledgers)
        {
            ledger.Status = "PAID";
        }

        var payout = new Payout
        {
            Id = Guid.NewGuid(),
            CabinId = cabinId,
            Amount = paidAmount,
            BankName = NormalizeOptionalText(request?.BankName),
            BankAccount = NormalizeOptionalText(request?.BankAccount),
            Status = "PAID",
            PaidAt = paidAt
        };

        _context.Payouts.Add(payout);
        cabin.WalletBalance = Math.Max(0m, cabin.WalletBalance - paidAmount);

        try
        {
            await _context.SaveChangesAsync(cancellationToken);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to pay commission for cabin {CabinId}", cabinId);
            return StatusCode(500, new { message = "Failed to process commission payout." });
        }

        return Ok(new PayCabinCommissionResponseDto
        {
            PayoutId = payout.Id.ToString(),
            CabinId = cabinId.ToString(),
            PaidAmount = paidAmount,
            PaidLedgerCount = paidLedgerCount,
            PaidAt = paidAt,
            BankName = payout.BankName,
            BankAccount = payout.BankAccount
        });
    }

    private static string? NormalizeOptionalText(string? value)
    {
        if (string.IsNullOrWhiteSpace(value))
        {
            return null;
        }

        return value.Trim();
    }
}
