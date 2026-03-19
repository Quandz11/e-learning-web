import React, { useEffect, useState } from 'react';
import { useLocation } from 'react-router-dom';
import { useSelector } from 'react-redux';
import type { RootState } from '../../store/store';
import { aiWidgetApi } from '../../services/aiWidgetApi';
import AiCoachDashboard from './AiCoachDashboard';

const AiChatWidget: React.FC = () => {
    const location = useLocation();
    const { isAuthenticated, user } = useSelector((state: RootState) => state.auth);
    const isStudent = user?.role?.toUpperCase() === 'STUDENT';

    const [isOpen, setIsOpen] = useState(false);
    const [isEnabled, setIsEnabled] = useState(false);
    const [isChatOpen, setIsChatOpen] = useState(false);

    useEffect(() => {
        if (isAuthenticated && isStudent) {
            void aiWidgetApi
                .getStatus()
                .then((status) => setIsEnabled(status.isEnabled))
                .catch(() => setIsEnabled(false));
            return;
        }

        setIsEnabled(false);
        setIsOpen(false);
    }, [isAuthenticated, isStudent]);

    useEffect(() => {
        const appWindow = window as Window & { __elearningChatOpen?: boolean };
        if (appWindow.__elearningChatOpen) {
            setIsChatOpen(true);
            setIsOpen(false);
        }

        const handleChatWidgetState = (event: Event) => {
            const customEvent = event as CustomEvent<{ isOpen?: boolean }>;
            const chatOpen = Boolean(customEvent.detail?.isOpen);
            setIsChatOpen(chatOpen);

            if (chatOpen) {
                setIsOpen(false);
            }
        };

        window.addEventListener('chat-widget-state-change', handleChatWidgetState);
        return () => window.removeEventListener('chat-widget-state-change', handleChatWidgetState);
    }, []);

    if (!isAuthenticated || !isStudent || !isEnabled || location.pathname === '/my-learning-plan') {
        return null;
    }

    return (
        <>
            {isOpen && (
                <div className="fixed inset-x-4 bottom-20 z-[69] sm:bottom-24 sm:left-auto sm:right-6">
                    <AiCoachDashboard mode="widget" onClose={() => setIsOpen(false)} />
                </div>
            )}

            {!isOpen && !isChatOpen && (
                <button
                    onClick={() => setIsOpen(true)}
                    className="fixed bottom-40 right-4 z-[70] flex items-center justify-center rounded-full bg-primary p-4 text-white shadow-lg transition-all duration-300 hover:scale-110 hover:bg-primary/90 sm:bottom-44 sm:right-6"
                    aria-label="Open AI plan"
                >
                    <span className="material-symbols-outlined text-3xl">event_note</span>
                </button>
            )}
        </>
    );
};

export default AiChatWidget;
