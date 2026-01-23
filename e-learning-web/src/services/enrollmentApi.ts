import { authApi } from './authApi';

const API_URL = import.meta.env.VITE_API_URL || 'https://localhost:7145/api';

const getAuthHeaders = () => {
    const token = authApi.getAccessToken();
    return {
        'Content-Type': 'application/json',
        ...(token ? { 'Authorization': `Bearer ${token}` } : {})
    };
};

export interface EnrollmentResponse {
    id: string;
    courseId: string;
    courseTitle: string;
    enrolledAt: string;
    progressPercentage: number;
    completedAt: string | null;
    lastAccessedAt: string;
}

export interface CourseProgressResponse {
    enrollmentId: string;
    progressPercentage: number;
    completedLessons: number;
    totalLessons: number;
    completedAt: string | null;
    lessonProgress: LessonProgressDto[];
}

export interface LessonProgressDto {
    lessonId: string;
    lessonTitle: string;
    isCompleted: boolean;
    watchedDuration: number;
    completedAt: string | null;
    lastWatchedAt: string;
}

class EnrollmentApi {
    async enrollInCourse(courseId: string): Promise<EnrollmentResponse> {
        const response = await fetch(`${API_URL}/enrollments`, {
            method: 'POST',
            headers: getAuthHeaders(),
            credentials: 'include',
            body: JSON.stringify({ courseId })
        });

        if (!response.ok) {
            let errorMessage = 'Failed to enroll in course';
            try {
                const error = await response.json();
                errorMessage = error.message || errorMessage;
            } catch {
                // If can't parse JSON, use status text or default message
                errorMessage = response.statusText || errorMessage;
            }
            throw new Error(errorMessage);
        }

        return response.json();
    }

    async checkEnrollment(courseId: string): Promise<boolean> {
        const response = await fetch(`${API_URL}/enrollments/check/${courseId}`, {
            method: 'GET',
            headers: getAuthHeaders(),
            credentials: 'include'
        });

        if (!response.ok) {
            return false;
        }

        const data = await response.json();
        return data.isEnrolled;
    }

    async getUserEnrollments(): Promise<EnrollmentResponse[]> {
        const response = await fetch(`${API_URL}/enrollments`, {
            method: 'GET',
            headers: getAuthHeaders(),
            credentials: 'include'
        });

        if (!response.ok) {
            throw new Error('Failed to fetch enrollments');
        }

        return response.json();
    }

    async getCourseProgress(courseId: string): Promise<CourseProgressResponse> {
        const response = await fetch(`${API_URL}/enrollments/${courseId}/progress`, {
            method: 'GET',
            headers: getAuthHeaders(),
            credentials: 'include'
        });

        if (!response.ok) {
            throw new Error('Failed to fetch course progress');
        }

        return response.json();
    }

    async updateLessonProgress(courseId: string, lessonId: string, watchedDuration: number): Promise<void> {
        const response = await fetch(`${API_URL}/enrollments/${courseId}/lessons/${lessonId}/progress`, {
            method: 'POST',
            headers: getAuthHeaders(),
            credentials: 'include',
            body: JSON.stringify({ watchedDuration })
        });

        if (!response.ok) {
            // Silently fail for progress updates or log console
            console.error('Failed to update progress', response.status);
            // Don't throw to avoid interrupting video? Or throw?
            // Throwing allows caller to know.
            let errorMessage = 'Failed to update lesson progress';
            try {
                const error = await response.json();
                errorMessage = error.message || errorMessage;
            } catch {
                errorMessage = response.statusText || errorMessage;
            }
            throw new Error(errorMessage);
        }
    }

    async markLessonComplete(courseId: string, lessonId: string): Promise<void> {
        const response = await fetch(`${API_URL}/enrollments/${courseId}/lessons/${lessonId}/complete`, {
            method: 'POST',
            headers: getAuthHeaders(),
            credentials: 'include'
        });

        if (!response.ok) {
            let errorMessage = 'Failed to mark lesson complete';
            try {
                const error = await response.json();
                errorMessage = error.message || errorMessage;
            } catch {
                errorMessage = response.statusText || errorMessage;
            }
            throw new Error(errorMessage);
        }
    }

    async updateLastAccessed(courseId: string): Promise<void> {
        await fetch(`${API_URL}/enrollments/${courseId}/access`, {
            method: 'PUT',
            headers: getAuthHeaders(),
            credentials: 'include'
        });
    }
}

export const enrollmentApi = new EnrollmentApi();
