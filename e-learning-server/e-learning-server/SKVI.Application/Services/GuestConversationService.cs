using System.Collections.Concurrent;
using SKVI.Application.Interfaces;
using SKVI.Application.Models.Chat;

namespace SKVI.Application.Services;

public class GuestConversationService : IGuestConversationService
{
    private readonly ConcurrentDictionary<string, GuestConversation> _conversations = new();
    private readonly object _lock = new();

    public void AddOrUpdateConversation(string guestId, GuestMessage message)
    {
        _conversations.AddOrUpdate(
            guestId,
            // Add new conversation
            _ => new GuestConversation
            {
                GuestId = guestId,
                Messages = new List<GuestMessage> { message },
                CreatedAt = DateTime.UtcNow,
                LastActivity = DateTime.UtcNow,
                IsActive = true,
                UnreadCount = message.IsFromGuest ? 1 : 0
            },
            // Update existing conversation
            (_, existing) =>
            {
                lock (_lock)
                {
                    existing.Messages.Add(message);
                    existing.LastActivity = DateTime.UtcNow;
                    if (message.IsFromGuest)
                    {
                        existing.UnreadCount++;
                    }
                }
                return existing;
            }
        );
    }

    public List<GuestConversation> GetAllActiveConversations()
    {
        return _conversations.Values
            .Where(c => c.IsActive)
            .OrderByDescending(c => c.LastActivity)
            .ToList();
    }

    public GuestConversation? GetConversation(string guestId)
    {
        lock (_lock)
        {
            if (_conversations.TryGetValue(guestId, out var conversation))
            {
                // Return a copy or careful clone? For now just reference, but modification is risky.
                // ideally return DTO or Clone. since GuestConversation is mutable List.
                // Deep clone is expensive.
                // Assuming callers don't modify the list directly without service.
                return conversation; 
            }
            return null;
        }
    }

    public List<GuestMessage> GetMessages(string guestId)
    {
        lock (_lock)
        {
            if (_conversations.TryGetValue(guestId, out var conversation))
            {
                return conversation.Messages.ToList();
            }
            return new List<GuestMessage>();
        }
    }

    public void CloseConversation(string guestId)
    {
        if (_conversations.TryGetValue(guestId, out var conversation))
        {
            conversation.IsActive = false;
        }
    }

    public void CleanupInactiveConversations(TimeSpan inactiveThreshold)
    {
        var cutoffTime = DateTime.UtcNow - inactiveThreshold;
        var toRemove = _conversations
            .Where(kvp => !kvp.Value.IsActive || kvp.Value.LastActivity < cutoffTime)
            .Select(kvp => kvp.Key)
            .ToList();

        foreach (var guestId in toRemove)
        {
            _conversations.TryRemove(guestId, out _);
        }
    }

    public void MarkAsRead(string guestId)
    {
        if (_conversations.TryGetValue(guestId, out var conversation))
        {
            conversation.UnreadCount = 0;
        }
    }

    public void UpdateActivity(string guestId)
    {
        if (_conversations.TryGetValue(guestId, out var conversation))
        {
            conversation.LastActivity = DateTime.UtcNow;
        }
    }
}
