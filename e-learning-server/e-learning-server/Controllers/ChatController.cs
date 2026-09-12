using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.SignalR;
using SKVI.Application.DTOs.Chat;
using SKVI.Application.Interfaces;
using SKVI.Infrastructure.Hubs;
using System.Security.Claims;

namespace SKVI.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class ChatController : ControllerBase
{
    private readonly IChatService _chatService;
    private readonly IHubContext<ChatHub> _hubContext;

    public ChatController(
        IChatService chatService,
        IHubContext<ChatHub> hubContext)
    {
        _chatService = chatService;
        _hubContext = hubContext;
    }

    [HttpGet("conversations")]
    public async Task<ActionResult<List<ConversationResponse>>> GetConversations()
    {
        var userId = Guid.Parse(User.FindFirst(ClaimTypes.NameIdentifier)!.Value);
        var conversations = await _chatService.GetUserConversationsAsync(userId);
        return Ok(conversations);
    }

    [HttpGet("conversations/{id}")]
    public async Task<ActionResult<ConversationResponse>> GetConversation(Guid id)
    {
        var userId = Guid.Parse(User.FindFirst(ClaimTypes.NameIdentifier)!.Value);
        
        try
        {
            var conversation = await _chatService.GetConversationByIdAsync(id, userId);
            return Ok(conversation);
        }
        catch (UnauthorizedAccessException)
        {
            return Forbid();
        }
    }

    [HttpPost("conversations")]
    public async Task<ActionResult<ConversationResponse>> CreateConversation([FromBody] CreateConversationDto dto)
    {
        var userId = Guid.Parse(User.FindFirst(ClaimTypes.NameIdentifier)!.Value);
        try
        {
            var conversation = await _chatService.CreateConversationAsync(userId, dto.RecipientId);
            return Ok(conversation);
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    [HttpGet("conversations/{id}/messages")]
    public async Task<ActionResult<List<MessageResponse>>> GetMessages(Guid id)
    {
        var userId = Guid.Parse(User.FindFirst(ClaimTypes.NameIdentifier)!.Value);
        
        try
        {
            var messages = await _chatService.GetConversationMessagesAsync(id, userId);
            return Ok(messages);
        }
        catch (UnauthorizedAccessException)
        {
            return Forbid();
        }
    }

    [HttpPost("messages")]
    public async Task<ActionResult<MessageResponse>> SendMessage([FromBody] SendMessageDto dto)
    {
        var userId = Guid.Parse(User.FindFirst(ClaimTypes.NameIdentifier)!.Value);
        
        try
        {
            var message = await _chatService.SendMessageAsync(dto.ConversationId, userId, dto.Content);

            // Broadcast to conversation group and care-group for real-time SignalR sync
            await _hubContext.Clients.Group($"conversation-{dto.ConversationId}").SendAsync("ReceiveMessage", message);
            await _hubContext.Clients.Group("care-group").SendAsync("ReceiveMessage", message);

            // Broadcast to participant user groups for multi-device sync
            try
            {
                var conv = await _chatService.GetConversationByIdAsync(dto.ConversationId, userId);
                foreach (var p in conv.Participants)
                {
                    await _hubContext.Clients.Group($"user-{p.UserId}").SendAsync("ReceiveMessage", message);
                    await _hubContext.Clients.Group($"user-{p.UserId}").SendAsync("ConversationUpdated", conv);
                }
            }
            catch
            {
                // Silently ignore broadcast lookup errors
            }

            return Ok(message);
        }
        catch (UnauthorizedAccessException)
        {
            return Forbid();
        }
    }

    [HttpPut("conversations/{id}/read")]
    public async Task<IActionResult> MarkAsRead(Guid id)
    {
        var userId = Guid.Parse(User.FindFirst(ClaimTypes.NameIdentifier)!.Value);
        
        try
        {
            await _chatService.MarkMessagesAsReadAsync(id, userId);

            // Broadcast "MessagesRead" to the conversation group so counterparty sees "Seen"
            await _hubContext.Clients.Group($"conversation-{id}")
                .SendAsync("MessagesRead", id, userId);

            return NoContent();
        }
        catch (UnauthorizedAccessException)
        {
            return Forbid();
        }
    }

    [HttpGet("unread-count")]
    public async Task<ActionResult<int>> GetUnreadCount()
    {
        var userId = Guid.Parse(User.FindFirst(ClaimTypes.NameIdentifier)!.Value);
        var count = await _chatService.GetUnreadCountAsync(userId);
        return Ok(count);
    }

    [HttpGet("support-user")]
    public async Task<ActionResult<UserSummary?>> GetSupportUser()
    {
        var support = await _chatService.GetDefaultSupportUserAsync();
        if (support == null) return NotFound();
        return Ok(support);
    }
}
