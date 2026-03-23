import { useState } from 'react';
import { Link, useNavigate, useSearchParams } from 'react-router-dom';
import { phoneAuthApi } from '../../services/phoneAuthApi';

const PhoneRegisterPage = () => {
  const navigate = useNavigate();
  const [searchParams] = useSearchParams();
  const referralCodeFromUrl = searchParams.get('ref')?.trim().toUpperCase() || '';

  const [fullName, setFullName] = useState('');
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
    if (!fullName.trim()) return 'Vui lòng nhập họ tên.';
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
      await phoneAuthApi.register({
        fullName: fullName.trim(),
        phone: phone.trim(),
        referralCode: referralCodeFromUrl || undefined,
      });

      navigate('/otp-verify-phone', {
        state: {
          phone: phone.trim(),
          mode: 'register',
        },
      });
    } catch (err: any) {
      setError(err?.message || 'Không thể đăng ký bằng số điện thoại.');
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <>
      <div className="text-center sm:text-left space-y-2">
        <h1 className="text-3xl sm:text-4xl font-bold text-gray-900 dark:text-white">
          Đăng ký bằng số điện thoại
        </h1>
        <p className="text-gray-500 dark:text-gray-400 text-base">
          Hệ thống sẽ gửi OTP qua Zalo để xác minh.
        </p>
      </div>

      {error && (
        <div className="bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800 rounded-lg p-4">
          <p className="text-sm text-red-800 dark:text-red-300">{error}</p>
        </div>
      )}

      <form className="space-y-5" onSubmit={handleSubmit}>
        <div className="space-y-1.5">
          <label className="block text-sm font-semibold text-gray-900 dark:text-gray-200">Họ và tên</label>
          <input
            className="w-full h-12 px-4 rounded-lg bg-white dark:bg-gray-800 border border-gray-200 dark:border-gray-700 focus:border-primary focus:ring-1 focus:ring-primary text-gray-900 dark:text-white"
            placeholder="Nhập họ và tên"
            type="text"
            value={fullName}
            onChange={(e) => setFullName(e.target.value)}
            disabled={isLoading}
          />
        </div>

        <div className="space-y-1.5">
          <label className="block text-sm font-semibold text-gray-900 dark:text-gray-200">Số điện thoại</label>
          <input
            className="w-full h-12 px-4 rounded-lg bg-white dark:bg-gray-800 border border-gray-200 dark:border-gray-700 focus:border-primary focus:ring-1 focus:ring-primary text-gray-900 dark:text-white"
            placeholder="Ví dụ: 0987654321"
            type="tel"
            value={phone}
            onChange={(e) => setPhone(e.target.value)}
            disabled={isLoading}
          />
        </div>

        <button
          className="w-full h-12 bg-primary hover:bg-primary/90 text-white font-bold rounded-lg shadow-lg shadow-primary/20 transition-all duration-200 disabled:opacity-50"
          type="submit"
          disabled={isLoading}
        >
          {isLoading ? 'Đang gửi OTP...' : 'Tiếp tục'}
        </button>
      </form>

      <p className="text-center text-sm text-gray-500 dark:text-gray-400 pt-4">
        Đã có tài khoản?{' '}
        <Link className="font-bold text-primary hover:text-primary/80 hover:underline" to="/login-phone">
          Đăng nhập bằng số điện thoại
        </Link>
      </p>
    </>
  );
};

export default PhoneRegisterPage;
