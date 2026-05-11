import { apiClient } from './apiClient';
import type { AuthResponse } from './authApi';

export interface PhoneRegisterRequest {
  fullName: string;
  phone: string;
  email?: string;
  password?: string;
  referralCode?: string;
}

class PhoneAuthApi {
  async register(data: PhoneRegisterRequest): Promise<{ message: string }> {
    return apiClient('/auth/phone/register', {
      method: 'POST',
      body: JSON.stringify(data),
    });
  }

  async verifyRegisterOtp(phone: string, otp: string): Promise<AuthResponse> {
    return apiClient('/auth/phone/verify-register-otp', {
      method: 'POST',
      body: JSON.stringify({ phone, otp }),
    });
  }

  async resendRegisterOtp(phone: string): Promise<{ message: string }> {
    return apiClient('/auth/phone/resend-register-otp', {
      method: 'POST',
      body: JSON.stringify({ phone }),
    });
  }

  async requestForgotPasswordOtp(phone: string): Promise<{ message: string }> {
    return apiClient('/auth/phone/request-forgot-password-otp', {
      method: 'POST',
      body: JSON.stringify({ phone }),
    });
  }

  async resendForgotPasswordOtp(phone: string): Promise<{ message: string }> {
    return apiClient('/auth/phone/resend-forgot-password-otp', {
      method: 'POST',
      body: JSON.stringify({ phone }),
    });
  }

  async verifyForgotPasswordOtp(phone: string, otp: string, newPassword: string): Promise<{ message: string }> {
    return apiClient('/auth/phone/verify-forgot-password-otp', {
      method: 'POST',
      body: JSON.stringify({ phone, otp, newPassword }),
    });
  }
}

export const phoneAuthApi = new PhoneAuthApi();
