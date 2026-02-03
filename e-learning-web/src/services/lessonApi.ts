import { authApi } from './authApi';

const API_BASE_URL = import.meta.env.VITE_API_URL || 'https://localhost:7145/api';

function authHeaders() {
    const token = authApi.getAccessToken();
    const headers: Record<string, string> = {};
    if (token) {
        headers['Authorization'] = `Bearer ${token}`;
    }
    return headers;
}

export interface LessonPartDto {
    id: string;
    title: string;
    type: string; // "Video", "Document"
    orderIndex: number;
    isPreview: boolean;
    videoDuration: number;
    videoId?: string;
    playbackUrl?: string;
    documentId?: string;
    documentUrl?: string; // Full CDN URL
    documentFileName?: string;
    content?: string;
}

export interface LessonDto {
    id: string;
    title: string;
    description?: string;
    thumbnailUrl?: string;
    createdAt: string;
    updatedAt?: string;
    parts: LessonPartDto[];
}

export interface CreateLessonRequest {
    title: string;
    description?: string;
    thumbnailUrl?: string;
}

export interface UpdateLessonRequest {
    title: string;
    description?: string;
    thumbnailUrl?: string;
}

export interface CreateLessonPartRequest {
    title: string;
    type: string;
    orderIndex: number;
    isPreview: boolean;
    videoId?: string;
    documentId?: string;
    content?: string;
}

export interface UpdateLessonPartRequest extends CreateLessonPartRequest { }

export const lessonApi = {
    async getAll(): Promise<LessonDto[]> {
        const res = await fetch(`${API_BASE_URL}/lessons`, {
            method: 'GET',
            headers: { 'Content-Type': 'application/json', ...authHeaders() },
        });
        if (!res.ok) throw new Error('Failed to fetch lessons');
        return res.json();
    },

    async getById(id: string): Promise<LessonDto> {
        const res = await fetch(`${API_BASE_URL}/lessons/${id}`, {
            method: 'GET',
            headers: { 'Content-Type': 'application/json', ...authHeaders() },
        });
        if (!res.ok) throw new Error('Failed to fetch lesson');
        return res.json();
    },

    async create(payload: CreateLessonRequest): Promise<LessonDto> {
        const res = await fetch(`${API_BASE_URL}/lessons`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json', ...authHeaders() },
            body: JSON.stringify(payload),
        });
        if (!res.ok) throw new Error('Failed to create lesson');
        return res.json();
    },

    async update(id: string, payload: UpdateLessonRequest): Promise<LessonDto> {
        const res = await fetch(`${API_BASE_URL}/lessons/${id}`, {
            method: 'PUT',
            headers: { 'Content-Type': 'application/json', ...authHeaders() },
            body: JSON.stringify(payload),
        });
        if (!res.ok) throw new Error('Failed to update lesson');
        return res.json();
    },

    async delete(id: string): Promise<void> {
        const res = await fetch(`${API_BASE_URL}/lessons/${id}`, {
            method: 'DELETE',
            headers: { ...authHeaders() },
        });
        if (!res.ok) throw new Error('Failed to delete lesson');
    },

    async addPart(lessonId: string, payload: CreateLessonPartRequest): Promise<LessonDto> {
        const res = await fetch(`${API_BASE_URL}/lessons/${lessonId}/parts`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json', ...authHeaders() },
            body: JSON.stringify(payload),
        });
        if (!res.ok) throw new Error('Failed to add lesson part');
        return res.json();
    },

    async updatePart(lessonId: string, partId: string, payload: UpdateLessonPartRequest): Promise<LessonDto> {
        const res = await fetch(`${API_BASE_URL}/lessons/${lessonId}/parts/${partId}`, {
            method: 'PUT',
            headers: { 'Content-Type': 'application/json', ...authHeaders() },
            body: JSON.stringify(payload),
        });
        if (!res.ok) throw new Error('Failed to update lesson part');
        return res.json();
    },

    async deletePart(lessonId: string, partId: string): Promise<LessonDto> {
        const res = await fetch(`${API_BASE_URL}/lessons/${lessonId}/parts/${partId}`, {
            method: 'DELETE',
            headers: { ...authHeaders() },
        });
        if (!res.ok) throw new Error('Failed to delete lesson part');
        return res.json();
    }
};
