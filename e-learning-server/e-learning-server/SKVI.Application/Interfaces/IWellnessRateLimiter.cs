namespace SKVI.Application.Interfaces;

public interface IWellnessRateLimiter
{
    bool TryConsume(
        Guid userId,
        string bucket,
        int maxRequests,
        TimeSpan window,
        out TimeSpan retryAfter);
}

