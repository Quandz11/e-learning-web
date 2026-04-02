import React, { useEffect, useState } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { useSelector, useDispatch } from 'react-redux';
import { useTranslation } from 'react-i18next';
import type { RootState, AppDispatch } from '../../store/store';
import { logout } from '../../store/authSlice';
import { authApi } from '../../services/authApi';
import { clearAuth } from '../../services/authStorage';
import HeaderNotification from '../common/HeaderNotification';
import LanguageSwitcher from '../common/LanguageSwitcher';
import UserMenu from '../common/UserMenu';
import logoImg from '../../assets/logo-rm-bg.png';
import { paymentCart, PAYMENT_CART_CHANGED_EVENT } from '../../services/paymentCart';

interface NavLinkItem {
    label: string;
    to?: string;
    href?: string;
}

const UserHeader: React.FC = () => {
    const { t } = useTranslation();
    const navigate = useNavigate();
    const dispatch = useDispatch<AppDispatch>();
    const { isAuthenticated, user } = useSelector((state: RootState) => state.auth);
    const [cartCount, setCartCount] = useState(0);
    const [isMobileMenuOpen, setIsMobileMenuOpen] = useState(false);
    const contactHref = '/contact';

    useEffect(() => {
        const syncCartCount = () => {
            setCartCount(paymentCart.count());
        };

        syncCartCount();
        window.addEventListener(PAYMENT_CART_CHANGED_EVENT, syncCartCount);
        window.addEventListener('storage', syncCartCount);

        return () => {
            window.removeEventListener(PAYMENT_CART_CHANGED_EVENT, syncCartCount);
            window.removeEventListener('storage', syncCartCount);
        };
    }, []);

    const handleLogout = async () => {
        try {
            await authApi.logout();
            dispatch(logout());
            clearAuth();
            setIsMobileMenuOpen(false);
            navigate('/login');
        } catch (error) {
            console.error('Logout error:', error);
        }
    };

    const trainingItems: NavLinkItem[] = [
        { label: t('home.header.nav.courses'), to: '/courses' },
        { label: t('home.header.nav.knowledge', { defaultValue: 'Cập nhật kiến thức' }), to: '/articles' },
        { label: t('home.header.nav.challenge', { defaultValue: 'Thử thách 10 ngày' }), to: '/challenge-10-days' },
        { label: t('home.header.nav.specialCoaching', { defaultValue: 'Huấn luyện đặc biệt' }), to: '/pricing' },
    ];

    const communityItems: NavLinkItem[] = [
        { label: t('home.header.nav.forum', { defaultValue: 'Diễn đàn' }), to: '/forum' },
        { label: t('home.header.nav.ambassador', { defaultValue: 'Đại sứ sức khỏe' }), to: '/ambassador' },
        { label: t('home.header.nav.testimonials'), to: '/testimonials' },
    ];

    const aboutItems: NavLinkItem[] = [
        { label: t('home.header.nav.missionVision', { defaultValue: 'Sứ mệnh & tầm nhìn' }), to: '/mission-vision' },
        { label: t('home.header.nav.pricing', { defaultValue: 'Bảng giá' }), to: '/pricing' },
        { label: t('home.header.nav.policy', { defaultValue: 'Chính sách' }), to: '/privacy-policy' },
    ];
    const courseCenterItem: NavLinkItem = { label: t('home.header.nav.courseCenter', { defaultValue: 'Trung tâm khóa học' }), to: '/courses' };

    const renderDesktopMenuItem = (item: NavLinkItem, className: string, key: string) => {
        if (item.to) {
            return (
                <Link key={key} to={item.to} className={className}>
                    {item.label}
                </Link>
            );
        }

        return (
            <a key={key} href={item.href} className={className}>
                {item.label}
            </a>
        );
    };

    const renderMobileMenuItem = (item: NavLinkItem, className: string, key: string) => {
        if (item.to) {
            return (
                <Link
                    key={key}
                    to={item.to}
                    onClick={() => setIsMobileMenuOpen(false)}
                    className={className}
                >
                    {item.label}
                </Link>
            );
        }

        return (
            <a
                key={key}
                href={item.href}
                onClick={() => setIsMobileMenuOpen(false)}
                className={className}
            >
                {item.label}
            </a>
        );
    };

    const renderDesktopDropdown = (label: string, items: NavLinkItem[]) => (
        <div className="group relative">
            <button
                type="button"
                className="inline-flex items-center gap-1 text-[#0c1c1d] dark:text-gray-300 hover:text-primary dark:hover:text-primary transition-colors text-sm font-medium"
            >
                {label}
                <span className="material-symbols-outlined text-[18px] transition-transform group-hover:rotate-180">expand_more</span>
            </button>

            <div className="invisible absolute left-0 top-full z-50 pt-2 opacity-0 transition-all duration-150 group-hover:visible group-hover:opacity-100 group-focus-within:visible group-focus-within:opacity-100">
                <div className="min-w-[15rem] rounded-xl border border-gray-200 bg-white p-2 shadow-xl dark:border-gray-700 dark:bg-slate-900">
                    {items.map((item, index) =>
                        renderDesktopMenuItem(
                            item,
                            'block rounded-lg px-3 py-2 text-sm text-gray-700 dark:text-gray-200 hover:bg-primary/10 hover:text-primary',
                            `${label}-${index}`,
                        )
                    )}
                </div>
            </div>
        </div>
    );

    return (
        <header className="sticky top-0 z-50 w-full bg-background-light/95 dark:bg-background-dark/95 backdrop-blur-md border-b border-gray-200 dark:border-gray-800">
            <div className="w-full px-3 sm:px-4 lg:px-5">
                <div className="flex items-center justify-between gap-2 h-16 sm:h-20">
                    {/* Logo */}
                    <Link
                        to="/"
                        onClick={() => setIsMobileMenuOpen(false)}
                        className="flex items-center gap-2 sm:gap-3"
                    >
                        <div className="size-10 sm:size-12 flex items-center justify-center overflow-hidden">
                            <img src={logoImg} alt="Logo" className="w-full h-full object-contain" />
                        </div>
                        <h2 className="hidden sm:block text-[#0c1c1d] dark:text-white text-base lg:text-lg font-bold tracking-tight">
                            NhinAnChuaLanh<span className="text-primary">.vn</span>
                        </h2>
                    </Link>

                    {/* Desktop Nav */}
                    <nav className="hidden lg:flex items-center gap-6 xl:gap-8">
                        <Link
                            className="text-[#0c1c1d] dark:text-gray-300 hover:text-primary dark:hover:text-primary transition-colors text-sm font-semibold"
                            to="/"
                        >
                            {t('home.header.nav.home')}
                        </Link>
                        {renderDesktopMenuItem(
                            courseCenterItem,
                            'text-[#0c1c1d] dark:text-gray-300 hover:text-primary dark:hover:text-primary transition-colors text-sm font-medium',
                            'course-center-desktop',
                        )}
                        {renderDesktopDropdown(
                            t('home.header.nav.training', { defaultValue: 'Đào tạo' }),
                            trainingItems,
                        )}
                        {renderDesktopDropdown(
                            t('home.header.nav.community', { defaultValue: 'Cộng đồng' }),
                            communityItems,
                        )}
                        {renderDesktopDropdown(
                            t('home.header.nav.about', { defaultValue: 'Về chúng tôi' }),
                            aboutItems,
                        )}
                        <a
                            className="text-[#0c1c1d] dark:text-gray-300 hover:text-primary dark:hover:text-primary transition-colors text-sm font-medium"
                            href={contactHref}
                        >
                            {t('home.header.nav.contact', { defaultValue: 'Liên hệ' })}
                        </a>
                    </nav>

                    {/* Auth Buttons */}
                    <div className="flex items-center gap-2 sm:gap-3">
                        <LanguageSwitcher />
                        {isAuthenticated && user ? (
                            <>
                                <Link
                                    to="/checkout"
                                    className="relative inline-flex h-10 w-10 sm:h-11 sm:w-11 items-center justify-center rounded-lg border border-primary text-primary hover:bg-primary/10 transition-colors"
                                    title={t('home.header.cartTitle')}
                                >
                                    <span className="material-symbols-outlined text-[20px]">shopping_cart</span>
                                    {cartCount > 0 && (
                                        <span className="absolute -right-2 -top-2 inline-flex h-5 min-w-5 items-center justify-center rounded-full bg-red-500 px-1 text-[10px] font-bold text-white">
                                            {cartCount}
                                        </span>
                                    )}
                                </Link>

                                <div className="hidden sm:block">
                                    <HeaderNotification />
                                </div>

                                <UserMenu user={user} />

                                <button
                                    onClick={handleLogout}
                                    className="hidden md:flex h-11 items-center justify-center rounded-lg px-5 bg-primary hover:bg-primary/90 text-white font-bold text-sm shadow-md shadow-primary/20 transition-all hover:scale-105"
                                >
                                    {t('home.header.logout')}
                                </button>
                            </>
                        ) : (
                            <>
                                <Link
                                    to="/login"
                                    className="hidden sm:flex h-11 items-center justify-center rounded-lg px-4 text-primary font-bold text-sm hover:bg-primary/10 transition-colors border-2 border-primary"
                                >
                                    {t('auth.logIn')}
                                </Link>
                                <Link
                                    to="/register"
                                    className="hidden sm:flex h-11 items-center justify-center rounded-lg px-5 bg-primary hover:bg-primary/90 text-white font-bold text-sm shadow-md shadow-primary/20 transition-all hover:scale-105"
                                >
                                    {t('auth.signUp')}
                                </Link>

                                <Link
                                    to="/login"
                                    className="sm:hidden inline-flex h-10 w-10 items-center justify-center rounded-lg border border-primary text-primary hover:bg-primary/10"
                                    title={t('auth.logIn')}
                                >
                                    <span className="material-symbols-outlined text-[20px]">person</span>
                                </Link>
                            </>
                        )}

                        <button
                            onClick={() => setIsMobileMenuOpen((prev) => !prev)}
                            className="inline-flex lg:hidden h-10 w-10 items-center justify-center rounded-lg border border-gray-200 dark:border-gray-700 text-gray-700 dark:text-gray-300"
                            aria-label="Toggle menu"
                        >
                            <span className="material-symbols-outlined text-[20px]">
                                {isMobileMenuOpen ? 'close' : 'menu'}
                            </span>
                        </button>
                    </div>
                </div>

                {/* Mobile Menu */}
                <div
                    className={`lg:hidden overflow-hidden transition-all duration-300 ${isMobileMenuOpen ? 'max-h-[42rem] opacity-100 pb-3' : 'max-h-0 opacity-0'}`}
                >
                    <nav className="border-t border-gray-200 dark:border-gray-800 pt-3 space-y-1">
                        <Link
                            to="/"
                            onClick={() => setIsMobileMenuOpen(false)}
                            className="block rounded-lg px-3 py-2.5 text-sm font-medium text-gray-800 dark:text-gray-200 hover:bg-primary/10"
                        >
                            {t('home.header.nav.home')}
                        </Link>
                        {renderMobileMenuItem(
                            courseCenterItem,
                            'block rounded-lg px-3 py-2.5 text-sm font-medium text-gray-800 dark:text-gray-200 hover:bg-primary/10',
                            'course-center-mobile',
                        )}

                        <p className="px-3 pt-2 text-[11px] font-bold uppercase tracking-wide text-primary">
                            {t('home.header.nav.training', { defaultValue: 'Đào tạo' })}
                        </p>
                        {trainingItems.map((item, index) =>
                            renderMobileMenuItem(
                                item,
                                'block rounded-lg px-6 py-2 text-sm font-medium text-gray-800 dark:text-gray-200 hover:bg-primary/10',
                                `training-${index}`,
                            )
                        )}

                        <p className="px-3 pt-2 text-[11px] font-bold uppercase tracking-wide text-primary">
                            {t('home.header.nav.community', { defaultValue: 'Cộng đồng' })}
                        </p>
                        {communityItems.map((item, index) =>
                            renderMobileMenuItem(
                                item,
                                'block rounded-lg px-6 py-2 text-sm font-medium text-gray-800 dark:text-gray-200 hover:bg-primary/10',
                                `community-${index}`,
                            )
                        )}

                        <p className="px-3 pt-2 text-[11px] font-bold uppercase tracking-wide text-primary">
                            {t('home.header.nav.about', { defaultValue: 'Về chúng tôi' })}
                        </p>
                        {aboutItems.map((item, index) =>
                            renderMobileMenuItem(
                                item,
                                'block rounded-lg px-6 py-2 text-sm font-medium text-gray-800 dark:text-gray-200 hover:bg-primary/10',
                                `about-${index}`,
                            )
                        )}

                        <a
                            href={contactHref}
                            onClick={() => setIsMobileMenuOpen(false)}
                            className="block rounded-lg px-3 py-2.5 text-sm font-medium text-gray-800 dark:text-gray-200 hover:bg-primary/10"
                        >
                            {t('home.header.nav.contact', { defaultValue: 'Liên hệ' })}
                        </a>
                    </nav>

                    <div className="mt-3 border-t border-gray-200 dark:border-gray-800 pt-3">
                        {isAuthenticated && user ? (
                            <div className="space-y-2">
                                <p className="px-3 text-sm font-medium text-gray-900 dark:text-white">{user.fullName}</p>
                                <button
                                    onClick={handleLogout}
                                    className="w-full h-11 rounded-lg bg-primary text-white font-semibold"
                                >
                                    {t('home.header.logout')}
                                </button>
                            </div>
                        ) : (
                            <div className="grid grid-cols-2 gap-2">
                                <Link
                                    to="/login"
                                    onClick={() => setIsMobileMenuOpen(false)}
                                    className="h-11 rounded-lg border-2 border-primary text-primary font-semibold flex items-center justify-center"
                                >
                                    {t('auth.logIn')}
                                </Link>
                                <Link
                                    to="/register"
                                    onClick={() => setIsMobileMenuOpen(false)}
                                    className="h-11 rounded-lg bg-primary text-white font-semibold flex items-center justify-center"
                                >
                                    {t('auth.signUp')}
                                </Link>
                            </div>
                        )}
                    </div>
                </div>
            </div>
        </header>
    );
};

export default UserHeader;
