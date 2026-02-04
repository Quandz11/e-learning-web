import { apiClient } from './apiClient';

export interface NotificationDto {
    id: string;
    title: string;
    content: string;
    isRead: boolean;
    createdAt: string;
}

export interface SendNotificationRequest {
    title: string;
    content: string;
    targetType: 'USER' | 'ROLE' | 'ALL';
    targetUserId?: string;
    targetRole?: string;
}

const notificationApi = {
    // Admin: Send notification
    send: async (data: SendNotificationRequest) => {
        const response = await apiClient('/notifications/send', {
            method: 'POST',
            body: JSON.stringify(data)
        });
        return response;
    },

    // User: Get my notifications
    getMyNotifications: async () => {
        const response = await apiClient<{ notifications: NotificationDto[], unreadCount: number }>('/notifications', {
            method: 'GET'
        });
        return response;
    },

    // User: Mark as read
    markAsRead: async (id: string) => {
        await apiClient(`/notifications/${id}/read`, {
            method: 'PUT'
        });
    },

    // User: Mark all as read
    markAllAsRead: async () => {
        await apiClient('/notifications/read-all', {
            method: 'PUT'
        });
    }
};

export default notificationApi;
