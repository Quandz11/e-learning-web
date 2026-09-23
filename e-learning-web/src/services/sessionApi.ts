import { apiClient } from './apiClient';

export interface ActiveSession {
    platform: string;
    lastActiveAt: string;
    sessionId: string;
    deviceName: string;
    browser: string;
    ipAddress: string;
    loginTime: string;
    expiresAt: string;
    isCurrentSession: boolean;
}

export const sessionApi = {
    getUserSessions: (userId: string): Promise<ActiveSession[]> => apiClient(`/admin/users/${encodeURIComponent(userId)}/sessions`),
    revokeUserSessions: async (userId: string, sessionId?: string): Promise<void> => {
        await apiClient(`/admin/users/${encodeURIComponent(userId)}/sessions/${sessionId ? 'revoke' : 'revoke-all'}`, {
            method: 'POST', ...(sessionId ? { body: JSON.stringify({ sessionId }) } : {}),
        });
    },
    /**
     * Get all active sessions for the current user
     */
    getActiveSessions: async (): Promise<ActiveSession[]> => {
        return await apiClient<ActiveSession[]>('/auth/sessions');
    },

    /**
     * Revoke a specific session by ID
     */
    revokeSession: async (sessionId: string): Promise<void> => {
        await apiClient('/auth/sessions/revoke', {
            method: 'POST',
            body: JSON.stringify({ sessionId }),
        });
    },

    /**
     * Revoke all sessions except the current one
     */
    revokeAllSessions: async (): Promise<void> => {
        await apiClient('/auth/sessions/revoke-all', {
            method: 'POST',
        });
    },
};
