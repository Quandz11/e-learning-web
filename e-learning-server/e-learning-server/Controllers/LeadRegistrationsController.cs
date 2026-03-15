using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using SKVI.Application.DTOs.Leads;
using SKVI.Domain.Entities;
using SKVI.Infrastructure;

namespace e_learning_server.Controllers;

[ApiController]
[Route("api/lead-registrations")]
public class LeadRegistrationsController : ControllerBase
{
    private static readonly string[] AllowedStatuses =
    {
        "NEW",
        "CONTACTED",
        "CONSULTING",
        "CONVERTED",
        "LOST"
    };

    private readonly ApplicationDbContext _context;
    private readonly ILogger<LeadRegistrationsController> _logger;

    public LeadRegistrationsController(ApplicationDbContext context, ILogger<LeadRegistrationsController> logger)
    {
        _context = context;
        _logger = logger;
    }

    [HttpPost]
    [AllowAnonymous]
    public async Task<ActionResult<LeadRegistrationDto>> Create(
        [FromBody] CreateLeadRegistrationRequest request,
        CancellationToken cancellationToken = default)
    {
        try
        {
            var fullName = RequireValue(request.FullName, "Full name is required.");
            var email = RequireValue(request.Email, "Email is required.");
            var phone = RequireValue(request.Phone, "Phone is required.");
            var goal = RequireValue(request.Goal, "Consultation goal is required.");

            if (!email.Contains('@'))
            {
                return BadRequest(new { message = "Email is invalid." });
            }

            var now = DateTime.UtcNow;
            var lead = new Lead
            {
                Id = Guid.NewGuid(),
                FullName = fullName,
                Email = email,
                Phone = phone,
                Goal = goal,
                Source = "WEBSITE_FORM",
                Status = "NEW",
                CreatedAt = now,
                UpdatedAt = now
            };

            _context.Leads.Add(lead);
            await _context.SaveChangesAsync(cancellationToken);

            return CreatedAtAction(nameof(GetById), new { id = lead.Id }, MapToDto(lead, null));
        }
        catch (ArgumentException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to create lead registration");
            return StatusCode(500, new { message = "Failed to create lead registration" });
        }
    }

    [HttpGet]
    [Authorize(Roles = "ADMIN,CARE")]
    public async Task<ActionResult<LeadRegistrationPagedResultDto>> GetPaged(
        [FromQuery] string? search,
        [FromQuery] string? status,
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 20,
        CancellationToken cancellationToken = default)
    {
        var safePage = Math.Max(1, page);
        var safePageSize = Math.Clamp(pageSize, 1, 200);

        var query = _context.Leads
            .AsNoTracking()
            .Include(x => x.AssignedCare)
            .AsQueryable();

        if (!string.IsNullOrWhiteSpace(status))
        {
            var normalizedStatus = status.Trim().ToUpperInvariant();
            query = query.Where(x => x.Status == normalizedStatus);
        }

        if (!string.IsNullOrWhiteSpace(search))
        {
            var keyword = search.Trim().ToUpperInvariant();
            query = query.Where(x =>
                (x.FullName != null && x.FullName.ToUpper().Contains(keyword))
                || (x.Email != null && x.Email.ToUpper().Contains(keyword))
                || (x.Phone != null && x.Phone.ToUpper().Contains(keyword))
                || (x.Goal != null && x.Goal.ToUpper().Contains(keyword)));
        }

        var total = await query.CountAsync(cancellationToken);

        var items = await query
            .OrderByDescending(x => x.CreatedAt)
            .Skip((safePage - 1) * safePageSize)
            .Take(safePageSize)
            .ToListAsync(cancellationToken);

        return Ok(new LeadRegistrationPagedResultDto
        {
            Items = items.Select(x => MapToDto(x, x.AssignedCare?.FullName ?? x.AssignedCare?.Email)).ToList(),
            Total = total,
            Page = safePage,
            PageSize = safePageSize
        });
    }

    [HttpGet("{id:guid}")]
    [Authorize(Roles = "ADMIN,CARE")]
    public async Task<ActionResult<LeadRegistrationDto>> GetById(Guid id, CancellationToken cancellationToken = default)
    {
        var lead = await _context.Leads
            .AsNoTracking()
            .Include(x => x.AssignedCare)
            .FirstOrDefaultAsync(x => x.Id == id, cancellationToken);

        if (lead == null)
        {
            return NotFound(new { message = "Lead registration not found." });
        }

        return Ok(MapToDto(lead, lead.AssignedCare?.FullName ?? lead.AssignedCare?.Email));
    }

    [HttpPut("{id:guid}")]
    [Authorize(Roles = "ADMIN,CARE")]
    public async Task<ActionResult<LeadRegistrationDto>> Update(
        Guid id,
        [FromBody] UpdateLeadRegistrationRequest request,
        CancellationToken cancellationToken = default)
    {
        var lead = await _context.Leads
            .Include(x => x.AssignedCare)
            .FirstOrDefaultAsync(x => x.Id == id, cancellationToken);

        if (lead == null)
        {
            return NotFound(new { message = "Lead registration not found." });
        }

        try
        {
            if (request.FullName != null)
            {
                lead.FullName = RequireValue(request.FullName, "Full name is required.");
            }

            if (request.Email != null)
            {
                var email = RequireValue(request.Email, "Email is required.");
                if (!email.Contains('@'))
                {
                    return BadRequest(new { message = "Email is invalid." });
                }

                lead.Email = email;
            }

            if (request.Phone != null)
            {
                lead.Phone = RequireValue(request.Phone, "Phone is required.");
            }

            if (request.Goal != null)
            {
                lead.Goal = RequireValue(request.Goal, "Consultation goal is required.");
            }

            if (request.Status != null)
            {
                var normalizedStatus = request.Status.Trim().ToUpperInvariant();
                if (!AllowedStatuses.Contains(normalizedStatus))
                {
                    return BadRequest(new { message = "Status is invalid." });
                }

                lead.Status = normalizedStatus;
            }

            if (request.AssignedCareId != null)
            {
                if (string.IsNullOrWhiteSpace(request.AssignedCareId))
                {
                    lead.AssignedCareId = null;
                }
                else
                {
                    if (!Guid.TryParse(request.AssignedCareId, out var assignedCareId))
                    {
                        return BadRequest(new { message = "Assigned care id is invalid." });
                    }

                    var careExists = await _context.Users
                        .AsNoTracking()
                        .AnyAsync(
                            u => u.Id == assignedCareId
                            && !u.IsDeleted
                            && (u.Role == "CARE" || u.Role == "ADMIN"),
                            cancellationToken);

                    if (!careExists)
                    {
                        return BadRequest(new { message = "Assigned care user was not found." });
                    }

                    lead.AssignedCareId = assignedCareId;
                }
            }

            lead.UpdatedAt = DateTime.UtcNow;
            await _context.SaveChangesAsync(cancellationToken);

            var updatedLead = await _context.Leads
                .AsNoTracking()
                .Include(x => x.AssignedCare)
                .FirstAsync(x => x.Id == lead.Id, cancellationToken);

            return Ok(MapToDto(updatedLead, updatedLead.AssignedCare?.FullName ?? updatedLead.AssignedCare?.Email));
        }
        catch (ArgumentException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to update lead registration {LeadId}", id);
            return StatusCode(500, new { message = "Failed to update lead registration" });
        }
    }

    [HttpDelete("{id:guid}")]
    [Authorize(Roles = "ADMIN,CARE")]
    public async Task<IActionResult> Delete(Guid id, CancellationToken cancellationToken = default)
    {
        var lead = await _context.Leads.FirstOrDefaultAsync(x => x.Id == id, cancellationToken);
        if (lead == null)
        {
            return NotFound(new { message = "Lead registration not found." });
        }

        _context.Leads.Remove(lead);
        await _context.SaveChangesAsync(cancellationToken);
        return NoContent();
    }

    private static string RequireValue(string? value, string errorMessage)
    {
        if (string.IsNullOrWhiteSpace(value))
        {
            throw new ArgumentException(errorMessage);
        }

        return value.Trim();
    }

    private static LeadRegistrationDto MapToDto(Lead lead, string? assignedCareName)
    {
        return new LeadRegistrationDto
        {
            Id = lead.Id.ToString(),
            FullName = lead.FullName ?? string.Empty,
            Email = lead.Email ?? string.Empty,
            Phone = lead.Phone ?? string.Empty,
            Goal = lead.Goal ?? string.Empty,
            Status = lead.Status,
            Source = lead.Source ?? string.Empty,
            AssignedCareId = lead.AssignedCareId?.ToString(),
            AssignedCareName = assignedCareName,
            CreatedAt = lead.CreatedAt,
            UpdatedAt = lead.UpdatedAt
        };
    }
}
