import React from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { useSelector, useDispatch } from 'react-redux';
import { useTranslation } from 'react-i18next';
import type { RootState, AppDispatch } from '../../store/store';
import { logout } from '../../store/authSlice';
import { authApi } from '../../services/authApi';
import { clearAuth } from '../../services/authStorage';
import HeaderNotification from '../common/HeaderNotification';
import LanguageSwitcher from '../common/LanguageSwitcher'; import logoImg from '../../assets/logo.jpg';

const UserHeader: React.FC = () => {
    const { t } = useTranslation();
    const navigate = useNavigate();
    const dispatch = useDispatch<AppDispatch>();
    const { isAuthenticated, user } = useSelector((state: RootState) => state.auth);

    const handleLogout = async () => {
        try {
            await authApi.logout();
            dispatch(logout());
            clearAuth();
            navigate('/login');
        } catch (error) {
            console.error('Logout error:', error);
        }
    };

    return (
        <header className="sticky top-0 z-50 w-full bg-background-light/95 dark:bg-background-dark/95 backdrop-blur-md border-b border-gray-200 dark:border-gray-800">
            <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
                <div className="flex items-center justify-between h-20">
                    {/* Logo */}
                    <Link to="/" className="flex items-center gap-3">
                        <div className="size-12 flex items-center justify-center overflow-hidden rounded-full border-2 border-primary">
                            <img src={logoImg} alt="Logo" className="w-full h-full object-cover" />
                        </div>
                        <h2 className="text-[#0c1c1d] dark:text-white text-xl font-bold tracking-tight">
                            NhinAnChuaLanh<span className="text-primary">.</span>
                        </h2>
                    </Link>

                    {/* Desktop Nav */}
                    <nav className="hidden md:flex items-center gap-8">
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
                        <a
                            className="text-[#0c1c1d] dark:text-gray-300 hover:text-primary dark:hover:text-primary transition-colors text-sm font-medium"
                            href="#testimonials"
                        >
                            {t('home.header.nav.testimonials')}
                        </a>
                    </nav>

                    {/* Auth Buttons */}
                    <div className="flex items-center gap-3">
                        <LanguageSwitcher />
                        {isAuthenticated && user ? (
                            <>
                                <div className="mr-2">
                                    <HeaderNotification />
                                </div>
                                <span className="hidden sm:inline text-sm text-gray-600 dark:text-gray-300 font-display">
                                    {t('home.header.welcome')}, <span className="font-medium text-gray-900 dark:text-white normal-case">{user.fullName}</span>
                                </span>
                                <button
                                    onClick={handleLogout}
                                    className="flex h-10 items-center justify-center rounded-lg px-5 bg-primary hover:bg-primary/90 text-white font-bold text-sm shadow-md shadow-primary/20 transition-all hover:scale-105"
                                >
                                    {t('home.header.logout')}
                                </button>
                            </>
                        ) : (
                            <>
                                <Link
                                    to="/login"
                                    className="flex h-10 items-center justify-center rounded-lg px-4 text-primary font-bold text-sm hover:bg-primary/10 transition-colors border-2 border-primary"
                                >
                                    {t('auth.logIn')}
                                </Link>
                                <Link
                                    to="/register"
                                    className="flex h-10 items-center justify-center rounded-lg px-5 bg-primary hover:bg-primary/90 text-white font-bold text-sm shadow-md shadow-primary/20 transition-all hover:scale-105"
                                >
                                    {t('auth.signUp')}
                                </Link>
                            </>
                        )}
                    </div>
                </div>
            </div>
        </header>
    );
};

export default UserHeader;
