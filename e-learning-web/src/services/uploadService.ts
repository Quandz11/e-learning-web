import { apiClient } from './apiClient';

/**
 * Generic upload service for handling file uploads to various endpoints
 */
export const uploadService = {
    /**
     * Upload testimonial result image to Bunny Cloud via backend
     */
    async uploadTestimonialResultImage(file: File): Promise<{ url: string }> {
        const formData = new FormData();
        formData.append('file', file);
        return apiClient('/testimonials/upload-result', {
            method: 'POST',
            body: formData,
        });
    },

    /**
     * Upload course thumbnail to Bunny Cloud via backend
     */
    async uploadCourseThumbnail(file: File): Promise<{ url: string }> {
        const formData = new FormData();
        formData.append('file', file);
        return apiClient('/courses/thumbnail', {
            method: 'POST',
            body: formData,
        });
    },

    /**
     * Upload article thumbnail to Bunny Cloud via backend
     */
    async uploadArticleThumbnail(file: File): Promise<{ url: string }> {
        const formData = new FormData();
        formData.append('file', file);
        return apiClient('/articles/thumbnail', {
            method: 'POST',
            body: formData,
        });
    },
};
