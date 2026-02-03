import { authApi } from './authApi';

const API_BASE_URL = import.meta.env.VITE_API_URL || 'https://localhost:7145/api';

import type { LessonDto } from './lessonApi';

export interface CourseInput {
  title: string;
  description?: string;
  price: number;
  isFree: boolean;
  lecturerId: string;
  thumbnailUrl?: string;
  isPublished: boolean;
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

function authHeaders() {
  const token = authApi.getAccessToken();
  const headers: Record<string, string> = {};
  if (token) {
    headers['Authorization'] = `Bearer ${token}`;
  }
  return headers;
}

export const courseApi = {
  async getAll(isPublished?: boolean): Promise<CourseResponse[]> {
    const url = isPublished === undefined ? `${API_BASE_URL}/courses` : `${API_BASE_URL}/courses?isPublished=${isPublished}`;
    const res = await fetch(url, {
      method: 'GET',
      headers: {
        'Content-Type': 'application/json',
        ...authHeaders(),
      },
      credentials: 'include',
    });
    if (!res.ok) throw new Error('Failed to fetch courses');
    return res.json();
  },

  async getById(id: string): Promise<CourseResponse> {
    const res = await fetch(`${API_BASE_URL}/courses/${id}`, {
      method: 'GET',
      headers: {
        'Content-Type': 'application/json',
        ...authHeaders(),
      },
      credentials: 'include',
    });
    if (!res.ok) throw new Error('Failed to fetch course');
    return res.json();
  },

  async create(payload: CourseInput): Promise<CourseResponse> {
    const res = await fetch(`${API_BASE_URL}/courses`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        ...authHeaders(),
      },
      credentials: 'include',
      body: JSON.stringify(payload),
    });
    if (!res.ok) throw new Error('Failed to create course');
    return res.json();
  },

  async update(id: string, payload: CourseInput): Promise<CourseResponse> {
    const res = await fetch(`${API_BASE_URL}/courses/${id}`, {
      method: 'PUT',
      headers: {
        'Content-Type': 'application/json',
        ...authHeaders(),
      },
      credentials: 'include',
      body: JSON.stringify(payload),
    });
    if (!res.ok) throw new Error('Failed to update course');
    return res.json();
  },

  async remove(id: string): Promise<void> {
    const res = await fetch(`${API_BASE_URL}/courses/${id}`, {
      method: 'DELETE',
      headers: {
        ...authHeaders(),
      },
      credentials: 'include',
    });
    if (!res.ok) throw new Error('Failed to delete course');
  },

  async uploadVideo(file: File, title?: string): Promise<VideoUploadResponse> {
    const formData = new FormData();
    formData.append('file', file);
    if (title) formData.append('title', title);

    const res = await fetch(`${API_BASE_URL}/videos/upload`, {
      method: 'POST',
      headers: {
        ...authHeaders(),
      },
      credentials: 'include',
      body: formData,
    });

    if (!res.ok) {
      const message = await res.text();
      throw new Error(message || 'Failed to upload video');
    }

    return res.json();
  },

  async uploadVideoThumbnail(videoId: string, file: File): Promise<void> {
    const formData = new FormData();
    formData.append('file', file);

    const res = await fetch(`${API_BASE_URL}/videos/${videoId}/thumbnail`, {
      method: 'POST',
      headers: {
        ...authHeaders(),
      },
      credentials: 'include',
      body: formData,
    });

    if (!res.ok) {
      const message = await res.text();
      throw new Error(message || 'Failed to upload video thumbnail');
    }
  },

  async uploadThumbnail(file: File): Promise<UploadThumbnailResponse> {
    const formData = new FormData();
    formData.append('file', file);

    const res = await fetch(`${API_BASE_URL}/courses/thumbnail`, {
      method: 'POST',
      headers: {
        ...authHeaders(),
      },
      credentials: 'include',
      body: formData,
    });

    if (!res.ok) {
      const message = await res.text();
      throw new Error(message || 'Failed to upload thumbnail');
    }

    return res.json();
  },


  async syncVideoDuration(videoId: string): Promise<{ duration: number }> {
    const res = await fetch(`${API_BASE_URL}/videos/${videoId}/sync-duration`, {
      method: 'POST',
      headers: {
        ...authHeaders(),
      },
      credentials: 'include',
    });

    if (!res.ok) {
      const message = await res.text();
      throw new Error(message || 'Failed to sync video duration');
    }

    return res.json();
  },

  async getEnrolledStudents(id: string): Promise<StudentResponse[]> {
    const res = await fetch(`${API_BASE_URL}/courses/${id}/students`, {
      method: 'GET',
      headers: {
        'Content-Type': 'application/json',
        ...authHeaders(),
      },
      credentials: 'include',
    });
    if (!res.ok) throw new Error('Failed to fetch enrolled students');
    return res.json();
  },
};
