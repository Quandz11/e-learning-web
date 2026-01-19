const API_BASE_URL = import.meta.env.VITE_API_URL || 'https://localhost:7145/api';

// Store access token in memory for Authorization header
let accessToken: string | null = null;

export interface LoginRequest {
  email: string;
  password: string;
}

export interface AuthResponse {
  accessToken: string;
  expiresAt: string;
}

export interface User {
  id: string;
  email: string;
  fullName: string;
  role: string;
  avatarUrl?: string;
}

class AuthApi {
  // Set access token in memory when user logs in
  setAccessToken(token: string | null): void {
    accessToken = token;
  }

  // Get access token from memory
  getAccessToken(): string | null {
    return accessToken;
  }

  // Helper to get headers with Authorization
  private getHeaders(includeAuth = false): Record<string, string> {
    const headers: Record<string, string> = {
      'Content-Type': 'application/json',
    };

    if (includeAuth && accessToken) {
      headers['Authorization'] = `Bearer ${accessToken}`;
    }

    return headers;
  }
  async login(credentials: LoginRequest): Promise<AuthResponse> {
    const response = await fetch(`${API_BASE_URL}/auth/login`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      credentials: 'include', // Important: send cookies (refreshToken)
      body: JSON.stringify(credentials),
    });

    if (!response.ok) {
      const error = await response.json();
      throw new Error(error.message || 'Login failed');
    }

    return response.json();
  }

  async register(data: {
    email: string;
    password: string;
    fullName: string;
    phone?: string;
  }): Promise<{ message: string }> {
    const response = await fetch(`${API_BASE_URL}/auth/register`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(data),
    });

    if (!response.ok) {
      const error = await response.json();
      throw new Error(error.message || 'Registration failed');
    }

    return response.json();
  }

  async verifyOtp(email: string, otp: string): Promise<AuthResponse> {
    const response = await fetch(`${API_BASE_URL}/auth/verify-otp`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      credentials: 'include',
      body: JSON.stringify({ email, otp }),
    });

    if (!response.ok) {
      const error = await response.json();
      throw new Error(error.message || 'OTP verification failed');
    }

    return response.json();
  }

  async resendOtp(email: string): Promise<{ message: string }> {
    const response = await fetch(`${API_BASE_URL}/auth/resend-otp`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ email }),
    });

    if (!response.ok) {
      const error = await response.json();
      throw new Error(error.message || 'Resend OTP failed');
    }

    return response.json();
  }

  async refreshToken(): Promise<AuthResponse> {
    console.log('[AuthApi] 🔄 Calling /auth/refresh to get new token...');
    
    const response = await fetch(`${API_BASE_URL}/auth/refresh`, {
      method: 'POST',
      credentials: 'include',
    });

    if (!response.ok) {
      console.error('[AuthApi] ❌ Token refresh failed:', response.status, response.statusText);
      throw new Error('Token refresh failed');
    }

    const data = await response.json();
    console.log('[AuthApi] ✅ New access token received, expires at:', data.expiresAt);
    return data;
  }

  async logout(): Promise<void> {
    try {
      console.log('[AuthApi] 🚪 Logging out...');
      await fetch(`${API_BASE_URL}/auth/logout`, {
        method: 'POST',
        headers: this.getHeaders(),
        credentials: 'include',
      });
      console.log('[AuthApi] ✅ Logout successful, token cleared');
    } finally {
      // Clear access token from memory only (prevent XSS)
      this.setAccessToken(null);
    }
  }

  // Get current user from token (decode JWT)
  decodeToken(token: string): User | null {
    try {
      const payload = token.split('.')[1];
      const decoded = JSON.parse(atob(payload));

      const role = decoded.role || decoded['http://schemas.microsoft.com/ws/2008/06/identity/claims/role'];
      return {
        id: decoded.sub,
        email: decoded.email,
        fullName: decoded.fullName || '',
        role: role,
        avatarUrl: decoded.avatarUrl,
      };
    } catch (error) {
      console.error('Failed to decode token:', error);
      return null;
    }
  }

  isTokenExpired(expiresAt: string): boolean {
    const isExpired = new Date(expiresAt) <= new Date();
    if (isExpired) {
      console.warn('[AuthApi] ⏰ Access token EXPIRED at', expiresAt);
    } else {
      const secondsLeft = Math.floor((new Date(expiresAt).getTime() - new Date().getTime()) / 1000);
      console.log('[AuthApi] ⏱️  Access token valid, expires in', secondsLeft, 'seconds');
    }
    return isExpired;
  }
}

export const authApi = new AuthApi();
