import { apiClient } from './apiClient';

export interface AdminEnrollmentResponse {
    id: string;
    courseId: string;
    courseTitle: string;
    courseThumbnail?: string;
    userId: string;
    userEmail: string;
    userFullName?: string;
    enrolledAt: string;
    progressPercentage: number;
    completedAt: string | null;
    lastAccessedAt: string;
    accessDurationDays?: number | null;
    accessExpiresAt?: string | null;
    status: 'ACTIVE' | 'INACTIVE';
}

export const adminEnrollmentApi = {
    /**
     * [ADMIN] List all enrollments (any status) for a user
     */
    getUserEnrollments(userId: string): Promise<AdminEnrollmentResponse[]> {
        return apiClient(`/admin/users/${userId}/enrollments`);
    },

    /**
     * [ADMIN] Manually add enrollment for a user
     */
    addEnrollment(userId: string, courseId: string, accessDurationDays?: number | null): Promise<AdminEnrollmentResponse> {
        return apiClient(`/admin/users/${userId}/enrollments`, {
            method: 'POST',
            body: JSON.stringify({ courseId, accessDurationDays }),
        });
    },

    /**
     * [ADMIN] Remove enrollment (by courseId)
     */
    removeEnrollment(userId: string, courseId: string): Promise<void> {
        return apiClient(`/admin/users/${userId}/enrollments/${courseId}`, {
            method: 'DELETE',
        });
    },

    /**
     * [ADMIN] Set enrollment status: ACTIVE | INACTIVE
     */
    setEnrollmentStatus(
        userId: string,
        enrollmentId: string,
        status: 'ACTIVE' | 'INACTIVE'
    ): Promise<AdminEnrollmentResponse> {
        return apiClient(`/admin/users/${userId}/enrollments/${enrollmentId}/status`, {
            method: 'PATCH',
            body: JSON.stringify({ status }),
        });
    },
};
