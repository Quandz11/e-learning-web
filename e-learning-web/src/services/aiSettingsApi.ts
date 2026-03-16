import { apiClient } from './apiClient';

export interface AiSettings {
    id: string;
    apiKey: string;
    modelName: string;
    systemPrompt: string;
    isEnabled: boolean;
    updatedAt?: string;
}

export const aiSettingsApi = {
    getSettings: async (): Promise<AiSettings> => {
        const response = await apiClient<AiSettings>('/admin/ai-settings', {
            method: 'GET'
        });
        return response; // Since apiClient wrapper returns data directly
    },

    updateSettings: async (settings: Partial<AiSettings>): Promise<AiSettings> => {
        const response = await apiClient<AiSettings>('/admin/ai-settings', {
            method: 'PUT',
            body: JSON.stringify(settings)
        });
        return response;
    }
};
