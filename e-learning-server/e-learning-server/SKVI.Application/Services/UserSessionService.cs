using System.Data;
using System.Security.Claims;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Options;
using SKVI.Application.DTOs.Auth;
using SKVI.Application.Interfaces;
using SKVI.Domain.Entities;
using SKVI.Infrastructure;
using SKVI.Infrastructure.Security;

namespace SKVI.Application.Services;

public class UserSessionService(ApplicationDbContext db, ITokenService tokens,
    IOptions<JwtSettings> settings, IHttpContextAccessor accessor, SessionConnections connections)
{
    private static string Limit(string? value, int max, string fallback = "Unknown") =>
        string.IsNullOrWhiteSpace(value) ? fallback : value.Trim()[..Math.Min(value.Trim().Length, max)];

    public async Task<AuthResponse> CreateAsync(User user, string ip, string agent, CancellationToken ct = default)
    {
        var request = accessor.HttpContext?.Request;
        var ua = Limit(request?.Headers.UserAgent.ToString() ?? agent, 1000, "");
        var session = new UserSession {
            Id = Guid.NewGuid(), UserId = user.Id,
            IpAddress = Limit(accessor.HttpContext?.Connection.RemoteIpAddress?.ToString() ?? ip, 64),
            UserAgent = ua,
            Platform = Limit(request?.Headers["X-Device-Platform"].ToString(), 40, "Web"),
            DeviceName = Limit(request?.Headers["X-Device-Name"].ToString(), 200, DeviceName(ua)),
            ExpiresAt = DateTime.UtcNow.AddDays(settings.Value.RefreshTokenExpirationDays)
        };
        db.UserSessions.Add(session);
        var response = Issue(user, session);
        await db.SaveChangesAsync(ct);
        return response;
    }

    private AuthResponse Issue(User user, UserSession session)
    {
        var refresh = tokens.GenerateRefreshToken();
        db.RefreshTokens.Add(new RefreshToken { Id = Guid.NewGuid(), UserId = user.Id,
            SessionId = session.Id, TokenHash = refresh, IpAddress = session.IpAddress,
            UserAgent = session.UserAgent, ExpiresAt = session.ExpiresAt });
        return new AuthResponse(tokens.GenerateAccessToken(user.Id, user.Email, user.Role, user.FullName, session.Id),
            refresh, DateTime.UtcNow.AddMinutes(settings.Value.AccessTokenExpirationMinutes));
    }

    public async Task<AuthResponse> RefreshAsync(string refresh)
    {
        await using var transaction = await db.Database.BeginTransactionAsync(IsolationLevel.Serializable);
        var token = await db.RefreshTokens.Include(t => t.User).Include(t => t.Session)
            .SingleOrDefaultAsync(t => t.TokenHash == refresh);
        var now = DateTime.UtcNow;
        if (token?.Session == null || token.RevokedAt != null || token.ExpiresAt <= now ||
            token.Session.RevokedAt != null || token.Session.ExpiresAt <= now ||
            token.User.IsDeleted || token.User.Status != "ACTIVE")
            throw new UnauthorizedAccessException("AUTH_SESSION_REVOKED");
        token.RevokedAt = now;
        token.Session.LastActiveAt = now;
        token.Session.ExpiresAt = now.AddDays(settings.Value.RefreshTokenExpirationDays);
        var response = Issue(token.User, token.Session);
        await db.SaveChangesAsync();
        await transaction.CommitAsync();
        return response;
    }

    public async Task<bool> IsActiveAsync(Guid userId, Guid sessionId, CancellationToken ct = default) =>
        await db.UserSessions.AsNoTracking().AnyAsync(s => s.Id == sessionId && s.UserId == userId &&
            s.RevokedAt == null && s.ExpiresAt > DateTime.UtcNow && !s.User.IsDeleted && s.User.Status == "ACTIVE" &&
            db.RefreshTokens.Any(t => t.SessionId == s.Id && t.RevokedAt == null && t.ExpiresAt > DateTime.UtcNow), ct);

    public Task TouchAsync(Guid sessionId, CancellationToken ct = default) => db.UserSessions
        .Where(s => s.Id == sessionId && s.RevokedAt == null && s.LastActiveAt < DateTime.UtcNow.AddMinutes(-1))
        .ExecuteUpdateAsync(s => s.SetProperty(x => x.LastActiveAt, DateTime.UtcNow), ct);

    public async Task<List<ActiveSessionDto>> ListAsync(Guid userId, Guid? current)
    {
        var sessions = await db.UserSessions.AsNoTracking().Where(s => s.UserId == userId &&
            s.RevokedAt == null && s.ExpiresAt > DateTime.UtcNow &&
            db.RefreshTokens.Any(t => t.SessionId == s.Id && t.RevokedAt == null && t.ExpiresAt > DateTime.UtcNow))
            .OrderByDescending(s => s.LastActiveAt).ToListAsync();
        return sessions.Select(s => new ActiveSessionDto { SessionId = s.Id, DeviceName = s.DeviceName,
            Platform = s.Platform, Browser = Browser(s.UserAgent), IpAddress = s.IpAddress,
            LoginTime = DateTime.SpecifyKind(s.CreatedAt, DateTimeKind.Utc),
            LastActiveAt = DateTime.SpecifyKind(s.LastActiveAt, DateTimeKind.Utc),
            ExpiresAt = DateTime.SpecifyKind(s.ExpiresAt, DateTimeKind.Utc), IsCurrentSession = s.Id == current }).ToList();
    }

    public async Task LogoutAsync(string refresh)
    {
        var token = await db.RefreshTokens.AsNoTracking().FirstOrDefaultAsync(t => t.TokenHash == refresh);
        if (token?.SessionId is Guid sid) await RevokeAsync(token.UserId, sid, null, "logout");
    }

    public async Task RevokeAsync(Guid userId, Guid? sessionId, Guid? except, string reason, Guid? adminId = null)
    {
        await using var transaction = await db.Database.BeginTransactionAsync(IsolationLevel.Serializable);
        var query = db.UserSessions.Where(s => s.UserId == userId);
        if (sessionId != null) query = query.Where(s => s.Id == sessionId);
        if (except != null) query = query.Where(s => s.Id != except);
        var sessions = await query.ToListAsync();
        if (sessionId != null && sessions.Count == 0) throw new KeyNotFoundException("Session not found");
        var ids = sessions.Select(s => s.Id).ToArray();
        var now = DateTime.UtcNow;
        foreach (var session in sessions) session.RevokedAt ??= now;
        var refreshTokens = await db.RefreshTokens.Where(t => t.SessionId != null && ids.Contains(t.SessionId.Value) && t.RevokedAt == null).ToListAsync();
        foreach (var token in refreshTokens) token.RevokedAt = now;
        if (adminId != null) db.AuditLogs.Add(new AuditLog { Id = Guid.NewGuid(), UserId = adminId,
            Action = "ADMIN_SESSION_REVOKE", TargetTable = "Users", TargetId = userId,
            Metadata = System.Text.Json.JsonSerializer.Serialize(new { sessionId, count = ids.Length, result = "success" }) });
        await db.SaveChangesAsync();
        await transaction.CommitAsync();
        foreach (var id in ids) await connections.RevokeAsync(id, reason);
    }

    private static string DeviceName(string ua) => ua.Contains("Android") ? "Android" : ua.Contains("iPhone") ? "iPhone" :
        ua.Contains("Windows") ? "Windows" : ua.Contains("Mac") ? "Mac" : ua.Contains("Linux") ? "Linux" : "Unknown";
    private static string Browser(string ua) => ua.Contains("Edg/") ? "Edge" : ua.Contains("Chrome/") ? "Chrome" :
        ua.Contains("Firefox/") ? "Firefox" : ua.Contains("Safari/") ? "Safari" : "Ứng dụng";
}
