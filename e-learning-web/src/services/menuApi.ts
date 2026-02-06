import { apiClient } from './apiClient';

export interface MenuItem {
    id: string;
    title: string;
    url?: string;
    menuLocation: string;
    displayOrder: number;
    isActive: boolean;
    parentId?: string;
    children?: MenuItem[];
}

export interface CreateMenuItemDto {
    title: string;
    url?: string;
    menuLocation: string;
    displayOrder: number;
    isActive: boolean;
    parentId?: string;
}

export interface UpdateMenuItemDto {
    title: string;
    url?: string;
    menuLocation: string;
    displayOrder: number;
    isActive: boolean;
    parentId?: string;
}

export const menuApi = {
    // Public endpoints
    async getByLocation(location: string): Promise<MenuItem[]> {
        return apiClient(`/menu/${location}`);
    },

    // Admin endpoints
    async getAll(): Promise<MenuItem[]> {
        return apiClient('/menu/admin');
    },

    async getById(id: string): Promise<MenuItem> {
        return apiClient(`/menu/admin/${id}`);
    },

    async create(data: CreateMenuItemDto): Promise<MenuItem> {
        return apiClient('/menu', {
            method: 'POST',
            body: JSON.stringify(data),
        });
    },

    async update(id: string, data: UpdateMenuItemDto): Promise<MenuItem> {
        return apiClient(`/menu/${id}`, {
            method: 'PUT',
            body: JSON.stringify(data),
        });
    },

    async delete(id: string): Promise<void> {
        return apiClient(`/menu/${id}`, {
            method: 'DELETE',
        });
    },
};
