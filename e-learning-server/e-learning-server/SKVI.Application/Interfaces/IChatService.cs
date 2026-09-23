using SKVI.Application.DTOs.Chat;

namespace SKVI.Application.Interfaces;

public interface IChatService
{
    Task<List<ConversationResponse>> GetUserConversationsAsync(Guid userId);
    Task<List<ConversationResponse>> GetAllConversationsAsync();
    Task<List<MessageResponse>> GetConversationMessagesForAdminAsync(Guid conversationId); // New
    Task<ConversationResponse> GetConversationByIdAsync(Guid conversationId, Guid userId);
    Task<List<MessageResponse>> GetConversationMessagesAsync(Guid conversationId, Guid userId);
    Task<ConversationResponse> CreateConversationAsync(Guid userId, Guid recipientId);
    Task<MessageResponse> SendMessageAsync(Guid conversationId, Guid userId, string content, Guid? clientMessageId = null);
    Task MarkMessagesAsReadAsync(Guid conversationId, Guid userId);
    Task<int> GetUnreadCountAsync(Guid userId);

    /// <summary>
    /// Returns an available support/agent/admin user to receive conversations.
    /// Priority: CARE -> AGENT -> ADMIN. Returns null if none found.
    /// </summary>
    Task<UserSummary?> GetDefaultSupportUserAsync();
}

public record UserSummary(Guid Id, string FullName, string Role, string? AvatarUrl);
