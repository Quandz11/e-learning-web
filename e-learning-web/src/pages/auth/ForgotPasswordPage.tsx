
import { Link } from 'react-router-dom';
import { useTranslation } from 'react-i18next';

const ForgotPasswordPage = () => {
    const { t } = useTranslation();

    return (
        <div className="w-full h-full flex flex-col justify-center">
            {/* Icon Header */}
            <div className="mb-8 flex justify-center">
                <div className="w-16 h-16 rounded-full bg-primary/10 dark:bg-primary/20 flex items-center justify-center text-primary dark:text-primary-light">
                    <span className="material-symbols-outlined text-[32px]">lock_reset</span>
                </div>
            </div>
            {/* Text Content */}
            <div className="text-center mb-8 space-y-3">
                <h1 className="text-3xl font-bold tracking-tight text-gray-900 dark:text-white">
                    {t('auth.forgotPasswordTitle')}
                </h1>
                <p className="text-gray-500 dark:text-gray-400 text-base leading-relaxed px-4">
                    {t('auth.forgotPasswordDesc')}
                </p>
            </div>
            {/* Form */}
            <form className="space-y-6" onSubmit={(e) => e.preventDefault()}>
                <div className="space-y-2">
                    <label className="block text-sm font-semibold text-gray-900 dark:text-white ml-1" htmlFor="email">
                        {t('auth.email')}
                    </label>
                    <div className="relative group">
                        <div className="absolute inset-y-0 left-0 pl-4 flex items-center pointer-events-none">
                            <span className="material-symbols-outlined text-gray-400 group-focus-within:text-primary transition-colors">mail</span>
                        </div>
                        <input className="block w-full pl-11 pr-4 py-3.5 bg-background-light dark:bg-gray-800 border border-gray-200 dark:border-gray-700 rounded-lg text-gray-900 dark:text-white placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-primary/20 focus:border-primary transition-all text-base" id="email" name="email" placeholder="jane@university.edu" required type="email" />
                    </div>
                </div>
                <button className="w-full bg-primary hover:bg-primary/90 text-white font-bold text-base py-3.5 px-6 rounded-lg shadow-sm hover:shadow-md transition-all duration-200 flex items-center justify-center gap-2 group">
                    <span>{t('auth.sendResetLink')}</span>
                    <span className="material-symbols-outlined text-lg group-hover:translate-x-1 transition-transform">arrow_forward</span>
                </button>
            </form>
            {/* Back to Login */}
            <div className="mt-8 text-center">
                <Link className="inline-flex items-center gap-2 text-sm font-semibold text-gray-500 dark:text-gray-400 hover:text-primary dark:hover:text-white transition-colors group" to="/login">
                    <span className="material-symbols-outlined text-lg group-hover:-translate-x-1 transition-transform">arrow_back</span>
                    {t('auth.backToLogin')}
                </Link>
            </div>
        </div>
    );
};

export default ForgotPasswordPage;
