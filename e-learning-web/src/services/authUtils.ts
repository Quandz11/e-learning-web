import { tokenService } from './tokenService';
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

let inFlight: Promise<AuthResponse> | null = null;

export const authUtils = {
  async refreshToken(): Promise<AuthResponse> {
    if (inFlight) return inFlight;
    const generation = tokenService.getGeneration();
    const run = async () => {
      if (generation !== tokenService.getGeneration()) throw new Error('Session changed');
      const response = await fetch(`${API_BASE_URL}/auth/refresh`, { method: 'POST', credentials: 'include' });
      if (generation !== tokenService.getGeneration()) throw new Error('Session changed');
      if (!response.ok) {
        if (response.status === 401) tokenService.clearToken();
        throw new Error('Token refresh failed');
      }
      const result: AuthResponse = await response.json();
      if (generation !== tokenService.getGeneration()) throw new Error('Session changed');
      return result;
    };
    // Serialize cookie rotation across tabs, as well as within this tab.
    const promise: Promise<AuthResponse> = typeof navigator !== 'undefined' && navigator.locks
      ? (navigator.locks.request('skvi-token-refresh', run) as unknown as Promise<AuthResponse>) : run();
    inFlight = promise;
    try { return await promise; }
    finally { if (inFlight === promise) inFlight = null; }
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
