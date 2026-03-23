import React, { useEffect, useRef, useState } from 'react';
import { Link, useLocation, useNavigate } from 'react-router-dom';
import { useDispatch } from 'react-redux';
import type { AppDispatch } from '../../store/store';
import { loginSuccess, updateUser } from '../../store/authSlice';
import { authApi } from '../../services/authApi';
import { profileApi } from '../../services/profileApi';
import { saveAuth } from '../../services/authStorage';
import { phoneAuthApi } from '../../services/phoneAuthApi';

type PhoneOtpMode = 'register' | 'login';

const PhoneOtpVerifyPage = () => {
  const location = useLocation();
  const navigate = useNavigate();
  const dispatch = useDispatch<AppDispatch>();

  const phone: string | undefined = location.state?.phone;
  const mode: PhoneOtpMode = location.state?.mode === 'register' ? 'register' : 'login';

  const [otp, setOtp] = useState(['', '', '', '', '', '']);
  const inputRefs = useRef<(HTMLInputElement | null)[]>([]);

  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [successMessage, setSuccessMessage] = useState<string | null>(null);
  const [countdown, setCountdown] = useState(600);
  const [canResend, setCanResend] = useState(false);

  const syncProfile = async () => {
    try {
      const profile = await profileApi.getMyProfile();
      dispatch(
        updateUser({
          email: profile.email,
          fullName: profile.fullName || '',
          phone: profile.phone,
          avatarUrl: profile.avatarUrl,
          role: profile.role,
          id: profile.id,
        })
      );
    } catch (err) {
      console.warn('Failed to load profile for avatar', err);
    }
  };

  useEffect(() => {
    if (!phone) {
      navigate(mode === 'register' ? '/register' : '/login', { replace: true });
    }
  }, [phone, mode, navigate]);

  useEffect(() => {
    if (inputRefs.current[0]) {
      inputRefs.current[0].focus();
    }
  }, []);

  useEffect(() => {
    if (countdown <= 0) {
      setCanResend(true);
      return;
    }

    const timer = setInterval(() => {
      setCountdown((prev) => {
        if (prev <= 1) {
          setCanResend(true);
          return 0;
        }
        return prev - 1;
      });
    }, 1000);

    return () => clearInterval(timer);
  }, [countdown]);

  const formatCountdown = (): string => {
    const minutes = Math.floor(countdown / 60);
    const seconds = countdown % 60;
    return `${String(minutes).padStart(2, '0')}:${String(seconds).padStart(2, '0')}`;
  };

  const maskPhone = (rawPhone: string): string => {
    const clean = rawPhone.replace(/[^\d]/g, '');
    if (clean.length < 6) return rawPhone;
    return `${clean.slice(0, 3)}***${clean.slice(-3)}`;
  };

  const handleChange = (index: number, value: string) => {
    if (!/^\d*$/.test(value)) return;

    const newOtp = [...otp];
    newOtp[index] = value;
    setOtp(newOtp);

    if (value && index < 5) {
      inputRefs.current[index + 1]?.focus();
    }

    if (error) setError(null);
  };

  const handleKeyDown = (index: number, e: React.KeyboardEvent<HTMLInputElement>) => {
    if (e.key === 'Backspace' && !otp[index] && index > 0) {
      inputRefs.current[index - 1]?.focus();
    }
  };

  const handlePaste = (e: React.ClipboardEvent) => {
    e.preventDefault();
    const pastedData = e.clipboardData.getData('text/plain').trim();
    if (!/^\d{6}$/.test(pastedData)) return;

    const digits = pastedData.split('');
    setOtp(digits);
    inputRefs.current[5]?.focus();
  };

  const finishLogin = async (accessToken: string, expiresAt: string) => {
    const user = authApi.decodeToken(accessToken);
    if (!user) {
      throw new Error('Không thể đọc thông tin phiên đăng nhập.');
    }

    authApi.setAccessToken(accessToken);
    dispatch(
      loginSuccess({
        user,
        accessToken,
        expiresAt,
      })
    );

    await syncProfile();
    saveAuth({ user, accessToken, expiresAt });

    const role = user.role?.toUpperCase();
    navigate(role === 'ADMIN' ? '/admin/dashboard' : '/home', { replace: true });
  };

  const handleVerifyOtp = async (e: React.FormEvent) => {
    e.preventDefault();
    const otpCode = otp.join('');

    if (otpCode.length !== 6) {
      setError('Vui lòng nhập mã OTP gồm 6 chữ số.');
      return;
    }

    if (!phone) return;

    setIsLoading(true);
    setError(null);

    try {
      const response =
        mode === 'register'
          ? await phoneAuthApi.verifyRegisterOtp(phone, otpCode)
          : await phoneAuthApi.verifyLoginOtp(phone, otpCode);

      await finishLogin(response.accessToken, response.expiresAt);
    } catch (err: any) {
      setError(err?.message || 'OTP không hợp lệ hoặc đã hết hạn.');
    } finally {
      setIsLoading(false);
    }
  };

  const handleResendOtp = async () => {
    if (!canResend || !phone) return;

    setIsLoading(true);
    setError(null);
    setSuccessMessage(null);

    try {
      if (mode === 'register') {
        await phoneAuthApi.resendRegisterOtp(phone);
      } else {
        await phoneAuthApi.requestLoginOtp(phone);
      }

      setCountdown(600);
      setCanResend(false);
      setOtp(['', '', '', '', '', '']);
      inputRefs.current[0]?.focus();
      setSuccessMessage('Đã gửi lại OTP qua Zalo.');
      setTimeout(() => setSuccessMessage(null), 3000);
    } catch (err: any) {
      setError(err?.message || 'Không thể gửi lại OTP.');
    } finally {
      setIsLoading(false);
    }
  };

  if (!phone) {
    return null;
  }

  return (
    <div className="w-full h-full flex flex-col items-center justify-center">
      <div className="text-center flex flex-col items-center gap-2 mb-8">
        <div className="w-12 h-12 rounded-full bg-primary/10 flex items-center justify-center mb-2">
          <span className="material-symbols-outlined text-primary text-2xl">phone_iphone</span>
        </div>
        <h1 className="text-2xl sm:text-3xl font-bold text-gray-900 dark:text-white tracking-tight">
          Xác minh số điện thoại
        </h1>
        <p className="text-gray-500 dark:text-gray-400 text-base leading-relaxed max-w-sm">
          Mã OTP đã được gửi tới <span className="font-medium text-gray-900 dark:text-gray-200">{maskPhone(phone)}</span>
          {' '}qua Zalo.
        </p>
      </div>

      {error && (
        <div className="bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800 rounded-lg p-4 flex items-start gap-3 w-full max-w-[400px] mb-4">
          <span className="material-symbols-outlined text-red-600 dark:text-red-400 text-xl">error</span>
          <p className="text-sm text-red-800 dark:text-red-300 flex-1">{error}</p>
        </div>
      )}

      {successMessage && (
        <div className="bg-green-50 dark:bg-green-900/20 border border-green-200 dark:border-green-800 rounded-lg p-4 flex items-start gap-3 w-full max-w-[400px] mb-4">
          <span className="material-symbols-outlined text-green-600 dark:text-green-400 text-xl">check_circle</span>
          <p className="text-sm text-green-800 dark:text-green-300 flex-1">{successMessage}</p>
        </div>
      )}

      <form className="flex flex-col gap-8 w-full max-w-[400px]" onSubmit={handleVerifyOtp}>
        <div className="flex justify-center gap-2 sm:gap-3 w-full" onPaste={handlePaste}>
          {otp.map((digit, index) => (
            <React.Fragment key={index}>
              <input
                ref={(el: HTMLInputElement | null) => {
                  inputRefs.current[index] = el;
                }}
                className="w-10 h-12 sm:w-12 sm:h-14 text-center text-xl sm:text-2xl font-bold text-gray-900 dark:text-white bg-white dark:bg-gray-800 border border-gray-200 dark:border-gray-600 rounded-lg focus:outline-none focus:border-primary focus:ring-1 focus:ring-primary transition-all duration-200 disabled:opacity-50 disabled:cursor-not-allowed"
                inputMode="numeric"
                maxLength={1}
                placeholder="-"
                type="text"
                value={digit}
                onChange={(e) => handleChange(index, e.target.value)}
                onKeyDown={(e) => handleKeyDown(index, e)}
                disabled={isLoading}
              />
              {index === 2 && (
                <div className="flex items-center justify-center text-gray-300 dark:text-gray-600">-</div>
              )}
            </React.Fragment>
          ))}
        </div>

        <div className="flex flex-col items-center gap-2">
          <div className={`flex items-center gap-2 text-sm font-medium py-2 px-4 rounded-full border ${countdown > 0 ? 'text-gray-500 dark:text-gray-400 bg-background-light dark:bg-gray-800/50 border-transparent dark:border-gray-700' : 'text-red-600 dark:text-red-400 bg-red-50 dark:bg-red-900/20 border-red-200 dark:border-red-800'}`}>
            <span className="material-symbols-outlined text-lg" style={{ fontSize: '18px' }}>timer</span>
            <span className="font-mono">{formatCountdown()}</span>
          </div>

          <div className="text-sm">
            <span className="text-gray-400 dark:text-gray-500">Chưa nhận được mã?</span>
            <button
              className="font-semibold text-primary dark:text-primary-400 hover:text-primary/80 dark:hover:text-primary-300 ml-1 transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
              type="button"
              onClick={handleResendOtp}
              disabled={!canResend || isLoading}
            >
              Gửi lại
            </button>
          </div>
        </div>

        <div className="flex flex-col gap-4 mt-2">
          <button
            className="w-full bg-primary hover:bg-primary/90 text-white font-medium text-base h-12 rounded-lg shadow-sm transition-all duration-200 flex items-center justify-center gap-2 group disabled:opacity-50 disabled:cursor-not-allowed"
            type="submit"
            disabled={isLoading || otp.join('').length !== 6}
          >
            {isLoading ? (
              <>
                <div className="animate-spin rounded-full h-5 w-5 border-b-2 border-white"></div>
                <span>Đang xác minh...</span>
              </>
            ) : (
              <>
                <span>Xác minh và đăng nhập</span>
                <span className="material-symbols-outlined text-lg group-hover:translate-x-0.5 transition-transform">
                  arrow_forward
                </span>
              </>
            )}
          </button>

          <Link
            className="text-sm text-center text-gray-500 hover:text-gray-900 dark:text-gray-400 dark:hover:text-gray-200 transition-colors flex items-center justify-center gap-1 group"
            to={mode === 'register' ? '/register' : '/login'}
          >
            <span className="material-symbols-outlined text-base group-hover:-translate-x-0.5 transition-transform">
              arrow_back
            </span>
            Quay lại
          </Link>
        </div>
      </form>
    </div>
  );
};

export default PhoneOtpVerifyPage;
