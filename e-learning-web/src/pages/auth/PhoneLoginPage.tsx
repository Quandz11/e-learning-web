import { useState } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { phoneAuthApi } from '../../services/phoneAuthApi';

const PhoneLoginPage = () => {
  const navigate = useNavigate();

  const [phone, setPhone] = useState('');
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const normalizePhone = (value: string): string => {
    const raw = value.trim().replace(/[\s\-\.\(\)]/g, '');
    if (raw.startsWith('+')) return raw.slice(1);
    if (raw.startsWith('0')) return `84${raw.slice(1)}`;
    return raw;
  };

  const validate = (): string | null => {
    if (!phone.trim()) return 'Vui lòng nhập số điện thoại.';

    const normalized = normalizePhone(phone);
    if (!/^\d{9,15}$/.test(normalized)) {
      return 'Số điện thoại không đúng định dạng.';
    }

    return null;
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    const validationError = validate();
    if (validationError) {
      setError(validationError);
      return;
    }

    setIsLoading(true);
    setError(null);

    try {
      await phoneAuthApi.requestLoginOtp(phone.trim());
      navigate('/otp-verify-phone', {
        state: {
          phone: phone.trim(),
          mode: 'login',
        },
      });
    } catch (err: any) {
      setError(err?.message || 'Không thể gửi OTP đăng nhập.');
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <>
      <div className="text-center lg:text-left">
        <h2 className="text-3xl font-bold text-gray-900 dark:text-white mb-2">Đăng nhập bằng số điện thoại</h2>
        <p className="text-gray-500 dark:text-gray-400">Nhập số điện thoại để nhận OTP qua Zalo.</p>
      </div>

      {error && (
        <div className="bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800 rounded-lg p-4">
          <p className="text-sm text-red-800 dark:text-red-300">{error}</p>
        </div>
      )}

      <form className="flex flex-col gap-5" onSubmit={handleSubmit}>
        <div className="space-y-2">
          <label className="text-sm font-semibold text-gray-700 dark:text-gray-300" htmlFor="phone">
            Số điện thoại
          </label>
          <input
            className="w-full px-4 py-3.5 bg-gray-50 dark:bg-gray-800 border border-gray-200 dark:border-gray-700 rounded-lg focus:ring-2 focus:ring-primary/20 focus:border-primary text-gray-900 dark:text-white placeholder-gray-400 transition-colors disabled:opacity-50"
            id="phone"
            name="phone"
            placeholder="Ví dụ: 0987654321"
            type="tel"
            value={phone}
            onChange={(e) => setPhone(e.target.value)}
            required
            disabled={isLoading}
          />
        </div>

        <button
          className="w-full py-3.5 px-4 bg-primary hover:bg-primary/90 text-white font-bold rounded-lg shadow-[0_4px_12px_rgba(0,123,128,0.2)] transition-all disabled:opacity-50 disabled:cursor-not-allowed"
          type="submit"
          disabled={isLoading}
        >
          {isLoading ? 'Đang gửi OTP...' : 'Nhận OTP'}
        </button>
      </form>

      <p className="text-center text-sm text-gray-500 dark:text-gray-400">
        Chưa có tài khoản?{' '}
        <Link className="font-bold text-primary hover:text-primary/80 transition-colors" to="/register-phone">
          Đăng ký bằng số điện thoại
        </Link>
      </p>
    </>
  );
};

export default PhoneLoginPage;
