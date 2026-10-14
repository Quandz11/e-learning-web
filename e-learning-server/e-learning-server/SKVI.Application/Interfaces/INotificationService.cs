using SKVI.Application.DTOs.Notification;

namespace SKVI.Application.Interfaces;

public interface INotificationService
{
    Task SendToUserAsync(Guid userId, string title, string content);
    Task SendToRoleAsync(string role, string title, string content);
    Task SendToAllAsync(string title, string content);
    Task<IEnumerable<NotificationDto>> GetUserNotificationsAsync(Guid userId, int page = 1, int pageSize = 50);
    Task<int> GetUnreadCountAsync(Guid userId);
    Task MarkAsReadAsync(Guid notificationId, Guid userId);
    Task MarkAllAsReadAsync(Guid userId);
    Task RegisterDeviceTokenAsync(Guid userId, RegisterDeviceTokenRequest request);
    Task UnregisterDeviceTokenAsync(Guid userId, string deviceId);
    Task SendChatMessageNotificationAsync(Guid recipientUserId, Guid conversationId, string senderName, string content, string? senderAvatarUrl);
}
