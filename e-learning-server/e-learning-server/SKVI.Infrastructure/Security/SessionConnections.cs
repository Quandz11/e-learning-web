using System.Collections.Concurrent;
using System.Security.Claims;
using Microsoft.AspNetCore.SignalR;
using SKVI.Application.Services;
using SKVI.Infrastructure.Hubs;

namespace SKVI.Infrastructure.Security;

/// <summary>Server-owned connection revocation; clients cannot opt out.</summary>
public sealed class SessionConnections(IServiceScopeFactory scopes, IHubContext<NotificationHub> notifications,
    ILogger<SessionConnections> logger) : BackgroundService, IHubFilter
{
    private readonly ConcurrentDictionary<string, (Guid UserId, Guid SessionId, HubCallerContext Context)> _connections = new();

    public async Task OnConnectedAsync(HubLifetimeContext context, Func<HubLifetimeContext, Task> next)
    {
        var user = context.Context.User;
        if (user?.Identity?.IsAuthenticated == true)
        {
            if (!Guid.TryParse(user.FindFirstValue("sid"), out var sid) ||
                !Guid.TryParse(user.FindFirstValue(ClaimTypes.NameIdentifier), out var uid) || !await Active(uid, sid))
            { context.Context.Abort(); throw new HubException("AUTH_SESSION_REVOKED"); }
            _connections[context.Context.ConnectionId] = (uid, sid, context.Context);
            await context.Hub.Groups.AddToGroupAsync(context.Context.ConnectionId, $"session-{sid}");
        }
        await next(context);
    }

    public async Task OnDisconnectedAsync(HubLifetimeContext context, Exception? exception,
        Func<HubLifetimeContext, Exception?, Task> next)
    {
        _connections.TryRemove(context.Context.ConnectionId, out _);
        await next(context, exception);
    }

    public async ValueTask<object?> InvokeMethodAsync(HubInvocationContext context,
        Func<HubInvocationContext, ValueTask<object?>> next)
    {
        if (_connections.TryGetValue(context.Context.ConnectionId, out var c) && !await Active(c.UserId, c.SessionId))
        { context.Context.Abort(); throw new HubException("AUTH_SESSION_REVOKED"); }
        return await next(context);
    }

    private async Task<bool> Active(Guid userId, Guid sessionId)
    {
        using var scope = scopes.CreateScope();
        return await scope.ServiceProvider.GetRequiredService<UserSessionService>().IsActiveAsync(userId, sessionId);
    }

    public async Task RevokeAsync(Guid sessionId, string reason)
    {
        try { await notifications.Clients.Group($"session-{sessionId}").SendAsync("SessionRevoked", new { sessionId, reason }); }
        catch (Exception ex) { logger.LogWarning(ex, "Could not notify revoked session"); }
        finally {
            foreach (var pair in _connections.Where(c => c.Value.SessionId == sessionId)) {
                pair.Value.Context.Abort();
                _connections.TryRemove(pair.Key, out _);
            }
        }
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        using var timer = new PeriodicTimer(TimeSpan.FromSeconds(2));
        try {
            while (await timer.WaitForNextTickAsync(stoppingToken)) {
                foreach (var c in _connections.Values.DistinctBy(c => c.SessionId)) {
                    try { if (!await Active(c.UserId, c.SessionId)) await RevokeAsync(c.SessionId, "revoked"); }
                    catch (Exception ex) { logger.LogWarning(ex, "Session connection validation failed"); c.Context.Abort(); }
                }
            }
        } catch (OperationCanceledException) when (stoppingToken.IsCancellationRequested) { }
    }
}
