import { apiClient } from '../apiClient';

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
    getAllConversations: async (): Promise<AdminConversationsResponse> => {
        return apiClient('/admin/chat/conversations');
    },

    getGuestMessages: async (guestId: string): Promise<GuestMessage[]> => {
        return apiClient(`/admin/chat/guest/${guestId}/messages`);
    },

    getConversationMessages: async (conversationId: string): Promise<GuestMessage[]> => {
        return apiClient(`/admin/chat/conversations/${conversationId}/messages`);
    },

    closeGuestConversation: async (guestId: string): Promise<void> => {
        return apiClient(`/admin/chat/guest/${guestId}/close`, {
            method: 'POST',
        });
    },

    markConversationAsRead: async (conversationId: string): Promise<void> => {
        return apiClient(`/admin/chat/conversations/${conversationId}/read`, {
            method: 'POST',
        });
    },

    markGuestAsRead: async (guestId: string): Promise<void> => {
        return apiClient(`/admin/chat/guest/${guestId}/mark-read`, {
            method: 'POST',
        });
    },
};
