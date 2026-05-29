using Microsoft.AspNetCore.SignalR;
using Microsoft.EntityFrameworkCore;
using SKVI.Application.DTOs.Notification;
using SKVI.Application.Interfaces;
using SKVI.Domain.Entities;
using SKVI.Infrastructure.Hubs;

namespace SKVI.Infrastructure.Services;

public class NotificationService : INotificationService
{
    private readonly ApplicationDbContext _context;
    private readonly IHubContext<NotificationHub> _hubContext;
    private readonly ILogger<NotificationService> _logger;

    public NotificationService(
        ApplicationDbContext context,
        IHubContext<NotificationHub> hubContext,
        ILogger<NotificationService> logger)
    {
        _context = context;
        _hubContext = hubContext;
        _logger = logger;
    }

    public async Task SendToUserAsync(Guid userId, string title, string content)
    {
        try
        {
            var notification = new Notification
            {
                Id = Guid.NewGuid(),
                UserId = userId,
                Title = title,
                Content = content,
                CreatedAt = DateTime.UtcNow,
                IsRead = false
            };

            _context.Notifications.Add(notification);
            await _context.SaveChangesAsync();

            var dto = new NotificationDto
            {
                Id = notification.Id,
                Title = notification.Title,
                Content = notification.Content,
                IsRead = notification.IsRead,
                CreatedAt = notification.CreatedAt
            };

            await _hubContext.Clients.Group($"user-{userId}").SendAsync("ReceiveNotification", dto);
            await LogPushTargetsAsync(new[] { userId }, title);
            _logger.LogInformation("Sent notification {NotificationId} to user {UserId}", notification.Id, userId);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to send notification to user {UserId}", userId);
            throw;
        }
    }

    public async Task SendToRoleAsync(string role, string title, string content)
    {
        try
        {
            // Find users in role
            var users = await _context.Users
                .Where(u => u.Role == role)
                .Select(u => u.Id)
                .ToListAsync();

            if (!users.Any()) return;

            var notifications = users.Select(uid => new Notification
            {
                Id = Guid.NewGuid(),
                UserId = uid,
                Title = title,
                Content = content,
                CreatedAt = DateTime.UtcNow,
                IsRead = false
            }).ToList();

            await _context.Notifications.AddRangeAsync(notifications);
            await _context.SaveChangesAsync();

            // Broadcast via SignalR to role group
            // Note: This sends to online users. The dto passed here might act as a "generic" one
            // OR we rely on the fact they will fetch latest notifications.
            // But usually we want to show a toast.
            // We can send a "generic" DTO for the toast.
            var broadcastDto = new NotificationDto
            {
                Id = Guid.Empty, // Placeholder ID for broadcast toast, or generate one if client expects valid GUID
                Title = title,
                Content = content,
                IsRead = false,
                CreatedAt = DateTime.UtcNow
            };

            await _hubContext.Clients.Group($"role-{role}").SendAsync("ReceiveNotification", broadcastDto);
            await LogPushTargetsAsync(users, title);
            _logger.LogInformation("Sent notification to {Count} users in role {Role}", users.Count, role);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to send notification to role {Role}", role);
            throw;
        }
    }

    public async Task SendToAllAsync(string title, string content)
    {
        try
        {
            var users = await _context.Users.Select(u => u.Id).ToListAsync();
            if (!users.Any()) return;

            var notifications = users.Select(uid => new Notification
            {
                Id = Guid.NewGuid(),
                UserId = uid,
                Title = title,
                Content = content,
                CreatedAt = DateTime.UtcNow,
                IsRead = false
            }).ToList();

            // Use batch insert if available or just AddRange
            await _context.Notifications.AddRangeAsync(notifications);
            await _context.SaveChangesAsync();

            var broadcastDto = new NotificationDto
            {
                Id = Guid.Empty,
                Title = title,
                Content = content,
                IsRead = false,
                CreatedAt = DateTime.UtcNow
            };

            await _hubContext.Clients.Group("all-users").SendAsync("ReceiveNotification", broadcastDto);
            await LogPushTargetsAsync(users, title);
            _logger.LogInformation("Sent notification to all {Count} users", users.Count);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to send notification to all users");
            throw;
        }
    }

    public async Task<IEnumerable<NotificationDto>> GetUserNotificationsAsync(Guid userId)
    {
        return await _context.Notifications
            .Where(n => n.UserId == userId)
            .OrderByDescending(n => n.CreatedAt)
            .Select(n => new NotificationDto
            {
                Id = n.Id,
                Title = n.Title,
                Content = n.Content,
                IsRead = n.IsRead,
                CreatedAt = n.CreatedAt
            })
            .ToListAsync();
    }

    public async Task<int> GetUnreadCountAsync(Guid userId)
    {
        return await _context.Notifications
            .CountAsync(n => n.UserId == userId && !n.IsRead);
    }

    public async Task MarkAsReadAsync(Guid notificationId, Guid userId)
    {
        var notification = await _context.Notifications
            .FirstOrDefaultAsync(n => n.Id == notificationId && n.UserId == userId);

        if (notification != null)
        {
            notification.IsRead = true;
            await _context.SaveChangesAsync();
        }
    }

    public async Task MarkAllAsReadAsync(Guid userId)
    {
        var notifications = await _context.Notifications
            .Where(n => n.UserId == userId && !n.IsRead)
            .ToListAsync();

        if (notifications.Any())
        {
            foreach (var note in notifications)
            {
                note.IsRead = true;
            }
            await _context.SaveChangesAsync();
        }
    }

    public async Task RegisterDeviceTokenAsync(Guid userId, RegisterDeviceTokenRequest request)
    {
        var deviceId = request.DeviceId.Trim();
        var token = request.Token.Trim();
        var platform = request.Platform.Trim().ToUpperInvariant();

        if (string.IsNullOrWhiteSpace(deviceId) ||
            string.IsNullOrWhiteSpace(token) ||
            string.IsNullOrWhiteSpace(platform))
        {
            throw new ArgumentException("DeviceId, token, and platform are required.");
        }

        var now = DateTime.UtcNow;
        var existing = await _context.UserDeviceTokens
            .FirstOrDefaultAsync(t => t.UserId == userId && t.DeviceId == deviceId);

        if (existing == null)
        {
            _context.UserDeviceTokens.Add(new UserDeviceToken
            {
                Id = Guid.NewGuid(),
                UserId = userId,
                DeviceId = deviceId,
                Token = token,
                Platform = platform,
                AppVersion = request.AppVersion,
                IsActive = true,
                CreatedAt = now,
                UpdatedAt = now,
                LastSeenAt = now
            });
        }
        else
        {
            existing.Token = token;
            existing.Platform = platform;
            existing.AppVersion = request.AppVersion;
            existing.IsActive = true;
            existing.UpdatedAt = now;
            existing.LastSeenAt = now;
        }

        await _context.SaveChangesAsync();
    }

    public async Task UnregisterDeviceTokenAsync(Guid userId, string deviceId)
    {
        var normalizedDeviceId = deviceId.Trim();
        if (string.IsNullOrWhiteSpace(normalizedDeviceId))
        {
            return;
        }

        var token = await _context.UserDeviceTokens
            .FirstOrDefaultAsync(t => t.UserId == userId && t.DeviceId == normalizedDeviceId);
        if (token == null)
        {
            return;
        }

        token.IsActive = false;
        token.UpdatedAt = DateTime.UtcNow;
        await _context.SaveChangesAsync();
    }

    private async Task LogPushTargetsAsync(IEnumerable<Guid> userIds, string title)
    {
        var ids = userIds.Distinct().ToList();
        if (!ids.Any())
        {
            return;
        }

        var activeTokenCount = await _context.UserDeviceTokens
            .CountAsync(t => ids.Contains(t.UserId) && t.IsActive);

        if (activeTokenCount > 0)
        {
            _logger.LogInformation(
                "Push notification queued for {DeviceCount} active devices. Title={Title}",
                activeTokenCount,
                title);
        }
    }
}
