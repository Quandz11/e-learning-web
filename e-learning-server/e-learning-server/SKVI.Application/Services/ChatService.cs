using Microsoft.EntityFrameworkCore;
using SKVI.Application.DTOs.Chat;
using SKVI.Application.Interfaces;
using SKVI.Domain.Entities;
using SKVI.Infrastructure;

namespace SKVI.Application.Services;

public class ChatService : IChatService
{
    private readonly ApplicationDbContext _context;

    public ChatService(ApplicationDbContext context)
    {
        _context = context;
    }

    public async Task<List<ConversationResponse>> GetUserConversationsAsync(Guid userId)
    {
        var conversations = await _context.Conversations
            .Include(c => c.Participants)
                .ThenInclude(p => p.User)
            .Include(c => c.Messages.OrderByDescending(m => m.SentAt).Take(1))
                .ThenInclude(m => m.Sender)
            .Where(c => c.Participants.Any(p => p.UserId == userId) && c.IsActive)
            .OrderByDescending(c => c.LastMessageAt)
            .ToListAsync();

        var result = new List<ConversationResponse>();

        foreach (var conv in conversations)
        {
            var participant = conv.Participants.FirstOrDefault(p => p.UserId == userId);
            var otherParticipant = conv.Participants.FirstOrDefault(p => p.UserId != userId);
            var unreadCount = await _context.Messages
                .Where(m => m.ConversationId == conv.Id 
                    && m.SenderId != userId 
                    && !m.IsRead
                    && (participant == null || participant.LastReadAt == null || m.SentAt > participant.LastReadAt))
                .CountAsync();

            result.Add(new ConversationResponse
            {
                Id = conv.Id,
                Title = conv.Title ?? otherParticipant?.User?.FullName ?? "Trò chuyện",
                CreatedAt = conv.CreatedAt,
                LastMessageAt = conv.LastMessageAt,
                Participants = conv.Participants.Select(p => new ParticipantResponse
                {
                    UserId = p.UserId,
                    UserName = p.User?.FullName ?? "Unknown",
                    Role = p.User?.Role ?? "USER",
                    AvatarUrl = p.User?.AvatarUrl,
                    LastReadAt = p.LastReadAt
                }).ToList(),
                OtherParticipant = otherParticipant != null ? new ParticipantResponse
                {
                    UserId = otherParticipant.UserId,
                    UserName = otherParticipant.User?.FullName ?? "Unknown",
                    Role = otherParticipant.User?.Role ?? "USER",
                    AvatarUrl = otherParticipant.User?.AvatarUrl,
                    LastReadAt = otherParticipant.LastReadAt
                } : null,
                LastMessage = conv.Messages.OrderByDescending(m => m.SentAt).FirstOrDefault() != null
                    ? MapToMessageResponse(conv.Messages.OrderByDescending(m => m.SentAt).First())
                    : null,
                UnreadCount = unreadCount
            });
        }

        return result;
    }

    public async Task<List<ConversationResponse>> GetAllConversationsAsync()
    {
        var conversations = await _context.Conversations
            .Include(c => c.Participants)
                .ThenInclude(p => p.User)
            .Include(c => c.Messages.OrderByDescending(m => m.SentAt).Take(1))
                .ThenInclude(m => m.Sender)
            .Where(c => c.IsActive && c.Participants.Count > 0)
            .OrderByDescending(c => c.LastMessageAt)
            .ToListAsync();

        var result = new List<ConversationResponse>();

        foreach (var conv in conversations)
        {
            var unreadCount = await _context.Messages
                .Where(m => m.ConversationId == conv.Id && !m.IsRead)
                .CountAsync();

            var firstParticipant = conv.Participants.FirstOrDefault();
            var secondParticipant = conv.Participants.Skip(1).FirstOrDefault();

            result.Add(new ConversationResponse
            {
                Id = conv.Id,
                Title = conv.Title ?? string.Join(", ", conv.Participants.Select(p => p.User?.FullName ?? "Unknown")),
                CreatedAt = conv.CreatedAt,
                LastMessageAt = conv.LastMessageAt,
                Participants = conv.Participants.Select(p => new ParticipantResponse
                {
                    UserId = p.UserId,
                    UserName = p.User?.FullName ?? "Unknown",
                    Role = p.User?.Role ?? "USER",
                    AvatarUrl = p.User?.AvatarUrl,
                    LastReadAt = p.LastReadAt
                }).ToList(),
                OtherParticipant = secondParticipant != null ? new ParticipantResponse
                {
                    UserId = secondParticipant.UserId,
                    UserName = secondParticipant.User?.FullName ?? "Unknown",
                    Role = secondParticipant.User?.Role ?? "USER",
                    AvatarUrl = secondParticipant.User?.AvatarUrl,
                    LastReadAt = secondParticipant.LastReadAt
                } : (firstParticipant != null ? new ParticipantResponse
                {
                    UserId = firstParticipant.UserId,
                    UserName = firstParticipant.User?.FullName ?? "Unknown",
                    Role = firstParticipant.User?.Role ?? "USER",
                    AvatarUrl = firstParticipant.User?.AvatarUrl,
                    LastReadAt = firstParticipant.LastReadAt
                } : null),
                LastMessage = conv.Messages.OrderByDescending(m => m.SentAt).FirstOrDefault() != null
                    ? MapToMessageResponse(conv.Messages.OrderByDescending(m => m.SentAt).First())
                    : null,
                UnreadCount = unreadCount
            });
        }

        return result;
    }

    public async Task<ConversationResponse> GetConversationByIdAsync(Guid conversationId, Guid userId)
    {
        var conv = await _context.Conversations
            .Include(c => c.Participants)
                .ThenInclude(p => p.User)
            .Include(c => c.Messages.OrderByDescending(m => m.SentAt).Take(1))
                .ThenInclude(m => m.Sender)
            .FirstOrDefaultAsync(c => c.Id == conversationId && c.Participants.Any(p => p.UserId == userId));

        if (conv == null)
            throw new UnauthorizedAccessException("Not a participant of this conversation");

        var participant = conv.Participants.FirstOrDefault(p => p.UserId == userId);
        var otherParticipant = conv.Participants.FirstOrDefault(p => p.UserId != userId);
        var unreadCount = await _context.Messages
            .Where(m => m.ConversationId == conv.Id 
                && m.SenderId != userId 
                && !m.IsRead
                && (participant == null || participant.LastReadAt == null || m.SentAt > participant.LastReadAt))
            .CountAsync();

        return new ConversationResponse
        {
            Id = conv.Id,
            Title = conv.Title ?? otherParticipant?.User?.FullName ?? "Trò chuyện",
            CreatedAt = conv.CreatedAt,
            LastMessageAt = conv.LastMessageAt,
            Participants = conv.Participants.Select(p => new ParticipantResponse
            {
                UserId = p.UserId,
                UserName = p.User?.FullName ?? "Unknown",
                Role = p.User?.Role ?? "USER",
                AvatarUrl = p.User?.AvatarUrl,
                LastReadAt = p.LastReadAt
            }).ToList(),
            OtherParticipant = otherParticipant != null ? new ParticipantResponse
            {
                UserId = otherParticipant.UserId,
                UserName = otherParticipant.User?.FullName ?? "Unknown",
                Role = otherParticipant.User?.Role ?? "USER",
                AvatarUrl = otherParticipant.User?.AvatarUrl,
                LastReadAt = otherParticipant.LastReadAt
            } : null,
            LastMessage = conv.Messages.OrderByDescending(m => m.SentAt).FirstOrDefault() != null
                ? MapToMessageResponse(conv.Messages.OrderByDescending(m => m.SentAt).First())
                : null,
            UnreadCount = unreadCount
        };
    }

    public async Task<List<MessageResponse>> GetConversationMessagesAsync(Guid conversationId, Guid userId)
    {
        // Verify user is participant
        var isParticipant = await _context.ConversationParticipants
            .AnyAsync(p => p.ConversationId == conversationId && p.UserId == userId);

        if (!isParticipant)
            throw new UnauthorizedAccessException("Not a participant of this conversation");

        var messages = await _context.Messages
            .Include(m => m.Sender)
            .Where(m => m.ConversationId == conversationId)
            .OrderBy(m => m.SentAt)
            .ToListAsync();

        return messages.Select(MapToMessageResponse).ToList();
    }

    public async Task<List<MessageResponse>> GetConversationMessagesForAdminAsync(Guid conversationId)
    {
        var messages = await _context.Messages
            .Include(m => m.Sender)
            .Where(m => m.ConversationId == conversationId)
            .OrderBy(m => m.SentAt)
            .ToListAsync();

        return messages.Select(MapToMessageResponse).ToList();
    }

    public async Task<ConversationResponse> CreateConversationAsync(Guid userId, Guid recipientId)
    {
        // Ensure recipient exists; if not, pick a default support user
        var recipientExists = await _context.Users.AnyAsync(u => u.Id == recipientId);
        if (!recipientExists)
        {
            var support = await GetDefaultSupportUserAsync();
            if (support == null)
                throw new InvalidOperationException("No available support user to create conversation with.");

            recipientId = support.Id;
        }

        // Check if conversation already exists
        var existingConv = await _context.Conversations
            .Include(c => c.Participants)
            .FirstOrDefaultAsync(c => 
                c.Participants.Count == 2 &&
                c.Participants.Any(p => p.UserId == userId) &&
                c.Participants.Any(p => p.UserId == recipientId));

        if (existingConv != null)
        {
            return await GetConversationByIdAsync(existingConv.Id, userId);
        }

        // Create new conversation
        var conversation = new Conversation
        {
            Id = Guid.NewGuid(),
            CreatedAt = DateTime.UtcNow,
            LastMessageAt = DateTime.UtcNow,
            IsActive = true
        };

        conversation.Participants.Add(new ConversationParticipant
        {
            Id = Guid.NewGuid(),
            ConversationId = conversation.Id,
            UserId = userId,
            JoinedAt = DateTime.UtcNow
        });

        conversation.Participants.Add(new ConversationParticipant
        {
            Id = Guid.NewGuid(),
            ConversationId = conversation.Id,
            UserId = recipientId,
            JoinedAt = DateTime.UtcNow
        });

        _context.Conversations.Add(conversation);
        await _context.SaveChangesAsync();

        return await GetConversationByIdAsync(conversation.Id, userId);
    }

    public async Task<MessageResponse> SendMessageAsync(Guid conversationId, Guid userId, string content)
    {
        // Verify user is participant
        var isParticipant = await _context.ConversationParticipants
            .AnyAsync(p => p.ConversationId == conversationId && p.UserId == userId);

        if (!isParticipant)
            throw new UnauthorizedAccessException("Not a participant of this conversation");

        var message = new Message
        {
            Id = Guid.NewGuid(),
            ConversationId = conversationId,
            SenderId = userId,
            Content = content,
            SentAt = DateTime.UtcNow,
            IsRead = false,
            IsEdited = false
        };

        _context.Messages.Add(message);

        // Update conversation last message time
        var conversation = await _context.Conversations.FindAsync(conversationId);
        if (conversation != null)
        {
            conversation.LastMessageAt = DateTime.UtcNow;
        }

        await _context.SaveChangesAsync();

        // Load sender info
        var messageWithSender = await _context.Messages
            .Include(m => m.Sender)
            .FirstAsync(m => m.Id == message.Id);

        return MapToMessageResponse(messageWithSender);
    }

    public async Task MarkMessagesAsReadAsync(Guid conversationId, Guid userId)
    {
        var participant = await _context.ConversationParticipants
            .FirstOrDefaultAsync(p => p.ConversationId == conversationId && p.UserId == userId);

        if (participant == null)
            throw new UnauthorizedAccessException("Not a participant of this conversation");

        participant.LastReadAt = DateTime.UtcNow;

        // Mark all messages as read
        var unreadMessages = await _context.Messages
            .Where(m => m.ConversationId == conversationId && m.SenderId != userId && !m.IsRead)
            .ToListAsync();

        foreach (var msg in unreadMessages)
        {
            msg.IsRead = true;
        }

        await _context.SaveChangesAsync();
    }

    public async Task<int> GetUnreadCountAsync(Guid userId)
    {
        var participantConversations = await _context.ConversationParticipants
            .Where(p => p.UserId == userId)
            .Select(p => new { p.ConversationId, p.LastReadAt })
            .ToListAsync();

        var totalUnread = 0;

        foreach (var pc in participantConversations)
        {
            var unread = await _context.Messages
                .Where(m => m.ConversationId == pc.ConversationId 
                    && m.SenderId != userId 
                    && !m.IsRead
                    && (pc.LastReadAt == null || m.SentAt > pc.LastReadAt))
                .CountAsync();

            totalUnread += unread;
        }

        return totalUnread;
    }

    public async Task<UserSummary?> GetDefaultSupportUserAsync()
    {
        // Priority: CARE -> AGENT -> ADMIN
        var support = await _context.Users
            .Where(u => u.Role == "CARE" || u.Role == "AGENT" || u.Role == "ADMIN")
            .OrderBy(u => u.Role == "CARE" ? 0 : u.Role == "AGENT" ? 1 : 2)
            .Select(u => new UserSummary(u.Id, u.FullName ?? "Support", u.Role, u.AvatarUrl))
            .FirstOrDefaultAsync();

        return support;
    }

    private MessageResponse MapToMessageResponse(Message message)
    {
        return new MessageResponse
        {
            Id = message.Id,
            ConversationId = message.ConversationId,
            SenderId = message.SenderId,
            SenderName = message.Sender?.FullName ?? "Unknown User",
            SenderRole = message.Sender?.Role ?? "STUDENT", // Map Role
            Content = message.Content,
            SentAt = message.SentAt,
            IsRead = message.IsRead
        };
    }
}
