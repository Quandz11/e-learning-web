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
import logoImg from '../../assets/logo.jpg';
import { paymentCart, PAYMENT_CART_CHANGED_EVENT } from '../../services/paymentCart';

const UserHeader: React.FC = () => {
    const { t } = useTranslation();
    const navigate = useNavigate();
    const dispatch = useDispatch<AppDispatch>();
    const { isAuthenticated, user } = useSelector((state: RootState) => state.auth);
    const [cartCount, setCartCount] = useState(0);
    const [isMobileMenuOpen, setIsMobileMenuOpen] = useState(false);

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
                        <div className="size-10 sm:size-12 flex items-center justify-center overflow-hidden rounded-full border-2 border-primary">
                            <img src={logoImg} alt="Logo" className="w-full h-full object-cover" />
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
                        <Link
                            className="text-[#0c1c1d] dark:text-gray-300 hover:text-primary dark:hover:text-primary transition-colors text-sm font-medium"
                            to="/courses"
                        >
                            {t('home.header.nav.courses')}
                        </Link>
                        <Link
                            className="text-[#0c1c1d] dark:text-gray-300 hover:text-primary dark:hover:text-primary transition-colors text-sm font-medium"
                            to="/articles"
                        >
                            {t('home.header.nav.articles', { defaultValue: 'Bài viết' })}
                        </Link>
                        <Link
                            className="text-[#0c1c1d] dark:text-gray-300 hover:text-primary dark:hover:text-primary transition-colors text-sm font-medium"
                            to="/forum"
                        >
                            {t('home.header.nav.forum', { defaultValue: 'Diễn đàn' })}
                        </Link>
                        {isAuthenticated && user && (
                            <Link
                                className="text-[#0c1c1d] dark:text-gray-300 hover:text-primary dark:hover:text-primary transition-colors text-sm font-medium"
                                to="/my-courses"
                            >
                                {t('home.header.nav.myCourses')}
                            </Link>
                        )}
                        {isAuthenticated && user && (
                            <Link
                                className="text-[#0c1c1d] dark:text-gray-300 hover:text-primary dark:hover:text-primary transition-colors text-sm font-medium"
                                to="/my-orders"
                            >
                                {t('home.header.nav.myOrders')}
                            </Link>
                        )}
                        <a
                            className="text-[#0c1c1d] dark:text-gray-300 hover:text-primary dark:hover:text-primary transition-colors text-sm font-medium"
                            href="/#testimonials"
                        >
                            {t('home.header.nav.testimonials')}
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

                                <Link
                                    to="/profile"
                                    onClick={() => setIsMobileMenuOpen(false)}
                                    className="inline-flex h-10 w-10 sm:h-11 sm:w-11 items-center justify-center rounded-full border border-gray-200 dark:border-gray-700 overflow-hidden"
                                    title={t('home.header.profileTitle', { defaultValue: 'Profile' })}
                                >
                                    {user.avatarUrl ? (
                                        <img src={user.avatarUrl} alt={user.fullName} className="h-full w-full object-cover" />
                                    ) : (
                                        <span className="text-sm font-semibold text-primary">{user.fullName?.charAt(0)?.toUpperCase() || 'U'}</span>
                                    )}
                                </Link>

                                <span className="hidden xl:inline text-sm text-gray-600 dark:text-gray-300 font-display">
                                    {t('home.header.welcome')}, <span className="font-medium text-gray-900 dark:text-white normal-case">{user.fullName}</span>
                                </span>

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
                    className={`lg:hidden overflow-hidden transition-all duration-300 ${isMobileMenuOpen ? 'max-h-[32rem] opacity-100 pb-3' : 'max-h-0 opacity-0'}`}
                >
                    <nav className="border-t border-gray-200 dark:border-gray-800 pt-3 space-y-1">
                        <Link
                            to="/"
                            onClick={() => setIsMobileMenuOpen(false)}
                            className="block rounded-lg px-3 py-2.5 text-sm font-medium text-gray-800 dark:text-gray-200 hover:bg-primary/10"
                        >
                            {t('home.header.nav.home')}
                        </Link>
                        <Link
                            to="/courses"
                            onClick={() => setIsMobileMenuOpen(false)}
                            className="block rounded-lg px-3 py-2.5 text-sm font-medium text-gray-800 dark:text-gray-200 hover:bg-primary/10"
                        >
                            {t('home.header.nav.courses')}
                        </Link>
                        <Link
                            to="/articles"
                            onClick={() => setIsMobileMenuOpen(false)}
                            className="block rounded-lg px-3 py-2.5 text-sm font-medium text-gray-800 dark:text-gray-200 hover:bg-primary/10"
                        >
                            {t('home.header.nav.articles', { defaultValue: 'Bài viết' })}
                        </Link>
                        <Link
                            to="/forum"
                            onClick={() => setIsMobileMenuOpen(false)}
                            className="block rounded-lg px-3 py-2.5 text-sm font-medium text-gray-800 dark:text-gray-200 hover:bg-primary/10"
                        >
                            {t('home.header.nav.forum', { defaultValue: 'Diễn đàn' })}
                        </Link>
                        {isAuthenticated && user && (
                            <>
                                <Link
                                    to="/my-courses"
                                    onClick={() => setIsMobileMenuOpen(false)}
                                    className="block rounded-lg px-3 py-2.5 text-sm font-medium text-gray-800 dark:text-gray-200 hover:bg-primary/10"
                                >
                                    {t('home.header.nav.myCourses')}
                                </Link>
                                <Link
                                    to="/my-orders"
                                    onClick={() => setIsMobileMenuOpen(false)}
                                    className="block rounded-lg px-3 py-2.5 text-sm font-medium text-gray-800 dark:text-gray-200 hover:bg-primary/10"
                                >
                                    {t('home.header.nav.myOrders')}
                                </Link>
                            </>
                        )}
                        <a
                            href="/#testimonials"
                            onClick={() => setIsMobileMenuOpen(false)}
                            className="block rounded-lg px-3 py-2.5 text-sm font-medium text-gray-800 dark:text-gray-200 hover:bg-primary/10"
                        >
                            {t('home.header.nav.testimonials')}
                        </a>
                    </nav>

                    <div className="mt-3 border-t border-gray-200 dark:border-gray-800 pt-3">
                        {isAuthenticated && user ? (
                            <div className="space-y-2">
                                <p className="px-3 text-sm text-gray-600 dark:text-gray-300">
                                    {t('home.header.welcome')}, <span className="font-medium text-gray-900 dark:text-white">{user.fullName}</span>
                                </p>
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
