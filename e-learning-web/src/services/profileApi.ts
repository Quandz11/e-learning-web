import { authApi } from './authApi';

const API_BASE_URL = import.meta.env.VITE_API_URL || 'https://localhost:7145/api';

export interface UserProfileDto {
    id: string;
    email: string;
    fullName?: string;
    phone?: string;
    role: string;
    status: string;
    avatarUrl?: string;
    isEmailVerified: boolean;
    isPhoneVerified: boolean;
    isTwoFactorEnabled: boolean;
    createdAt: string;
    updatedAt: string;
}

export interface UpdateProfileRequest {
    fullName?: string;
    phone?: string;
    avatarUrl?: string;
}

export interface ChangePasswordRequest {
    currentPassword: string;
    newPassword: string;
}

function authHeaders() {
    const token = authApi.getAccessToken();
    const headers: Record<string, string> = { 'Content-Type': 'application/json' };
    if (token) headers['Authorization'] = `Bearer ${token}`;
    return headers;
}

export const profileApi = {
    async getMyProfile(): Promise<UserProfileDto> {
        const res = await fetch(`${API_BASE_URL}/profile/me`, {
            method: 'GET',
            headers: authHeaders(),
            credentials: 'include',
        });
        if (!res.ok) throw new Error('Failed to fetch profile');
        return res.json();
    },

    async updateProfile(payload: UpdateProfileRequest): Promise<UserProfileDto> {
        const res = await fetch(`${API_BASE_URL}/profile/me`, {
            method: 'PUT',
            headers: authHeaders(),
            credentials: 'include',
            body: JSON.stringify(payload),
        });
        if (!res.ok) {
            const msg = await res.text();
            throw new Error(msg || 'Update profile failed');
        }
        return res.json();
    },

    async changePassword(payload: ChangePasswordRequest): Promise<void> {
        const res = await fetch(`${API_BASE_URL}/profile/change-password`, {
            method: 'POST',
            headers: authHeaders(),
            credentials: 'include',
            body: JSON.stringify(payload),
        });
        if (!res.ok) {
            const msg = await res.text();
            throw new Error(msg || 'Change password failed');
        }
    },

    async uploadAvatar(file: File): Promise<{ url: string }> {
        const formData = new FormData();
        formData.append('file', file);

        const token = authApi.getAccessToken();
        const headers: Record<string, string> = {};
        if (token) headers['Authorization'] = `Bearer ${token}`;
        // Content-Type is set automatically by browser with boundary for FormData

        const res = await fetch(`${API_BASE_URL}/profile/upload-avatar`, {
            method: 'POST',
            headers,
            credentials: 'include',
            body: formData,
        });

        if (!res.ok) {
            const msg = await res.text();
            try {
                const json = JSON.parse(msg);
                throw new Error(json.message || 'Upload failed');
            } catch {
                throw new Error(msg || 'Upload failed');
            }
        }
        return res.json();
    }
};
