using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SKVI.Application.DTOs.Chat;
using SKVI.Application.Interfaces;
using System.Security.Claims;

namespace SKVI.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class ChatController : ControllerBase
{
    private readonly IChatService _chatService;

    public ChatController(IChatService chatService)
    {
        _chatService = chatService;
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
