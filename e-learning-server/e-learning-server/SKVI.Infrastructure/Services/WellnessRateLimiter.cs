using Microsoft.Extensions.Caching.Memory;
using SKVI.Application.Interfaces;

namespace SKVI.Infrastructure.Services;

public class WellnessRateLimiter : IWellnessRateLimiter
{
    private readonly IMemoryCache _cache;

    public WellnessRateLimiter(IMemoryCache cache)
    {
        _cache = cache;
    }

    public bool TryConsume(
        Guid userId,
        string bucket,
        int maxRequests,
        TimeSpan window,
        out TimeSpan retryAfter)
    {
        var now = DateTime.UtcNow;
        var key = $"wellness:rate:{bucket}:{userId:N}";

        var entries = _cache.GetOrCreate(key, entry =>
        {
            entry.AbsoluteExpirationRelativeToNow = window;
            return new List<DateTime>();
        })!;

        lock (entries)
        {
            entries.RemoveAll(ts => now - ts > window);
            if (entries.Count >= maxRequests)
            {
                retryAfter = window - (now - entries[0]);
                return false;
            }

            entries.Add(now);
            _cache.Set(key, entries, window);
        }

        retryAfter = TimeSpan.Zero;
        return true;
    }
}

