import React, { useMemo } from 'react';
import { Link, useLocation, useNavigate } from 'react-router-dom';
import { useDispatch, useSelector } from 'react-redux';
import { useTranslation } from 'react-i18next';
import type { AppDispatch, RootState } from '../../store/store';
import { logout } from '../../store/authSlice';
import { authApi } from '../../services/authApi';

const AdminSidebar: React.FC = () => {
  const { t } = useTranslation();
  const dispatch = useDispatch<AppDispatch>();
  const navigate = useNavigate();
  const location = useLocation();
  const { user } = useSelector((state: RootState) => state.auth);

  const userName = useMemo(() => user?.fullName || user?.email || 'User', [user]);
  const userRole = useMemo(() => user?.role || 'Admin', [user]);
  const userInitial = useMemo(() => (userName ? userName.charAt(0).toUpperCase() : 'U'), [userName]);

  const handleLogout = async () => {
    try {
      await authApi.logout();
    } catch (error) {
      console.error('Logout error:', error);
    } finally {
      authApi.setAccessToken(null);
      dispatch(logout());
      navigate('/login');
    }
  };

  return (
    <aside className="hidden w-64 flex-col justify-between border-r border-slate-200 bg-dashboard-surface-light z-20 flex-shrink-0 dark:border-slate-800 dark:bg-dashboard-surface-dark lg:flex">
      <div className="flex flex-col h-full">
        {/* Logo */}
        <div className="flex h-16 items-center border-b border-slate-100 px-6 dark:border-slate-800/50">
          <div className="flex items-center gap-3">
            <div className="flex h-8 w-8 items-center justify-center rounded-lg bg-dashboard-primary text-white">
              <span className="material-symbols-outlined text-[20px]">school</span>
            </div>
            <h1 className="text-lg font-bold tracking-tight text-slate-900 dark:text-white">SKVI Admin</h1>
          </div>
        </div>

        {/* Navigation Links */}
        <nav className="flex flex-1 flex-col gap-1 overflow-y-auto px-4 py-6">
          <Link
            to="/admin/dashboard"
            className={`group flex items-center gap-3 rounded-lg px-3 py-2.5 text-sm font-medium transition-colors ${location.pathname === '/admin/dashboard'
              ? 'bg-dashboard-primary text-white shadow-dashboard-subtle'
              : 'text-slate-600 hover:bg-slate-100 hover:text-dashboard-primary dark:text-slate-400 dark:hover:bg-slate-800/50 dark:hover:text-dashboard-primary-300'
            }`}
          >
            <span className="material-symbols-outlined text-[22px] transition-transform group-hover:scale-110">dashboard</span>
            <span className="text-sm font-medium">{t('admin.sidebar.dashboard')}</span>
          </Link>
          <Link
            to="/admin/courses"
            className={`group flex items-center gap-3 rounded-lg px-3 py-2.5 text-sm font-medium transition-colors ${location.pathname.startsWith('/admin/courses')
              ? 'bg-dashboard-primary text-white shadow-dashboard-subtle'
              : 'text-slate-600 hover:bg-slate-100 hover:text-dashboard-primary dark:text-slate-400 dark:hover:bg-slate-800/50 dark:hover:text-dashboard-primary-300'
            }`}
          >
            <span className="material-symbols-outlined text-[22px] transition-transform group-hover:scale-110">library_books</span>
            <span className="text-sm font-medium">{t('admin.sidebar.courses')}</span>
          </Link>
          <Link
            to="/admin/users"
            className={`group flex items-center gap-3 rounded-lg px-3 py-2.5 text-sm font-medium transition-colors ${location.pathname.startsWith('/admin/users')
              ? 'bg-dashboard-primary text-white shadow-dashboard-subtle'
              : 'text-slate-600 hover:bg-slate-100 hover:text-dashboard-primary dark:text-slate-400 dark:hover:bg-slate-800/50 dark:hover:text-dashboard-primary-300'
            }`}
          >
            <span className="material-symbols-outlined text-[22px] transition-transform group-hover:scale-110">groups</span>
            <span className="text-sm font-medium">{t('admin.sidebar.users')}</span>
          </Link>
          <a
            href="#"
            className="group flex items-center gap-3 rounded-lg px-3 py-2.5 text-slate-600 transition-colors hover:bg-slate-100 hover:text-dashboard-primary dark:text-slate-400 dark:hover:bg-slate-800/50 dark:hover:text-dashboard-primary-300"
          >
            <span className="material-symbols-outlined text-[22px] transition-transform group-hover:scale-110">cast_for_education</span>
            <span className="text-sm font-medium">{t('admin.sidebar.instructors')}</span>
          </a>
          <a
            href="#"
            className="group flex items-center gap-3 rounded-lg px-3 py-2.5 text-slate-600 transition-colors hover:bg-slate-100 hover:text-dashboard-primary dark:text-slate-400 dark:hover:bg-slate-800/50 dark:hover:text-dashboard-primary-300"
          >
            <span className="material-symbols-outlined text-[22px] transition-transform group-hover:scale-110">support_agent</span>
            <span className="text-sm font-medium">{t('admin.sidebar.agents')}</span>
          </a>
          <a
            href="#"
            className="group flex items-center gap-3 rounded-lg px-3 py-2.5 text-slate-600 transition-colors hover:bg-slate-100 hover:text-dashboard-primary dark:text-slate-400 dark:hover:bg-slate-800/50 dark:hover:text-dashboard-primary-300"
          >
            <span className="material-symbols-outlined text-[22px] transition-transform group-hover:scale-110">attach_money</span>
            <span className="text-sm font-medium">{t('admin.sidebar.revenue')}</span>
          </a>
          <div className="my-2 border-t border-slate-200 dark:border-slate-800"></div>
          <a
            href="#"
            className="group flex items-center gap-3 rounded-lg px-3 py-2.5 text-slate-600 transition-colors hover:bg-slate-100 hover:text-dashboard-primary dark:text-slate-400 dark:hover:bg-slate-800/50 dark:hover:text-dashboard-primary-300"
          >
            <span className="material-symbols-outlined text-[22px] transition-transform group-hover:scale-110">settings</span>
            <span className="text-sm font-medium">{t('admin.sidebar.settings')}</span>
          </a>
        </nav>

        {/* User Mini Profile */}
        <div className="border-t border-slate-200 p-4 dark:border-slate-800">
          <div className="flex items-center gap-3 rounded-lg p-2 transition-colors hover:bg-slate-50 dark:hover:bg-slate-800">
            <div className="h-10 w-10 rounded-full border border-slate-200 bg-dashboard-primary/10 flex items-center justify-center text-sm font-semibold text-dashboard-primary dark:border-slate-700">
              {userInitial}
            </div>
            <div className="flex flex-col overflow-hidden">
              <span className="truncate text-sm font-bold text-slate-900 dark:text-white">{userName}</span>
              <span className="truncate text-xs text-slate-500 dark:text-slate-400">{userRole}</span>
            </div>
            <span className="material-symbols-outlined ml-auto text-[18px] text-slate-400">more_vert</span>
          </div>
          <button
            onClick={handleLogout}
            className="mt-3 flex w-full items-center gap-2 rounded-lg border border-slate-200 px-3 py-2 text-sm font-medium text-red-600 transition-colors hover:bg-red-50 hover:border-red-200 dark:border-slate-700 dark:text-red-300 dark:hover:bg-red-900/20"
          >
            <span className="material-symbols-outlined text-[18px]">logout</span>
            Logout
          </button>
        </div>
      </div>
    </aside>
  );
};

export default AdminSidebar;
