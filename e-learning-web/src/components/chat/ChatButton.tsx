import React, { useState, useEffect } from 'react';
import { useSelector } from 'react-redux';
import { useLocation } from 'react-router-dom';
import type { RootState } from '../../store/store';
import ChatWindow from './ChatWindow';
import { chatApi } from '../../services/chat/chatApi';

const ChatButton: React.FC = () => {
    const [isOpen, setIsOpen] = useState(false);
    const [unreadCount, setUnreadCount] = useState(0);
    const { isAuthenticated, user } = useSelector((state: RootState) => state.auth);
    const location = useLocation();

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

    // Don't render if should be hidden
    if (shouldHideButton) {
        return null;
    }

    return (
        <>
            {/* Floating Chat Button */}
            <button
                onClick={() => setIsOpen(!isOpen)}
                className="fixed bottom-6 right-6 z-50 bg-primary hover:bg-primary/90 text-white rounded-full p-4 shadow-lg transition-all duration-300 hover:scale-110 flex items-center justify-center"
                aria-label="Open chat"
            >
                <span className="material-symbols-outlined text-3xl">chat</span>

                {/* Unread Badge */}
                {unreadCount > 0 && (
                    <span className="absolute -top-1 -right-1 bg-red-500 text-white text-xs font-bold rounded-full h-6 w-6 flex items-center justify-center">
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
