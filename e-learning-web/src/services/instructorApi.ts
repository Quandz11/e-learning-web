import { authApi } from './authApi';

const API_BASE_URL = import.meta.env.VITE_API_URL || 'https://localhost:7145/api';

export type InstructorStatus = 'ACTIVE' | 'INACTIVE' | 'SUSPENDED';

export interface InstructorDto {
    id: string;
    email: string;
    fullName?: string;
    phone?: string;
    status: InstructorStatus;
    avatarUrl?: string;
    isEmailVerified: boolean;
    isPhoneVerified: boolean;
    createdAt: string;
    totalCourses: number;
    totalStudents: number;
}

export interface InstructorDetailDto {
    id: string;
    email: string;
    fullName?: string;
    phone?: string;
    status: InstructorStatus;
    avatarUrl?: string;
    isEmailVerified: boolean;
    isPhoneVerified: boolean;
    isTwoFactorEnabled: boolean;
    createdAt: string;
    updatedAt: string;
    stats: InstructorStatsDto;
}

export interface InstructorStatsDto {
    totalCourses: number;
    publishedCourses: number;
    totalStudents: number;
    totalRevenue: number;
    averageRating: number;
    lastActive?: string;
}

export interface InstructorCourseDto {
    id: string;
    title: string;
    description?: string;
    price: number;
    isFree: boolean;
    isPublished: boolean;
    thumbnailUrl?: string;
    enrollmentCount: number;
    createdAt: string;
}

export interface PagedResult<T> {
    items: T[];
    total: number;
    page: number;
    pageSize: number;
}

export interface CreateInstructorRequest {
    email: string;
    password: string;
    fullName?: string;
    phone?: string;
    status: InstructorStatus;
    avatarUrl?: string;
}

export interface UpdateInstructorRequest {
    fullName?: string;
    phone?: string;
    status: InstructorStatus;
    avatarUrl?: string;
}

function authHeaders() {
    const token = authApi.getAccessToken();
    const headers: Record<string, string> = { 'Content-Type': 'application/json' };
    if (token) headers['Authorization'] = `Bearer ${token}`;
    return headers;
}

export const instructorApi = {
    async getPaged(params: { search?: string; status?: string; page?: number; pageSize?: number }): Promise<PagedResult<InstructorDto>> {
        const url = new URL(`${API_BASE_URL}/instructors`);
        if (params.search) url.searchParams.set('search', params.search);
        if (params.status) url.searchParams.set('status', params.status);
        url.searchParams.set('page', String(params.page ?? 1));
        url.searchParams.set('pageSize', String(params.pageSize ?? 20));

        const res = await fetch(url.toString(), {
            method: 'GET',
            headers: authHeaders(),
            credentials: 'include',
        });
        if (!res.ok) throw new Error('Failed to fetch instructors');
        return res.json();
    },

    async getById(id: string): Promise<InstructorDetailDto> {
        const res = await fetch(`${API_BASE_URL}/instructors/${id}`, {
            method: 'GET',
            headers: authHeaders(),
            credentials: 'include',
        });
        if (!res.ok) throw new Error('Failed to fetch instructor details');
        return res.json();
    },

    async getStats(id: string): Promise<InstructorStatsDto> {
        const res = await fetch(`${API_BASE_URL}/instructors/${id}/stats`, {
            method: 'GET',
            headers: authHeaders(),
            credentials: 'include',
        });
        if (!res.ok) throw new Error('Failed to fetch instructor stats');
        return res.json();
    },

    async getCourses(id: string): Promise<InstructorCourseDto[]> {
        const res = await fetch(`${API_BASE_URL}/instructors/${id}/courses`, {
            method: 'GET',
            headers: authHeaders(),
            credentials: 'include',
        });
        if (!res.ok) throw new Error('Failed to fetch instructor courses');
        return res.json();
    },

    async create(payload: CreateInstructorRequest): Promise<InstructorDto> {
        const res = await fetch(`${API_BASE_URL}/instructors`, {
            method: 'POST',
            headers: authHeaders(),
            credentials: 'include',
            body: JSON.stringify(payload),
        });
        if (!res.ok) {
            const msg = await res.text();
            throw new Error(msg || 'Create instructor failed');
        }
        return res.json();
    },

    async update(id: string, payload: UpdateInstructorRequest): Promise<InstructorDto> {
        const res = await fetch(`${API_BASE_URL}/instructors/${id}`, {
            method: 'PUT',
            headers: authHeaders(),
            credentials: 'include',
            body: JSON.stringify(payload),
        });
        if (!res.ok) {
            const msg = await res.text();
            throw new Error(msg || 'Update instructor failed');
        }
        return res.json();
    },

    async delete(id: string): Promise<void> {
        const res = await fetch(`${API_BASE_URL}/instructors/${id}`, {
            method: 'DELETE',
            headers: authHeaders(),
            credentials: 'include',
        });
        if (!res.ok) {
            const msg = await res.text();
            throw new Error(msg || 'Delete instructor failed');
        }
    },
};
