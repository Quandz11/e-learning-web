import React, { useEffect, useState } from 'react';
import { useTranslation } from 'react-i18next';
import { sessionApi, type ActiveSession } from '../../../../services/sessionApi';
import { formatDistanceToNow } from 'date-fns';
import { vi, enUS } from 'date-fns/locale';
import ConfirmModal from '../../../../components/ui/Modal/ConfirmModal';
import { useToast } from '../../../../contexts/ToastContext';

const LoginHistory: React.FC = () => {
    const { t, i18n } = useTranslation();
    const { showToast } = useToast();
    const [sessions, setSessions] = useState<ActiveSession[]>([]);
    const [loading, setLoading] = useState(true);
    const [showRevokeModal, setShowRevokeModal] = useState(false);
    const [showRevokeAllModal, setShowRevokeAllModal] = useState(false);
    const [revokingSessionId, setRevokingSessionId] = useState<string | null>(null);
    const [isRevoking, setIsRevoking] = useState(false);

    const locale = i18n.language === 'vi' ? vi : enUS;

    useEffect(() => {
        loadSessions();
    }, []);

    const loadSessions = async () => {
        try {
            setLoading(true);
            const data = await sessionApi.getActiveSessions();
            setSessions(data);
        } catch (error: any) {
            showToast(error.message || t('admin.settings.loginHistory.loadError'), 'error');
        } finally {
            setLoading(false);
        }
    };

    const handleRevokeClick = (sessionId: string) => {
        setRevokingSessionId(sessionId);
        setShowRevokeModal(true);
    };

    const handleConfirmRevoke = async () => {
        if (!revokingSessionId) return;

        setIsRevoking(true);
        try {
            await sessionApi.revokeSession(revokingSessionId);
            showToast(t('admin.settings.loginHistory.logoutSuccess'), 'success');
            setShowRevokeModal(false);
            await loadSessions();
        } catch (error: any) {
            showToast(error.message || t('admin.settings.loginHistory.logoutError'), 'error');
        } finally {
            setIsRevoking(false);
        }
    };

    const handleRevokeAllClick = () => {
        setShowRevokeAllModal(true);
    };

    const handleConfirmRevokeAll = async () => {
        setIsRevoking(true);
        try {
            await sessionApi.revokeAllSessions();
            showToast(t('admin.settings.loginHistory.logoutAllSuccess'), 'success');
            setShowRevokeAllModal(false);
            await loadSessions();
        } catch (error: any) {
            showToast(error.message || t('admin.settings.loginHistory.logoutAllError'), 'error');
        } finally {
            setIsRevoking(false);
        }
    };

    const getDeviceIcon = (deviceName: string) => {
        const lower = deviceName.toLowerCase();
        if (lower.includes('iphone') || lower.includes('android')) return 'smartphone';
        if (lower.includes('ipad') || lower.includes('tablet')) return 'tablet';
        if (lower.includes('mac') || lower.includes('windows') || lower.includes('linux')) return 'computer';
        return 'devices';
    };

    if (loading) {
        return (
            <div className="flex items-center justify-center py-12">
                <span className="material-symbols-outlined animate-spin text-4xl text-slate-400">progress_activity</span>
            </div>
        );
    }

    return (
        <div className="space-y-4">
            <div className="flex items-center justify-between">
                <div>
                    <h3 className="text-base font-medium text-slate-900 dark:text-white">
                        {t('admin.settings.loginHistory.title')}
                    </h3>
                    <p className="mt-1 text-sm text-slate-500 dark:text-slate-400">
                        {t('admin.settings.loginHistory.subtitle')}
                    </p>
                </div>
                {sessions.length > 1 && (
                    <button
                        onClick={handleRevokeAllClick}
                        className="inline-flex items-center gap-2 rounded-lg border border-red-200 px-4 py-2 text-sm font-medium text-red-600 transition hover:bg-red-50 dark:border-red-700 dark:text-red-400 dark:hover:bg-red-900/20"
                    >
                        <span className="material-symbols-outlined text-[18px]">logout</span>
                        {t('admin.settings.loginHistory.logoutAll')}
                    </button>
                )}
            </div>

            {sessions.length === 0 ? (
                <div className="rounded-xl border border-dashed border-slate-300 bg-slate-50 p-8 text-center dark:border-slate-700 dark:bg-slate-800/50">
                    <span className="material-symbols-outlined text-4xl text-slate-400">devices_off</span>
                    <p className="mt-2 text-sm text-slate-500 dark:text-slate-400">
                        {t('admin.settings.loginHistory.noSessions')}
                    </p>
                </div>
            ) : (
                <div className="space-y-3">
                    {sessions.map((session) => (
                        <div
                            key={session.sessionId}
                            className={`flex items-center justify-between rounded-xl border p-4 transition ${session.isCurrentSession
                                    ? 'border-green-200 bg-green-50 dark:border-green-800 dark:bg-green-900/20'
                                    : 'border-slate-200 bg-white dark:border-slate-700 dark:bg-slate-800'
                                }`}
                        >
                            <div className="flex items-start gap-4">
                                <div className={`flex h-12 w-12 items-center justify-center rounded-full ${session.isCurrentSession
                                        ? 'bg-green-100 text-green-600 dark:bg-green-900/40 dark:text-green-400'
                                        : 'bg-slate-100 text-slate-600 dark:bg-slate-700 dark:text-slate-400'
                                    }`}>
                                    <span className="material-symbols-outlined text-2xl">
                                        {getDeviceIcon(session.deviceName)}
                                    </span>
                                </div>

                                <div className="flex-1">
                                    <div className="flex items-center gap-2">
                                        <h4 className="font-semibold text-slate-900 dark:text-white">
                                            {session.deviceName}
                                        </h4>
                                        {session.isCurrentSession && (
                                            <span className="inline-flex items-center gap-1 rounded-full bg-green-100 px-2 py-0.5 text-xs font-semibold text-green-700 dark:bg-green-900/40 dark:text-green-300">
                                                <span className="material-symbols-outlined text-[14px]">check_circle</span>
                                                {t('admin.settings.loginHistory.currentDevice')}
                                            </span>
                                        )}
                                    </div>
                                    <div className="mt-1 space-y-0.5 text-sm text-slate-600 dark:text-slate-400">
                                        <div className="flex items-center gap-1.5">
                                            <span className="material-symbols-outlined text-[16px]">language</span>
                                            <span>{session.browser}</span>
                                        </div>
                                        <div className="flex items-center gap-1.5">
                                            <span className="material-symbols-outlined text-[16px]">location_on</span>
                                            <span>{session.ipAddress}</span>
                                        </div>
                                        <div className="flex items-center gap-1.5">
                                            <span className="material-symbols-outlined text-[16px]">schedule</span>
                                            <span>
                                                {formatDistanceToNow(new Date(session.loginTime), {
                                                    addSuffix: true,
                                                    locale,
                                                })}
                                            </span>
                                        </div>
                                    </div>
                                </div>
                            </div>

                            {!session.isCurrentSession && (
                                <button
                                    onClick={() => handleRevokeClick(session.sessionId)}
                                    className="inline-flex items-center gap-1 rounded-lg border border-red-200 px-3 py-1.5 text-sm font-medium text-red-600 transition hover:bg-red-50 dark:border-red-700 dark:text-red-400 dark:hover:bg-red-900/20"
                                >
                                    <span className="material-symbols-outlined text-[18px]">logout</span>
                                    {t('admin.settings.loginHistory.logout')}
                                </button>
                            )}
                        </div>
                    ))}
                </div>
            )}

            {/* Revoke Single Session Modal */}
            <ConfirmModal
                isOpen={showRevokeModal}
                onClose={() => setShowRevokeModal(false)}
                onConfirm={handleConfirmRevoke}
                title={t('admin.settings.loginHistory.confirmLogout')}
                message={t('admin.settings.loginHistory.confirmLogoutMessage')}
                confirmText={t('admin.settings.loginHistory.logout')}
                cancelText={t('modal.cancel')}
                variant="danger"
                isLoading={isRevoking}
            />

            {/* Revoke All Sessions Modal */}
            <ConfirmModal
                isOpen={showRevokeAllModal}
                onClose={() => setShowRevokeAllModal(false)}
                onConfirm={handleConfirmRevokeAll}
                title={t('admin.settings.loginHistory.confirmLogoutAll')}
                message={t('admin.settings.loginHistory.confirmLogoutAllMessage')}
                confirmText={t('admin.settings.loginHistory.logoutAll')}
                cancelText={t('modal.cancel')}
                variant="danger"
                isLoading={isRevoking}
            />
        </div>
    );
};

export default LoginHistory;
