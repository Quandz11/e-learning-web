const API_BASE_URL = import.meta.env.VITE_API_URL || 'https://localhost:7145/api';

export interface AdminConversation {
    id: string;
    type: 'authenticated' | 'guest';
    guestId?: string;
    userId?: string;
    userName: string;
    lastMessage?: string;
    lastActivity: string;
    unreadCount: number;
    isActive: boolean;
}

export interface GuestMessage {
    id: string;
    senderId: string;
    senderName: string;
    content: string;
    sentAt: string;
    isFromGuest: boolean;
}

export interface AdminConversationsResponse {
    authenticatedConversations: AdminConversation[];
    guestConversations: AdminConversation[];
}

export const adminChatApi = {
    getAllConversations: async (token: string): Promise<AdminConversationsResponse> => {
        const response = await fetch(`${API_BASE_URL}/admin/chat/conversations`, {
            headers: {
                'Authorization': `Bearer ${token}`,
                'Content-Type': 'application/json'
            }
        });

        if (!response.ok) {
            throw new Error('Failed to fetch conversations');
        }

        return response.json();
    },

    getGuestMessages: async (guestId: string, token: string): Promise<GuestMessage[]> => {
        const response = await fetch(`${API_BASE_URL}/admin/chat/guest/${guestId}/messages`, {
            headers: {
                'Authorization': `Bearer ${token}`,
                'Content-Type': 'application/json'
            }
        });

        if (!response.ok) {
            throw new Error('Failed to fetch guest messages');
        }

        return response.json();
    },

    getConversationMessages: async (conversationId: string, token: string): Promise<GuestMessage[]> => {
        const response = await fetch(`${API_BASE_URL}/admin/chat/conversations/${conversationId}/messages`, {
            headers: {
                'Authorization': `Bearer ${token}`,
                'Content-Type': 'application/json'
            }
        });

        if (!response.ok) {
            throw new Error('Failed to fetch conversation messages');
        }

        return response.json();
    },

    closeGuestConversation: async (guestId: string, token: string): Promise<void> => {
        const response = await fetch(`${API_BASE_URL}/admin/chat/guest/${guestId}/close`, {
            method: 'POST',
            headers: {
                'Authorization': `Bearer ${token}`
            }
        });

        if (!response.ok) {
            throw new Error('Failed to close conversation');
        }
    },

    markConversationAsRead: async (conversationId: string, token: string): Promise<void> => {
        const response = await fetch(`${API_BASE_URL}/admin/chat/conversations/${conversationId}/read`, {
            method: 'POST', // Assuming endpoint exists or needs creation? 
            // Wait, ChatHub.MarkAsRead is SignalR. Controller might not have MarkAsRead for Auth?
            // ChatService has MarkMessagesAsReadAsync. AdminChatController has MarkGuestAsRead.
            // We need MarkConversationAsRead in AdminChatController for Auth users?
            // Or we just rely on SignalR?
            // Implementation plan said "AdminChatPage: Call markAsRead".
            // AdminChatController usually mirrors SignalR for REST clients.
            // Let's add it to Controller to be safe/consistent.
            headers: {
                'Authorization': `Bearer ${token}`
            }
        });
        // If endpoint doesn't exist, we might get 404. 
        // Let's check AdminChatController.
    },

    markGuestAsRead: async (guestId: string, token: string): Promise<void> => {
        const response = await fetch(`${API_BASE_URL}/admin/chat/guest/${guestId}/mark-read`, {
            method: 'POST',
            headers: {
                'Authorization': `Bearer ${token}`,
                'Content-Type': 'application/json'
            }
        });

        if (!response.ok) {
            throw new Error('Failed to mark conversation as read');
        }
    },
};
