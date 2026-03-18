import React, { useMemo, useState } from 'react';
import { useSelector } from 'react-redux';
import { useLocation } from 'react-router-dom';
import { useTranslation } from 'react-i18next';
import {
    FaFacebookF,
    FaFacebookMessenger,
    FaInstagram,
    FaTelegram,
    FaWhatsapp,
    FaXTwitter,
    FaEnvelope,
    FaRegCopy,
    FaXmark,
    FaLink
} from 'react-icons/fa6';
import type { RootState } from '../../store/store';
import { useToast } from '../../contexts/ToastContext';
import { userReferralApi, type UserReferralOverviewDto } from '../../services/userReferralApi';
import {
    getDeviceKind,
    getPublicShareBaseUrl,
    getShareUrl,
    requiresManualPasteShare,
    shareViaNative,
    shouldTryNativePrefilledShare,
    type SharePlatform
} from '../../utils/referralShare';

const ReferralInviteFloat: React.FC = () => {
    const { t } = useTranslation();
    const location = useLocation();
    const { isAuthenticated, user } = useSelector((state: RootState) => state.auth);
    const { showToast } = useToast();

    const [isOpen, setIsOpen] = useState(false);
    const [isLoading, setIsLoading] = useState(false);
    const [overview, setOverview] = useState<UserReferralOverviewDto | null>(null);
    const isMobileDevice = useMemo(() => getDeviceKind() === 'mobile', []);

    const referralLink = useMemo(() => {
        if (!overview?.referral?.referralCode) return '';
        const base = getPublicShareBaseUrl();
        return `${base}/register?ref=${overview.referral.referralCode}`;
    }, [overview]);

    const shareMessage = useMemo(() => {
        if (!overview) return '';
        return t('referralInvite.shareMessage', {
            discountCode: overview.referral.discountCode,
            discountPercent: overview.referral.discountPercent,
        });
    }, [overview, t]);

    const shouldHideOnPath = useMemo(() => {
        const hiddenExactPaths = ['/login', '/register', '/forgot-password', '/otp-verify'];
        const hiddenPathPrefixes = ['/admin'];

        if (hiddenExactPaths.includes(location.pathname)) {
            return true;
        }

        return hiddenPathPrefixes.some((prefix) => location.pathname.startsWith(prefix));
    }, [location.pathname]);

    const shouldHideForRole = useMemo(() => {
        const normalizedRole = user?.role?.toUpperCase();
        return normalizedRole === 'ADMIN';
    }, [user?.role]);

    if (shouldHideOnPath || shouldHideForRole) {
        return null;
    }

    const loadReferral = async () => {
        try {
            setIsLoading(true);
            const data = await userReferralApi.getMyReferral();
            setOverview(data);
        } catch (error: any) {
            showToast(error?.message || t('referralInvite.toast.loadFailed'), 'error');
        } finally {
            setIsLoading(false);
        }
    };

    const handleOpen = async () => {
        if (!isAuthenticated) {
            showToast(t('referralInvite.toast.loginRequired'), 'info');
            return;
        }

        setIsOpen(true);
        if (!overview) {
            await loadReferral();
        }
    };

    const handleShare = async (platform: SharePlatform) => {
        if (!overview || !referralLink) {
            return;
        }

        const payload = {
            url: referralLink,
            text: shareMessage,
            title: t('referralInvite.shareTitle')
        };

        if (platform === 'copy') {
            await navigator.clipboard.writeText(referralLink);
            showToast(t('referralInvite.toast.linkCopied'), 'success');
            return;
        }

        const shareContent = `${shareMessage}\n\n${referralLink}`;

        // Mobile: try native share so message is prefilled and user can choose recipient in app.
        if (isMobileDevice && shouldTryNativePrefilledShare(platform)) {
            const nativeResult = await shareViaNative(payload);
            if (nativeResult === 'shared' || nativeResult === 'cancelled') {
                return;
            }
        }

        if (requiresManualPasteShare(platform)) {
            await navigator.clipboard.writeText(shareContent);
            window.open(getShareUrl(platform, payload), '_blank', 'noopener,noreferrer');

            if (platform === 'zalo') {
                showToast(t('referralInvite.toast.manualPasteZalo'), 'info');
            } else if (platform === 'messenger') {
                showToast(t('referralInvite.toast.manualPasteMessenger'), 'info');
            } else if (platform === 'facebook') {
                showToast(t('referralInvite.toast.manualPasteFacebook'), 'info');
            } else {
                showToast(t('referralInvite.toast.manualPasteInstagram'), 'info');
            }
            return;
        }

        const shareUrl = getShareUrl(platform, payload);
        if (platform === 'email') {
            window.location.href = shareUrl;
            return;
        }

        const popup = window.open(shareUrl, '_blank', 'noopener,noreferrer');
        if (!popup) {
            await navigator.clipboard.writeText(shareContent);
            showToast(t('referralInvite.toast.popupBlocked'), 'warning');
        }
    };

    return (
        <>
            <button
                onClick={handleOpen}
                className="group fixed bottom-24 right-4 z-[60] flex h-12 w-12 items-center justify-center rounded-full bg-sky-600 p-0 text-white shadow-xl transition-all duration-300 hover:scale-105 hover:bg-sky-500 sm:right-6 sm:h-auto sm:w-auto sm:justify-start sm:gap-2 sm:px-4 sm:py-3"
                aria-label={t('referralInvite.buttonAriaLabel')}
            >
                <span className="absolute -top-1 -right-1 inline-flex h-3 w-3 animate-ping rounded-full bg-amber-300" />
                <span className="absolute -top-1 -right-1 inline-flex h-3 w-3 rounded-full bg-amber-300" />
                <span className="material-symbols-outlined text-[22px]">share</span>
                <span className="hidden text-sm font-semibold sm:inline">{t('referralInvite.buttonLabel')}</span>
            </button>

            {isOpen && (
                <div className="fixed inset-0 z-[80] flex items-end justify-center bg-black/60 p-2 sm:items-center sm:p-4">
                    <div className="max-h-[92vh] w-full max-w-2xl overflow-y-auto rounded-2xl bg-white p-4 shadow-2xl dark:bg-gray-900 sm:p-6">
                        <div className="mb-4 flex items-center justify-between sm:mb-6">
                            <div>
                                <h3 className="text-lg font-bold text-slate-900 dark:text-white sm:text-xl">{t('referralInvite.modalTitle')}</h3>
                                <p className="mt-1 text-xs text-slate-500 dark:text-slate-400 sm:text-sm">
                                    {t('referralInvite.modalDescription')}
                                </p>
                            </div>
                            <button
                                onClick={() => setIsOpen(false)}
                                className="rounded-full p-2 text-slate-500 transition hover:bg-slate-100 hover:text-slate-700 dark:hover:bg-slate-800"
                                aria-label={t('referralInvite.closeAriaLabel')}
                            >
                                <FaXmark className="text-xl" />
                            </button>
                        </div>

                        {isLoading ? (
                            <div className="rounded-xl border border-slate-200 p-6 text-center text-sm text-slate-500 dark:border-slate-700">
                                {t('referralInvite.loading')}
                            </div>
                        ) : overview ? (
                            <>
                                <div className="grid gap-3 sm:grid-cols-2">
                                    <div className="rounded-xl border border-sky-200 bg-sky-50 p-4 dark:border-sky-800/60 dark:bg-sky-900/20">
                                        <p className="text-xs uppercase tracking-wide text-sky-700 dark:text-sky-300">{t('referralInvite.referralCodeLabel')}</p>
                                        <p className="mt-1 text-lg font-bold text-sky-900 dark:text-sky-100">{overview.referral.referralCode}</p>
                                    </div>
                                    <div className="rounded-xl border border-emerald-200 bg-emerald-50 p-4 dark:border-emerald-800/60 dark:bg-emerald-900/20">
                                        <p className="text-xs uppercase tracking-wide text-emerald-700 dark:text-emerald-300">{t('referralInvite.discountCodeLabel')}</p>
                                        <p className="mt-1 text-lg font-bold text-emerald-900 dark:text-emerald-100">
                                            {overview.referral.discountCode} ({overview.referral.discountPercent}%)
                                        </p>
                                    </div>
                                </div>

                                <div className="mt-4 grid grid-cols-1 gap-3 min-[420px]:grid-cols-3">
                                    <div className="rounded-xl border border-slate-200 bg-slate-50 p-3 text-center dark:border-slate-700 dark:bg-slate-800">
                                        <p className="text-xs text-slate-500">{t('referralInvite.stats.totalInvites')}</p>
                                        <p className="mt-1 text-lg font-bold text-slate-900 dark:text-white">{overview.stats.totalInvites}</p>
                                    </div>
                                    <div className="rounded-xl border border-slate-200 bg-slate-50 p-3 text-center dark:border-slate-700 dark:bg-slate-800">
                                        <p className="text-xs text-slate-500">{t('referralInvite.stats.successfulInvites')}</p>
                                        <p className="mt-1 text-lg font-bold text-slate-900 dark:text-white">{overview.stats.successfulInvites}</p>
                                    </div>
                                    <div className="rounded-xl border border-slate-200 bg-slate-50 p-3 text-center dark:border-slate-700 dark:bg-slate-800">
                                        <p className="text-xs text-slate-500">{t('referralInvite.stats.pendingInvites')}</p>
                                        <p className="mt-1 text-lg font-bold text-slate-900 dark:text-white">{overview.stats.pendingInvites}</p>
                                    </div>
                                </div>

                                <div className="mt-4 rounded-xl border border-slate-200 p-3 dark:border-slate-700">
                                    <p className="mb-2 text-xs text-slate-500">{t('referralInvite.linkLabel')}</p>
                                    <div className="flex flex-col gap-2 sm:flex-row">
                                        <input
                                            readOnly
                                            value={referralLink}
                                            className="w-full rounded-lg border border-slate-200 bg-slate-50 px-3 py-2 text-sm text-slate-700 dark:border-slate-700 dark:bg-slate-800 dark:text-slate-200"
                                        />
                                        <button
                                            onClick={() => handleShare('copy')}
                                            className="h-10 rounded-lg bg-slate-900 px-3 text-white transition hover:bg-slate-700 dark:bg-slate-200 dark:text-slate-900"
                                            aria-label={t('referralInvite.copyAriaLabel')}
                                        >
                                            <FaRegCopy />
                                        </button>
                                    </div>
                                </div>

                                <div className="mt-5 grid grid-cols-2 gap-2 sm:grid-cols-4">
                                    <ShareButton icon={<span className="font-bold">Z</span>} label="Zalo" color="bg-sky-500" onClick={() => handleShare('zalo')} />
                                    <ShareButton icon={<FaFacebookF />} label="Facebook" color="bg-blue-600" onClick={() => handleShare('facebook')} />
                                    <ShareButton icon={<FaFacebookMessenger />} label="Messenger" color="bg-indigo-600" onClick={() => handleShare('messenger')} />
                                    <ShareButton icon={<FaWhatsapp />} label="WhatsApp" color="bg-emerald-600" onClick={() => handleShare('whatsapp')} />
                                    <ShareButton icon={<FaTelegram />} label="Telegram" color="bg-cyan-600" onClick={() => handleShare('telegram')} />
                                    <ShareButton icon={<FaInstagram />} label="Instagram" color="bg-pink-600" onClick={() => handleShare('instagram')} />
                                    <ShareButton icon={<FaXTwitter />} label="Twitter" color="bg-slate-900" onClick={() => handleShare('twitter')} />
                                    <ShareButton icon={<FaEnvelope />} label="Email" color="bg-amber-600" onClick={() => handleShare('email')} />
                                </div>

                                <div className="mt-5 rounded-xl border border-dashed border-slate-300 p-3 text-sm text-slate-600 dark:border-slate-700 dark:text-slate-300">
                                    <p className="font-semibold">{t('referralInvite.shareTipsTitle')}</p>
                                    <p className="mt-1">{t('referralInvite.shareTip1')}</p>
                                    <p className="mt-1">{t('referralInvite.shareTip2')}</p>
                                </div>
                            </>
                        ) : (
                            <div className="rounded-xl border border-slate-200 p-6 text-center text-sm text-slate-500 dark:border-slate-700">
                                {t('referralInvite.loadError')}
                                <div className="mt-3">
                                    <button
                                        onClick={loadReferral}
                                        className="rounded-lg bg-primary px-4 py-2 text-white transition hover:bg-primary-dark"
                                    >
                                        {t('referralInvite.reload')}
                                    </button>
                                </div>
                            </div>
                        )}
                    </div>
                </div>
            )}
        </>
    );
};

type ShareButtonProps = {
    icon: React.ReactNode;
    label: string;
    color: string;
    onClick: () => void;
};

const ShareButton: React.FC<ShareButtonProps> = ({ icon, label, color, onClick }) => {
    return (
        <button
            onClick={onClick}
            className={`group flex items-center gap-2 rounded-xl ${color} px-3 py-2 text-sm font-semibold text-white transition hover:-translate-y-0.5 hover:shadow-lg`}
        >
            <span className="flex h-7 w-7 items-center justify-center rounded-full bg-white/20 text-base">
                {icon}
            </span>
            <span className="truncate">{label}</span>
            <FaLink className="ml-auto text-[11px] opacity-0 transition group-hover:opacity-100" />
        </button>
    );
};

export default ReferralInviteFloat;
