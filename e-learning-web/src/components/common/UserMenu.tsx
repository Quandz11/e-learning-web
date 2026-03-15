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
        <div className="relative">
            {/* Trigger Button */}
            <button
                ref={triggerRef}
                onClick={() => setIsOpen(!isOpen)}
                className="inline-flex h-10 w-10 sm:h-11 sm:w-11 items-center justify-center rounded-full border border-gray-200 dark:border-gray-700 overflow-hidden hover:bg-gray-100 dark:hover:bg-gray-800 transition-colors"
                title={t('home.header.profileTitle', { defaultValue: 'Profile' })}
                aria-label="User menu"
                aria-expanded={isOpen}
            >
                {user.avatarUrl ? (
                    <img src={user.avatarUrl} alt={user.fullName} className="h-full w-full object-cover" />
                ) : (
                    <span className="text-sm font-semibold text-primary">{user.fullName?.charAt(0)?.toUpperCase() || 'U'}</span>
                )}
            </button>

            {/* Dropdown Menu */}
            {isOpen && (
                <div
                    ref={menuRef}
                    className="absolute right-0 mt-2 w-56 bg-white dark:bg-slate-800 rounded-lg shadow-lg border border-gray-200 dark:border-gray-700 z-50 overflow-hidden"
                >
                    {/* Menu items */}
                    <div className="py-2">
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
