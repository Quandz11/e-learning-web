import { authApi } from '../authApi';

const API_BASE_URL = import.meta.env.VITE_API_URL || 'https://localhost:7145/api';

export interface ConversationResponse {
    id: string;
    title?: string;
    createdAt: string;
    lastMessageAt: string;
    participants: ParticipantResponse[];
    lastMessage?: MessageResponse;
    unreadCount: number;
}

export interface ParticipantResponse {
    userId: string;
    userName: string;
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

const getAuthHeaders = () => {
    const token = authApi.getAccessToken();

    if (!token) {
        throw new Error('Missing access token for authenticated chat request');
    }

    return {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${token}`,
    };
};

export const chatApi = {
    getConversations: async (): Promise<ConversationResponse[]> => {
        const response = await fetch(`${API_BASE_URL}/chat/conversations`, {
            headers: getAuthHeaders(),
        });

        if (!response.ok) {
            throw new Error('Failed to fetch conversations');
        }

        return response.json();
    },

    getConversation: async (id: string): Promise<ConversationResponse> => {
        const response = await fetch(`${API_BASE_URL}/chat/conversations/${id}`, {
            headers: getAuthHeaders(),
        });

        if (!response.ok) {
            throw new Error('Failed to fetch conversation');
        }

        return response.json();
    },

    createConversation: async (dto: CreateConversationDto): Promise<ConversationResponse> => {
        const response = await fetch(`${API_BASE_URL}/chat/conversations`, {
            method: 'POST',
            headers: getAuthHeaders(),
            body: JSON.stringify(dto),
        });

        if (!response.ok) {
            throw new Error('Failed to create conversation');
        }

        return response.json();
    },

    getMessages: async (conversationId: string): Promise<MessageResponse[]> => {
        const response = await fetch(
            `${API_BASE_URL}/chat/conversations/${conversationId}/messages`,
            {
                headers: getAuthHeaders(),
            }
        );

        if (!response.ok) {
            throw new Error('Failed to fetch messages');
        }

        return response.json();
    },

    sendMessage: async (dto: SendMessageDto): Promise<MessageResponse> => {
        const response = await fetch(`${API_BASE_URL}/chat/messages`, {
            method: 'POST',
            headers: getAuthHeaders(),
            body: JSON.stringify(dto),
        });

        if (!response.ok) {
            throw new Error('Failed to send message');
        }

        return response.json();
    },

    markAsRead: async (conversationId: string): Promise<void> => {
        const response = await fetch(
            `${API_BASE_URL}/chat/conversations/${conversationId}/read`,
            {
                method: 'PUT',
                headers: getAuthHeaders(),
            }
        );

        if (!response.ok) {
            throw new Error('Failed to mark as read');
        }
    },

    getUnreadCount: async (): Promise<number> => {
        const response = await fetch(`${API_BASE_URL}/chat/unread-count`, {
            headers: getAuthHeaders(),
        });

        if (!response.ok) {
            throw new Error('Failed to fetch unread count');
        }

        return response.json();
    },

    getSupportUser: async (): Promise<SupportUserResponse> => {
        const response = await fetch(`${API_BASE_URL}/chat/support-user`, {
            headers: getAuthHeaders(),
        });

        if (response.status === 404) {
            throw new Error('No support user available');
        }

        if (!response.ok) {
            throw new Error('Failed to fetch support user');
        }

        return response.json();
    },
};
