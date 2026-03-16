import React, { useRef, useEffect, useState } from 'react';
import { Link } from 'react-router-dom';
import { useTranslation } from 'react-i18next';

interface UserMenuProps {
    user: {
        avatarUrl?: string;
        fullName: string;
        email: string;
    };
}

const UserMenu: React.FC<UserMenuProps> = ({ user }) => {
    const { t } = useTranslation();
    const [isOpen, setIsOpen] = useState(false);
    const menuRef = useRef<HTMLDivElement>(null);
    const triggerRef = useRef<HTMLButtonElement>(null);

    // Close menu when clicking outside
    useEffect(() => {
        const handleClickOutside = (event: MouseEvent) => {
            if (
                menuRef.current &&
                !menuRef.current.contains(event.target as Node) &&
                triggerRef.current &&
                !triggerRef.current.contains(event.target as Node)
            ) {
                setIsOpen(false);
            }
        };

        if (isOpen) {
            document.addEventListener('mousedown', handleClickOutside);
            return () => {
                document.removeEventListener('mousedown', handleClickOutside);
            };
        }
    }, [isOpen]);

    const handleMenuItemClick = (callback?: () => void) => {
        setIsOpen(false);
        if (callback) {
            callback();
        }
    };

    return (
        <div
            className="relative"
            onMouseEnter={() => setIsOpen(true)}
            onMouseLeave={() => setIsOpen(false)}
        >
            <button
                ref={triggerRef}
                onClick={() => setIsOpen((prev) => !prev)}
                className="inline-flex h-10 items-center gap-1 rounded-lg px-2 text-sm font-semibold text-gray-900 transition-colors hover:bg-primary/10 hover:text-primary dark:text-white dark:hover:bg-slate-800"
                title={t('home.header.profileTitle', { defaultValue: 'Profile' })}
                aria-label="User menu"
                aria-expanded={isOpen}
            >
                <span className="max-w-[10rem] truncate">{user.fullName}</span>
                <span className={`material-symbols-outlined text-[18px] transition-transform ${isOpen ? 'rotate-180' : ''}`}>expand_more</span>
            </button>

            {/* Dropdown Menu */}
            {isOpen && (
                <div
                    ref={menuRef}
                    className="absolute right-0 top-full z-50 w-56 pt-2"
                >
                    <div className="overflow-hidden rounded-lg border border-gray-200 bg-white py-2 shadow-lg dark:border-gray-700 dark:bg-slate-800">
                        <Link
                            to="/my-courses"
                            onClick={() => handleMenuItemClick()}
                            className="flex items-center gap-3 px-4 py-2.5 text-sm text-gray-700 dark:text-gray-300 hover:bg-gray-100 dark:hover:bg-gray-700 transition-colors"
                        >
                            <span className="material-symbols-outlined text-[20px]">library_books</span>
                            {t('home.header.nav.myCourses')}
                        </Link>

                        <Link
                            to="/my-orders"
                            onClick={() => handleMenuItemClick()}
                            className="flex items-center gap-3 px-4 py-2.5 text-sm text-gray-700 dark:text-gray-300 hover:bg-gray-100 dark:hover:bg-gray-700 transition-colors"
                        >
                            <span className="material-symbols-outlined text-[20px]">shopping_bag</span>
                            {t('home.header.nav.myOrders')}
                        </Link>

                        <Link
                            to="/profile"
                            onClick={() => handleMenuItemClick()}
                            className="flex items-center gap-3 px-4 py-2.5 text-sm text-gray-700 dark:text-gray-300 hover:bg-gray-100 dark:hover:bg-gray-700 transition-colors"
                        >
                            <span className="material-symbols-outlined text-[20px]">person</span>
                            {t('home.header.userMenu.profile')}
                        </Link>

                        <Link
                            to="/profile"
                            onClick={() => handleMenuItemClick()}
                            className="flex items-center gap-3 px-4 py-2.5 text-sm text-gray-700 dark:text-gray-300 hover:bg-gray-100 dark:hover:bg-gray-700 transition-colors"
                        >
                            <span className="material-symbols-outlined text-[20px]">settings</span>
                            {t('home.header.userMenu.settings')}
                        </Link>
                    </div>
                </div>
            )}
        </div>
    );
};

export default UserMenu;
