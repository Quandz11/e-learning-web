import { apiClient } from './apiClient';

export interface TestimonialDto {
    id: string;
    name: string;
    position?: string;
    content: string;
    avatarUrl?: string;
    order: number;
    isActive: boolean;
    createdAt: string;
}

export interface CreateTestimonialRequest {
    name: string;
    position?: string;
    content: string;
    avatarUrl?: string;
    order: number;
    isActive: boolean;
}

export interface UpdateTestimonialRequest {
    name: string;
    position?: string;
    content: string;
    avatarUrl?: string;
    order: number;
    isActive: boolean;
}

export const testimonialApi = {
    async getActive(): Promise<TestimonialDto[]> {
        return apiClient('/testimonials/active');
    },

    async getAll(): Promise<TestimonialDto[]> {
        return apiClient('/testimonials');
    },

    async getById(id: string): Promise<TestimonialDto> {
        return apiClient(`/testimonials/${id}`);
    },

    async create(data: CreateTestimonialRequest): Promise<TestimonialDto> {
        return apiClient('/testimonials', {
            method: 'POST',
            body: JSON.stringify(data),
        });
    },

    async update(id: string, data: UpdateTestimonialRequest): Promise<TestimonialDto> {
        return apiClient(`/testimonials/${id}`, {
            method: 'PUT',
            body: JSON.stringify(data),
        });
    },

    async delete(id: string): Promise<void> {
        return apiClient(`/testimonials/${id}`, {
            method: 'DELETE',
        });
    },
};
