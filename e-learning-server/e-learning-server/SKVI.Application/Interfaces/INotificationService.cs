using SKVI.Application.DTOs.Notification;

namespace SKVI.Application.Interfaces;

public interface INotificationService
{
    Task SendToUserAsync(Guid userId, string title, string content);
    Task SendToRoleAsync(string role, string title, string content);
    Task SendToAllAsync(string title, string content);
    Task<IEnumerable<NotificationDto>> GetUserNotificationsAsync(Guid userId);
    Task<int> GetUnreadCountAsync(Guid userId);
    Task MarkAsReadAsync(Guid notificationId, Guid userId);
    Task MarkAllAsReadAsync(Guid userId);
}
