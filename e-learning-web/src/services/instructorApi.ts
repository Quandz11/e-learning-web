import { apiClient } from './apiClient';




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



export const instructorApi = {
    async getPaged(params: { search?: string; status?: string; page?: number; pageSize?: number }): Promise<PagedResult<InstructorDto>> {
        const searchParams = new URLSearchParams();
        if (params.search) searchParams.set('search', params.search);
        if (params.status) searchParams.set('status', params.status);
        searchParams.set('page', String(params.page ?? 1));
        searchParams.set('pageSize', String(params.pageSize ?? 20));

        return apiClient(`/instructors?${searchParams.toString()}`);
    },

    async getById(id: string): Promise<InstructorDetailDto> {
        return apiClient(`/instructors/${id}`);
    },

    async getStats(id: string): Promise<InstructorStatsDto> {
        return apiClient(`/instructors/${id}/stats`);
    },

    async getCourses(id: string): Promise<InstructorCourseDto[]> {
        return apiClient(`/instructors/${id}/courses`);
    },

    async create(payload: CreateInstructorRequest): Promise<InstructorDto> {
        return apiClient('/instructors', {
            method: 'POST',
            body: JSON.stringify(payload),
        });
    },

    async update(id: string, payload: UpdateInstructorRequest): Promise<InstructorDto> {
        return apiClient(`/instructors/${id}`, {
            method: 'PUT',
            body: JSON.stringify(payload),
        });
    },

    async delete(id: string): Promise<void> {
        return apiClient(`/instructors/${id}`, {
            method: 'DELETE',
        });
    },
};
