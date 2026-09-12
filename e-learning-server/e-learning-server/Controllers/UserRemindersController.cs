using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using SKVI.Application.DTOs.Mobile;
using SKVI.Domain.Entities;
using SKVI.Infrastructure;
using System.Security.Claims;

namespace e_learning_server.Controllers;

[ApiController]
[Route("api/user/reminders")]
[Authorize]
public class UserRemindersController : ControllerBase
{
    private readonly ApplicationDbContext _db;
    private readonly ILogger<UserRemindersController> _logger;

    public UserRemindersController(ApplicationDbContext db, ILogger<UserRemindersController> logger)
    {
        _db = db;
        _logger = logger;
    }

    private Guid GetUserId()
    {
        var claim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (string.IsNullOrEmpty(claim) || !Guid.TryParse(claim, out var userId))
        {
            throw new UnauthorizedAccessException("Invalid user ID");
        }
        return userId;
    }

    private static UserReminderDto ToDto(UserReminder r)
    {
        var repeatDays = new List<int>();
        if (!string.IsNullOrWhiteSpace(r.RepeatDays))
        {
            repeatDays = r.RepeatDays
                .Split(',', StringSplitOptions.RemoveEmptyEntries)
                .Select(s => int.TryParse(s.Trim(), out var n) ? n : (int?)null)
                .Where(n => n.HasValue)
                .Select(n => n!.Value)
                .ToList();
        }

        return new UserReminderDto
        {
            Id = r.Id,
            ClientId = r.ClientId,
            Type = r.Type,
            Title = r.Title,
            Message = r.Message,
            Enabled = r.Enabled,
            StartTimeHour = r.StartTimeHour,
            StartTimeMinute = r.StartTimeMinute,
            EndTimeHour = r.EndTimeHour,
            EndTimeMinute = r.EndTimeMinute,
            RepeatDays = repeatDays,
            SoundEnabled = r.SoundEnabled,
            VibrationEnabled = r.VibrationEnabled,
            CreatedAt = r.CreatedAt,
            UpdatedAt = r.UpdatedAt
        };
    }

    /// <summary>
    /// Get all reminders of current user.
    /// </summary>
    [HttpGet]
    public async Task<IActionResult> GetReminders(CancellationToken cancellationToken)
    {
        try
        {
            var userId = GetUserId();
            var reminders = await _db.UserReminders
                .Where(r => r.UserId == userId)
                .OrderBy(r => r.StartTimeHour)
                .ThenBy(r => r.StartTimeMinute)
                .ToListAsync(cancellationToken);

            return Ok(reminders.Select(ToDto));
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error getting user reminders");
            return Ok(new List<UserReminderDto>());
        }
    }

    /// <summary>
    /// Batch synchronize reminders between mobile app and server.
    /// </summary>
    [HttpPost("sync")]
    public async Task<IActionResult> SyncReminders([FromBody] SyncRemindersRequestDto request, CancellationToken cancellationToken)
    {
        try
        {
            var userId = GetUserId();
            var existingReminders = await _db.UserReminders
                .Where(r => r.UserId == userId)
                .ToListAsync(cancellationToken);

            var existingByClientId = new Dictionary<string, UserReminder>();
            foreach (var r in existingReminders)
            {
                var k = string.IsNullOrEmpty(r.ClientId) ? r.Id.ToString() : r.ClientId;
                existingByClientId[k] = r;
            }

            if (request?.Reminders != null)
            {
                foreach (var item in request.Reminders)
                {
                    var key = string.IsNullOrEmpty(item.ClientId) ? (item.Id != Guid.Empty ? item.Id.ToString() : Guid.NewGuid().ToString()) : item.ClientId;
                    var repeatDaysStr = string.Join(",", item.RepeatDays ?? new List<int>());

                    if (existingByClientId.TryGetValue(key, out var existing))
                    {
                        existing.Type = item.Type ?? "custom";
                        existing.Title = item.Title ?? string.Empty;
                        existing.Message = item.Message ?? string.Empty;
                        existing.Enabled = item.Enabled;
                        existing.StartTimeHour = item.StartTimeHour;
                        existing.StartTimeMinute = item.StartTimeMinute;
                        existing.EndTimeHour = item.EndTimeHour;
                        existing.EndTimeMinute = item.EndTimeMinute;
                        existing.RepeatDays = repeatDaysStr;
                        existing.SoundEnabled = item.SoundEnabled;
                        existing.VibrationEnabled = item.VibrationEnabled;
                        existing.UpdatedAt = DateTime.UtcNow;
                    }
                    else
                    {
                        var newReminder = new UserReminder
                        {
                            Id = item.Id != Guid.Empty ? item.Id : Guid.NewGuid(),
                            UserId = userId,
                            ClientId = key,
                            Type = item.Type ?? "custom",
                            Title = item.Title ?? string.Empty,
                            Message = item.Message ?? string.Empty,
                            Enabled = item.Enabled,
                            StartTimeHour = item.StartTimeHour,
                            StartTimeMinute = item.StartTimeMinute,
                            EndTimeHour = item.EndTimeHour,
                            EndTimeMinute = item.EndTimeMinute,
                            RepeatDays = repeatDaysStr,
                            SoundEnabled = item.SoundEnabled,
                            VibrationEnabled = item.VibrationEnabled,
                            CreatedAt = DateTime.UtcNow,
                            UpdatedAt = DateTime.UtcNow
                        };
                        _db.UserReminders.Add(newReminder);
                    }
                }

                await _db.SaveChangesAsync(cancellationToken);
            }

            var allUserReminders = await _db.UserReminders
                .Where(r => r.UserId == userId)
                .OrderBy(r => r.StartTimeHour)
                .ThenBy(r => r.StartTimeMinute)
                .ToListAsync(cancellationToken);

            return Ok(allUserReminders.Select(ToDto));
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error syncing user reminders");
            return Ok(new List<UserReminderDto>());
        }
    }

    /// <summary>
    /// Create a single reminder.
    /// </summary>
    [HttpPost]
    public async Task<IActionResult> CreateReminder([FromBody] UserReminderDto dto, CancellationToken cancellationToken)
    {
        try
        {
            var userId = GetUserId();
            var clientId = string.IsNullOrEmpty(dto.ClientId) ? (dto.Id != Guid.Empty ? dto.Id.ToString() : Guid.NewGuid().ToString()) : dto.ClientId;

            var reminder = new UserReminder
            {
                Id = dto.Id != Guid.Empty ? dto.Id : Guid.NewGuid(),
                UserId = userId,
                ClientId = clientId,
                Type = dto.Type ?? "custom",
                Title = dto.Title ?? string.Empty,
                Message = dto.Message ?? string.Empty,
                Enabled = dto.Enabled,
                StartTimeHour = dto.StartTimeHour,
                StartTimeMinute = dto.StartTimeMinute,
                EndTimeHour = dto.EndTimeHour,
                EndTimeMinute = dto.EndTimeMinute,
                RepeatDays = string.Join(",", dto.RepeatDays ?? new List<int>()),
                SoundEnabled = dto.SoundEnabled,
                VibrationEnabled = dto.VibrationEnabled,
                CreatedAt = DateTime.UtcNow,
                UpdatedAt = DateTime.UtcNow
            };

            _db.UserReminders.Add(reminder);
            await _db.SaveChangesAsync(cancellationToken);

            return Ok(ToDto(reminder));
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error creating user reminder");
            return StatusCode(500, new { message = ex.Message });
        }
    }

    /// <summary>
    /// Update an existing reminder.
    /// </summary>
    [HttpPut("{id:guid}")]
    public async Task<IActionResult> UpdateReminder(Guid id, [FromBody] UserReminderDto dto, CancellationToken cancellationToken)
    {
        var userId = GetUserId();
        var reminder = await _db.UserReminders
            .FirstOrDefaultAsync(r => (r.Id == id || r.ClientId == dto.ClientId) && r.UserId == userId, cancellationToken);

        if (reminder == null)
        {
            return NotFound(new { message = "Reminder not found" });
        }

        reminder.Type = dto.Type ?? "custom";
        reminder.Title = dto.Title ?? string.Empty;
        reminder.Message = dto.Message ?? string.Empty;
        reminder.Enabled = dto.Enabled;
        reminder.StartTimeHour = dto.StartTimeHour;
        reminder.StartTimeMinute = dto.StartTimeMinute;
        reminder.EndTimeHour = dto.EndTimeHour;
        reminder.EndTimeMinute = dto.EndTimeMinute;
        reminder.RepeatDays = string.Join(",", dto.RepeatDays ?? new List<int>());
        reminder.SoundEnabled = dto.SoundEnabled;
        reminder.VibrationEnabled = dto.VibrationEnabled;
        reminder.UpdatedAt = DateTime.UtcNow;

        await _db.SaveChangesAsync(cancellationToken);
        return Ok(ToDto(reminder));
    }

    /// <summary>
    /// Delete a reminder.
    /// </summary>
    [HttpDelete("{id:guid}")]
    public async Task<IActionResult> DeleteReminder(Guid id, CancellationToken cancellationToken)
    {
        var userId = GetUserId();
        var reminder = await _db.UserReminders
            .FirstOrDefaultAsync(r => r.Id == id && r.UserId == userId, cancellationToken);

        if (reminder != null)
        {
            _db.UserReminders.Remove(reminder);
            await _db.SaveChangesAsync(cancellationToken);
        }

        return NoContent();
    }

    /// <summary>
    /// Toggle reminder enabled state.
    /// </summary>
    [HttpPatch("{id:guid}/toggle")]
    public async Task<IActionResult> ToggleReminder(Guid id, [FromBody] bool enabled, CancellationToken cancellationToken)
    {
        var userId = GetUserId();
        var reminder = await _db.UserReminders
            .FirstOrDefaultAsync(r => r.Id == id && r.UserId == userId, cancellationToken);

        if (reminder == null)
        {
            return NotFound(new { message = "Reminder not found" });
        }

        reminder.Enabled = enabled;
        reminder.UpdatedAt = DateTime.UtcNow;
        await _db.SaveChangesAsync(cancellationToken);

        return Ok(ToDto(reminder));
    }
}
