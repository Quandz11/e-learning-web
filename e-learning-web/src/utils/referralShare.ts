export type SharePlatform =
    | 'zalo'
    | 'facebook'
    | 'messenger'
    | 'whatsapp'
    | 'telegram'
    | 'instagram'
    | 'twitter'
    | 'email'
    | 'copy';

export interface SharePayload {
    url: string;
    text: string;
    title?: string;
}

export type DeviceKind = 'mobile' | 'desktop';

const encode = (value: string) => encodeURIComponent(value);

export const getPublicShareBaseUrl = () => {
    const configuredBase = (import.meta.env.VITE_PUBLIC_APP_URL || import.meta.env.VITE_SITE_URL || '').trim();
    if (configuredBase) {
        return configuredBase.replace(/\/+$/, '');
    }

    if (typeof window !== 'undefined') {
        const { origin, hostname } = window.location;
        if (hostname === 'localhost' || hostname === '127.0.0.1') {
            return 'https://nhinanchualanh.vn';
        }

        return origin;
    }

    return 'https://nhinanchualanh.vn';
};

export const getDeviceKind = (): DeviceKind => {
    if (typeof window === 'undefined' || typeof navigator === 'undefined') {
        return 'desktop';
    }

    const ua = navigator.userAgent || '';
    const isMobileUA = /Android|webOS|iPhone|iPad|iPod|BlackBerry|IEMobile|Opera Mini/i.test(ua);
    const hasTouch = (navigator.maxTouchPoints || 0) > 0;
    const isCoarsePointer = typeof window.matchMedia === 'function'
        ? window.matchMedia('(pointer: coarse)').matches
        : false;
    const isNarrowViewport = window.innerWidth < 900;

    return isMobileUA || (hasTouch && isCoarsePointer && isNarrowViewport)
        ? 'mobile'
        : 'desktop';
};

export const shouldTryNativePrefilledShare = (platform: SharePlatform) => {
    return platform === 'zalo' || platform === 'messenger' || platform === 'facebook';
};

export const shareViaNative = async (
    payload: SharePayload
): Promise<'shared' | 'cancelled' | 'unsupported' | 'failed'> => {
    if (typeof navigator === 'undefined' || typeof navigator.share !== 'function') {
        return 'unsupported';
    }

    try {
        await navigator.share({
            title: payload.title,
            text: payload.text,
            url: payload.url,
        });
        return 'shared';
    } catch (error: any) {
        if (error?.name === 'AbortError') {
            return 'cancelled';
        }

        return 'failed';
    }
};

export const requiresManualPasteShare = (platform: SharePlatform) => {
    return platform === 'zalo' || platform === 'messenger' || platform === 'facebook' || platform === 'instagram';
};

export const buildReferralMessage = (discountCode: string, discountPercent: number) => {
    return `Mình mời bạn tham gia học trên SKVI! Dùng link này để đăng ký. Mình có mã giảm giá ${discountCode} (${discountPercent}% off) khi bạn tham gia thành công.`;
};

export const getShareUrl = (platform: SharePlatform, payload: SharePayload): string => {
    const { url, text, title } = payload;

    switch (platform) {
        case 'zalo':
            return 'https://chat.zalo.me/';
        case 'facebook':
            return 'https://www.facebook.com/messages/new/';
        case 'messenger':
            return 'https://www.messenger.com/new';
        case 'whatsapp':
            return `https://wa.me/?text=${encode(`${text}\n\n${url}`)}`;
        case 'telegram':
            return `https://t.me/share/url?url=${encode(url)}&text=${encode(text)}`;
        case 'instagram':
            return 'https://www.instagram.com/direct/inbox/';
        case 'twitter':
            return `https://twitter.com/intent/tweet?text=${encode(text)}&url=${encode(url)}`;
        case 'email':
            return `mailto:?subject=${encode(title || 'Lời mời tham gia SKVI')}&body=${encode(`${text}\n\n${url}`)}`;
        case 'copy':
            return url;
        default:
            return url;
    }
};
