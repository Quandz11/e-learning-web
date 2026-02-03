import React, { useEffect, useState } from 'react';
import { useTranslation } from 'react-i18next';
import { useSelector } from 'react-redux';
import { Link } from 'react-router-dom';
import type { RootState } from '../../store/store';
import { chatSignalR, type NotificationMessage } from '../../services/chat/chatSignalR';

interface AdminHeaderProps {
    onToggleMobileNav?: () => void;
}

const AdminHeader: React.FC<AdminHeaderProps> = ({ onToggleMobileNav }) => {
    const { t, i18n } = useTranslation();
    const { user } = useSelector((state: RootState) => state.auth);
    const [notifications, setNotifications] = useState<NotificationMessage[]>([]);
    const [unreadCount, setUnreadCount] = useState(0);

    const changeLanguage = () => {
        const newLang = i18n.language === 'en' ? 'vi' : 'en';
        i18n.changeLanguage(newLang);
    };

    useEffect(() => {
        // Subscribe to real-time notifications
        chatSignalR.onReceiveNotification((notification) => {
            console.log('New notification received:', notification);
            setNotifications(prev => [notification, ...prev]);
            setUnreadCount(prev => prev + 1);

            // Optional: Show browser notification if permission granted
            if (Notification.permission === 'granted') {
                new Notification(notification.title, { body: notification.message });
            }
        });

        // Request notification permission
        if (Notification.permission !== 'granted' && Notification.permission !== 'denied') {
            Notification.requestPermission();
        }
    }, []);

    const markAllRead = () => {
        setUnreadCount(0);
        // Implement API call to mark as read if backend supports persistence
    };

    return (
        <header className="sticky top-0 z-50 flex h-16 items-center justify-between border-b border-slate-200 bg-dashboard-surface-light/90 px-6 backdrop-blur-sm dark:border-slate-800 dark:bg-dashboard-surface-dark/90">
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
            <div className="flex items-center gap-4">
                <button
                    onClick={changeLanguage}
                    className="flex h-9 w-9 items-center justify-center rounded-full text-sm font-semibold text-slate-600 transition-colors hover:bg-slate-100 dark:text-slate-300 dark:hover:bg-slate-800"
                    title="Change Language"
                >
                    {i18n.language === 'en' ? 'EN' : 'VI'}
                </button>

                <div className="relative">
                    <button
                        onClick={markAllRead}
                        className="relative rounded-full p-2 text-slate-500 transition-colors hover:bg-slate-100 hover:text-slate-700 dark:text-slate-400 dark:hover:bg-slate-800 dark:hover:text-slate-200"
                    >
                        <span className="material-symbols-outlined">notifications</span>
                        {unreadCount > 0 && (
                            <span className="absolute right-2 top-2 h-2 w-2 rounded-full bg-dashboard-accent ring-2 ring-white dark:ring-dashboard-surface-dark"></span>
                        )}
                    </button>

                    {/* Simple Dropdown for Demo */}
                    {unreadCount > 0 && (
                        <div className="absolute right-0 mt-2 w-80 origin-top-right rounded-md bg-white py-1 shadow-lg ring-1 ring-black ring-opacity-5 focus:outline-none dark:bg-slate-800 dark:ring-slate-700">
                            <div className="px-4 py-2 border-b border-slate-100 dark:border-slate-700">
                                <h3 className="text-sm font-semibold text-slate-900 dark:text-slate-100">Notifications</h3>
                            </div>
                            <div className="max-h-64 overflow-y-auto">
                                {notifications.slice(0, 5).map((n, i) => (
                                    <div key={i} className="px-4 py-3 hover:bg-slate-50 dark:hover:bg-slate-700/50">
                                        <p className="text-sm font-medium text-slate-900 dark:text-slate-100">{n.title}</p>
                                        <p className="text-xs text-slate-500 dark:text-slate-400 truncate">{n.message}</p>
                                        <p className="text-[10px] text-slate-400 mt-1">{new Date(n.timestamp).toLocaleTimeString()}</p>
                                    </div>
                                ))}
                            </div>
                        </div>
                    )}
                </div>

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
