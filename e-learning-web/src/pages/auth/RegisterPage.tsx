import { useState } from 'react';
import { Link } from 'react-router-dom';
import { useTranslation } from 'react-i18next';

const RegisterPage = () => {
    const { t } = useTranslation();
    const [role, setRole] = useState<'student' | 'agent'>('student');

    return (
        <>
            {/* Header */}
            <div className="text-center sm:text-left space-y-2">
                <h1 className="text-3xl sm:text-4xl font-bold text-gray-900 dark:text-white">{t('auth.createAccount')}</h1>
                <p className="text-gray-500 dark:text-gray-400 text-base">{t('auth.joinCommunity')}</p>
            </div>

            {/* Role Selector */}
            <div className="bg-gray-100 dark:bg-gray-800 p-1.5 rounded-xl flex relative">
                <label className="flex-1 cursor-pointer group">
                    <input
                        type="radio"
                        name="role"
                        value="student"
                        className="peer sr-only"
                        checked={role === 'student'}
                        onChange={() => setRole('student')}
                    />
                    <div className={`flex items-center justify-center gap-2 py-2.5 px-4 rounded-lg transition-all duration-200 font-medium border border-transparent ${role === 'student' ? 'bg-primary text-white border-primary' : 'text-gray-600 dark:text-gray-400 group-hover:text-primary dark:group-hover:text-primary-light'}`}>
                        <span className="material-symbols-outlined text-[20px]">school</span>
                        <span>{t('auth.student')}</span>
                    </div>
                </label>
                <label className="flex-1 cursor-pointer group">
                    <input
                        type="radio"
                        name="role"
                        value="agent"
                        className="peer sr-only"
                        checked={role === 'agent'}
                        onChange={() => setRole('agent')}
                    />
                    <div className={`flex items-center justify-center gap-2 py-2.5 px-4 rounded-lg transition-all duration-200 font-medium border border-transparent ${role === 'agent' ? 'bg-primary text-white border-primary' : 'text-gray-600 dark:text-gray-400 group-hover:text-primary dark:group-hover:text-primary-light'}`}>
                        <span className="material-symbols-outlined text-[20px]">badge</span>
                        <span>{t('auth.agent')}</span>
                    </div>
                </label>
            </div>

            {/* Main Form */}
            <form className="space-y-5" onSubmit={(e) => e.preventDefault()}>
                {/* Full Name */}
                <div className="space-y-1.5">
                    <label className="block text-sm font-semibold text-gray-900 dark:text-gray-200">{t('auth.fullName')}</label>
                    <div className="relative">
                        <input className="w-full h-12 px-4 rounded-lg bg-white dark:bg-gray-800 border border-gray-200 dark:border-gray-700 focus:border-primary focus:ring-1 focus:ring-primary text-gray-900 dark:text-white placeholder-gray-400 transition-colors" placeholder={t('auth.fullNamePlaceholder')} type="text" />
                        <div className="absolute inset-y-0 right-4 flex items-center pointer-events-none text-gray-400">
                            <span className="material-symbols-outlined text-[20px]">person</span>
                        </div>
                    </div>
                </div>
                {/* Email */}
                <div className="space-y-1.5">
                    <label className="block text-sm font-semibold text-gray-900 dark:text-gray-200">{t('auth.email')}</label>
                    <div className="relative">
                        <input className="w-full h-12 px-4 rounded-lg bg-white dark:bg-gray-800 border border-gray-200 dark:border-gray-700 focus:border-primary focus:ring-1 focus:ring-primary text-gray-900 dark:text-white placeholder-gray-400 transition-colors" placeholder={t('auth.emailPlaceholder')} type="email" />
                        <div className="absolute inset-y-0 right-4 flex items-center pointer-events-none text-gray-400">
                            <span className="material-symbols-outlined text-[20px]">mail</span>
                        </div>
                    </div>
                </div>
                {/* Password */}
                <div className="space-y-1.5">
                    <label className="block text-sm font-semibold text-gray-900 dark:text-gray-200">{t('auth.password')}</label>
                    <div className="relative">
                        <input className="w-full h-12 px-4 rounded-lg bg-white dark:bg-gray-800 border border-gray-200 dark:border-gray-700 focus:border-primary focus:ring-1 focus:ring-primary text-gray-900 dark:text-white placeholder-gray-400 transition-colors" placeholder={t('auth.createPassword')} type="password" />
                        <button className="absolute inset-y-0 right-4 flex items-center text-gray-400 hover:text-gray-600 dark:hover:text-gray-200 transition-colors" type="button">
                            <span className="material-symbols-outlined text-[20px]">visibility</span>
                        </button>
                    </div>
                    <p className="text-xs text-gray-500 dark:text-gray-400 mt-1">{t('auth.passwordHint')}</p>
                </div>
                {/* Referral Code */}
                <div className="space-y-1.5">
                    <div className="flex justify-between items-center">
                        <label className="block text-sm font-semibold text-gray-900 dark:text-gray-200">{t('auth.referralCode')}</label>
                        <span className="text-xs font-medium text-gray-400 uppercase tracking-wide">{t('auth.optional')}</span>
                    </div>
                    <div className="relative">
                        <input className="w-full h-12 px-4 rounded-lg bg-white dark:bg-gray-800 border border-gray-200 dark:border-gray-700 border-dashed focus:border-solid focus:border-primary focus:ring-1 focus:ring-primary text-gray-900 dark:text-white placeholder-gray-400 transition-all" placeholder={t('auth.enterCode')} type="text" />
                        <div className="absolute inset-y-0 right-4 flex items-center pointer-events-none text-gray-400">
                            <span className="material-symbols-outlined text-[20px]">confirmation_number</span>
                        </div>
                    </div>
                </div>
                {/* Submit Button */}
                <button className="w-full h-12 bg-primary hover:bg-primary/90 text-white font-bold rounded-lg shadow-lg shadow-primary/20 transition-all duration-200 flex items-center justify-center gap-2 mt-4" type="submit">
                    <span>{t('auth.createAccount')}</span>
                    <span className="material-symbols-outlined text-[20px]">arrow_forward</span>
                </button>
                {/* Divider */}
                <div className="relative flex py-2 items-center">
                    <div className="flex-grow border-t border-gray-200 dark:border-gray-700"></div>
                    <span className="flex-shrink-0 mx-4 text-gray-400 text-sm">{t('auth.orSignUpWith')}</span>
                    <div className="flex-grow border-t border-gray-200 dark:border-gray-700"></div>
                </div>
                {/* Social Login */}
                <div className="grid grid-cols-2 gap-4">
                    <button className="flex items-center justify-center gap-2 h-11 px-4 rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-800 hover:bg-gray-50 dark:hover:bg-gray-700 transition-colors text-sm font-medium text-gray-900 dark:text-gray-200">
                        <svg className="w-5 h-5" fill="none" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
                            <path d="M23.766 12.2764C23.766 11.4607 23.6999 10.6406 23.5588 9.83807H12.24V14.4591H18.7217C18.4528 15.9494 17.5885 17.2678 16.323 18.1056V21.1039H20.19C22.4608 19.0139 23.766 15.9274 23.766 12.2764Z" fill="#4285F4"></path>
                            <path d="M12.24 24.0008C15.4765 24.0008 18.2058 22.9382 20.1945 21.1039L16.3275 18.1055C15.2517 18.8375 13.8627 19.252 12.2445 19.252C9.11388 19.252 6.45946 17.1399 5.50705 14.3003H1.5166V17.3912C3.55371 21.4434 7.7029 24.0008 12.24 24.0008Z" fill="#34A853"></path>
                            <path d="M5.50253 14.3003C5.00236 12.8099 5.00236 11.1961 5.50253 9.70575V6.61481H1.51649C-0.18551 10.0056 -0.18551 14.0004 1.51649 17.3912L5.50253 14.3003Z" fill="#FBBC05"></path>
                            <path d="M12.24 4.74966C13.9509 4.7232 15.6044 5.36697 16.8434 6.54867L20.2695 3.12262C18.1001 1.0855 15.2208 -0.034466 12.24 0.000808666C7.7029 0.000808666 3.55371 2.55822 1.5166 6.61481L5.50264 9.70575C6.45064 6.86173 9.10947 4.74966 12.24 4.74966Z" fill="#EA4335"></path>
                        </svg>
                        Google
                    </button>
                    <button className="flex items-center justify-center gap-2 h-11 px-4 rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-800 hover:bg-gray-50 dark:hover:bg-gray-700 transition-colors text-sm font-medium text-gray-900 dark:text-gray-200">
                        <svg className="w-5 h-5 text-gray-900 dark:text-white" fill="currentColor" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
                            <path d="M12 2C6.477 2 2 6.477 2 12C2 17.523 6.477 22 12 22C17.523 22 22 17.523 22 12C22 6.477 17.523 2 12 2ZM15.556 16.944L13.778 15.167L15.556 13.389L13.778 11.611L15.556 9.833L13.778 8.056L15.556 6.278L13.778 4.5L12 6.278L10.222 4.5L8.444 6.278L10.222 8.056L8.444 9.833L10.222 11.611L8.444 13.389L10.222 15.167L8.444 16.944L10.222 18.722L12 16.944L13.778 18.722L15.556 16.944Z" fillOpacity="0"></path>
                            <path clipRule="evenodd" d="M12 2C6.477 2 2 6.477 2 12C2 16.418 5.614 20 10 20V12.25H8V9.75H10V8.25C10 6.134 11.168 5 13.064 5C13.974 5 14.75 5.068 14.75 5.068V7.167H13.805C12.756 7.167 12.5 7.818 12.5 8.484V9.75H15L14.5 12.25H12.5V20C16.886 20 20.5 16.418 20.5 12C20.5 6.477 16.023 2 10.5 2H12Z" fill="currentColor" fillRule="evenodd"></path>
                        </svg>
                        Facebook
                    </button>
                </div>
            </form>
            {/* Footer Link */}
            <p className="text-center text-sm text-gray-500 dark:text-gray-400 pt-4">
                {t('auth.alreadyHaveAccount')}
                <Link className="font-bold text-primary hover:text-primary/80 hover:underline ml-1" to="/login">{t('auth.logIn')}</Link>
            </p>
        </>
    );
};

export default RegisterPage;
