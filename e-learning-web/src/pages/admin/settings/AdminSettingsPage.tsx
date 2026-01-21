import { useEffect, useState } from 'react';
import { useSelector } from 'react-redux';
import { useTranslation } from 'react-i18next';
import AdminLayout from '../../../components/admin/AdminLayout';
import { authApi } from '../../../services/authApi';
import { userApi } from '../../../services/userApi';
import type { RootState } from '../../../store/store';
import TwoFactorSetupModal from './components/TwoFactorSetupModal';

const AdminSettingsPage = () => {
    const { t } = useTranslation();
    const { user } = useSelector((state: RootState) => state.auth);

    // States
    const [is2FAEnabled, setIs2FAEnabled] = useState(false);
    const [loading, setLoading] = useState(true);
    const [showSetupModal, setShowSetupModal] = useState(false);

    // Disable Flow
    const [showDisableConfirm, setShowDisableConfirm] = useState(false);
    const [disablePassword, setDisablePassword] = useState('');
    const [disableLoading, setDisableLoading] = useState(false);
    const [disableError, setDisableError] = useState<string | null>(null);

    useEffect(() => {
        if (user?.id) {
            fetchSettings();
        }
    }, [user?.id]);

    const fetchSettings = async () => {
        try {
            setLoading(true);
            const userDetails = await userApi.getById(user!.id);
            // Assuming userDetails has isTwoFactorEnabled. 
            // If API doesn't return it yet, we might need to update backend DTO or endpoint.
            // For now, let's assume it does or we check a separate status?
            // Actually, backend UserDto might NOT have it.
            // We'll check userApi.ts content next. 
            // If missing, I will add it to UserDto in backend and frontend.
            if ('isTwoFactorEnabled' in userDetails) {
                setIs2FAEnabled((userDetails as any).isTwoFactorEnabled);
            }
        } catch (error) {
            console.error('Failed to fetch user settings', error);
        } finally {
            setLoading(false);
        }
    };

    const handleDisable2FA = async () => {
        try {
            setDisableLoading(true);
            setDisableError(null);
            await authApi.disableTwoFactor(disablePassword);
            setIs2FAEnabled(false);
            setShowDisableConfirm(false);
            setDisablePassword('');
        } catch (err: any) {
            setDisableError(err.message || 'Failed to disable 2FA');
        } finally {
            setDisableLoading(false);
        }
    };

    return (
        <AdminLayout>
            <div className="mx-auto max-w-4xl p-6">
                <h1 className="mb-6 text-2xl font-bold text-slate-900 dark:text-white">{t('admin.settings.title')}</h1>

                <div className="rounded-xl border border-slate-200 bg-white shadow-sm dark:border-slate-800 dark:bg-dashboard-surface-dark">
                    <div className="border-b border-slate-200 px-6 py-4 dark:border-slate-800">
                        <h2 className="text-lg font-semibold text-slate-900 dark:text-white">{t('admin.settings.security.title')}</h2>
                    </div>

                    <div className="p-6">
                        <div className="flex items-center justify-between">
                            <div>
                                <h3 className="text-base font-medium text-slate-900 dark:text-white">{t('admin.settings.security.twoFactor')}</h3>
                                <p className="mt-1 text-sm text-slate-500 dark:text-slate-400">
                                    {t('admin.settings.security.twoFactorDesc')}
                                </p>
                            </div>

                            {loading ? (
                                <span className="material-symbols-outlined animate-spin text-slate-400">progress_activity</span>
                            ) : (
                                <button
                                    onClick={() => is2FAEnabled ? setShowDisableConfirm(true) : setShowSetupModal(true)}
                                    className={`relative inline-flex h-6 w-11 flex-shrink-0 cursor-pointer rounded-full border-2 border-transparent transition-colors duration-200 ease-in-out focus:outline-none focus:ring-2 focus:ring-dashboard-primary focus:ring-offset-2 ${is2FAEnabled ? 'bg-dashboard-primary' : 'bg-slate-200 dark:bg-slate-700'
                                        }`}
                                >
                                    <span
                                        className={`pointer-events-none inline-block h-5 w-5 transform rounded-full bg-white shadow ring-0 transition duration-200 ease-in-out ${is2FAEnabled ? 'translate-x-5' : 'translate-x-0'
                                            }`}
                                    />
                                </button>
                            )}
                        </div>

                        {is2FAEnabled && (
                            <div className="mt-4 flex items-center gap-2 rounded-md bg-green-50 px-3 py-2 text-sm text-green-700 dark:bg-green-900/20 dark:text-green-300">
                                <span className="material-symbols-outlined text-[18px]">check_circle</span>
                                <span>{t('admin.settings.security.statusEnabled')}</span>
                            </div>
                        )}
                    </div>
                </div>
            </div>

            {/* Setup Modal */}
            <TwoFactorSetupModal
                isOpen={showSetupModal}
                onClose={() => setShowSetupModal(false)}
                onSuccess={() => {
                    setIs2FAEnabled(true);
                    fetchSettings(); // Refresh
                }}
            />

            {/* Disable Confirm Modal */}
            {showDisableConfirm && (
                <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 p-4">
                    <div className="w-full max-w-sm rounded-2xl bg-white p-6 shadow-xl dark:bg-gray-800">
                        <h3 className="mb-4 text-lg font-bold text-gray-900 dark:text-white">{t('admin.settings.security.disableTitle')}</h3>
                        <p className="mb-4 text-sm text-gray-500 dark:text-gray-400">
                            {t('admin.settings.security.disableDesc')}
                        </p>

                        <div className="space-y-4">
                            <input
                                type="password"
                                className="w-full rounded-lg border border-gray-300 p-3 text-sm focus:border-dashboard-primary focus:ring-dashboard-primary dark:border-gray-600 dark:bg-gray-700 dark:text-white"
                                placeholder={t('admin.settings.security.currentPassword')}
                                value={disablePassword}
                                onChange={(e) => setDisablePassword(e.target.value)}
                            />

                            {disableError && <p className="text-sm text-red-500">{disableError}</p>}

                            <div className="flex justify-end gap-3">
                                <button
                                    onClick={() => setShowDisableConfirm(false)}
                                    className="rounded-lg px-4 py-2 text-sm text-gray-600 hover:bg-gray-100 dark:text-gray-300 dark:hover:bg-gray-700"
                                >
                                    {t('admin.settings.security.cancel')}
                                </button>
                                <button
                                    onClick={handleDisable2FA}
                                    disabled={!disablePassword || disableLoading}
                                    className="rounded-lg bg-red-600 px-4 py-2 text-sm font-semibold text-white hover:bg-red-700 disabled:opacity-50"
                                >
                                    {disableLoading ? t('admin.settings.security.disabling') : t('admin.settings.security.disable')}
                                </button>
                            </div>
                        </div>
                    </div>
                </div>
            )}
        </AdminLayout>
    );
};

export default AdminSettingsPage;
