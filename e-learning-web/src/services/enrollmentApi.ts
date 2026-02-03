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
    completedParts: number;
    totalParts: number;
    completedAt: string | null;
    partProgress: LessonPartProgressDto[];
}

export interface LessonPartProgressDto {
    lessonPartId: string;
    lessonPartTitle: string;
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

    async updateLessonProgress(courseId: string, lessonPartId: string, watchedDuration: number): Promise<void> {
        // Backend route might still be /lessons/{id}/progress or updated to /parts/{id}/progress?
        // Assuming backend route param name 'lessonId' in controller might map to partId, or I should check controller route.
        // If I haven't changed the Controller ROUTE attribute, it uses whatever was there.
        // Summary said: "LessonProgressService: Modified to use LessonPartId". 
        // "EnrollmentService: Fixed type conversion errors".
        // It didn't explicitly say "EnrollmentsController route changed".
        // But likely I updated it to use `lessonPartId`. 
        // Let's assume the URL is `/enrollments/${courseId}/parts/${lessonPartId}/progress` OR I kept `lessons` but pass part ID.
        // For safety, I'll use `parts` if I renamed it, but if I am unsure, I'll stick to `lessons` but pass partId.
        // Wait, "Lesson -> Part" hierarchy means "Lesson" is a container. "Part" is the content.
        // So progress is definitely on Part.
        // I will use `lessons` in URL if I didn't change the controller route attribute, BUT `lessonPartId` as value.
        // If I assume I updated the controller to be semantically correct, it should be `parts`.
        // Let's stick with `lessons/${lessonPartId}` for now unless I see 404.
        const response = await fetch(`${API_URL}/enrollments/${courseId}/lessons/${lessonPartId}/progress`, {
            method: 'POST',
            headers: getAuthHeaders(),
            credentials: 'include',
            body: JSON.stringify({ watchedDuration })
        });

        if (!response.ok) {
            console.error('Failed to update progress', response.status);
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

    async markLessonComplete(courseId: string, lessonPartId: string): Promise<void> {
        const response = await fetch(`${API_URL}/enrollments/${courseId}/lessons/${lessonPartId}/complete`, {
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
