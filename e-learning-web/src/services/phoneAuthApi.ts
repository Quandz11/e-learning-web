import type { AuthResponse } from './authApi';

const API_BASE_URL = import.meta.env.VITE_API_URL || 'https://localhost:7145/api';

export interface PhoneRegisterRequest {
  fullName: string;
  phone: string;
  email?: string;
  password?: string;
  referralCode?: string;
}

function extractErrorMessage(payload: any, fallback: string): string {
  if (payload && typeof payload.message === 'string' && payload.message.trim().length > 0) {
    return payload.message;
  }
  return fallback;
}

class PhoneAuthApi {
  async register(data: PhoneRegisterRequest): Promise<{ message: string }> {
    const response = await fetch(`${API_BASE_URL}/auth/phone/register`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(data),
    });

    if (!response.ok) {
      const error = await response.json().catch(() => null);
      throw new Error(extractErrorMessage(error, 'Phone registration failed'));
    }

    return response.json();
  }

  async verifyRegisterOtp(phone: string, otp: string): Promise<AuthResponse> {
    const response = await fetch(`${API_BASE_URL}/auth/phone/verify-register-otp`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      credentials: 'include',
      body: JSON.stringify({ phone, otp }),
    });

    if (!response.ok) {
      const error = await response.json().catch(() => null);
      throw new Error(extractErrorMessage(error, 'Verify register OTP failed'));
    }

    return response.json();
  }

  async resendRegisterOtp(phone: string): Promise<{ message: string }> {
    const response = await fetch(`${API_BASE_URL}/auth/phone/resend-register-otp`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ phone }),
    });

    if (!response.ok) {
      const error = await response.json().catch(() => null);
      throw new Error(extractErrorMessage(error, 'Resend register OTP failed'));
    }

    return response.json();
  }

  async requestForgotPasswordOtp(phone: string): Promise<{ message: string }> {
    const response = await fetch(`${API_BASE_URL}/auth/phone/request-forgot-password-otp`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ phone }),
    });

    if (!response.ok) {
      const error = await response.json().catch(() => null);
      throw new Error(extractErrorMessage(error, 'Request forgot-password OTP failed'));
    }

    return response.json();
  }

  async resendForgotPasswordOtp(phone: string): Promise<{ message: string }> {
    const response = await fetch(`${API_BASE_URL}/auth/phone/resend-forgot-password-otp`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ phone }),
    });

    if (!response.ok) {
      const error = await response.json().catch(() => null);
      throw new Error(extractErrorMessage(error, 'Resend forgot-password OTP failed'));
    }

    return response.json();
  }

  async verifyForgotPasswordOtp(phone: string, otp: string, newPassword: string): Promise<{ message: string }> {
    const response = await fetch(`${API_BASE_URL}/auth/phone/verify-forgot-password-otp`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ phone, otp, newPassword }),
    });

    if (!response.ok) {
      const error = await response.json().catch(() => null);
      throw new Error(extractErrorMessage(error, 'Verify forgot-password OTP failed'));
    }

    return response.json();
  }
}

export const phoneAuthApi = new PhoneAuthApi();
