import React, { useState, useRef, useEffect } from 'react';
import { useNotification } from '../../context/NotificationContext';
import { useTranslation } from 'react-i18next';
import { formatDistanceToNow } from 'date-fns';
import { vi, enUS } from 'date-fns/locale';
import { Link } from 'react-router-dom';

export default function HeaderNotification() {
    const { notifications, unreadCount, markAsRead, markAllAsRead } = useNotification();
    const { t, i18n } = useTranslation();
    const [isOpen, setIsOpen] = useState(false);
    const dropdownRef = useRef<HTMLDivElement>(null);

    // Close dropdown on click outside
    useEffect(() => {
        const handleClickOutside = (event: MouseEvent) => {
            if (dropdownRef.current && !dropdownRef.current.contains(event.target as Node)) {
                setIsOpen(false);
            }
        };
        document.addEventListener('mousedown', handleClickOutside);
        return () => document.removeEventListener('mousedown', handleClickOutside);
    }, []);

    const handleMarkAsRead = (id: string, e: React.MouseEvent) => {
        e.stopPropagation();
        markAsRead(id);
    };

    const handleMarkAllRead = () => {
        markAllAsRead();
    };

    const getDateLocale = () => {
        return i18n.language === 'vi' ? vi : enUS;
    };

    return (
        <div className="relative" ref={dropdownRef}>
            <button
                onClick={() => setIsOpen(!isOpen)}
                className="relative p-2 text-gray-500 hover:text-gray-700 dark:text-gray-400 dark:hover:text-gray-200 focus:outline-none"
            >
                {/* Bell Icon */}
                <svg xmlns="http://www.w3.org/2000/svg" className="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 17h5l-1.405-1.405A2.032 2.032 0 0118 14.158V11a6.002 6.002 0 00-4-5.659V5a2 2 0 10-4 0v.341C7.67 6.165 6 8.388 6 11v3.159c0 .538-.214 1.055-.595 1.436L4 17h5m6 0v1a3 3 0 11-6 0v-1m6 0H9" />
                </svg>

                {unreadCount > 0 && (
                    <span className="absolute top-0 right-0 inline-flex items-center justify-center px-2 py-1 text-xs font-bold leading-none text-red-100 transform translate-x-1/4 -translate-y-1/4 bg-red-600 rounded-full">
                        {unreadCount > 99 ? '99+' : unreadCount}
                    </span>
                )}
            </button>

            {isOpen && (
                <div className="absolute right-0 mt-2 w-80 sm:w-96 bg-white dark:bg-gray-800 rounded-lg shadow-xl overflow-hidden z-50 border border-gray-100 dark:border-gray-700">
                    <div className="px-4 py-3 border-b border-gray-100 dark:border-gray-700 flex justify-between items-center bg-gray-50 dark:bg-gray-700">
                        <h3 className="text-sm font-semibold text-gray-700 dark:text-gray-200">{t('notifications.title')}</h3>
                        {unreadCount > 0 && (
                            <button
                                onClick={handleMarkAllRead}
                                className="text-xs text-primary hover:text-primary-dark font-medium"
                            >
                                {t('notifications.markAllRead')}
                            </button>
                        )}
                    </div>

                    <div className="max-h-[400px] overflow-y-auto">
                        {notifications.length === 0 ? (
                            <div className="px-4 py-8 text-center text-gray-500 dark:text-gray-400">
                                <p>{t('notifications.empty')}</p>
                            </div>
                        ) : (
                            <ul className="divide-y divide-gray-100 dark:divide-gray-700">
                                {notifications.map((notification) => (
                                    <li
                                        key={notification.id}
                                        className={`px-4 py-3 hover:bg-gray-50 dark:hover:bg-gray-700 transition duration-150 ease-in-out ${!notification.isRead ? 'bg-blue-50/50 dark:bg-blue-900/10' : ''}`}
                                    >
                                        <div className="flex justify-between items-start">
                                            <div className="flex-1 min-w-0">
                                                <p className={`text-sm font-medium ${!notification.isRead ? 'text-gray-900 dark:text-white' : 'text-gray-600 dark:text-gray-300'}`}>
                                                    {notification.title}
                                                </p>
                                                <p className="text-sm text-gray-500 dark:text-gray-400 mt-0.5 line-clamp-2">
                                                    {notification.content}
                                                </p>
                                                <p className="text-xs text-gray-400 dark:text-gray-500 mt-1">
                                                    {formatDistanceToNow(new Date(notification.createdAt.endsWith('Z') ? notification.createdAt : notification.createdAt + 'Z'), { addSuffix: true, locale: getDateLocale() })}
                                                </p>
                                            </div>
                                            {!notification.isRead && (
                                                <button
                                                    onClick={(e) => handleMarkAsRead(notification.id, e)}
                                                    className="ml-2 w-2 h-2 rounded-full bg-blue-600 hover:bg-blue-800"
                                                    title="Mark as read"
                                                />
                                            )}
                                        </div>
                                    </li>
                                ))}
                            </ul>
                        )}
                    </div>

                    <div className="px-4 py-2 border-t border-gray-100 dark:border-gray-700 bg-gray-50 dark:bg-gray-700 text-center">
                        <Link
                            to="/admin/notifications"
                            onClick={() => setIsOpen(false)}
                            className="text-sm text-dashboard-primary hover:text-dashboard-primary-dark font-medium hover:underline"
                        >
                            {t('notifications.viewAll')}
                        </Link>
                    </div>
                </div>
            )}
        </div>
    );
}
