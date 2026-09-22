import { apiClient } from './apiClient';



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



export const profileApi = {
    async getMyProfile(): Promise<UserProfileDto> {
        return apiClient('/profile/me');
    },

    async updateProfile(payload: UpdateProfileRequest): Promise<UserProfileDto> {
        return apiClient('/profile/me', {
            method: 'PUT',
            body: JSON.stringify(payload),
        });
    },

    async changePassword(payload: ChangePasswordRequest): Promise<void> {
        return apiClient('/profile/change-password', {
            method: 'POST',
            body: JSON.stringify(payload),
        });
    },

    async uploadAvatar(file: File): Promise<{ url: string }> {
        const formData = new FormData();
        formData.append('file', file);
        return apiClient('/profile/upload-avatar', {
            method: 'POST',
            body: formData,
        });
    },

    async deleteMyAccount(): Promise<{ message: string }> {
        return apiClient('/profile/me', {
            method: 'DELETE',
        });
    },

    async requestPublicDeleteAccount(payload: { emailOrPhone: string; password?: string; reason?: string }): Promise<{ message: string; isDeletedImmediately: boolean }> {
        return apiClient('/profile/public-delete-account', {
            method: 'POST',
            body: JSON.stringify(payload),
        });
    }
};
