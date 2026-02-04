import { apiClient } from './apiClient';

export interface ActiveSession {
    sessionId: string;
    deviceName: string;
    browser: string;
    ipAddress: string;
    loginTime: string;
    expiresAt: string;
    isCurrentSession: boolean;
}

export const sessionApi = {
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
