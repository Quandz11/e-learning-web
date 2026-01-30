using SKVI.Application.Interfaces;

namespace SKVI.Infrastructure.BackgroundServices;

public class GuestConversationCleanupService : BackgroundService
{
    private readonly IServiceProvider _serviceProvider;
    private readonly ILogger<GuestConversationCleanupService> _logger;
    private readonly TimeSpan _cleanupInterval = TimeSpan.FromMinutes(5);
    private readonly TimeSpan _inactiveThreshold = TimeSpan.FromMinutes(30);

    public GuestConversationCleanupService(
        IServiceProvider serviceProvider,
        ILogger<GuestConversationCleanupService> logger)
    {
        _serviceProvider = serviceProvider;
        _logger = logger;
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        _logger.LogInformation("Guest Conversation Cleanup Service started");

        while (!stoppingToken.IsCancellationRequested)
        {
            try
            {
                await Task.Delay(_cleanupInterval, stoppingToken);

                using var scope = _serviceProvider.CreateScope();
                var guestConversationService = scope.ServiceProvider
                    .GetRequiredService<IGuestConversationService>();

                var beforeCount = guestConversationService.GetAllActiveConversations().Count;
                guestConversationService.CleanupInactiveConversations(_inactiveThreshold);
                var afterCount = guestConversationService.GetAllActiveConversations().Count;

                if (beforeCount != afterCount)
                {
                    _logger.LogInformation(
                        "Cleaned up {Count} inactive guest conversations",
                        beforeCount - afterCount);
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error during guest conversation cleanup");
            }
        }

        _logger.LogInformation("Guest Conversation Cleanup Service stopped");
    }
}
