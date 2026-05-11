import { apiClient } from './apiClient';
import { tokenService } from './tokenService';
import { authUtils } from './authUtils';
import type { AuthResponse, User } from './authUtils';

export interface LoginRequest {
  email: string;
  password: string;
}

class AuthApi {
  setAccessToken(token: string | null): void {
    tokenService.setAccessToken(token);
  }

  getAccessToken(): string | null {
    return tokenService.getAccessToken();
  }

  async login(credentials: LoginRequest): Promise<AuthResponse> {
    // We use apiClient here for consistency, but login usually doesn't need 401 handling
    return apiClient('/auth/login', {
      method: 'POST',
      body: JSON.stringify(credentials),
    });
  }

  async register(data: {
    email: string;
    password: string;
    fullName: string;
    phone?: string;
    referralCode?: string;
  }): Promise<{ message: string }> {
    return apiClient('/auth/register', {
      method: 'POST',
      body: JSON.stringify(data),
    });
  }

  async verifyOtp(email: string, otp: string): Promise<AuthResponse> {
    return apiClient('/auth/verify-otp', {
      method: 'POST',
      body: JSON.stringify({ email, otp }),
    });
  }

  async resendOtp(email: string): Promise<{ message: string }> {
    return apiClient('/auth/resend-otp', {
      method: 'POST',
      body: JSON.stringify({ email }),
    });
  }

  async refreshToken(): Promise<AuthResponse> {
    return authUtils.refreshToken();
  }

  // 2FA Methods
  async setupTwoFactor(): Promise<{ secret: string; qrCodeUri: string }> {
    return apiClient('/auth/2fa/setup', {
      method: 'POST',
    });
  }

  async enableTwoFactor(secret: string, code: string): Promise<AuthResponse> {
    return apiClient('/auth/2fa/enable', {
      method: 'POST',
      body: JSON.stringify({ secret, code }),
    });
  }

  async disableTwoFactor(password: string): Promise<{ message: string }> {
    return apiClient('/auth/2fa/disable', {
      method: 'POST',
      body: JSON.stringify({ password }),
    });
  }

  async loginVerifyTwoFactor(code: string): Promise<AuthResponse> {
    return apiClient('/auth/2fa/login-verify', {
      method: 'POST',
      body: JSON.stringify({ code }),
    });
  }

  async logout(): Promise<void> {
    try {
      await apiClient('/auth/logout', {
        method: 'POST',
      });
    } finally {
      this.setAccessToken(null);
    }
  }

  decodeToken(token: string): User | null {
    return authUtils.decodeToken(token);
  }

  isTokenExpired(expiresAt: string): boolean {
    return authUtils.isTokenExpired(expiresAt);
  }
}

export const authApi = new AuthApi();
export type { AuthResponse, User };
