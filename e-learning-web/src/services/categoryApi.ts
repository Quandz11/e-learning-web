import { apiClient } from './apiClient';

export interface CategoryDto {
    id: string;
    name: string;
    description?: string;
    order: number;
    isActive: boolean;
    createdAt: string;
}

export interface CreateCategoryRequest {
    name: string;
    description?: string;
    order: number;
    isActive: boolean;
}

export interface UpdateCategoryRequest {
    name: string;
    description?: string;
    order: number;
    isActive: boolean;
}

export const categoryApi = {
    async getAll(): Promise<CategoryDto[]> {
        return apiClient('/categories');
    },

    async getActive(): Promise<CategoryDto[]> {
        return apiClient('/categories/active');
    },

    async getById(id: string): Promise<CategoryDto> {
        return apiClient(`/categories/${id}`);
    },

    async create(payload: CreateCategoryRequest): Promise<CategoryDto> {
        return apiClient('/categories', {
            method: 'POST',
            body: JSON.stringify(payload),
        });
    },

    async update(id: string, payload: UpdateCategoryRequest): Promise<CategoryDto> {
        return apiClient(`/categories/${id}`, {
            method: 'PUT',
            body: JSON.stringify(payload),
        });
    },

    async delete(id: string): Promise<void> {
        return apiClient(`/categories/${id}`, {
            method: 'DELETE',
        });
    },
};
