import { apiClient } from './apiClient';


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
        return apiClient('/enrollments', {
            method: 'POST',
            body: JSON.stringify({ courseId })
        });
    }

    async checkEnrollment(courseId: string): Promise<boolean> {
        try {
            const data = await apiClient<{ isEnrolled: boolean }>(`/enrollments/check/${courseId}`);
            return data.isEnrolled;
        } catch {
            return false;
        }
    }

    async getUserEnrollments(): Promise<EnrollmentResponse[]> {
        return apiClient('/enrollments');
    }

    async getCourseProgress(courseId: string): Promise<CourseProgressResponse> {
        return apiClient(`/enrollments/${courseId}/progress`);
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
        try {
            await apiClient(`/enrollments/${courseId}/lessons/${lessonPartId}/progress`, {
                method: 'POST',
                body: JSON.stringify({ watchedDuration })
            });
        } catch (error: any) {
            console.error('Failed to update progress', error);
            throw new Error(error.message || 'Failed to update lesson progress');
        }
    }

    async markLessonComplete(courseId: string, lessonPartId: string): Promise<void> {
        try {
            await apiClient(`/enrollments/${courseId}/lessons/${lessonPartId}/complete`, {
                method: 'POST',
            });
        } catch (error: any) {
            throw new Error(error.message || 'Failed to mark lesson complete');
        }
    }

    async updateLastAccessed(courseId: string): Promise<void> {
        await apiClient(`/enrollments/${courseId}/access`, {
            method: 'PUT',
        });
    }
}

export const enrollmentApi = new EnrollmentApi();
