import React, { useState, useEffect } from 'react';
import { useSelector } from 'react-redux';
import { useTranslation } from 'react-i18next';
import { useLocation } from 'react-router-dom';
import type { RootState } from '../../store/store';
import ChatWindow from './ChatWindow';
import { chatApi } from '../../services/chat/chatApi';

const ChatButton: React.FC = () => {
    const { t } = useTranslation();
    const location = useLocation();
    const [isOpen, setIsOpen] = useState(false);
    const [unreadCount, setUnreadCount] = useState(0);
    const { isAuthenticated, user } = useSelector((state: RootState) => state.auth);

    // Hide chat button on admin pages
    const isAdminPage = location.pathname.startsWith('/admin');
    const isAdminUser = user?.role?.toUpperCase() === 'ADMIN';
    const shouldHideButton = isAdminPage && isAdminUser;

    useEffect(() => {
        if (!isAuthenticated) {
            // Guest users don't have unread count
            setUnreadCount(0);
            return;
        }

        // Fetch unread count periodically for authenticated users
        const fetchUnreadCount = async () => {
            try {
                const count = await chatApi.getUnreadCount();
                setUnreadCount(count);
            } catch (error) {
                console.error('Failed to fetch unread count:', error);
            }
        };

        fetchUnreadCount();
        const interval = setInterval(fetchUnreadCount, 30000); // Every 30s

        return () => clearInterval(interval);
    }, [isAuthenticated]);

    useEffect(() => {
        const chatOpen = !shouldHideButton && isOpen;
        const appWindow = window as Window & { __elearningChatOpen?: boolean };
        appWindow.__elearningChatOpen = chatOpen;
        window.dispatchEvent(new CustomEvent('chat-widget-state-change', { detail: { isOpen: chatOpen } }));
    }, [isOpen, shouldHideButton]);

    useEffect(() => {
        return () => {
            const appWindow = window as Window & { __elearningChatOpen?: boolean };
            appWindow.__elearningChatOpen = false;
            window.dispatchEvent(new CustomEvent('chat-widget-state-change', { detail: { isOpen: false } }));
        };
    }, []);

    // Don't render if should be hidden
    if (shouldHideButton) {
        return null;
    }

    return (
        <>
            {/* Floating Chat Button */}
            <button
                onClick={() => setIsOpen(!isOpen)}
                className="group fixed bottom-6 right-4 z-[60] flex h-12 w-12 items-center justify-center rounded-full bg-primary p-0 text-white shadow-xl transition-all duration-300 hover:scale-105 hover:bg-primary/90 sm:right-6 sm:h-auto sm:w-auto sm:justify-start sm:gap-2 sm:px-4 sm:py-3"
                aria-label={t('chat.buttonAriaLabel')}
            >
                <span className="material-symbols-outlined text-[22px]">person</span>
                <span className="text-sm font-semibold">{t('chat.buttonLabel')}</span>

                {/* Unread Badge */}
                {unreadCount > 0 && (
                    <span className="absolute -top-1 -right-1 flex h-5 w-5 items-center justify-center rounded-full bg-red-500 text-[10px] font-bold text-white ring-2 ring-white dark:ring-gray-900">
                        {unreadCount > 9 ? '9+' : unreadCount}
                    </span>
                )}
            </button>

            {/* Chat Window - Always mounted, hidden via CSS */}
            <div style={{ display: isOpen ? 'block' : 'none' }}>
                <ChatWindow
                    isOpen={isOpen}
                    onClose={() => setIsOpen(false)}
                    onUnreadCountChange={setUnreadCount}
                />
            </div>
        </>
    );
};

export default ChatButton;
