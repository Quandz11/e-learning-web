using Microsoft.AspNetCore.SignalR;
using SKVI.Application.Interfaces;
using SKVI.Infrastructure.Hubs;

namespace SKVI.Infrastructure.Services;

public class NotificationService : INotificationService
{
    private readonly IHubContext<ChatHub> _hubContext;
    private readonly ILogger<NotificationService> _logger;

    public NotificationService(IHubContext<ChatHub> hubContext, ILogger<NotificationService> logger)
    {
        _hubContext = hubContext;
        _logger = logger;
    }

    public async Task NotifyUserAsync(string userId, string title, string message, string type = "info", object? data = null)
    {
        try
        {
            await _hubContext.Clients.Group($"user-{userId}").SendAsync("ReceiveNotification", new
            {
                Title = title,
                Message = message,
                Type = type,
                Data = data,
                Timestamp = DateTime.UtcNow
            });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to send notification to user {UserId}", userId);
        }
    }

    public async Task NotifyAdminsAsync(string title, string message, string type = "info", object? data = null)
    {
        try
        {
            await _hubContext.Clients.Group("admin-group").SendAsync("ReceiveNotification", new
            {
                Title = title,
                Message = message,
                Type = type,
                Data = data,
                Timestamp = DateTime.UtcNow
            });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to send notification to admins");
        }
    }
}
