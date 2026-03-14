import { apiClient } from './apiClient';


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
    categoryId?: string;
    categoryName?: string;
    createdAt: string;
    updatedAt?: string;
    parts: LessonPartDto[];
}

export interface CreateLessonRequest {
    title: string;
    description?: string;
    thumbnailUrl?: string;
    categoryId?: string;
}

export interface UpdateLessonRequest {
    title: string;
    description?: string;
    thumbnailUrl?: string;
    categoryId?: string;
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
        return apiClient('/lessons');
    },

    async getById(id: string): Promise<LessonDto> {
        return apiClient(`/lessons/${id}`);
    },

    async create(payload: CreateLessonRequest): Promise<LessonDto> {
        return apiClient('/lessons', {
            method: 'POST',
            body: JSON.stringify(payload),
        });
    },

    async update(id: string, payload: UpdateLessonRequest): Promise<LessonDto> {
        return apiClient(`/lessons/${id}`, {
            method: 'PUT',
            body: JSON.stringify(payload),
        });
    },

    async delete(id: string): Promise<void> {
        return apiClient(`/lessons/${id}`, {
            method: 'DELETE',
        });
    },

    async addPart(lessonId: string, payload: CreateLessonPartRequest): Promise<LessonDto> {
        return apiClient(`/lessons/${lessonId}/parts`, {
            method: 'POST',
            body: JSON.stringify(payload),
        });
    },

    async updatePart(lessonId: string, partId: string, payload: UpdateLessonPartRequest): Promise<LessonDto> {
        return apiClient(`/lessons/${lessonId}/parts/${partId}`, {
            method: 'PUT',
            body: JSON.stringify(payload),
        });
    },

    async deletePart(lessonId: string, partId: string): Promise<LessonDto> {
        return apiClient(`/lessons/${lessonId}/parts/${partId}`, {
            method: 'DELETE',
        });
    }
};
