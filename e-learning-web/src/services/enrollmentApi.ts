import { apiClient } from './apiClient';


export interface EnrollmentResponse {
    id: string;
    courseId: string;
    courseTitle: string;
    courseThumbnail?: string;
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

interface CourseProgressResponseRaw {
    enrollmentId?: unknown;
    progressPercentage?: unknown;
    completedParts?: unknown;
    totalParts?: unknown;
    completedLessons?: unknown;
    totalLessons?: unknown;
    completedAt?: unknown;
    partProgress?: unknown;
    lessonProgress?: unknown;
}

const toNumber = (value: unknown, fallback = 0): number => {
    if (typeof value === 'number' && Number.isFinite(value)) {
        return value;
    }
    return fallback;
};

const toStringValue = (value: unknown, fallback = ''): string => {
    if (typeof value === 'string') {
        return value;
    }
    return fallback;
};

const toNullableString = (value: unknown): string | null => {
    if (typeof value === 'string') {
        return value;
    }
    return null;
};

const normalizePartProgress = (value: unknown): LessonPartProgressDto[] => {
    const rows = Array.isArray(value) ? value : [];

    return rows
        .filter((row): row is Record<string, unknown> => Boolean(row) && typeof row === 'object')
        .map((row) => ({
            lessonPartId: toStringValue(row.lessonPartId ?? row.lessonId),
            lessonPartTitle: toStringValue(row.lessonPartTitle ?? row.lessonTitle),
            isCompleted: Boolean(row.isCompleted),
            watchedDuration: toNumber(row.watchedDuration),
            completedAt: toNullableString(row.completedAt),
            lastWatchedAt: toStringValue(row.lastWatchedAt, new Date(0).toISOString())
        }));
};

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
        const raw = await apiClient<CourseProgressResponseRaw>(`/enrollments/${courseId}/progress`);

        return {
            enrollmentId: toStringValue(raw.enrollmentId),
            progressPercentage: toNumber(raw.progressPercentage),
            completedParts: toNumber(raw.completedParts, toNumber(raw.completedLessons)),
            totalParts: toNumber(raw.totalParts, toNumber(raw.totalLessons)),
            completedAt: toNullableString(raw.completedAt),
            partProgress: normalizePartProgress(raw.partProgress ?? raw.lessonProgress)
        };
    }

    async updateLessonProgress(courseId: string, lessonPartId: string, watchedDuration: number): Promise<void> {
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
