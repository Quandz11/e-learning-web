import { apiClient } from './apiClient';




export type UserRole = 'ADMIN' | 'CARE' | 'CABIN_OWNER' | 'STUDENT' | 'LECTURER';
export type UserStatus = 'ACTIVE' | 'INACTIVE' | 'SUSPENDED';

export interface UserDto {
  id: string;
  email: string;
  fullName?: string;
  phone?: string;
  role: UserRole;
  status: UserStatus;
  avatarUrl?: string;
  isEmailVerified: boolean;
  isPhoneVerified: boolean;
  isTwoFactorEnabled: boolean;
  createdAt: string;
}

export interface PagedResult<T> {
  items: T[];
  total: number;
  page: number;
  pageSize: number;
}

export interface CreateUserRequest {
  email: string;
  password: string;
  fullName?: string;
  phone?: string;
  role: UserRole;
  status: UserStatus;
  avatarUrl?: string;
}

export interface UpdateUserRequest {
  fullName?: string;
  phone?: string;
  role: UserRole;
  status: UserStatus;
  avatarUrl?: string;
}

export interface ResetPasswordRequest {
  newPassword: string;
}



export const userApi = {
  async getPaged(params: { search?: string; role?: string; status?: string; page?: number; pageSize?: number }): Promise<PagedResult<UserDto>> {
    const searchParams = new URLSearchParams();
    if (params.search) searchParams.set('search', params.search);
    if (params.role) searchParams.set('role', params.role);
    if (params.status) searchParams.set('status', params.status);
    searchParams.set('page', String(params.page ?? 1));
    searchParams.set('pageSize', String(params.pageSize ?? 20));

    return apiClient(`/users?${searchParams.toString()}`);
  },

  async getById(id: string): Promise<UserDto> {
    return apiClient(`/users/${id}`);
  },

  async create(payload: CreateUserRequest): Promise<UserDto> {
    return apiClient('/users', {
      method: 'POST',
      body: JSON.stringify(payload),
    });
  },

  async update(id: string, payload: UpdateUserRequest): Promise<UserDto> {
    return apiClient(`/users/${id}`, {
      method: 'PUT',
      body: JSON.stringify(payload),
    });
  },

  async delete(id: string): Promise<void> {
    return apiClient(`/users/${id}`, {
      method: 'DELETE',
    });
  },

  async resetPassword(id: string, payload: ResetPasswordRequest): Promise<void> {
    return apiClient(`/users/${id}/reset-password`, {
      method: 'POST',
      body: JSON.stringify(payload),
    });
  },
};
