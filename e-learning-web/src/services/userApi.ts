import { authApi } from './authApi';

const API_BASE_URL = import.meta.env.VITE_API_URL || 'https://localhost:7145/api';

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

function authHeaders() {
  const token = authApi.getAccessToken();
  const headers: Record<string, string> = { 'Content-Type': 'application/json' };
  if (token) headers['Authorization'] = `Bearer ${token}`;
  return headers;
}

export const userApi = {
  async getPaged(params: { search?: string; role?: string; status?: string; page?: number; pageSize?: number }): Promise<PagedResult<UserDto>> {
    const url = new URL(`${API_BASE_URL}/users`);
    if (params.search) url.searchParams.set('search', params.search);
    if (params.role) url.searchParams.set('role', params.role);
    if (params.status) url.searchParams.set('status', params.status);
    url.searchParams.set('page', String(params.page ?? 1));
    url.searchParams.set('pageSize', String(params.pageSize ?? 20));

    const res = await fetch(url.toString(), {
      method: 'GET',
      headers: authHeaders(),
      credentials: 'include',
    });
    if (!res.ok) throw new Error('Failed to fetch users');
    return res.json();
  },

  async getById(id: string): Promise<UserDto> {
    const res = await fetch(`${API_BASE_URL}/users/${id}`, {
      method: 'GET',
      headers: authHeaders(),
      credentials: 'include',
    });
    if (!res.ok) throw new Error('Failed to fetch user details');
    return res.json();
  },

  async create(payload: CreateUserRequest): Promise<UserDto> {
    const res = await fetch(`${API_BASE_URL}/users`, {
      method: 'POST',
      headers: authHeaders(),
      credentials: 'include',
      body: JSON.stringify(payload),
    });
    if (!res.ok) {
      const msg = await res.text();
      throw new Error(msg || 'Create user failed');
    }
    return res.json();
  },

  async update(id: string, payload: UpdateUserRequest): Promise<UserDto> {
    const res = await fetch(`${API_BASE_URL}/users/${id}`, {
      method: 'PUT',
      headers: authHeaders(),
      credentials: 'include',
      body: JSON.stringify(payload),
    });
    if (!res.ok) {
      const msg = await res.text();
      throw new Error(msg || 'Update user failed');
    }
    return res.json();
  },

  async delete(id: string): Promise<void> {
    const res = await fetch(`${API_BASE_URL}/users/${id}`, {
      method: 'DELETE',
      headers: authHeaders(),
      credentials: 'include',
    });
    if (!res.ok) {
      const msg = await res.text();
      throw new Error(msg || 'Delete user failed');
    }
  },

  async resetPassword(id: string, payload: ResetPasswordRequest): Promise<void> {
    const res = await fetch(`${API_BASE_URL}/users/${id}/reset-password`, {
      method: 'POST',
      headers: authHeaders(),
      credentials: 'include',
      body: JSON.stringify(payload),
    });
    if (!res.ok) {
      const msg = await res.text();
      throw new Error(msg || 'Reset password failed');
    }
  },
};
