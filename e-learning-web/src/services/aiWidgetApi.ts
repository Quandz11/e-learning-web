import { apiClient } from './apiClient';

export interface UserStudyPlan {
    id: string;
    goal: string;
    currentKnowledgeLevel: string;
    motivation: string;
    timeBudgetMinutesPerDay: number;
    preferredStudyTime: string;
    constraints: string;
    primaryCourseId?: string | null;
    primaryCourseTitle: string;
    currentStreakDays: number;
    lastCheckInDate?: string | null;
    latestGuidanceMessage: string;
    status: string;
    planVersion: number;
    createdAt: string;
}

export interface DailyStudyTask {
    id: string;
    taskDate: string;
    title: string;
    content: string;
    taskType: string;
    estimatedMinutes: number;
    sortOrder: number;
    status: string;
    relatedCourseId?: string | null;
    relatedCourseTitle: string;
    relatedLessonPartId?: string | null;
    relatedLessonTitle: string;
    reflectionPrompt: string;
    isCompleted: boolean;
    userFeedback: string;
    aiAdvice: string;
    actualMinutesSpent?: number | null;
    difficultyRating?: number | null;
    confidenceRating?: number | null;
    needsSupport: boolean;
    completedAt?: string | null;
}

export interface DailyStudyCheckIn {
    id: string;
    checkInDate: string;
    moodScore: number;
    energyScore: number;
    confidenceScore: number;
    actualMinutesSpentToday?: number | null;
    minutesAvailableTomorrow: number;
    notes: string;
    needsSupport: boolean;
    coachAdvice: string;
}

export interface StudyPlanDashboard {
    plan: UserStudyPlan | null;
    todayTasks: DailyStudyTask[];
    latestCheckIn: DailyStudyCheckIn | null;
    openSupportAlerts: number;
    guidanceMessage: string;
}

export interface AiChatMessage {
    id: string;
    role: string;
    content: string;
    createdAt: string;
}

export interface InitializeStudyPlanPayload {
    goal: string;
    currentKnowledge: string;
    motivation: string;
    timeBudgetMinutesPerDay: number;
    preferredStudyTime: string;
    constraints: string;
    primaryCourseId?: string;
}

export interface SubmitStudyTaskPayload {
    isCompleted: boolean;
    feedback: string;
    actualMinutesSpent?: number;
    difficultyRating?: number;
    confidenceRating?: number;
    needsSupport: boolean;
}

export interface DailyStudyCheckInPayload {
    moodScore: number;
    energyScore: number;
    confidenceScore: number;
    actualMinutesSpentToday?: number;
    minutesAvailableTomorrow: number;
    notes: string;
    needsSupport: boolean;
}

export interface AiRoadmapAccessState {
    isUnlocked: boolean;
    currentPackage?: string;
    allowedPackages: string[];
    requiredPackages: string[];
    ctaPath: string;
    reasonCode: string;
    message: string;
}

export interface AiCoachStatus {
    isEnabled: boolean;
    access?: AiRoadmapAccessState;
}

export const aiWidgetApi = {
    getStatus: async (): Promise<AiCoachStatus> => {
        return await apiClient<AiCoachStatus>('/ai/settings/status', { method: 'GET' });
    },

    getDashboard: async (): Promise<StudyPlanDashboard> => {
        const plan = await aiWidgetApi.getActivePlan();
        if (!plan) {
            return {
                plan: null,
                todayTasks: [],
                latestCheckIn: null,
                openSupportAlerts: 0,
                guidanceMessage: ''
            };
        }

        const todayTasks = await aiWidgetApi.getTodayTasks(plan.id);
        return {
            plan,
            todayTasks,
            latestCheckIn: null,
            openSupportAlerts: 0,
            guidanceMessage: plan.latestGuidanceMessage || ''
        };
    },

    initPlan: async (payload: InitializeStudyPlanPayload): Promise<UserStudyPlan> => {
        return await apiClient<UserStudyPlan>('/ai/plan/init', {
            method: 'POST',
            body: JSON.stringify(payload)
        });
    },

    getActivePlan: async (): Promise<UserStudyPlan | null> => {
        return await apiClient<UserStudyPlan | null>('/ai/plan/active', { method: 'GET' });
    },

    getTodayTasks: async (planId: string): Promise<DailyStudyTask[]> => {
        return await apiClient<DailyStudyTask[]>(`/ai/plan/${planId}/today-tasks`, { method: 'GET' });
    },

    submitTask: async (taskId: string, payload: SubmitStudyTaskPayload): Promise<DailyStudyTask> => {
        return await apiClient<DailyStudyTask>(`/ai/tasks/${taskId}/submit`, {
            method: 'POST',
            body: JSON.stringify(payload)
        });
    },

    submitCheckIn: async (payload: DailyStudyCheckInPayload): Promise<DailyStudyCheckIn> => {
        return await apiClient<DailyStudyCheckIn>('/ai/check-in', {
            method: 'POST',
            body: JSON.stringify(payload)
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
