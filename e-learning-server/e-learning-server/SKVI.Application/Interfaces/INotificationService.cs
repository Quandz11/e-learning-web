namespace SKVI.Application.Interfaces;

public interface INotificationService
{
    Task NotifyUserAsync(string userId, string title, string message, string type = "info", object? data = null);
    Task NotifyAdminsAsync(string title, string message, string type = "info", object? data = null);
}
