import React, { useMemo, useState } from 'react';
import { useSelector } from 'react-redux';
import { useLocation } from 'react-router-dom';
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
    buildReferralMessage,
    getDeviceKind,
    getPublicShareBaseUrl,
    getShareUrl,
    requiresManualPasteShare,
    shareViaNative,
    shouldTryNativePrefilledShare,
    type SharePlatform
} from '../../utils/referralShare';

const ReferralInviteFloat: React.FC = () => {
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
        return buildReferralMessage(overview.referral.discountCode, overview.referral.discountPercent);
    }, [overview]);

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
            showToast(error?.message || 'Không thể tải mã mời. Vui lòng thử lại.', 'error');
        } finally {
            setIsLoading(false);
        }
    };

    const handleOpen = async () => {
        if (!isAuthenticated) {
            showToast('Vui lòng đăng nhập để lấy link mời bạn bè.', 'info');
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
            title: 'Mời bạn học cùng SKVI'
        };

        if (platform === 'copy') {
            await navigator.clipboard.writeText(referralLink);
            showToast('Đã sao chép link mời.', 'success');
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
                showToast('Đã sao chép nội dung. Bạn dán vào Zalo để gửi lời mời nhé.', 'info');
            } else if (platform === 'messenger') {
                showToast('Đã sao chép nội dung. Bạn dán vào Messenger để gửi lời mời nhé.', 'info');
            } else if (platform === 'facebook') {
                showToast('Đã sao chép nội dung. Bạn chọn người nhận trên Facebook rồi dán để gửi nhé.', 'info');
            } else {
                showToast('Đã sao chép nội dung. Bạn dán vào Instagram DM hoặc story nhé.', 'info');
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
            showToast('Trình duyệt đang chặn popup. Nội dung đã được sao chép để bạn dán thủ công.', 'warning');
        }
    };

    return (
        <>
            <button
                onClick={handleOpen}
                className="group fixed bottom-24 right-6 z-[60] flex items-center gap-2 rounded-full bg-sky-600 px-4 py-3 text-white shadow-xl transition-all duration-300 hover:scale-105 hover:bg-sky-500"
                aria-label="Mời bạn bè"
            >
                <span className="absolute -top-1 -right-1 inline-flex h-3 w-3 animate-ping rounded-full bg-amber-300" />
                <span className="absolute -top-1 -right-1 inline-flex h-3 w-3 rounded-full bg-amber-300" />
                <span className="material-symbols-outlined text-[22px]">share</span>
                <span className="text-sm font-semibold">Mời bạn</span>
            </button>

            {isOpen && (
                <div className="fixed inset-0 z-[80] flex items-center justify-center bg-black/60 p-4">
                    <div className="w-full max-w-2xl rounded-2xl bg-white p-6 shadow-2xl dark:bg-gray-900">
                        <div className="mb-6 flex items-center justify-between">
                            <div>
                                <h3 className="text-xl font-bold text-slate-900 dark:text-white">Mời bạn bè cùng học</h3>
                                <p className="mt-1 text-sm text-slate-500 dark:text-slate-400">
                                    Chia sẻ link mời của bạn qua Zalo, Facebook, Instagram và nhiều nền tảng khác.
                                </p>
                            </div>
                            <button
                                onClick={() => setIsOpen(false)}
                                className="rounded-full p-2 text-slate-500 transition hover:bg-slate-100 hover:text-slate-700 dark:hover:bg-slate-800"
                                aria-label="Đóng"
                            >
                                <FaXmark className="text-xl" />
                            </button>
                        </div>

                        {isLoading ? (
                            <div className="rounded-xl border border-slate-200 p-6 text-center text-sm text-slate-500 dark:border-slate-700">
                                Đang tạo mã mời cho bạn...
                            </div>
                        ) : overview ? (
                            <>
                                <div className="grid gap-3 sm:grid-cols-2">
                                    <div className="rounded-xl border border-sky-200 bg-sky-50 p-4 dark:border-sky-800/60 dark:bg-sky-900/20">
                                        <p className="text-xs uppercase tracking-wide text-sky-700 dark:text-sky-300">Mã mời</p>
                                        <p className="mt-1 text-lg font-bold text-sky-900 dark:text-sky-100">{overview.referral.referralCode}</p>
                                    </div>
                                    <div className="rounded-xl border border-emerald-200 bg-emerald-50 p-4 dark:border-emerald-800/60 dark:bg-emerald-900/20">
                                        <p className="text-xs uppercase tracking-wide text-emerald-700 dark:text-emerald-300">Mã giảm giá của bạn</p>
                                        <p className="mt-1 text-lg font-bold text-emerald-900 dark:text-emerald-100">
                                            {overview.referral.discountCode} ({overview.referral.discountPercent}%)
                                        </p>
                                    </div>
                                </div>

                                <div className="mt-4 grid grid-cols-3 gap-3">
                                    <div className="rounded-xl border border-slate-200 bg-slate-50 p-3 text-center dark:border-slate-700 dark:bg-slate-800">
                                        <p className="text-xs text-slate-500">Tổng lời mời</p>
                                        <p className="mt-1 text-lg font-bold text-slate-900 dark:text-white">{overview.stats.totalInvites}</p>
                                    </div>
                                    <div className="rounded-xl border border-slate-200 bg-slate-50 p-3 text-center dark:border-slate-700 dark:bg-slate-800">
                                        <p className="text-xs text-slate-500">Thành công</p>
                                        <p className="mt-1 text-lg font-bold text-slate-900 dark:text-white">{overview.stats.successfulInvites}</p>
                                    </div>
                                    <div className="rounded-xl border border-slate-200 bg-slate-50 p-3 text-center dark:border-slate-700 dark:bg-slate-800">
                                        <p className="text-xs text-slate-500">Đang chờ</p>
                                        <p className="mt-1 text-lg font-bold text-slate-900 dark:text-white">{overview.stats.pendingInvites}</p>
                                    </div>
                                </div>

                                <div className="mt-4 rounded-xl border border-slate-200 p-3 dark:border-slate-700">
                                    <p className="mb-2 text-xs text-slate-500">Link mời của bạn</p>
                                    <div className="flex gap-2">
                                        <input
                                            readOnly
                                            value={referralLink}
                                            className="w-full rounded-lg border border-slate-200 bg-slate-50 px-3 py-2 text-sm text-slate-700 dark:border-slate-700 dark:bg-slate-800 dark:text-slate-200"
                                        />
                                        <button
                                            onClick={() => handleShare('copy')}
                                            className="rounded-lg bg-slate-900 px-3 text-white transition hover:bg-slate-700 dark:bg-slate-200 dark:text-slate-900"
                                            aria-label="Sao chép"
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
                                    <p className="font-semibold">Mẹo chia sẻ</p>
                                    <p className="mt-1">Khi bạn bè đăng ký qua link này, hệ thống ghi nhận lời mời của bạn để mở khóa ưu đãi giảm giá.</p>
                                    <p className="mt-1">Mobile: Zalo/Facebook/Messenger mở bảng chia sẻ với tin nhắn sẵn. Desktop: hệ thống copy trước rồi mở chat để bạn dán gửi.</p>
                                </div>
                            </>
                        ) : (
                            <div className="rounded-xl border border-slate-200 p-6 text-center text-sm text-slate-500 dark:border-slate-700">
                                Chưa thể tải dữ liệu referral. Bạn bấm thử lại nhé.
                                <div className="mt-3">
                                    <button
                                        onClick={loadReferral}
                                        className="rounded-lg bg-primary px-4 py-2 text-white transition hover:bg-primary-dark"
                                    >
                                        Tải lại
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
            <span>{label}</span>
            <FaLink className="ml-auto text-[11px] opacity-0 transition group-hover:opacity-100" />
        </button>
    );
};

export default ReferralInviteFloat;
