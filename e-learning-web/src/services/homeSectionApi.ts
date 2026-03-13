import { apiClient } from './apiClient';

export interface HomeVideoSectionDto {
    id: string;
    contentHtml: string;
    videoType: 'bunny' | 'youtube';
    videoId?: string | null;
    bunnyVideoId?: string | null;
    videoUrl?: string | null;
    updatedAt: string;
}

export interface UpdateHomeVideoSectionDto {
    contentHtml: string;
    videoType: 'bunny' | 'youtube';
    videoId?: string | null;
    videoUrl?: string | null;
}

export const homeSectionApi = {
    getHomeSection: async (): Promise<HomeVideoSectionDto> => {
        return apiClient<HomeVideoSectionDto>('/HomeSection');
    },

    updateHomeSection: async (data: UpdateHomeVideoSectionDto): Promise<HomeVideoSectionDto> => {
        return apiClient<HomeVideoSectionDto>('/HomeSection', {
            method: 'PUT',
            body: JSON.stringify(data),
        });
    }
};
