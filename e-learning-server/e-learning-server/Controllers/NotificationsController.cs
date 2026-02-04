using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SKVI.Application.DTOs.Notification;
using SKVI.Application.Interfaces;
using System.Security.Claims;

namespace e_learning_server.Controllers;

[Route("api/[controller]")]
[ApiController]
[Authorize]
public class NotificationsController : ControllerBase
{
    private readonly INotificationService _notificationService;

    public NotificationsController(INotificationService notificationService)
    {
        _notificationService = notificationService;
    }

    [HttpPost("send")]
    [Authorize(Roles = "ADMIN")]
    public async Task<IActionResult> SendNotification([FromBody] CreateNotificationRequest request)
    {
        if (request.TargetType == "USER")
        {
            if (request.TargetUserId == null)
                return BadRequest("TargetUserId is required for USER type");

            await _notificationService.SendToUserAsync(request.TargetUserId.Value, request.Title, request.Content);
        }
        else if (request.TargetType == "ROLE")
        {
             if (string.IsNullOrEmpty(request.TargetRole))
                return BadRequest("TargetRole is required for ROLE type");
                
             await _notificationService.SendToRoleAsync(request.TargetRole, request.Title, request.Content);
        }
        else if (request.TargetType == "ALL")
        {
            await _notificationService.SendToAllAsync(request.Title, request.Content);
        }
        else
        {
            return BadRequest("Invalid TargetType. Must be USER, ROLE, or ALL");
        }

        return Ok(new { message = "Notification sent successfully" });
    }

    [HttpGet]
    public async Task<IActionResult> GetMyNotifications()
    {
        var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (string.IsNullOrEmpty(userId)) return Unauthorized();

        var notifications = await _notificationService.GetUserNotificationsAsync(Guid.Parse(userId));
        var unreadCount = await _notificationService.GetUnreadCountAsync(Guid.Parse(userId));

        return Ok(new { notifications, unreadCount });
    }

    [HttpPut("{id}/read")]
    public async Task<IActionResult> MarkAsRead(Guid id)
    {
        var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (string.IsNullOrEmpty(userId)) return Unauthorized();

        await _notificationService.MarkAsReadAsync(id, Guid.Parse(userId));
        return NoContent();
    }

    [HttpPut("read-all")]
    public async Task<IActionResult> MarkAllAsRead()
    {
        var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (string.IsNullOrEmpty(userId)) return Unauthorized();

        await _notificationService.MarkAllAsReadAsync(Guid.Parse(userId));
        return NoContent();
    }
}
