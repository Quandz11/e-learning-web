import { apiClient } from './apiClient';



import type { LessonDto } from './lessonApi';

export interface CourseInput {
  title: string;
  description?: string;
  price: number;
  isFree: boolean;
  lecturerId: string;
  thumbnailUrl?: string;
  isPublished: boolean;
  defaultAccessDurationDays?: number | null;
  learningOutcomes?: string[];
  lessonIds: string[];
}

export interface LecturerInfo {
  id: string;
  fullName: string;
  email: string;
  avatarUrl?: string;
}

export interface CourseResponse extends Omit<CourseInput, 'lessonIds'> {
  id: string;
  createdAt: string;
  lecturer?: LecturerInfo;
  learningOutcomes?: string[];
  lessons: LessonDto[];
}

export interface StudentResponse {
  id: string;
  fullName: string;
  email: string;
  avatarUrl?: string;
  enrolledAt: string;
}

export interface VideoUploadResponse {
  videoId: string;
  bunnyVideoId: string;
  playlistUrl: string;
  duration: number;
}

export interface UploadThumbnailResponse {
  url: string;
}



export const courseApi = {
  async getAll(isPublished?: boolean): Promise<CourseResponse[]> {
    const url = isPublished === undefined ? '/courses' : `/courses?isPublished=${isPublished}`;
    return apiClient(url);
  },

  async getById(id: string): Promise<CourseResponse> {
    return apiClient(`/courses/${id}`);
  },

  async create(payload: CourseInput): Promise<CourseResponse> {
    return apiClient('/courses', {
      method: 'POST',
      body: JSON.stringify(payload),
    });
  },

  async update(id: string, payload: CourseInput): Promise<CourseResponse> {
    return apiClient(`/courses/${id}`, {
      method: 'PUT',
      body: JSON.stringify(payload),
    });
  },

  async remove(id: string): Promise<void> {
    return apiClient(`/courses/${id}`, {
      method: 'DELETE',
    });
  },

  async uploadVideo(file: File, title?: string): Promise<VideoUploadResponse> {
    const formData = new FormData();
    formData.append('file', file);
    if (title) formData.append('title', title);

    try {
      return apiClient('/videos/upload', {
        method: 'POST',
        body: formData,
      });
    } catch (err) {
      throw new Error('Failed to upload video');
    }
  },

  async uploadVideoThumbnail(videoId: string, file: File): Promise<void> {
    const formData = new FormData();
    formData.append('file', file);

    try {
      return apiClient(`/videos/${videoId}/thumbnail`, {
        method: 'POST',
        body: formData,
      });
    } catch (err) {
      throw new Error('Failed to upload video thumbnail');
    }
  },

  async uploadThumbnail(file: File): Promise<UploadThumbnailResponse> {
    const formData = new FormData();
    formData.append('file', file);

    try {
      return apiClient('/courses/thumbnail', {
        method: 'POST',
        body: formData,
      });
    } catch {
      throw new Error('Failed to upload thumbnail');
    }
  },


  async syncVideoDuration(videoId: string): Promise<{ duration: number }> {
    try {
      return apiClient(`/videos/${videoId}/sync-duration`, {
        method: 'POST',
      });
    } catch {
      throw new Error('Failed to sync video duration');
    }
  },

  async getEnrolledStudents(id: string): Promise<StudentResponse[]> {
    return apiClient(`/courses/${id}/students`);
  },
};
