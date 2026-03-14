import { apiClient } from './apiClient';

export interface WhyChooseUsItemDto {
    id: string;
    icon: string;
    title: string;
    description: string;
    order: number;
    isActive: boolean;
    createdAt: string;
}

export interface CreateWhyChooseUsItemRequest {
    icon: string;
    title: string;
    description: string;
    order: number;
    isActive: boolean;
}

export interface UpdateWhyChooseUsItemRequest {
    icon: string;
    title: string;
    description: string;
    order: number;
    isActive: boolean;
}

export const whyChooseUsApi = {
    async getActive(): Promise<WhyChooseUsItemDto[]> {
        return apiClient('/why-choose-us/active');
    },

    async getAll(): Promise<WhyChooseUsItemDto[]> {
        return apiClient('/why-choose-us');
    },

    async getById(id: string): Promise<WhyChooseUsItemDto> {
        return apiClient(`/why-choose-us/${id}`);
    },

    async create(data: CreateWhyChooseUsItemRequest): Promise<WhyChooseUsItemDto> {
        return apiClient('/why-choose-us', {
            method: 'POST',
            body: JSON.stringify(data),
        });
    },

    async update(id: string, data: UpdateWhyChooseUsItemRequest): Promise<WhyChooseUsItemDto> {
        return apiClient(`/why-choose-us/${id}`, {
            method: 'PUT',
            body: JSON.stringify(data),
        });
    },

    async delete(id: string): Promise<void> {
        return apiClient(`/why-choose-us/${id}`, {
            method: 'DELETE',
        });
    },
};
