using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using SKVI.Infrastructure.Services;

namespace SKVI.Infrastructure.BackgroundServices;

public sealed class ZaloTokenRefreshWorker : BackgroundService
{
    private readonly IServiceScopeFactory _scopeFactory;
    private readonly ILogger<ZaloTokenRefreshWorker> _logger;

    public ZaloTokenRefreshWorker(
        IServiceScopeFactory scopeFactory,
        ILogger<ZaloTokenRefreshWorker> logger)
    {
        _scopeFactory = scopeFactory;
        _logger = logger;
    }

    protected override async Task ExecuteAsync(
        CancellationToken stoppingToken)
    {
        _logger.LogInformation(
            "Zalo token refresh worker started.");

        // Cho các thành phần khác của API khởi động trước.
        try
        {
            await Task.Delay(
                TimeSpan.FromSeconds(30),
                stoppingToken);
        }
        catch (OperationCanceledException)
        {
            return;
        }

        await CheckTokenAsync(stoppingToken);

        using var timer = new PeriodicTimer(
            TimeSpan.FromMinutes(5));

        try
        {
            while (await timer.WaitForNextTickAsync(stoppingToken))
            {
                await CheckTokenAsync(stoppingToken);
            }
        }
        catch (OperationCanceledException)
            when (stoppingToken.IsCancellationRequested)
        {
            // API đang dừng bình thường.
        }
    }

    private async Task CheckTokenAsync(
        CancellationToken cancellationToken)
    {
        try
        {
            await using var scope =
                _scopeFactory.CreateAsyncScope();

            var settings = scope.ServiceProvider
                .GetRequiredService<
                    Microsoft.Extensions.Options.IOptions<
                        ZaloOtpSettings>>()
                .Value;

            if (!settings.Enabled)
            {
                return;
            }

            var tokenManager =
                scope.ServiceProvider
                    .GetRequiredService<ZaloTokenManager>();

            await tokenManager.GetAccessTokenAsync(
                cancellationToken: cancellationToken);
        }
        catch (OperationCanceledException)
            when (cancellationToken.IsCancellationRequested)
        {
            // Không coi việc shutdown là lỗi.
        }
        catch (Exception ex)
        {
            _logger.LogError(
                ex,
                "Zalo token refresh check failed. Will retry on next interval.");
        }
    }
}
