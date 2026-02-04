using Microsoft.AspNetCore.SignalR;
using Microsoft.AspNetCore.Authorization;
using System.Security.Claims;

namespace SKVI.Infrastructure.Hubs;

[Authorize]
public class NotificationHub : Hub
{
    private readonly ILogger<NotificationHub> _logger;

    public NotificationHub(ILogger<NotificationHub> logger)
    {
        _logger = logger;
    }

    public override async Task OnConnectedAsync()
    {
        var userId = Context.User?.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        var role = Context.User?.FindFirst(ClaimTypes.Role)?.Value;

        if (!string.IsNullOrEmpty(userId))
        {
            // Join personal group for direct messages
            await Groups.AddToGroupAsync(Context.ConnectionId, $"user-{userId}");
            _logger.LogInformation($"[NotificationHub] User {userId} connected.");

            // Join role-based group if role exists
            if (!string.IsNullOrEmpty(role))
            {
                // Normalize role to lowercase/standard format if needed, but assuming exact match for now
                // Group name: "role-{ROLE_NAME}"
                await Groups.AddToGroupAsync(Context.ConnectionId, $"role-{role}");
                _logger.LogInformation($"[NotificationHub] User {userId} joined group role-{role}.");
            }
            
            // Join "all" group for broadcast messages
            await Groups.AddToGroupAsync(Context.ConnectionId, "all-users");
        }

        await base.OnConnectedAsync();
    }

    public override async Task OnDisconnectedAsync(Exception? exception)
    {
        var userId = Context.User?.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        var role = Context.User?.FindFirst(ClaimTypes.Role)?.Value;

        if (!string.IsNullOrEmpty(userId))
        {
            await Groups.RemoveFromGroupAsync(Context.ConnectionId, $"user-{userId}");
            
            if (!string.IsNullOrEmpty(role))
            {
                await Groups.RemoveFromGroupAsync(Context.ConnectionId, $"role-{role}");
            }
            
            await Groups.RemoveFromGroupAsync(Context.ConnectionId, "all-users");
        }

        await base.OnDisconnectedAsync(exception);
    }
}
