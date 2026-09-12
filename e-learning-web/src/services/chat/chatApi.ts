import { apiClient } from '../apiClient';

export interface ConversationResponse {
    id: string;
    title?: string;
    createdAt: string;
    lastMessageAt: string;
    participants: ParticipantResponse[];
    otherParticipant?: ParticipantResponse;
    lastMessage?: MessageResponse;
    unreadCount: number;
}

export interface ParticipantResponse {
    userId: string;
    userName: string;
    role?: string;
    avatarUrl?: string;
    lastReadAt?: string;
}

export interface MessageResponse {
    id: string;
    conversationId: string;
    senderId: string;
    senderName: string;
    content: string;
    sentAt: string;
    isRead: boolean;
}

export interface SupportUserResponse {
    id: string;
    fullName: string;
    role: string;
    avatarUrl?: string;
}

export interface CreateConversationDto {
    recipientId: string;
}

export interface SendMessageDto {
    conversationId: string;
    content: string;
}

export const chatApi = {
    getConversations: async (): Promise<ConversationResponse[]> => {
        return apiClient('/chat/conversations');
    },

    getConversation: async (id: string): Promise<ConversationResponse> => {
        return apiClient(`/chat/conversations/${id}`);
    },

    createConversation: async (dto: CreateConversationDto): Promise<ConversationResponse> => {
        return apiClient('/chat/conversations', {
            method: 'POST',
            body: JSON.stringify(dto),
        });
    },

    getMessages: async (conversationId: string): Promise<MessageResponse[]> => {
        return apiClient(`/chat/conversations/${conversationId}/messages`);
    },

    sendMessage: async (dto: SendMessageDto): Promise<MessageResponse> => {
        return apiClient('/chat/messages', {
            method: 'POST',
            body: JSON.stringify(dto),
        });
    },

    markAsRead: async (conversationId: string): Promise<void> => {
        return apiClient(`/chat/conversations/${conversationId}/read`, {
            method: 'PUT',
        });
    },

    getUnreadCount: async (): Promise<number> => {
        return apiClient('/chat/unread-count');
    },

    getSupportUser: async (): Promise<SupportUserResponse> => {
        return apiClient('/chat/support-user');
    },
};
