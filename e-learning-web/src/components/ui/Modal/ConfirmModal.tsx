import React, { useEffect } from 'react';
import { useTranslation } from 'react-i18next';

export interface ConfirmModalProps {
    isOpen: boolean;
    onClose: () => void;
    onConfirm: () => void;
    title: string;
    message: string;
    confirmText?: string;
    cancelText?: string;
    variant?: 'default' | 'danger';
    isLoading?: boolean;
}

const ConfirmModal: React.FC<ConfirmModalProps> = ({
    isOpen,
    onClose,
    onConfirm,
    title,
    message,
    confirmText,
    cancelText,
    variant = 'default',
    isLoading = false,
}) => {
    const { t } = useTranslation();

    // Handle ESC key
    useEffect(() => {
        const handleEscape = (e: KeyboardEvent) => {
            if (e.key === 'Escape' && isOpen && !isLoading) {
                onClose();
            }
        };

        if (isOpen) {
            document.addEventListener('keydown', handleEscape);
            // Prevent body scroll
            document.body.style.overflow = 'hidden';
        }

        return () => {
            document.removeEventListener('keydown', handleEscape);
            document.body.style.overflow = 'unset';
        };
    }, [isOpen, isLoading, onClose]);

    // Handle Enter key
    useEffect(() => {
        const handleEnter = (e: KeyboardEvent) => {
            if (e.key === 'Enter' && isOpen && !isLoading) {
                onConfirm();
            }
        };

        if (isOpen) {
            document.addEventListener('keydown', handleEnter);
        }

        return () => {
            document.removeEventListener('keydown', handleEnter);
        };
    }, [isOpen, isLoading, onConfirm]);

    if (!isOpen) return null;

    const getConfirmButtonClass = () => {
        if (variant === 'danger') {
            return 'bg-red-600 hover:bg-red-700 text-white focus:ring-red-500';
        }
        return 'bg-primary hover:bg-primary/90 text-white focus:ring-primary';
    };

    return (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
            {/* Backdrop */}
            <div
                className="absolute inset-0 bg-black/50 backdrop-blur-sm transition-opacity"
                onClick={!isLoading ? onClose : undefined}
                aria-hidden="true"
            />

            {/* Modal */}
            <div
                className="relative bg-white dark:bg-gray-800 rounded-xl shadow-2xl max-w-md w-full transform transition-all animate-in fade-in zoom-in-95 duration-200"
                role="dialog"
                aria-modal="true"
                aria-labelledby="modal-title"
            >
                {/* Header */}
                <div className="p-6 pb-4">
                    <div className="flex items-start gap-4">
                        {/* Icon */}
                        <div
                            className={`
                flex-shrink-0 w-12 h-12 rounded-full flex items-center justify-center
                ${variant === 'danger'
                                    ? 'bg-red-100 dark:bg-red-900/30'
                                    : 'bg-blue-100 dark:bg-blue-900/30'
                                }
              `}
                        >
                            <span
                                className={`
                  material-symbols-outlined text-2xl
                  ${variant === 'danger'
                                        ? 'text-red-600 dark:text-red-400'
                                        : 'text-blue-600 dark:text-blue-400'
                                    }
                `}
                            >
                                {variant === 'danger' ? 'warning' : 'help'}
                            </span>
                        </div>

                        {/* Content */}
                        <div className="flex-1 min-w-0">
                            <h3
                                id="modal-title"
                                className="text-lg font-semibold text-gray-900 dark:text-white mb-2"
                            >
                                {title}
                            </h3>
                            <p className="text-sm text-gray-600 dark:text-gray-400 whitespace-pre-line">
                                {message}
                            </p>
                        </div>
                    </div>
                </div>

                {/* Actions */}
                <div className="px-6 py-4 bg-gray-50 dark:bg-gray-900/50 rounded-b-xl flex gap-3 justify-end">
                    <button
                        onClick={onClose}
                        disabled={isLoading}
                        className="px-4 py-2.5 text-sm font-medium text-gray-700 dark:text-gray-300 bg-white dark:bg-gray-800 border border-gray-300 dark:border-gray-600 rounded-lg hover:bg-gray-50 dark:hover:bg-gray-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-gray-500 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
                    >
                        {cancelText || t('modal.cancel')}
                    </button>
                    <button
                        onClick={onConfirm}
                        disabled={isLoading}
                        className={`
              px-4 py-2.5 text-sm font-medium rounded-lg
              focus:outline-none focus:ring-2 focus:ring-offset-2
              disabled:opacity-50 disabled:cursor-not-allowed
              transition-colors flex items-center gap-2
              ${getConfirmButtonClass()}
            `}
                    >
                        {isLoading && (
                            <span className="material-symbols-outlined animate-spin text-[18px]">
                                progress_activity
                            </span>
                        )}
                        {confirmText || t('modal.confirm')}
                    </button>
                </div>
            </div>
        </div>
    );
};

export default ConfirmModal;
