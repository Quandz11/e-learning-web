import React, { useState } from 'react';
import { useTranslation } from 'react-i18next';
import { userApi } from '../../../../services/userApi';

interface ResetPasswordModalProps {
    isOpen: boolean;
    onClose: () => void;
    userId: string;
}

const ResetPasswordModal: React.FC<ResetPasswordModalProps> = ({ isOpen, onClose, userId }) => {
    const { t } = useTranslation();
    const [resetting, setResetting] = useState(false);
    const [error, setError] = useState<string | null>(null);
    const [resetPassword, setResetPassword] = useState('');
    const [showResetPassword, setShowResetPassword] = useState(false);

    const resetPasswordSubmit = async () => {
        if (!resetPassword.trim()) {
            setError(t('admin.users.errors.passwordRequired'));
            return;
        }
        try {
            setResetting(true);
            setError(null);
            await userApi.resetPassword(userId, { newPassword: resetPassword });
            onClose();
        } catch (err: any) {
            setError(err.message || t('admin.users.errors.resetFailed'));
        } finally {
            setResetting(false);
        }
    };

    if (!isOpen) return null;

    return (
        <div className="fixed inset-0 z-[100] flex items-start justify-center overflow-y-auto bg-black/50 p-4">
            <div className="w-full max-w-md rounded-2xl border border-slate-200 bg-white shadow-2xl dark:border-slate-700 dark:bg-dashboard-surface-dark">
                <div className="flex items-center justify-between border-b border-slate-200 px-6 py-4 dark:border-slate-700">
                    <div>
                        <h3 className="text-lg font-semibold text-slate-900 dark:text-white">{t('admin.users.reset.title')}</h3>
                        <p className="text-sm text-slate-500 dark:text-slate-400">{t('admin.users.reset.subtitle')}</p>
                    </div>
                    <button onClick={onClose} className="rounded-full p-2 text-slate-500 hover:bg-slate-100 dark:text-slate-300 dark:hover:bg-slate-800">
                        <span className="material-symbols-outlined">close</span>
                    </button>
                </div>
                <div className="px-6 py-5 space-y-3">
                    {error && (
                        <div className="rounded-lg border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-700 dark:border-red-900/50 dark:bg-red-900/20 dark:text-red-200">
                            {error}
                        </div>
                    )}
                    <label className="text-sm font-medium text-slate-700 dark:text-slate-200">{t('admin.users.reset.password')}</label>
                    <div className="relative">
                        <input
                            className="w-full rounded-lg border border-slate-200 bg-slate-50 px-3 py-2 text-sm focus:border-dashboard-primary focus:bg-white focus:outline-none dark:border-slate-700 dark:bg-slate-900"
                            type={showResetPassword ? 'text' : 'password'}
                            value={resetPassword}
                            onChange={(e) => setResetPassword(e.target.value)}
                        />
                        <button
                            type="button"
                            className="absolute right-3 top-1/2 -translate-y-1/2 text-xs font-medium text-dashboard-primary hover:text-dashboard-primary-dark"
                            onClick={() => setShowResetPassword((v) => !v)}
                        >
                            {showResetPassword ? t('admin.users.passwordToggle.hide') : t('admin.users.passwordToggle.show')}
                        </button>
                    </div>
                </div>
                <div className="flex items-center justify-end gap-3 border-t border-slate-200 px-6 py-4 dark:border-slate-700">
                    <button
                        onClick={onClose}
                        className="rounded-lg border border-slate-200 px-4 py-2 text-sm font-medium text-slate-700 hover:bg-slate-100 dark:border-slate-700 dark:text-slate-200 dark:hover:bg-slate-800"
                    >
                        {t('admin.users.form.cancel')}
                    </button>
                    <button
                        onClick={resetPasswordSubmit}
                        disabled={resetting}
                        className="inline-flex items-center gap-2 rounded-lg bg-dashboard-primary px-4 py-2 text-sm font-semibold text-white shadow-sm shadow-dashboard-primary/30 transition hover:bg-dashboard-primary-dark disabled:opacity-60"
                    >
                        {resetting ? t('common.saving', { defaultValue: 'Saving...' }) : t('admin.users.reset.submit')}
                    </button>
                </div>
            </div>
        </div>
    );
};

export default ResetPasswordModal;
