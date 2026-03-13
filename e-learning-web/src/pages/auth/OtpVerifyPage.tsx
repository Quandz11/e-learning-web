import React, { useRef, useState, useEffect } from 'react';
import { Link, useLocation, useNavigate } from 'react-router-dom';
import { useTranslation } from 'react-i18next';
import { useDispatch } from 'react-redux';
import type { AppDispatch } from '../../store/store';
import { loginSuccess, updateUser } from '../../store/authSlice';
import { authApi } from '../../services/authApi';
import { profileApi } from '../../services/profileApi';
import { saveAuth } from '../../services/authStorage';

const OtpVerifyPage = () => {
    const { t } = useTranslation();
    const location = useLocation();
    const navigate = useNavigate();
    const dispatch = useDispatch<AppDispatch>();

    // Get email from navigation state
    const email = location.state?.email;

    const [otp, setOtp] = useState(['', '', '', '', '', '']);
    const inputRefs = useRef<(HTMLInputElement | null)[]>([]);

    // UI state
    const [isLoading, setIsLoading] = useState(false);
    const [error, setError] = useState<string | null>(null);
    const [successMessage, setSuccessMessage] = useState<string | null>(null);
    const [countdown, setCountdown] = useState(600); // 10 minutes in seconds
    const [canResend, setCanResend] = useState(false);
    const syncProfile = async () => {
        try {
            const profile = await profileApi.getMyProfile();
            dispatch(updateUser({
                email: profile.email,
                fullName: profile.fullName || '',
                phone: profile.phone,
                avatarUrl: profile.avatarUrl,
                role: profile.role,
                id: profile.id,
            }));
        } catch (err) {
            console.warn('Failed to load profile for avatar', err);
        }
    };

    // Redirect if no email provided
    useEffect(() => {
        if (!email) {
            navigate('/register', { replace: true });
        }
    }, [email, navigate]);

    // Focus first input on mount
    useEffect(() => {
        if (inputRefs.current[0]) {
            inputRefs.current[0].focus();
        }
    }, []);

    // Countdown timer
    useEffect(() => {
        if (countdown <= 0) {
            setCanResend(true);
            return;
        }

        const timer = setInterval(() => {
            setCountdown(prev => {
                if (prev <= 1) {
                    setCanResend(true);
                    return 0;
                }
                return prev - 1;
            });
        }, 1000);

        return () => clearInterval(timer);
    }, [countdown]);

    // Format countdown as MM:SS
    const formatCountdown = (): string => {
        const minutes = Math.floor(countdown / 60);
        const seconds = countdown % 60;
        return `${String(minutes).padStart(2, '0')}:${String(seconds).padStart(2, '0')}`;
    };

    const handleChange = (index: number, value: string) => {
        if (!/^\d*$/.test(value)) return;

        const newOtp = [...otp];
        newOtp[index] = value;
        setOtp(newOtp);

        if (value && index < 5) {
            inputRefs.current[index + 1]?.focus();
        }

        // Clear error when user types
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

        // Only allow 6-digit numbers
        if (!/^\d{6}$/.test(pastedData)) return;

        const digits = pastedData.split('');
        setOtp(digits);

        // Focus last input
        inputRefs.current[5]?.focus();
    };

    const handleVerifyOtp = async (e: React.FormEvent) => {
        e.preventDefault();

        const otpCode = otp.join('');

        if (otpCode.length !== 6) {
            setError(t('auth.errors.otpInvalid') || 'Please enter a 6-digit code');
            return;
        }

        setIsLoading(true);
        setError(null);

        try {
            const response = await authApi.verifyOtp(email!, otpCode);

            // Decode token to get user info
            const user = authApi.decodeToken(response.accessToken);

            if (user) {
                // Store access token in memory
                authApi.setAccessToken(response.accessToken);

                // Update Redux state - user is now logged in
                dispatch(loginSuccess({
                    user,
                    accessToken: response.accessToken,
                    expiresAt: response.expiresAt,
                }));

                await syncProfile();

                saveAuth({ user, accessToken: response.accessToken, expiresAt: response.expiresAt });

                // Navigate to appropriate page based on role
                const role = user.role?.toUpperCase();
                navigate(role === 'ADMIN' ? '/admin/dashboard' : '/home', { replace: true });
            }
        } catch (err: any) {
            console.error('OTP verification error:', err);
            setError(err.message || t('auth.errors.otpVerificationFailed') || 'Invalid or expired OTP code');
        } finally {
            setIsLoading(false);
        }
    };

    const handleResendOtp = async () => {
        if (!canResend) return;

        setIsLoading(true);
        setError(null);
        setSuccessMessage(null);

        try {
            await authApi.resendOtp(email!);

            // Reset countdown and OTP inputs
            setCountdown(600);
            setCanResend(false);
            setOtp(['', '', '', '', '', '']);
            inputRefs.current[0]?.focus();

            setSuccessMessage(t('auth.otpResent') || 'A new verification code has been sent to your email');

            // Clear success message after 3 seconds
            setTimeout(() => setSuccessMessage(null), 3000);
        } catch (err: any) {
            console.error('Resend OTP error:', err);
            setError(err.message || t('auth.errors.resendFailed') || 'Failed to resend code. Please try again.');
        } finally {
            setIsLoading(false);
        }
    };

    // Don't render if no email (will redirect)
    if (!email) {
        return null;
    }

    // Mask email for display (show first 3 chars and domain)
    const maskedEmail = email.replace(/(.{3})(.*)(@.+)/, '$1***$3');

    return (
        <div className="w-full h-full flex flex-col items-center justify-center">
            {/* Header Section */}
            <div className="text-center flex flex-col items-center gap-2 mb-8">
                <div className="w-12 h-12 rounded-full bg-primary/10 flex items-center justify-center mb-2">
                    <span className="material-symbols-outlined text-primary text-2xl">lock_person</span>
                </div>
                <h1 className="text-2xl sm:text-3xl font-bold text-gray-900 dark:text-white tracking-tight">{t('auth.verifyAccount')}</h1>
                <p className="text-gray-500 dark:text-gray-400 text-base leading-relaxed max-w-sm">
                    {t('auth.codeSentTo')} <span className="font-medium text-gray-900 dark:text-gray-200">{maskedEmail}</span>.
                </p>
            </div>

            {/* Error Alert */}
            {error && (
                <div className="bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800 rounded-lg p-4 flex items-start gap-3 w-full max-w-[400px] mb-4">
                    <span className="material-symbols-outlined text-red-600 dark:text-red-400 text-xl">error</span>
                    <p className="text-sm text-red-800 dark:text-red-300 flex-1">{error}</p>
                    <button
                        onClick={() => setError(null)}
                        className="text-red-600 dark:text-red-400 hover:text-red-800 dark:hover:text-red-200"
                    >
                        <span className="material-symbols-outlined text-xl">close</span>
                    </button>
                </div>
            )}

            {/* Success Alert */}
            {successMessage && (
                <div className="bg-green-50 dark:bg-green-900/20 border border-green-200 dark:border-green-800 rounded-lg p-4 flex items-start gap-3 w-full max-w-[400px] mb-4">
                    <span className="material-symbols-outlined text-green-600 dark:text-green-400 text-xl">check_circle</span>
                    <p className="text-sm text-green-800 dark:text-green-300 flex-1">{successMessage}</p>
                </div>
            )}

            {/* Verification Form */}
            <form className="flex flex-col gap-8 w-full max-w-[400px]" onSubmit={handleVerifyOtp}>
                {/* OTP Inputs */}
                <div className="flex justify-center gap-2 sm:gap-3 w-full" onPaste={handlePaste}>
                    {otp.map((digit, index) => (
                        <React.Fragment key={index}>
                            <input
                                ref={(el: HTMLInputElement | null) => { inputRefs.current[index] = el; }}
                                autoFocus={index === 0}
                                className="w-10 h-12 sm:w-12 sm:h-14 text-center text-xl sm:text-2xl font-bold text-gray-900 dark:text-white bg-white dark:bg-gray-800 border border-gray-200 dark:border-gray-600 rounded-lg focus:outline-none focus:border-primary focus:ring-1 focus:ring-primary transition-all duration-200 selection:bg-primary/20 placeholder-transparent disabled:opacity-50 disabled:cursor-not-allowed"
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

                {/* Timer & Resend */}
                <div className="flex flex-col items-center gap-2">
                    <div className={`flex items-center gap-2 text-sm font-medium py-2 px-4 rounded-full border ${countdown > 0 ? 'text-gray-500 dark:text-gray-400 bg-background-light dark:bg-gray-800/50 border-transparent dark:border-gray-700' : 'text-red-600 dark:text-red-400 bg-red-50 dark:bg-red-900/20 border-red-200 dark:border-red-800'}`}>
                        <span className="material-symbols-outlined text-lg" style={{ fontSize: '18px' }}>timer</span>
                        <span className="font-mono">{formatCountdown()}</span>
                    </div>
                    <div className="text-sm">
                        <span className="text-gray-400 dark:text-gray-500">{t('auth.didntReceiveCode')}</span>
                        <button
                            className="font-semibold text-primary dark:text-primary-400 hover:text-primary/80 dark:hover:text-primary-300 ml-1 transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
                            type="button"
                            onClick={handleResendOtp}
                            disabled={!canResend || isLoading}
                        >
                            {t('auth.resend')}
                        </button>
                    </div>
                </div>

                {/* Actions */}
                <div className="flex flex-col gap-4 mt-2">
                    <button
                        className="w-full bg-primary hover:bg-primary/90 text-white font-medium text-base h-12 rounded-lg shadow-sm transition-all duration-200 flex items-center justify-center gap-2 group disabled:opacity-50 disabled:cursor-not-allowed"
                        type="submit"
                        disabled={isLoading || otp.join('').length !== 6}
                    >
                        {isLoading ? (
                            <>
                                <div className="animate-spin rounded-full h-5 w-5 border-b-2 border-white"></div>
                                <span>{t('auth.verifying') || 'Verifying...'}</span>
                            </>
                        ) : (
                            <>
                                <span>{t('auth.verifyAndProceed')}</span>
                                <span className="material-symbols-outlined text-lg group-hover:translate-x-0.5 transition-transform">arrow_forward</span>
                            </>
                        )}
                    </button>
                    <Link
                        className="text-sm text-center text-gray-500 hover:text-gray-900 dark:text-gray-400 dark:hover:text-gray-200 transition-colors flex items-center justify-center gap-1 group"
                        to="/login"
                    >
                        <span className="material-symbols-outlined text-base group-hover:-translate-x-0.5 transition-transform">arrow_back</span>
                        {t('auth.backToLogin')}
                    </Link>
                </div>
            </form>

            {/* Footer Info */}
            <div className="mt-8 text-xs text-gray-400 dark:text-gray-600 text-center w-full px-4">
                <p>© 2024 NhinAnChuaLanh. Secure Verification System.</p>
            </div>
        </div>
    );
};

export default OtpVerifyPage;
