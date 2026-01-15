
import { Link } from 'react-router-dom';
import { useTranslation } from 'react-i18next';

const LoginPage = () => {
    const { t } = useTranslation();

    return (
        <>
            <div className="text-center lg:text-left">
                <h2 className="text-3xl font-bold text-gray-900 dark:text-white mb-2">{t('auth.welcomeBack')}</h2>
                <p className="text-gray-500 dark:text-gray-400">{t('auth.enterDetails')}</p>
            </div>
            <form className="flex flex-col gap-5" onSubmit={(e) => e.preventDefault()}>
                {/* Email Field */}
                <div className="space-y-2">
                    <label className="text-sm font-semibold text-gray-700 dark:text-gray-300" htmlFor="email">{t('auth.email')}</label>
                    <div className="relative">
                        <span className="absolute inset-y-0 left-0 pl-4 flex items-center pointer-events-none">
                            <span className="material-symbols-outlined text-gray-400 text-[20px]">mail</span>
                        </span>
                        <input className="w-full pl-11 pr-4 py-3.5 bg-gray-50 dark:bg-gray-800 border border-gray-200 dark:border-gray-700 rounded-lg focus:ring-2 focus:ring-primary/20 focus:border-primary text-gray-900 dark:text-white placeholder-gray-400 transition-colors" id="email" name="email" placeholder={t('auth.emailPlaceholder')} required type="email" />
                    </div>
                </div>
                {/* Password Field */}
                <div className="space-y-2">
                    <label className="text-sm font-semibold text-gray-700 dark:text-gray-300" htmlFor="password">{t('auth.password')}</label>
                    <div className="relative">
                        <span className="absolute inset-y-0 left-0 pl-4 flex items-center pointer-events-none">
                            <span className="material-symbols-outlined text-gray-400 text-[20px]">lock</span>
                        </span>
                        <input className="w-full pl-11 pr-12 py-3.5 bg-gray-50 dark:bg-gray-800 border border-gray-200 dark:border-gray-700 rounded-lg focus:ring-2 focus:ring-primary/20 focus:border-primary text-gray-900 dark:text-white placeholder-gray-400 transition-colors" id="password" name="password" placeholder={t('auth.passwordPlaceholder')} required type="password" />
                        <button className="absolute inset-y-0 right-0 pr-4 flex items-center text-gray-400 hover:text-gray-600 dark:hover:text-gray-300" type="button">
                            <span className="material-symbols-outlined text-[20px]">visibility</span>
                        </button>
                    </div>
                </div>
                {/* Actions */}
                <div className="flex items-center justify-between">
                    <label className="flex items-center gap-2 cursor-pointer group">
                        <input className="w-4 h-4 rounded border-gray-300 text-primary focus:ring-primary/20 cursor-pointer" type="checkbox" />
                        <span className="text-sm text-gray-600 dark:text-gray-400 group-hover:text-gray-900 dark:group-hover:text-gray-200 transition-colors">{t('auth.rememberMe')}</span>
                    </label>
                    <Link className="text-sm font-semibold text-primary hover:text-primary/80 transition-colors" to="/forgot-password">{t('auth.forgotPassword')}</Link>
                </div>
                {/* Submit Button */}
                <button className="w-full py-3.5 px-4 bg-primary hover:bg-primary/90 text-white font-bold rounded-lg shadow-[0_4px_12px_rgba(0,123,128,0.2)] hover:shadow-[0_6px_16px_rgba(0,123,128,0.3)] transition-all transform active:scale-[0.98]" type="submit">
                    {t('auth.logIn')}
                </button>
            </form>
            {/* Divider */}
            <div className="relative flex items-center py-2">
                <div className="flex-grow border-t border-gray-200 dark:border-gray-700"></div>
                <span className="flex-shrink-0 mx-4 text-sm text-gray-400">{t('auth.orLogInWith')}</span>
                <div className="flex-grow border-t border-gray-200 dark:border-gray-700"></div>
            </div>
            {/* Social Login */}
            <div className="grid grid-cols-2 gap-4">
                <button className="flex items-center justify-center gap-2 px-4 py-3 bg-white dark:bg-gray-800 border border-gray-200 dark:border-gray-700 rounded-lg hover:bg-gray-50 dark:hover:bg-gray-700 transition-colors group">
                    <svg className="w-5 h-5" fill="none" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
                        <path d="M23.766 12.2764C23.766 11.4607 23.6999 10.6406 23.5588 9.83807H12.24V14.4591H18.7217C18.4528 15.9494 17.5885 17.2678 16.323 18.1056V21.1039H20.19C22.4608 19.0139 23.766 15.9274 23.766 12.2764Z" fill="#4285F4"></path>
                        <path d="M12.24 24.0008C15.4765 24.0008 18.2059 22.9382 20.1945 21.1039L16.3275 18.1055C15.2517 18.8375 13.8627 19.252 12.2445 19.252C9.11388 19.252 6.45946 17.1399 5.50705 14.3003H1.5166V17.3912C3.55371 21.4434 7.7029 24.0008 12.24 24.0008Z" fill="#34A853"></path>
                        <path d="M5.50253 14.3003C5.00236 12.8099 5.00236 11.1961 5.50253 9.70575V6.61481H1.5166C-0.18551 10.0056 -0.18551 14.0004 1.5166 17.3912L5.50253 14.3003Z" fill="#FBBC05"></path>
                        <path d="M12.24 4.74966C13.9509 4.7232 15.6044 5.36697 16.8434 6.54867L20.2695 3.12262C18.1001 1.0855 15.2208 -0.034466 12.24 0.000808666C7.7029 0.000808666 3.55371 2.55822 1.5166 6.61481L5.50253 9.70575C6.45064 6.86173 9.10947 4.74966 12.24 4.74966Z" fill="#EA4335"></path>
                    </svg>
                    <span className="text-sm font-semibold text-gray-700 dark:text-gray-200 group-hover:text-gray-900 dark:group-hover:text-white">Google</span>
                </button>
                <button className="flex items-center justify-center gap-2 px-4 py-3 bg-white dark:bg-gray-800 border border-gray-200 dark:border-gray-700 rounded-lg hover:bg-gray-50 dark:hover:bg-gray-700 transition-colors group">
                    <svg className="w-5 h-5 text-[#1877F2]" fill="currentColor" viewBox="0 0 24 24">
                        <path d="M24 12.073c0-6.627-5.373-12-12-12s-12 5.373-12 12c0 5.99 4.388 10.954 10.125 11.854v-8.385H7.078v-3.47h3.047V9.43c0-3.007 1.791-4.669 4.533-4.669 1.312 0 2.686.235 2.686.235v2.953H15.83c-1.491 0-1.956.925-1.956 1.874v2.25h3.328l-.532 3.47h-2.796v8.385C19.612 23.027 24 18.062 24 12.073z"></path>
                    </svg>
                    <span className="text-sm font-semibold text-gray-700 dark:text-gray-200 group-hover:text-gray-900 dark:group-hover:text-white">Facebook</span>
                </button>
            </div>
            {/* Footer */}
            <p className="text-center text-sm text-gray-500 dark:text-gray-400">
                {t('auth.dontHaveAccount')}
                <Link className="font-bold text-primary hover:text-primary/80 transition-colors ml-1" to="/register">{t('auth.signUp')}</Link>
            </p>
        </>
    );
};


export default LoginPage;
