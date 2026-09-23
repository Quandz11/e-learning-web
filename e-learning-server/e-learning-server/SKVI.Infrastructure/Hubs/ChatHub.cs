using Microsoft.AspNetCore.SignalR;
using Microsoft.AspNetCore.Authorization;
using System.Security.Claims;
using SKVI.Application.Interfaces;

namespace SKVI.Infrastructure.Hubs;

public class ChatHub : Hub
{
    private readonly IChatService _chatService;
    private readonly IGuestConversationService _guestConversationService;
    private readonly ILogger<ChatHub> _logger;
    private static readonly Dictionary<string, string> _guestConnections = new(); // connectionId -> guestId
    private static readonly Dictionary<string, DateTime> _lastMessageTime = new(); // userId/guestId -> last message time
    
    // Rate limiting constants (per Chat.md section 11.1)
    private const int GUEST_RATE_LIMIT_SECONDS = 2;
    private const int USER_RATE_LIMIT_SECONDS = 1;
    private const int MAX_MESSAGE_LENGTH = 1000; // Chat.md section 11.2

    public ChatHub(IChatService chatService, IGuestConversationService guestConversationService, ILogger<ChatHub> logger)
    {
        _chatService = chatService;
        _guestConversationService = guestConversationService;
        _logger = logger;
    }
    
    private bool CheckRateLimit(string identifier, int rateLimitSeconds)
    {
        lock (_lastMessageTime)
        {
            if (_lastMessageTime.TryGetValue(identifier, out var lastTime))
            {
                var timeSinceLastMessage = DateTime.UtcNow - lastTime;
                if (timeSinceLastMessage.TotalSeconds < rateLimitSeconds)
                {
                    return false; // Rate limit exceeded
                }
            }
            
            _lastMessageTime[identifier] = DateTime.UtcNow;
            return true;
        }
    }

    public override async Task OnConnectedAsync()
    {
        var userId = Context.User?.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        var role = Context.User?.FindFirst(ClaimTypes.Role)?.Value;
        
        _logger.LogInformation($"[ChatHub] Connected: ConnectionId={Context.ConnectionId}, UserId={userId}, Role={role}");

        if (!string.IsNullOrEmpty(userId))
        {
            // Authenticated user - join their personal group
            await Groups.AddToGroupAsync(Context.ConnectionId, $"user-{userId}");

            // Resolve role from standard ClaimTypes or raw "role" claim
            // Resolve role from standard ClaimTypes or raw "role" claim
            var roleClaim = Context.User?.Claims.FirstOrDefault(c => 
                c.Type == ClaimTypes.Role || 
                c.Type == "role" || 
                c.Type == "http://schemas.microsoft.com/ws/2008/06/identity/claims/role");
            
            var userRole = roleClaim?.Value;

            _logger.LogInformation($"[ChatHub] User Connected: {userId}, RoleClaim={userRole}");

            // Support roles join a shared support group to receive guest chats
            if (!string.IsNullOrEmpty(userRole))
            {
                if (userRole.Equals("ADMIN", StringComparison.OrdinalIgnoreCase))
                {
                    await Groups.AddToGroupAsync(Context.ConnectionId, "admin-group");
                    _logger.LogInformation($"[ChatHub] User {userId} added to admin-group.");
                }

                if (userRole.Equals("ADMIN", StringComparison.OrdinalIgnoreCase) || 
                    userRole.Equals("AGENT", StringComparison.OrdinalIgnoreCase) || 
                    userRole.Equals("CARE", StringComparison.OrdinalIgnoreCase))
                {
                    await Groups.AddToGroupAsync(Context.ConnectionId, "care-group");
                    _logger.LogInformation($"[ChatHub] User {userId} added to care-group.");
                }
            }
        }
        
        await base.OnConnectedAsync();
    }

    public override async Task OnDisconnectedAsync(Exception? exception)
    {
        var userId = Context.User?.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        var role = Context.User?.FindFirst(ClaimTypes.Role)?.Value;
        
        if (!string.IsNullOrEmpty(userId))
        {
            await Groups.RemoveFromGroupAsync(Context.ConnectionId, $"user-{userId}");
            
            if (!string.IsNullOrEmpty(role))
            {
                if (role.Equals("ADMIN", StringComparison.OrdinalIgnoreCase))
                {
                    await Groups.RemoveFromGroupAsync(Context.ConnectionId, "admin-group");
                }

                if (role.Equals("ADMIN", StringComparison.OrdinalIgnoreCase) || 
                    role.Equals("AGENT", StringComparison.OrdinalIgnoreCase) || 
                    role.Equals("CARE", StringComparison.OrdinalIgnoreCase))
                {
                    await Groups.RemoveFromGroupAsync(Context.ConnectionId, "care-group");
                }
            }
        }
        
        if (_guestConnections.TryGetValue(Context.ConnectionId, out var guestId))
        {
            // Mark conversation as inactive
            _guestConversationService.CloseConversation(guestId);
            
            // Notify care agents that guest has disconnected
            await Clients.Group("care-group").SendAsync("GuestDisconnected", guestId);
            
            _guestConnections.Remove(Context.ConnectionId);
        }
        
        await base.OnDisconnectedAsync(exception);
    }

    // Guest chat (temporary, no DB)
    [AllowAnonymous]
    public async Task SendGuestMessage(string guestId, string guestName, string content, string agentId)
    {
        // Validate message length
        if (string.IsNullOrWhiteSpace(content) || content.Length > MAX_MESSAGE_LENGTH)
        {
            await Clients.Caller.SendAsync("Error", "Message must be between 1 and 1000 characters");
            return;
        }
        
        // Check rate limit for guest
        if (!CheckRateLimit($"guest-{guestId}", GUEST_RATE_LIMIT_SECONDS))
        {
            await Clients.Caller.SendAsync("RateLimitExceeded", "Please wait before sending another message");
            return;
        }
        
        var message = new SKVI.Application.Models.Chat.GuestMessage
        {
            Id = Guid.NewGuid().ToString(),
            SenderId = guestId,
            SenderName = !string.IsNullOrWhiteSpace(guestName) ? guestName : "Guest",
            Content = content,
            SentAt = DateTime.UtcNow,
            IsFromGuest = true
        };

        // Store in guest conversation service
        _guestConversationService.AddOrUpdateConversation(guestId, message);
        _guestConversationService.UpdateActivity(guestId);

        // Send to all online care agents
        await Clients.Group("care-group").SendAsync("ReceiveGuestMessage", guestId, message);
        
        // Echo back to guest
        await Clients.Caller.SendAsync("ReceiveMessage", message);
    }

    // Agent reply to guest
    [Authorize]
    public async Task SendGuestReply(string guestId, string content)
    {
        var userId = Context.User?.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        var userName = Context.User?.FindFirst(ClaimTypes.Name)?.Value ?? "SKVI Support";

        var message = new SKVI.Application.Models.Chat.GuestMessage
        {
            Id = Guid.NewGuid().ToString(),
            SenderId = userId ?? "unknown",
            SenderName = userName,
            Content = content,
            SentAt = DateTime.UtcNow,
            IsFromGuest = false
        };

        // Store in guest conversation service
        _guestConversationService.AddOrUpdateConversation(guestId, message);
        _guestConversationService.UpdateActivity(guestId);

        // Send to all connections with this guestId (in case multiple tabs)
        await Clients.Group($"guest-{guestId}").SendAsync("ReceiveMessage", message);
        
        // Echo back to agent
        await Clients.Caller.SendAsync("ReceiveMessage", message);
    }

    // Join guest group (for receiving agent replies)
    [AllowAnonymous]
    public async Task JoinGuestChat(string guestId)
    {
        await Groups.AddToGroupAsync(Context.ConnectionId, $"guest-{guestId}");
        _guestConnections[Context.ConnectionId] = guestId;
    }

    // Authenticated user chat (persistent)
    [Authorize]
    public async Task SendMessage(Guid conversationId, string content, Guid? clientMessageId = null)
    {
        var userId = Context.User?.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (string.IsNullOrEmpty(userId)) return;
        
        // Validate message length
        if (string.IsNullOrWhiteSpace(content) || content.Length > MAX_MESSAGE_LENGTH)
        {
            await Clients.Caller.SendAsync("Error", "Message must be between 1 and 1000 characters");
            return;
        }
        
        // Check rate limit for authenticated user
        if (!CheckRateLimit($"user-{userId}", USER_RATE_LIMIT_SECONDS))
        {
            await Clients.Caller.SendAsync("RateLimitExceeded", "Please wait before sending another message");
            return;
        }

        var message = await _chatService.SendMessageAsync(conversationId, Guid.Parse(userId), content, clientMessageId);
        
        // Send to all participants in conversation
        await Clients.Group($"conversation-{conversationId}").SendAsync("ReceiveMessage", message);

        // Notify Admins/Support (care-group) so they see the new message in their list immediately
        await Clients.Group("care-group").SendAsync("ReceiveMessage", message);

        // Broadcast to user groups of all participants for multi-device & conversation list real-time sync
        try
        {
            var conv = await _chatService.GetConversationByIdAsync(conversationId, Guid.Parse(userId));
            foreach (var p in conv.Participants)
            {
                await Clients.Group($"user-{p.UserId}").SendAsync("ReceiveMessage", message);
                await Clients.Group($"user-{p.UserId}").SendAsync("ConversationUpdated", conv);
            }
        }
        catch (Exception ex)
        {
            _logger.LogWarning(ex, "[ChatHub] Failed to broadcast ConversationUpdated to participant user groups");
        }
    }

    [Authorize]
    public async Task JoinConversation(Guid conversationId)
    {
        await Groups.AddToGroupAsync(Context.ConnectionId, $"conversation-{conversationId}");
    }

    [Authorize]
    public async Task LeaveConversation(Guid conversationId)
    {
        await Groups.RemoveFromGroupAsync(Context.ConnectionId, $"conversation-{conversationId}");
    }

    [Authorize]
    public async Task MarkAsRead(Guid conversationId)
    {
        var userId = Context.User?.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (string.IsNullOrEmpty(userId)) return;

        await _chatService.MarkMessagesAsReadAsync(conversationId, Guid.Parse(userId));
        
        // Notify other participants
        await Clients.OthersInGroup($"conversation-{conversationId}")
            .SendAsync("MessagesRead", conversationId, userId);
    }

    [Authorize]
    public async Task StartTyping(Guid conversationId)
    {
        var userId = Context.User?.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        var userName = Context.User?.FindFirst(ClaimTypes.Name)?.Value;
        
        await Clients.OthersInGroup($"conversation-{conversationId}")
            .SendAsync("UserTyping", userId, userName);
    }

    [Authorize]
    public async Task StopTyping(Guid conversationId)
    {
        var userId = Context.User?.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        
        await Clients.OthersInGroup($"conversation-{conversationId}")
            .SendAsync("UserStoppedTyping", userId);
    }

    // Agent starts typing in guest chat
    [Authorize]
    public async Task StartTypingGuest(string guestId)
    {
        await Clients.Group($"guest-{guestId}").SendAsync("AgentTyping");
    }

    [Authorize]
    public async Task StopTypingGuest(string guestId)
    {
        await Clients.Group($"guest-{guestId}").SendAsync("AgentStoppedTyping");
    }

    // Guest starts typing (AllowAnonymous because guests are not auth users)
    [AllowAnonymous]
    public async Task GuestStartTyping(string guestId)
    {
        // Notify care agents
        await Clients.Group("care-group").SendAsync("GuestTyping", guestId);
    }

    [AllowAnonymous]
    public async Task GuestStopTyping(string guestId)
    {
        // Notify care agents
        await Clients.Group("care-group").SendAsync("GuestStoppedTyping", guestId);
    }
    [Authorize]
    public async Task MarkGuestAsRead(string guestId)
    {
        _guestConversationService.MarkAsRead(guestId);
        
        // Notify guest that messages were read
        // Note: For guests, we don't track per-message read status usually, 
        // just "last read time" or "all read". 
        // We'll send a generic "MessagesRead" event to the guest.
        await Clients.Group($"guest-{guestId}").SendAsync("MessagesRead");
    }
}
