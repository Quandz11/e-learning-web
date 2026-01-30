import { authApi } from './authApi';

const API_BASE_URL = import.meta.env.VITE_API_URL || 'https://localhost:7145/api';

export interface DocumentUploadResponse {
    documentId: string;
    fileUrl: string;
}

export interface DocumentResponse {
    id: string;
    fileName: string;
    fileUrl: string;
    fileSizeBytes: number;
    uploadedAt: string;
}

function authHeaders() {
    const token = authApi.getAccessToken();
    const headers: Record<string, string> = {};
    if (token) {
        headers['Authorization'] = `Bearer ${token}`;
    }
    return headers;
}

export const documentApi = {
    async uploadPdf(file: File): Promise<DocumentUploadResponse> {
        const formData = new FormData();
        formData.append('file', file);

        const res = await fetch(`${API_BASE_URL}/documents/upload`, {
            method: 'POST',
            headers: {
                ...authHeaders(),
            },
            credentials: 'include',
            body: formData,
        });

        if (!res.ok) {
            const message = await res.text();
            throw new Error(message || 'Failed to upload PDF');
        }

        return res.json();
    },

    async getById(id: string): Promise<DocumentResponse> {
        const res = await fetch(`${API_BASE_URL}/documents/${id}`, {
            method: 'GET',
            headers: {
                'Content-Type': 'application/json',
                ...authHeaders(),
            },
            credentials: 'include',
        });

        if (!res.ok) {
            throw new Error('Failed to fetch document');
        }

        return res.json();
    },
};
