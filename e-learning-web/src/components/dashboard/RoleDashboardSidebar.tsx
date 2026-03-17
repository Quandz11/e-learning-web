import React, { useMemo } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { useDispatch, useSelector } from 'react-redux';
import { useTranslation } from 'react-i18next';
import type { AppDispatch, RootState } from '../../store/store';
import { logout } from '../../store/authSlice';
import { authApi } from '../../services/authApi';
import { clearAuth } from '../../services/authStorage';
import logoImg from '../../assets/logo-rm-bg.png';

export interface RoleSidebarItem {
  id: string;
  label: string;
  icon: string;
}

interface RoleDashboardSidebarProps {
  brand: string;
  menuItems: RoleSidebarItem[];
  activeTab: string;
  onTabChange: (tabId: string) => void;
  isMobileOpen?: boolean;
  onClose?: () => void;
}

const RoleDashboardSidebar: React.FC<RoleDashboardSidebarProps> = ({
  brand,
  menuItems,
  activeTab,
  onTabChange,
  isMobileOpen = false,
  onClose,
}) => {
  const { t } = useTranslation();
  const dispatch = useDispatch<AppDispatch>();
  const navigate = useNavigate();
  const { user } = useSelector((state: RootState) => state.auth);

  const userName = useMemo(() => user?.fullName || user?.email || 'User', [user]);
  const userRole = useMemo(() => user?.role || 'User', [user]);
  const userInitial = useMemo(() => (userName ? userName.charAt(0).toUpperCase() : 'U'), [userName]);

  const handleLogout = async () => {
    try {
      await authApi.logout();
    } catch (error) {
      console.error('Logout error:', error);
    } finally {
      authApi.setAccessToken(null);
      clearAuth();
      dispatch(logout());
      navigate('/login');
    }
  };

  const handleNav = (tabId: string) => {
    onTabChange(tabId);
    if (onClose) {
      onClose();
    }
  };

  return (
    <>
      <div
        className={`lg:hidden fixed inset-0 z-40 bg-black/30 backdrop-blur-sm transition-opacity ${
          isMobileOpen ? 'opacity-100 pointer-events-auto' : 'opacity-0 pointer-events-none'
        }`}
        onClick={onClose}
      />

      <aside
        className={`fixed lg:static inset-y-0 left-0 z-50 lg:z-20 w-[85vw] max-w-72 lg:w-64 flex-col justify-between border-r border-slate-200 bg-dashboard-surface-light flex-shrink-0 dark:border-slate-800 dark:bg-dashboard-surface-dark transform transition-transform duration-200 ${
          isMobileOpen ? 'translate-x-0' : '-translate-x-full lg:translate-x-0'
        } flex`}
      >
        <div className="flex h-full flex-col">
          <div className="flex h-16 items-center border-b border-slate-100 px-6 dark:border-slate-800/50">
            <div className="flex items-center gap-3">
              <div className="flex h-12 w-12 items-center justify-center rounded-full overflow-hidden">
                <img src={logoImg} alt="Logo" className="h-full w-full object-contain" />
              </div>
              <h1 className="text-base sm:text-lg font-bold tracking-tight text-slate-900 dark:text-white truncate">
                {brand}
              </h1>
            </div>
            <button
              type="button"
              onClick={onClose}
              className="ml-auto rounded-md p-2 text-slate-500 hover:bg-slate-100 dark:text-slate-300 dark:hover:bg-slate-800 lg:hidden"
              aria-label="Close navigation"
            >
              <span className="material-symbols-outlined">close</span>
            </button>
          </div>

          <nav className="flex flex-1 flex-col gap-1 overflow-y-auto px-4 py-6">
            {menuItems.map((item) => {
              const isActive = activeTab === item.id;

              return (
                <button
                  key={item.id}
                  type="button"
                  onClick={() => handleNav(item.id)}
                  className={`group flex items-center gap-3 rounded-lg px-3 py-2.5 text-left text-sm font-medium transition-colors ${
                    isActive
                      ? 'bg-dashboard-primary text-white shadow-dashboard-subtle'
                      : 'text-slate-600 hover:bg-slate-100 hover:text-dashboard-primary dark:text-slate-400 dark:hover:bg-slate-800/50 dark:hover:text-dashboard-primary-300'
                  }`}
                >
                  <span className="material-symbols-outlined text-[22px] transition-transform group-hover:scale-110">
                    {item.icon}
                  </span>
                  <span className="text-sm font-medium">{item.label}</span>
                </button>
              );
            })}
          </nav>

          <div className="border-t border-slate-200 p-4 dark:border-slate-800">
            <Link
              to="/profile"
              onClick={onClose}
              className="flex items-center gap-3 rounded-lg p-2 transition-colors hover:bg-slate-50 dark:hover:bg-slate-800"
            >
              <div className="h-10 w-10 rounded-full border border-slate-200 bg-dashboard-primary/10 flex items-center justify-center overflow-hidden dark:border-slate-700">
                {user?.avatarUrl ? (
                  <img src={user.avatarUrl} alt={userName} className="h-full w-full object-cover" />
                ) : (
                  <span className="text-sm font-semibold text-dashboard-primary">{userInitial}</span>
                )}
              </div>
              <div className="flex flex-col overflow-hidden">
                <span className="truncate text-sm font-bold text-slate-900 dark:text-white">{userName}</span>
                <span className="truncate text-xs text-slate-500 dark:text-slate-400">{userRole}</span>
              </div>
              <span className="material-symbols-outlined ml-auto text-[18px] text-slate-400">more_vert</span>
            </Link>
            <button
              type="button"
              onClick={handleLogout}
              className="mt-3 flex w-full items-center gap-2 rounded-lg border border-slate-200 px-3 py-2 text-sm font-medium text-red-600 transition-colors hover:bg-red-50 hover:border-red-200 dark:border-slate-700 dark:text-red-300 dark:hover:bg-red-900/20"
            >
              <span className="material-symbols-outlined text-[18px]">logout</span>
              {t('common.logout')}
            </button>
          </div>
        </div>
      </aside>
    </>
  );
};

export default RoleDashboardSidebar;
