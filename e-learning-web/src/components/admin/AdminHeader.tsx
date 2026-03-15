import React from 'react';
import { useTranslation } from 'react-i18next';
import { useSelector } from 'react-redux';
import { Link } from 'react-router-dom';
import type { RootState } from '../../store/store';
import HeaderNotification from '../common/HeaderNotification';

interface AdminHeaderProps {
    onToggleMobileNav?: () => void;
}

const AdminHeader: React.FC<AdminHeaderProps> = ({ onToggleMobileNav }) => {
    const { t, i18n } = useTranslation();
    const { user } = useSelector((state: RootState) => state.auth);

    const changeLanguage = () => {
        const newLang = i18n.language === 'en' ? 'vi' : 'en';
        i18n.changeLanguage(newLang);
    };

    return (
        <header className="sticky top-0 z-50 flex h-16 items-center justify-between border-b border-slate-200 bg-dashboard-surface-light/90 px-3 sm:px-4 lg:px-6 backdrop-blur-sm dark:border-slate-800 dark:bg-dashboard-surface-dark/90">
            {/* Mobile Menu Trigger */}
            <button
                onClick={onToggleMobileNav}
                className="rounded-md p-2 text-slate-600 hover:bg-slate-100 dark:text-slate-300 dark:hover:bg-slate-800 lg:hidden"
                aria-label="Toggle navigation"
            >
                <span className="material-symbols-outlined">menu</span>
            </button>

            {/* Search Bar */}
            <div className="hidden max-w-md flex-1 md:flex lg:ml-0">
                <div className="group relative w-full">
                    <span className="pointer-events-none absolute inset-y-0 left-0 flex items-center pl-3">
                        <span className="material-symbols-outlined text-slate-400 transition-colors group-focus-within:text-dashboard-primary">search</span>
                    </span>
                    <input
                        className="block w-full rounded-lg border border-slate-200 bg-slate-50 py-2 pl-10 pr-3 leading-5 text-slate-900 placeholder-slate-400 transition-all focus:border-dashboard-primary focus:bg-white focus:outline-none focus:ring-1 focus:ring-dashboard-primary dark:border-slate-700 dark:bg-slate-900 dark:text-slate-100 dark:focus:bg-slate-950 sm:text-sm"
                        placeholder={t('admin.header.searchPlaceholder')}
                        type="text"
                    />
                </div>
            </div>

            {/* Right Actions */}
            <div className="flex items-center gap-2 sm:gap-3 md:gap-4">
                <button
                    onClick={changeLanguage}
                    className="flex h-9 w-9 items-center justify-center rounded-full text-sm font-semibold text-slate-600 transition-colors hover:bg-slate-100 dark:text-slate-300 dark:hover:bg-slate-800"
                    title="Change Language"
                >
                    {i18n.language === 'en' ? 'EN' : 'VI'}
                </button>

                <HeaderNotification />

                <button className="hidden rounded-full p-2 text-slate-500 transition-colors hover:bg-slate-100 hover:text-slate-700 dark:text-slate-400 dark:hover:bg-slate-800 dark:hover:text-slate-200 sm:block">
                    <span className="material-symbols-outlined">help</span>
                </button>
                <div className="mx-1 hidden h-8 w-[1px] bg-slate-200 dark:bg-slate-700 sm:block"></div>
                {/* Mini Profile for Mobile (Simplified) */}
                <Link to="/profile" className="flex items-center gap-2 lg:hidden">
                    <div className="h-8 w-8 rounded-full border border-slate-200 bg-dashboard-primary/10 flex items-center justify-center overflow-hidden dark:border-slate-700">
                        {user?.avatarUrl ? (
                            <img src={user.avatarUrl} alt={user.fullName} className="h-full w-full object-cover" />
                        ) : (
                            <span className="text-xs font-semibold text-dashboard-primary">
                                {user?.fullName ? user.fullName.charAt(0).toUpperCase() : 'U'}
                            </span>
                        )}
                    </div>
                </Link>
            </div>
        </header>
    );
};

export default AdminHeader;
