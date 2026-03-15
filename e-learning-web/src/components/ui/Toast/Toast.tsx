import React, { useEffect, useState } from 'react';
import { useTranslation } from 'react-i18next';
import type { Toast as ToastType } from '../../../contexts/ToastContext';

interface ToastProps {
    toast: ToastType;
    onClose: () => void;
}

const Toast: React.FC<ToastProps> = ({ toast, onClose }) => {
    const { t } = useTranslation();
    const [progress, setProgress] = useState(100);
    const [isExiting, setIsExiting] = useState(false);

    useEffect(() => {
        if (!toast.duration || toast.duration <= 0) return;

        const interval = 50; // Update every 50ms
        const decrement = (interval / toast.duration) * 100;

        const timer = setInterval(() => {
            setProgress((prev) => {
                const next = prev - decrement;
                if (next <= 0) {
                    clearInterval(timer);
                    return 0;
                }
                return next;
            });
        }, interval);

        return () => clearInterval(timer);
    }, [toast.duration]);

    const handleClose = () => {
        setIsExiting(true);
        setTimeout(onClose, 300); // Match animation duration
    };

    const getIcon = () => {
        switch (toast.type) {
            case 'success':
                return (
                    <span className="material-symbols-outlined text-green-600 dark:text-green-400">
                        check_circle
                    </span>
                );
            case 'error':
                return (
                    <span className="material-symbols-outlined text-red-600 dark:text-red-400">
                        error
                    </span>
                );
            case 'warning':
                return (
                    <span className="material-symbols-outlined text-yellow-600 dark:text-yellow-400">
                        warning
                    </span>
                );
            case 'info':
                return (
                    <span className="material-symbols-outlined text-blue-600 dark:text-blue-400">
                        info
                    </span>
                );
        }
    };

    const getBackgroundColor = () => {
        switch (toast.type) {
            case 'success':
                return 'bg-green-50 dark:bg-green-900/20 border-green-200 dark:border-green-800';
            case 'error':
                return 'bg-red-50 dark:bg-red-900/20 border-red-200 dark:border-red-800';
            case 'warning':
                return 'bg-yellow-50 dark:bg-yellow-900/20 border-yellow-200 dark:border-yellow-800';
            case 'info':
                return 'bg-blue-50 dark:bg-blue-900/20 border-blue-200 dark:border-blue-800';
        }
    };

    const getProgressColor = () => {
        switch (toast.type) {
            case 'success':
                return 'bg-green-600 dark:bg-green-400';
            case 'error':
                return 'bg-red-600 dark:bg-red-400';
            case 'warning':
                return 'bg-yellow-600 dark:bg-yellow-400';
            case 'info':
                return 'bg-blue-600 dark:bg-blue-400';
        }
    };

    return (
        <div
            className={`
        ${getBackgroundColor()}
        border rounded-lg shadow-lg p-3 sm:p-4 mb-3
        min-w-[16rem] max-w-[calc(100vw-1rem)] sm:max-w-md
        transform transition-all duration-300 ease-out
        ${isExiting ? 'translate-x-full opacity-0' : 'translate-x-0 opacity-100'}
      `}
            role="alert"
        >
            <div className="flex items-start gap-3">
                <div className="flex-shrink-0 mt-0.5">{getIcon()}</div>

                <div className="flex-1 min-w-0">
                    <p className="text-sm font-medium text-gray-900 dark:text-white break-words">
                        {toast.message}
                    </p>
                </div>

                <button
                    onClick={handleClose}
                    className="flex-shrink-0 text-gray-400 hover:text-gray-600 dark:hover:text-gray-300 transition-colors"
                    aria-label={t('modal.close')}
                >
                    <span className="material-symbols-outlined text-[20px]">close</span>
                </button>
            </div>

            {/* Progress bar */}
            {toast.duration && toast.duration > 0 && (
                <div className="mt-3 h-1 bg-gray-200 dark:bg-gray-700 rounded-full overflow-hidden">
                    <div
                        className={`h-full ${getProgressColor()} transition-all duration-50 ease-linear`}
                        style={{ width: `${progress}%` }}
                    />
                </div>
            )}
        </div>
    );
};

export default Toast;
