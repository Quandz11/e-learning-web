
import React, { useState } from 'react';
import { useNavigate, Link } from 'react-router-dom';
import { useTranslation } from 'react-i18next';
import { useDispatch } from 'react-redux';
import type { AppDispatch } from '../../store/store';
import { loginStart, loginSuccess, loginFailure } from '../../store/authSlice';
import { authApi } from '../../services/authApi';

const LoginPage = () => {
    const { t } = useTranslation();
    const navigate = useNavigate();
    const dispatch = useDispatch<AppDispatch>();

    const [email, setEmail] = useState('');
    const [password, setPassword] = useState('');
    const [showPassword, setShowPassword] = useState(false);
    const [rememberMe, setRememberMe] = useState(false);
    const [isLoading, setIsLoading] = useState(false);
    const [error, setError] = useState<string | null>(null);

    const handleSubmit = async (e: React.FormEvent<HTMLFormElement>) => {
        e.preventDefault();
        setError(null);
        setIsLoading(true);

        try {
            dispatch(loginStart());

            // Call login API
            const response = await authApi.login({ email, password });

            // Decode token to get user info
            const user = authApi.decodeToken(response.accessToken);
            console.log('Decoded user:', user);

            if (!user) {
                throw new Error('Failed to decode token');
            }

            // Dispatch success action
            dispatch(loginSuccess({
                user,
                accessToken: response.accessToken,
                expiresAt: response.expiresAt,
            }));

            // Store access token in memory only (prevent XSS)
            authApi.setAccessToken(response.accessToken);

            // Redirect based on role
            if (user.role === 'ADMIN') {
                navigate('/admin/dashboard');
            } else {
                navigate('/home'); // or appropriate page for other roles
            }
        } catch (err) {
            const message = err instanceof Error ? err.message : 'Login failed';
            setError(message);
            dispatch(loginFailure(message));
        } finally {
            setIsLoading(false);
        }
    };

    return (
        <>
            <div className="text-center lg:text-left">
                <h2 className="text-3xl font-bold text-gray-900 dark:text-white mb-2">{t('auth.welcomeBack')}</h2>
                <p className="text-gray-500 dark:text-gray-400">{t('auth.enterDetails')}</p>
            </div>

            {/* Error Message */}
            {error && (
                <div className="mb-4 p-3 bg-red-50 dark:bg-red-900/30 border border-red-200 dark:border-red-800 rounded-lg">
                    <p className="text-sm text-red-600 dark:text-red-400">{error}</p>
                </div>
            )}

            <form className="flex flex-col gap-5" onSubmit={handleSubmit}>
                {/* Email Field */}
                <div className="space-y-2">
                    <label className="text-sm font-semibold text-gray-700 dark:text-gray-300" htmlFor="email">{t('auth.email')}</label>
                    <div className="relative">
                        <span className="absolute inset-y-0 left-0 pl-4 flex items-center pointer-events-none">
                            <span className="material-symbols-outlined text-gray-400 text-[20px]">mail</span>
                        </span>
                        <input
                            className="w-full pl-11 pr-4 py-3.5 bg-gray-50 dark:bg-gray-800 border border-gray-200 dark:border-gray-700 rounded-lg focus:ring-2 focus:ring-primary/20 focus:border-primary text-gray-900 dark:text-white placeholder-gray-400 transition-colors disabled:opacity-50"
                            id="email"
                            name="email"
                            placeholder={t('auth.emailPlaceholder')}
                            type="email"
                            value={email}
                            onChange={(e) => setEmail(e.target.value)}
                            required
                            disabled={isLoading}
                        />
                    </div>
                </div>

                {/* Password Field */}
                <div className="space-y-2">
                    <label className="text-sm font-semibold text-gray-700 dark:text-gray-300" htmlFor="password">{t('auth.password')}</label>
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
                            <span className="material-symbols-outlined text-[20px]">
                                {showPassword ? 'visibility_off' : 'visibility'}
                            </span>
                        </button>
                    </div>
                </div>

                {/* Actions */}
                <div className="flex items-center justify-between">
                    <label className="flex items-center gap-2 cursor-pointer group">
                        <input
                            className="w-4 h-4 rounded border-gray-300 text-primary focus:ring-primary/20 cursor-pointer disabled:opacity-50"
                            type="checkbox"
                            checked={rememberMe}
                            onChange={(e) => setRememberMe(e.target.checked)}
                            disabled={isLoading}
                        />
                        <span className="text-sm text-gray-600 dark:text-gray-400 group-hover:text-gray-900 dark:group-hover:text-gray-200 transition-colors">{t('auth.rememberMe')}</span>
                    </label>
                    <Link className="text-sm font-semibold text-primary hover:text-primary/80 transition-colors" to="/forgot-password">{t('auth.forgotPassword')}</Link>
                </div>

                {/* Submit Button */}
                <button
                    className="w-full py-3.5 px-4 bg-primary hover:bg-primary/90 text-white font-bold rounded-lg shadow-[0_4px_12px_rgba(0,123,128,0.2)] hover:shadow-[0_6px_16px_rgba(0,123,128,0.3)] transition-all transform active:scale-[0.98] disabled:opacity-50 disabled:cursor-not-allowed flex items-center justify-center gap-2"
                    type="submit"
                    disabled={isLoading}
                >
                    {isLoading && <span className="material-symbols-outlined animate-spin text-[20px]">progress_activity</span>}
                    <span>{isLoading ? 'Logging in...' : t('auth.logIn')}</span>
                </button>
            </form>

            {/* Footer */}
            <p className="text-center text-sm text-gray-500 dark:text-gray-400">
                {t('auth.dontHaveAccount')}
                <Link className="font-bold text-primary hover:text-primary/80 transition-colors ml-1" to="/register">{t('auth.signUp')}</Link>
            </p>
        </>
    );
};

export default LoginPage;
