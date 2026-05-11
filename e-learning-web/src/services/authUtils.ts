const API_BASE_URL = import.meta.env.VITE_API_URL || 'https://skvi-api.azurewebsites.net/api';

export interface AuthResponse {
  accessToken: string;
  expiresAt: string;
  requiresTwoFactor?: boolean;
}

export interface User {
  id: string;
  email: string;
  fullName: string;
  role: string;
  avatarUrl?: string;
  phone?: string;
}

export const authUtils = {
  async refreshToken(): Promise<AuthResponse> {
    const response = await fetch(`${API_BASE_URL}/auth/refresh`, {
      method: 'POST',
      credentials: 'include',
    });

    if (!response.ok) {
      throw new Error('Token refresh failed');
    }

    return response.json();
  },

  decodeToken(token: string): User | null {
    try {
      const payload = token.split('.')[1];
      const base64 = payload.replace(/-/g, '+').replace(/_/g, '/');
      const jsonPayload = decodeURIComponent(
        atob(base64)
          .split('')
          .map((c) => '%' + ('00' + c.charCodeAt(0).toString(16)).slice(-2))
          .join('')
      );
      const decoded = JSON.parse(jsonPayload);

      const role = decoded.role || decoded['http://schemas.microsoft.com/ws/2008/06/identity/claims/role'];
      return {
        id: decoded.sub,
        email: decoded.email,
        fullName: decoded.fullName || '',
        role: role,
        avatarUrl: decoded.avatarUrl,
      };
    } catch (error) {
      return null;
    }
  },

  isTokenExpired(expiresAt: string): boolean {
    return new Date(expiresAt) <= new Date();
  },
};
