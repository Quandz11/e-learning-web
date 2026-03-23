import { Link, useNavigate } from 'react-router-dom';
import { useTranslation } from 'react-i18next';
import { useState } from 'react';
import { phoneAuthApi } from '../../services/phoneAuthApi';
import { useToast } from '../../contexts/ToastContext';

const ForgotPasswordPage = () => {
  const { t } = useTranslation();
  const navigate = useNavigate();
  const { showToast } = useToast();

  const [phone, setPhone] = useState('');
  const [isLoading, setIsLoading] = useState(false);

  const handleSubmit = async (e: React.FormEvent<HTMLFormElement>) => {
    e.preventDefault();

    if (!phone.trim()) {
      showToast(t('auth.errors.phoneRequired', { defaultValue: 'Vui lòng nhập số điện thoại.' }), 'error');
      return;
    }

    setIsLoading(true);
    try {
      await phoneAuthApi.requestForgotPasswordOtp(phone.trim());
      showToast(
        t('auth.phoneOtpSent', { defaultValue: 'Đã gửi OTP qua Zalo. Vui lòng kiểm tra tin nhắn.' }),
        'success'
      );
      navigate('/otp-verify-phone', {
        state: {
          phone: phone.trim(),
          mode: 'forgotPassword',
        },
      });
    } catch (error: any) {
      showToast(error?.message || t('auth.errors.forgotPasswordRequestFailed', { defaultValue: 'Không thể gửi OTP lúc này.' }), 'error');
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <div className="w-full h-full flex flex-col justify-center">
      <div className="mb-8 flex justify-center">
        <div className="w-16 h-16 rounded-full bg-primary/10 dark:bg-primary/20 flex items-center justify-center text-primary dark:text-primary-light">
          <span className="material-symbols-outlined text-[32px]">lock_reset</span>
        </div>
      </div>

      <div className="text-center mb-8 space-y-3">
        <h1 className="text-3xl font-bold tracking-tight text-gray-900 dark:text-white">{t('auth.forgotPasswordTitle')}</h1>
        <p className="text-gray-500 dark:text-gray-400 text-base leading-relaxed px-4">
          {t('auth.forgotPasswordDesc', {
            defaultValue: 'Nhập số điện thoại để nhận OTP qua Zalo và đặt lại mật khẩu.',
          })}
        </p>
      </div>

      <form className="space-y-6" onSubmit={handleSubmit}>
        <div className="space-y-2">
          <label className="block text-sm font-semibold text-gray-900 dark:text-white ml-1" htmlFor="phone">
            {t('auth.phone', { defaultValue: 'Số điện thoại' })}
          </label>
          <div className="relative group">
            <div className="absolute inset-y-0 left-0 pl-4 flex items-center pointer-events-none">
              <span className="material-symbols-outlined text-gray-400 group-focus-within:text-primary transition-colors">
                phone
              </span>
            </div>
            <input
              className="block w-full pl-11 pr-4 py-3.5 bg-background-light dark:bg-gray-800 border border-gray-200 dark:border-gray-700 rounded-lg text-gray-900 dark:text-white placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-primary/20 focus:border-primary transition-all text-base"
              id="phone"
              name="phone"
              placeholder="0901234567"
              required
              type="tel"
              value={phone}
              onChange={(e) => setPhone(e.target.value)}
              disabled={isLoading}
            />
          </div>
        </div>

        <button
          className="w-full bg-primary hover:bg-primary/90 text-white font-bold text-base py-3.5 px-6 rounded-lg shadow-sm hover:shadow-md transition-all duration-200 flex items-center justify-center gap-2 group disabled:opacity-60"
          disabled={isLoading}
          type="submit"
        >
          <span>
            {isLoading
              ? t('auth.sendingOtp', { defaultValue: 'Đang gửi OTP...' })
              : t('auth.sendResetLink', { defaultValue: 'Gửi OTP đặt lại mật khẩu' })}
          </span>
          <span className="material-symbols-outlined text-lg group-hover:translate-x-1 transition-transform">arrow_forward</span>
        </button>
      </form>

      <div className="mt-8 text-center">
        <Link
          className="inline-flex items-center gap-2 text-sm font-semibold text-gray-500 dark:text-gray-400 hover:text-primary dark:hover:text-white transition-colors group"
          to="/login"
        >
          <span className="material-symbols-outlined text-lg group-hover:-translate-x-1 transition-transform">arrow_back</span>
          {t('auth.backToLogin')}
        </Link>
      </div>
    </div>
  );
};

export default ForgotPasswordPage;
