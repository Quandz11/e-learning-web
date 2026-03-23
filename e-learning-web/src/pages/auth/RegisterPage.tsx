import { useMemo, useState } from 'react';
import { Link, useNavigate, useSearchParams } from 'react-router-dom';
import { useTranslation } from 'react-i18next';
import { authApi } from '../../services/authApi';
import { phoneAuthApi } from '../../services/phoneAuthApi';

type OtpChannel = 'email' | 'phone';

const normalizePhone = (value: string): string => {
    const raw = value.trim().replace(/[\s\-\.\(\)]/g, '');
    if (raw.startsWith('+')) return raw.slice(1);
    if (raw.startsWith('0')) return `84${raw.slice(1)}`;
    return raw;
};

const RegisterPage = () => {
    const { t } = useTranslation();
    const navigate = useNavigate();
    const [searchParams] = useSearchParams();
    const referralCodeFromUrl = searchParams.get('ref')?.trim().toUpperCase() || '';

    const [otpChannel, setOtpChannel] = useState<OtpChannel>('email');
    const [formData, setFormData] = useState({
        fullName: '',
        email: '',
        phone: '',
        password: '',
        confirmPassword: '',
    });

    const [showPassword, setShowPassword] = useState(false);
    const [showConfirmPassword, setShowConfirmPassword] = useState(false);
    const [isLoading, setIsLoading] = useState(false);
    const [error, setError] = useState<string | null>(null);
    const [fieldErrors, setFieldErrors] = useState<Record<string, string>>({});

    const isEmailChannel = otpChannel === 'email';

    const validateForm = (): boolean => {
        const errors: Record<string, string> = {};

        if (!formData.fullName.trim()) {
            errors.fullName = t('auth.errors.fullNameRequired');
        }

        if (isEmailChannel) {
            if (!formData.email.trim()) {
                errors.email = t('auth.errors.emailRequired');
            } else if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(formData.email)) {
                errors.email = t('auth.errors.emailInvalid');
            }

            if (!formData.password) {
                errors.password = t('auth.errors.passwordRequired');
            } else if (formData.password.length < 8) {
                errors.password = t('auth.errors.passwordLength');
            }

            if (!formData.confirmPassword) {
                errors.confirmPassword = t('auth.errors.confirmPasswordRequired', { defaultValue: 'Vui lòng xác nhận mật khẩu.' });
            } else if (formData.password !== formData.confirmPassword) {
                errors.confirmPassword = t('auth.errors.confirmPasswordMismatch', { defaultValue: 'Mật khẩu xác nhận không khớp.' });
            }
        } else {
            const normalizedPhone = normalizePhone(formData.phone);
            if (!formData.phone.trim()) {
                errors.phone = t('auth.errors.phoneRequired', { defaultValue: 'Vui lòng nhập số điện thoại.' });
            } else if (!/^\d{9,15}$/.test(normalizedPhone)) {
                errors.phone = t('auth.errors.phoneInvalid', { defaultValue: 'Số điện thoại không đúng định dạng.' });
            }
        }

        setFieldErrors(errors);
        return Object.keys(errors).length === 0;
    };

    const handleChange = (field: string, value: string) => {
        setFormData((prev) => ({ ...prev, [field]: value }));
        if (fieldErrors[field]) {
            setFieldErrors((prev) => ({ ...prev, [field]: '' }));
        }
        if (error) setError(null);
    };

    const submitEmailFlow = async () => {
        await authApi.register({
            email: formData.email.trim().toLowerCase(),
            password: formData.password,
            fullName: formData.fullName.trim(),
            phone: formData.phone.trim() || undefined,
            referralCode: referralCodeFromUrl || undefined,
        });

        navigate('/otp-verify', {
            state: {
                email: formData.email.trim().toLowerCase(),
                fromRegistration: true,
            },
        });
    };

    const submitPhoneFlow = async () => {
        await phoneAuthApi.register({
            fullName: formData.fullName.trim(),
            phone: formData.phone.trim(),
            email: formData.email.trim() || undefined,
            password: formData.password.trim() || undefined,
            referralCode: referralCodeFromUrl || undefined,
        });

        navigate('/otp-verify-phone', {
            state: {
                phone: formData.phone.trim(),
                mode: 'register',
            },
        });
    };

    const handleSubmit = async (e: React.FormEvent) => {
        e.preventDefault();
        if (!validateForm()) return;

        setIsLoading(true);
        setError(null);

        try {
            if (isEmailChannel) {
                await submitEmailFlow();
            } else {
                await submitPhoneFlow();
            }
        } catch (err: any) {
            setError(err?.message || t('auth.errors.registrationFailed'));
        } finally {
            setIsLoading(false);
        }
    };

    const registerTitle = useMemo(
        () => (isEmailChannel
            ? t('auth.registerByEmail', { defaultValue: 'Đăng ký bằng email' })
            : t('auth.registerByPhone', { defaultValue: 'Đăng ký bằng số điện thoại' })),
        [isEmailChannel, t],
    );

    return (
        <>
            <div className="text-center sm:text-left space-y-2">
                <h1 className="text-3xl sm:text-4xl font-bold text-gray-900 dark:text-white">{t('auth.createAccount')}</h1>
                <p className="text-gray-500 dark:text-gray-400 text-base">{t('auth.joinCommunity')}</p>
            </div>

            {error && (
                <div className="bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800 rounded-lg p-4 flex items-start gap-3">
                    <span className="material-symbols-outlined text-red-600 dark:text-red-400 text-xl">error</span>
                    <p className="text-sm text-red-800 dark:text-red-300 flex-1">{error}</p>
                </div>
            )}

            {referralCodeFromUrl && (
                <div className="bg-emerald-50 dark:bg-emerald-900/20 border border-emerald-200 dark:border-emerald-800 rounded-lg p-4 flex items-start gap-3">
                    <span className="material-symbols-outlined text-emerald-600 dark:text-emerald-400 text-xl">celebration</span>
                    <div className="flex-1">
                        <p className="text-sm font-semibold text-emerald-800 dark:text-emerald-200">{t('auth.referralDetected', { defaultValue: 'Bạn đang đăng ký từ link mời' })}</p>
                        <p className="text-xs text-emerald-700 dark:text-emerald-300 mt-1">{t('auth.referralCodeLabel', { defaultValue: 'Mã giới thiệu' })}: {referralCodeFromUrl}</p>
                    </div>
                </div>
            )}

            <div className="space-y-2">
                <p className="text-sm font-semibold text-gray-900 dark:text-gray-200">{t('auth.otpChannelTitle', { defaultValue: 'Chọn phương thức gửi OTP' })}</p>
                <div className="grid grid-cols-2 gap-3">
                    <button
                        type="button"
                        onClick={() => setOtpChannel('email')}
                        className={`h-11 rounded-lg border text-sm font-semibold transition-colors ${otpChannel === 'email' ? 'border-primary bg-primary text-white' : 'border-gray-200 bg-white text-gray-700 dark:border-gray-700 dark:bg-gray-800 dark:text-gray-200'}`}
                    >
                        {t('auth.otpViaEmail', { defaultValue: 'Qua email' })}
                    </button>
                    <button
                        type="button"
                        onClick={() => setOtpChannel('phone')}
                        className={`h-11 rounded-lg border text-sm font-semibold transition-colors ${otpChannel === 'phone' ? 'border-primary bg-primary text-white' : 'border-gray-200 bg-white text-gray-700 dark:border-gray-700 dark:bg-gray-800 dark:text-gray-200'}`}
                    >
                        {t('auth.otpViaPhone', { defaultValue: 'Qua số điện thoại' })}
                    </button>
                </div>
                <p className="text-xs text-gray-500 dark:text-gray-400">{registerTitle}</p>
            </div>

            <form className="space-y-5" onSubmit={handleSubmit}>
                <div className="space-y-1.5">
                    <label className="block text-sm font-semibold text-gray-900 dark:text-gray-200">{t('auth.fullName')}</label>
                    <input
                        className={`w-full h-12 px-4 rounded-lg bg-white dark:bg-gray-800 border ${fieldErrors.fullName ? 'border-red-500 dark:border-red-500' : 'border-gray-200 dark:border-gray-700'} focus:border-primary focus:ring-1 focus:ring-primary text-gray-900 dark:text-white placeholder-gray-400 transition-colors`}
                        placeholder={t('auth.fullNamePlaceholder')}
                        type="text"
                        value={formData.fullName}
                        onChange={(e) => handleChange('fullName', e.target.value)}
                        disabled={isLoading}
                    />
                    {fieldErrors.fullName && <p className="text-xs text-red-600 dark:text-red-400">{fieldErrors.fullName}</p>}
                </div>

                <div className="space-y-1.5">
                    <label className="block text-sm font-semibold text-gray-900 dark:text-gray-200">{t('auth.email')}</label>
                    <input
                        className={`w-full h-12 px-4 rounded-lg bg-white dark:bg-gray-800 border ${fieldErrors.email ? 'border-red-500 dark:border-red-500' : 'border-gray-200 dark:border-gray-700'} focus:border-primary focus:ring-1 focus:ring-primary text-gray-900 dark:text-white placeholder-gray-400 transition-colors`}
                        placeholder={t('auth.emailPlaceholder')}
                        type="email"
                        value={formData.email}
                        onChange={(e) => handleChange('email', e.target.value)}
                        disabled={isLoading}
                    />
                    {fieldErrors.email && <p className="text-xs text-red-600 dark:text-red-400">{fieldErrors.email}</p>}
                </div>

                <div className="space-y-1.5">
                    <label className="block text-sm font-semibold text-gray-900 dark:text-gray-200">{t('auth.phone')}</label>
                    <input
                        className={`w-full h-12 px-4 rounded-lg bg-white dark:bg-gray-800 border ${fieldErrors.phone ? 'border-red-500 dark:border-red-500' : 'border-gray-200 dark:border-gray-700'} focus:border-primary focus:ring-1 focus:ring-primary text-gray-900 dark:text-white placeholder-gray-400 transition-colors`}
                        placeholder={t('auth.phonePlaceholder')}
                        type="tel"
                        value={formData.phone}
                        onChange={(e) => handleChange('phone', e.target.value)}
                        disabled={isLoading}
                    />
                    {fieldErrors.phone && <p className="text-xs text-red-600 dark:text-red-400">{fieldErrors.phone}</p>}
                </div>

                {isEmailChannel && (
                    <>
                        <div className="space-y-1.5">
                            <label className="block text-sm font-semibold text-gray-900 dark:text-gray-200">{t('auth.password')}</label>
                            <div className="relative">
                                <input
                                    className={`w-full h-12 px-4 rounded-lg bg-white dark:bg-gray-800 border ${fieldErrors.password ? 'border-red-500 dark:border-red-500' : 'border-gray-200 dark:border-gray-700'} focus:border-primary focus:ring-1 focus:ring-primary text-gray-900 dark:text-white placeholder-gray-400 transition-colors`}
                                    placeholder={t('auth.createPassword')}
                                    type={showPassword ? 'text' : 'password'}
                                    value={formData.password}
                                    onChange={(e) => handleChange('password', e.target.value)}
                                    disabled={isLoading}
                                />
                                <button
                                    className="absolute inset-y-0 right-4 flex items-center text-gray-400 hover:text-gray-600 dark:hover:text-gray-200 transition-colors"
                                    type="button"
                                    onClick={() => setShowPassword(!showPassword)}
                                >
                                    <span className="material-symbols-outlined text-[20px]">{showPassword ? 'visibility_off' : 'visibility'}</span>
                                </button>
                            </div>
                            {fieldErrors.password ? (
                                <p className="text-xs text-red-600 dark:text-red-400">{fieldErrors.password}</p>
                            ) : (
                                <p className="text-xs text-gray-500 dark:text-gray-400 mt-1">{t('auth.passwordHint')}</p>
                            )}
                        </div>

                        <div className="space-y-1.5">
                            <label className="block text-sm font-semibold text-gray-900 dark:text-gray-200">{t('auth.confirmPassword', { defaultValue: 'Xác nhận mật khẩu' })}</label>
                            <div className="relative">
                                <input
                                    className={`w-full h-12 px-4 rounded-lg bg-white dark:bg-gray-800 border ${fieldErrors.confirmPassword ? 'border-red-500 dark:border-red-500' : 'border-gray-200 dark:border-gray-700'} focus:border-primary focus:ring-1 focus:ring-primary text-gray-900 dark:text-white placeholder-gray-400 transition-colors`}
                                    placeholder={t('auth.confirmPasswordPlaceholder', { defaultValue: 'Nhập lại mật khẩu' })}
                                    type={showConfirmPassword ? 'text' : 'password'}
                                    value={formData.confirmPassword}
                                    onChange={(e) => handleChange('confirmPassword', e.target.value)}
                                    disabled={isLoading}
                                />
                                <button
                                    className="absolute inset-y-0 right-4 flex items-center text-gray-400 hover:text-gray-600 dark:hover:text-gray-200 transition-colors"
                                    type="button"
                                    onClick={() => setShowConfirmPassword(!showConfirmPassword)}
                                >
                                    <span className="material-symbols-outlined text-[20px]">{showConfirmPassword ? 'visibility_off' : 'visibility'}</span>
                                </button>
                            </div>
                            {fieldErrors.confirmPassword && <p className="text-xs text-red-600 dark:text-red-400">{fieldErrors.confirmPassword}</p>}
                        </div>
                    </>
                )}

                <button
                    className="w-full h-12 bg-primary hover:bg-primary/90 text-white font-bold rounded-lg shadow-lg shadow-primary/20 transition-all duration-200 flex items-center justify-center gap-2 mt-4 disabled:opacity-50 disabled:cursor-not-allowed"
                    type="submit"
                    disabled={isLoading}
                >
                    {isLoading ? (
                        <>
                            <div className="animate-spin rounded-full h-5 w-5 border-b-2 border-white"></div>
                            <span>{t('auth.sendingOtp', { defaultValue: 'Đang gửi OTP...' })}</span>
                        </>
                    ) : (
                        <>
                            <span>{t('auth.createAccount')}</span>
                            <span className="material-symbols-outlined text-[20px]">arrow_forward</span>
                        </>
                    )}
                </button>
            </form>

            <p className="text-center text-sm text-gray-500 dark:text-gray-400 pt-4">
                {t('auth.alreadyHaveAccount')}
                <Link className="font-bold text-primary hover:text-primary/80 hover:underline ml-1" to="/login">{t('auth.logIn')}</Link>
            </p>
        </>
    );
};

export default RegisterPage;
