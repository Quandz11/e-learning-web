import React, { useMemo, useState } from 'react';
import { useNavigate, Link } from 'react-router-dom';
import { useTranslation } from 'react-i18next';
import { useDispatch, useSelector } from 'react-redux';
import type { AppDispatch, RootState } from '../../store/store';
import { loginStart, loginSuccess, loginFailure, updateUser } from '../../store/authSlice';
import { authApi } from '../../services/authApi';
import { profileApi } from '../../services/profileApi';
import { saveAuth } from '../../services/authStorage';
import { useToast } from '../../contexts/ToastContext';
import { extractErrorMessage, getErrorI18nKey } from '../../utils/errorHandler';

type LoginMode = 'email' | 'phone' | 'unknown';

const normalizePhone = (value: string): string => {
  const raw = value.trim().replace(/[\s\-\.\(\)]/g, '');
  if (raw.startsWith('+')) return raw.slice(1);
  if (raw.startsWith('0')) return `84${raw.slice(1)}`;
  return raw;
};

const detectLoginMode = (value: string): LoginMode => {
  const identifier = value.trim();
  if (!identifier) return 'unknown';

  const emailLike = /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(identifier);
  if (emailLike) return 'email';

  const phone = normalizePhone(identifier);
  if (/^\d{9,15}$/.test(phone)) return 'phone';

  return 'unknown';
};

const LoginPage = () => {
  const { t } = useTranslation();
  const navigate = useNavigate();
  const dispatch = useDispatch<AppDispatch>();
  const { requiresTwoFactor } = useSelector((state: RootState) => state.auth);
  const { showToast } = useToast();

  const [twoFactorCode, setTwoFactorCode] = useState('');
  const [identifier, setIdentifier] = useState('');
  const [password, setPassword] = useState('');
  const [showPassword, setShowPassword] = useState(false);
  const [rememberMe, setRememberMe] = useState(false);
  const [isLoading, setIsLoading] = useState(false);

  const loginMode = useMemo(() => detectLoginMode(identifier), [identifier]);

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
    } catch (profileErr) {
      console.warn('Failed to load profile for avatar', profileErr);
    }
  };

  const handleCredentialLogin = async () => {
    if (!password.trim()) {
      throw new Error(t('auth.errors.passwordRequired'));
    }

    dispatch(loginStart());

    const normalizedIdentifier = loginMode === 'phone' ? normalizePhone(identifier) : identifier.trim().toLowerCase();

    const response = await authApi.login({
      email: normalizedIdentifier,
      password,
    });

    const isTwoFactorRequired = response.requiresTwoFactor || (response as any).RequiresTwoFactor;
    if (isTwoFactorRequired) {
      dispatch(
        loginSuccess({
          user: null,
          accessToken: response.accessToken,
          expiresAt: response.expiresAt,
          requiresTwoFactor: true,
        })
      );
      authApi.setAccessToken(response.accessToken);
      return;
    }

    const user = authApi.decodeToken(response.accessToken);
    if (!user) {
      throw new Error('Failed to decode token');
    }

    dispatch(
      loginSuccess({
        user,
        accessToken: response.accessToken,
        expiresAt: response.expiresAt,
      })
    );

    authApi.setAccessToken(response.accessToken);
    await syncProfile();
    saveAuth({ user, accessToken: response.accessToken, expiresAt: response.expiresAt });

    showToast(t('notifications.success.loginSuccess'), 'success');

    if (user.role === 'ADMIN') {
      navigate('/admin/dashboard');
    } else {
      navigate('/');
    }
  };

  const handleSubmit = async (e: React.FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    setIsLoading(true);

    try {
      if (loginMode === 'unknown') {
        throw new Error(
          t('auth.errors.loginIdentifierInvalid', {
            defaultValue: 'Định dạng email hoặc số điện thoại chưa hợp lệ.',
          })
        );
      }

      await handleCredentialLogin();
    } catch (err: any) {
      const message = extractErrorMessage(err);
      const i18nKey = getErrorI18nKey(message);
      const displayMessage = i18nKey ? t(i18nKey) : message;

      showToast(displayMessage, 'error');
      dispatch(loginFailure(message));
    } finally {
      setIsLoading(false);
    }
  };

  const handle2FASubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsLoading(true);

    try {
      const response = await authApi.loginVerifyTwoFactor(twoFactorCode);
      const user = authApi.decodeToken(response.accessToken);
      if (!user) throw new Error('Failed to decode token');

      dispatch(
        loginSuccess({
          user,
          accessToken: response.accessToken,
          expiresAt: response.expiresAt,
          requiresTwoFactor: false,
        })
      );

      authApi.setAccessToken(response.accessToken);
      await syncProfile();
      saveAuth({ user, accessToken: response.accessToken, expiresAt: response.expiresAt });

      showToast(t('notifications.success.loginSuccess'), 'success');

      if (user.role === 'ADMIN') {
        navigate('/admin/dashboard');
      } else {
        navigate('/');
      }
    } catch (err: any) {
      const message = extractErrorMessage(err);
      const i18nKey = getErrorI18nKey(message);
      const displayMessage = i18nKey ? t(i18nKey) : message;

      showToast(displayMessage, 'error');
      dispatch(loginFailure(message));
    } finally {
      setIsLoading(false);
    }
  };

  if (requiresTwoFactor) {
    return (
      <>
        <div className="text-center lg:text-left">
          <h2 className="text-3xl font-bold text-gray-900 dark:text-white mb-2">{t('auth.twoFactor.title')}</h2>
          <p className="text-gray-500 dark:text-gray-400">{t('auth.twoFactor.desc')}</p>
        </div>

        <form className="flex flex-col gap-5" onSubmit={handle2FASubmit}>
          <div className="space-y-2">
            <label className="text-sm font-semibold text-gray-700 dark:text-gray-300" htmlFor="code">
              {t('auth.twoFactor.label')}
            </label>
            <input
              className="w-full px-4 py-3.5 bg-gray-50 dark:bg-gray-800 border border-gray-200 dark:border-gray-700 rounded-lg focus:ring-2 focus:ring-primary/20 focus:border-primary text-gray-900 dark:text-white placeholder-gray-400 text-center text-2xl tracking-widest"
              id="code"
              maxLength={6}
              placeholder="000 000"
              value={twoFactorCode}
              onChange={(e) => setTwoFactorCode(e.target.value.replace(/\D/g, ''))}
              required
              disabled={isLoading}
              autoFocus
            />
          </div>

          <button
            className="w-full py-3.5 px-4 bg-primary hover:bg-primary/90 text-white font-bold rounded-lg shadow-[0_4px_12px_rgba(0,123,128,0.2)] hover:shadow-[0_6px_16px_rgba(0,123,128,0.3)] transition-all transform active:scale-[0.98] disabled:opacity-50 flex items-center justify-center gap-2"
            type="submit"
            disabled={isLoading}
          >
            {isLoading ? t('auth.twoFactor.verifying') : t('auth.twoFactor.verify')}
          </button>

          <button
            type="button"
            onClick={() => window.location.reload()}
            className="text-sm text-gray-500 hover:text-gray-700 dark:text-gray-400 dark:hover:text-gray-300 underline text-center block w-full"
          >
            {t('auth.twoFactor.backToLogin')}
          </button>
        </form>
      </>
    );
  }

  return (
    <>
      <div className="text-center lg:text-left">
        <h2 className="text-3xl font-bold text-gray-900 dark:text-white mb-2">{t('auth.welcomeBack')}</h2>
        <p className="text-gray-500 dark:text-gray-400">{t('auth.enterDetails')}</p>
      </div>

      <form className="flex flex-col gap-5" onSubmit={handleSubmit}>
        <div className="space-y-2">
          <label className="text-sm font-semibold text-gray-700 dark:text-gray-300" htmlFor="identifier">
            {t('auth.loginIdentifier', { defaultValue: 'Email hoặc số điện thoại' })}
          </label>
          <div className="relative">
            <span className="absolute inset-y-0 left-0 pl-4 flex items-center pointer-events-none">
              <span className="material-symbols-outlined text-gray-400 text-[20px]">
                {loginMode === 'phone' ? 'phone' : 'alternate_email'}
              </span>
            </span>
            <input
              className="w-full pl-11 pr-4 py-3.5 bg-gray-50 dark:bg-gray-800 border border-gray-200 dark:border-gray-700 rounded-lg focus:ring-2 focus:ring-primary/20 focus:border-primary text-gray-900 dark:text-white placeholder-gray-400 transition-colors disabled:opacity-50"
              id="identifier"
              name="identifier"
              placeholder={t('auth.loginIdentifierPlaceholder', { defaultValue: 'Nhập email hoặc số điện thoại' })}
              type="text"
              value={identifier}
              onChange={(e) => setIdentifier(e.target.value)}
              required
              disabled={isLoading}
            />
          </div>
        </div>

        <div className="space-y-2">
          <label className="text-sm font-semibold text-gray-700 dark:text-gray-300" htmlFor="password">
            {t('auth.password')}
          </label>
          <div className="relative">
            <span className="absolute inset-y-0 left-0 pl-4 flex items-center pointer-events-none">
              <span className="material-symbols-outlined text-gray-400 text-[20px]">lock</span>
            </span>
            <input
              className="w-full pl-11 pr-12 py-3.5 bg-gray-50 dark:bg-gray-800 border border-gray-200 dark:border-gray-700 rounded-lg focus:ring-2 focus:ring-primary/20 focus:border-primary text-gray-900 dark:text-white placeholder-gray-400 transition-colors disabled:opacity-50"
              id="password"
              name="password"
              placeholder={t('auth.passwordPlaceholder')}
              type={showPassword ? 'text' : 'password'}
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              required
              disabled={isLoading}
            />
            <button
              className="absolute inset-y-0 right-0 pr-4 flex items-center text-gray-400 hover:text-gray-600 dark:hover:text-gray-300 transition-colors"
              type="button"
              onClick={() => setShowPassword(!showPassword)}
              disabled={isLoading}
            >
              <span className="material-symbols-outlined text-[20px]">{showPassword ? 'visibility_off' : 'visibility'}</span>
            </button>
          </div>
        </div>

        <div className="flex items-center justify-between">
          <label className="flex items-center gap-2 cursor-pointer group">
            <input
              className="w-4 h-4 rounded border-gray-300 text-primary focus:ring-primary/20 cursor-pointer disabled:opacity-50"
              type="checkbox"
              checked={rememberMe}
              onChange={(e) => setRememberMe(e.target.checked)}
              disabled={isLoading}
            />
            <span className="text-sm text-gray-600 dark:text-gray-400 group-hover:text-gray-900 dark:group-hover:text-gray-200 transition-colors">
              {t('auth.rememberMe')}
            </span>
          </label>
          <Link className="text-sm font-semibold text-primary hover:text-primary/80 transition-colors" to="/forgot-password">
            {t('auth.forgotPassword')}
          </Link>
        </div>

        <button
          className="w-full py-3.5 px-4 bg-primary hover:bg-primary/90 text-white font-bold rounded-lg shadow-[0_4px_12px_rgba(0,123,128,0.2)] hover:shadow-[0_6px_16px_rgba(0,123,128,0.3)] transition-all transform active:scale-[0.98] disabled:opacity-50 disabled:cursor-not-allowed flex items-center justify-center gap-2"
          type="submit"
          disabled={isLoading}
        >
          {isLoading && <span className="material-symbols-outlined animate-spin text-[20px]">progress_activity</span>}
          <span>{isLoading ? t('auth.loggingIn', { defaultValue: 'Đang đăng nhập...' }) : t('auth.logIn')}</span>
        </button>
      </form>

      <p className="text-center text-sm text-gray-500 dark:text-gray-400">
        {t('auth.dontHaveAccount')}
        <Link className="font-bold text-primary hover:text-primary/80 transition-colors ml-1" to="/register">
          {t('auth.signUp')}
        </Link>
      </p>
    </>
  );
};

export default LoginPage;
