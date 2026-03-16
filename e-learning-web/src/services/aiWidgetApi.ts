import { apiClient } from './apiClient';

export interface UserStudyPlan {
    id: string;
    goal: string;
    currentKnowledgeLevel: string;
    status: string;
}

export interface DailyStudyTask {
    id: string;
    taskDate: string;
    content: string;
    isCompleted: boolean;
    userFeedback: string;
    aiAdvice: string;
}

export interface AiChatMessage {
    id: string;
    role: string;
    content: string;
    createdAt: string;
}

export const aiWidgetApi = {
    getStatus: async (): Promise<{ isEnabled: boolean }> => {
        return await apiClient<{ isEnabled: boolean }>('/ai/settings/status', { method: 'GET' });
    },
    
    initPlan: async (goal: string, currentKnowledge: string): Promise<UserStudyPlan> => {
        return await apiClient<UserStudyPlan>('/ai/plan/init', {
            method: 'POST',
            body: JSON.stringify({ goal, currentKnowledge })
        });
    },

    getActivePlan: async (): Promise<UserStudyPlan> => {
        return await apiClient<UserStudyPlan>('/ai/plan/active', { method: 'GET' });
    },

    getTodayTasks: async (planId: string): Promise<DailyStudyTask[]> => {
        return await apiClient<DailyStudyTask[]>(`/ai/plan/${planId}/today-tasks`, { method: 'GET' });
    },

    submitTask: async (taskId: string, feedback: string): Promise<DailyStudyTask> => {
        return await apiClient<DailyStudyTask>(`/ai/tasks/${taskId}/submit`, {
            method: 'POST',
            body: JSON.stringify({ feedback })
        });
    },

    chat: async (prompt: string): Promise<{ response: string }> => {
        return await apiClient<{ response: string }>('/ai/chat', {
            method: 'POST',
            body: JSON.stringify({ prompt })
        });
    },

    getChatHistory: async (): Promise<AiChatMessage[]> => {
        return await apiClient<AiChatMessage[]>('/ai/chat/history', { method: 'GET' });
    }
};
