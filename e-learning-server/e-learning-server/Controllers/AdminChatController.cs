using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SKVI.Application.DTOs.Chat;
using SKVI.Application.Interfaces;
using SKVI.Application.Models.Chat;

using Microsoft.AspNetCore.SignalR;
using SKVI.Infrastructure.Hubs;

namespace SKVI.API.Controllers;

[ApiController]
[Route("api/admin/chat")]
[Authorize(Roles = "ADMIN,CARE")]
public class AdminChatController : ControllerBase
{
    private readonly IChatService _chatService;
    private readonly IGuestConversationService _guestConversationService;
    private readonly IHubContext<ChatHub> _hubContext;

    public AdminChatController(
        IChatService chatService,
        IGuestConversationService guestConversationService,
        IHubContext<ChatHub> hubContext)
    {
        _chatService = chatService;
        _guestConversationService = guestConversationService;
        _hubContext = hubContext;
    }

    [HttpPost("guest/{guestId}/send")]
    public async Task<IActionResult> SendGuestReply(string guestId, [FromBody] GuestReplyRequest request)
    {
        if (string.IsNullOrWhiteSpace(request.Content) || request.Content.Length > 1000)
            return BadRequest(new { message = "Invalid message content" });
        if (_guestConversationService.GetConversation(guestId) == null) return NotFound();
        var message = new GuestMessage {
            SenderId = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)!.Value,
            SenderName = User.FindFirst("fullName")?.Value ?? "SKVI Support",
            Content = request.Content.Trim(), IsFromGuest = false
        };
        _guestConversationService.AddOrUpdateConversation(guestId, message);
        await _hubContext.Clients.Group($"guest-{guestId}").SendAsync("ReceiveMessage", message);
        await _hubContext.Clients.Group("care-group").SendAsync("ReceiveGuestMessage", guestId, message);
        return Ok(message);
    }

    public record GuestReplyRequest(string Content);

    [HttpGet("conversations")]
    public async Task<ActionResult<AdminConversationsResponse>> GetAllConversations()
    {
        try
        {
            // Get guest conversations
            var guestConversations = _guestConversationService.GetAllActiveConversations();

            // Get authenticated conversations
            var userConversations = await _chatService.GetAllConversationsAsync();

            var response = new AdminConversationsResponse
            {
                AuthenticatedConversations = userConversations.Select(c => new AdminConversationDto
                {
                    Id = c.Id.ToString(),
                    Type = "authenticated",
                    UserId = c.OtherParticipant?.UserId.ToString() ?? c.Participants.FirstOrDefault()?.UserId.ToString(), 
                    // Display name: Show student/member name or other participant name
                    UserName = c.OtherParticipant?.UserName ?? c.Title ?? c.Participants.FirstOrDefault()?.UserName ?? "Thành viên",
                    LastMessage = c.LastMessage?.Content,
                    LastActivity = c.LastMessage?.SentAt ?? c.CreatedAt,
                    UnreadCount = c.UnreadCount,
                    IsActive = true
                }).ToList(),
                
                GuestConversations = guestConversations.Select(g => 
                {
                    var guestName = g.Messages.FirstOrDefault(m => m.IsFromGuest)?.SenderName;
                    var displayName = !string.IsNullOrWhiteSpace(guestName) && guestName != "Guest"
                        ? guestName
                        : $"Guest ({g.GuestId.Substring(0, 8)}...)";

                    return new AdminConversationDto
                    {
                        Id = g.GuestId,
                        Type = "guest",
                        GuestId = g.GuestId,
                        UserName = displayName,
                        LastMessage = g.LastMessage,
                        LastActivity = g.LastActivity,
                        UnreadCount = g.UnreadCount,
                        IsActive = g.IsActive
                    };
                }).ToList()
            };

            return Ok(response);
        }
        catch (Exception ex)
        {
            return StatusCode(500, new { message = "Error fetching conversations", error = ex.Message });
        }
    }

    [HttpGet("guest/{guestId}/messages")]
    public ActionResult<List<GuestMessage>> GetGuestMessages(string guestId)
    {
        try
        {
            var messages = _guestConversationService.GetMessages(guestId);
            return Ok(messages);
        }
        catch (Exception ex)
        {
            return StatusCode(500, new { message = "Error fetching guest messages", error = ex.Message });
        }
    }

    [HttpPost("guest/{guestId}/close")]
    public ActionResult CloseGuestConversation(string guestId)
    {
        try
        {
            _guestConversationService.CloseConversation(guestId);
            return Ok(new { message = "Guest conversation closed successfully" });
        }
        catch (Exception ex)
        {
            return StatusCode(500, new { message = "Error closing guest conversation", error = ex.Message });
        }
    }

    [HttpPost("guest/{guestId}/mark-read")]
    public ActionResult MarkGuestConversationAsRead(string guestId)
    {
        try
        {
            _guestConversationService.MarkAsRead(guestId);
            return Ok(new { message = "Guest conversation marked as read" });
        }
        catch (Exception ex)
        {
            return StatusCode(500, new { message = "Error marking conversation as read", error = ex.Message });
        }
    }

    [HttpGet("conversations/{conversationId}/messages")]
    public async Task<IActionResult> GetConversationMessages(Guid conversationId)
    {
        var messages = await _chatService.GetConversationMessagesForAdminAsync(conversationId);
        return Ok(messages.Select(m => new GuestMessage
        {
            Id = m.Id.ToString(),
            SenderId = m.SenderId.ToString(),
            SenderName = m.SenderName,
            Content = m.Content,
            SentAt = m.SentAt,
            // Check if sender is Student/User (Guest side) or Admin/Care/Agent (Me side)
            IsFromGuest = m.SenderRole == "STUDENT" || m.SenderRole == "USER"
        }));
    }

    [HttpPost("conversations/{conversationId}/read")]
    public async Task<IActionResult> MarkConversationAsRead(Guid conversationId)
    {
        // Admin marking auth user conversation as read
        // SenderId param in MarkMessagesAsReadAsync is the "ReaderId"
        // So we pass the current Admin's ID
        var adminId = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;
        if (string.IsNullOrEmpty(adminId)) return Unauthorized();

        await _chatService.MarkMessagesAsReadAsync(conversationId, Guid.Parse(adminId));
        
        // Broadcast "MessagesRead" to the conversation group so the User sees "Seen"
        await _hubContext.Clients.Group($"conversation-{conversationId}")
            .SendAsync("MessagesRead", conversationId, adminId);
            
        return Ok();
    }
}

public class AdminConversationsResponse
{
    public List<AdminConversationDto> AuthenticatedConversations { get; set; } = new();
    public List<AdminConversationDto> GuestConversations { get; set; } = new();
}

public class AdminConversationDto
{
    public string Id { get; set; } = string.Empty;
    public string Type { get; set; } = string.Empty; // "authenticated" or "guest"
    public string? GuestId { get; set; }
    public string? UserId { get; set; }
    public string UserName { get; set; } = string.Empty;
    public string? LastMessage { get; set; }
    public DateTime LastActivity { get; set; }
    public int UnreadCount { get; set; }
    public bool IsActive { get; set; }
}
