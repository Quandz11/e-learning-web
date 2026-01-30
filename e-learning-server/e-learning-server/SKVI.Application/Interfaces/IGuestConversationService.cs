using SKVI.Application.Models.Chat;

namespace SKVI.Application.Interfaces;

public interface IGuestConversationService
{
    // Add or update guest conversation
    void AddOrUpdateConversation(string guestId, GuestMessage message);
    
    // Get all active guest conversations
    List<GuestConversation> GetAllActiveConversations();
    
    // Get specific guest conversation
    GuestConversation? GetConversation(string guestId);
    
    // Get messages for a guest
    List<GuestMessage> GetMessages(string guestId);
    
    // Mark conversation as inactive
    void CloseConversation(string guestId);
    
    // Clean up old conversations
    void CleanupInactiveConversations(TimeSpan inactiveThreshold);
    
    // Mark messages as read
    void MarkAsRead(string guestId);
    
    // Update last activity
    void UpdateActivity(string guestId);
}
