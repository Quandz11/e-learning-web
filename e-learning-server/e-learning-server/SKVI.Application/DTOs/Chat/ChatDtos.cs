using System;

namespace SKVI.Application.DTOs.Chat;

public class MessageResponse
{
    public Guid Id { get; set; }
    public Guid ConversationId { get; set; }
    public Guid SenderId { get; set; }
    public string SenderName { get; set; } = string.Empty;
    public string SenderRole { get; set; } = string.Empty; // Added for Admin Chat
    public string Content { get; set; } = string.Empty;
    public DateTime SentAt { get; set; }
    public bool IsRead { get; set; }
}

public class ConversationResponse
{
    public Guid Id { get; set; }
    public string? Title { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime LastMessageAt { get; set; }
    public List<ParticipantResponse> Participants { get; set; } = new();
    public ParticipantResponse? OtherParticipant { get; set; }
    public MessageResponse? LastMessage { get; set; }
    public int UnreadCount { get; set; }
}

public class ParticipantResponse
{
    public Guid UserId { get; set; }
    public string UserName { get; set; } = string.Empty;
    public string Role { get; set; } = string.Empty;
    public string? AvatarUrl { get; set; }
    public DateTime? LastReadAt { get; set; }
}

public class CreateConversationDto
{
    public Guid RecipientId { get; set; }
}

public class SendMessageDto
{
    public Guid ConversationId { get; set; }
    public string Content { get; set; } = string.Empty;
}
