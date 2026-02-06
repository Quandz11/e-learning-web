import React, { useMemo } from 'react';
import { Link, useLocation, useNavigate } from 'react-router-dom';
import { useDispatch, useSelector } from 'react-redux';
import { useTranslation } from 'react-i18next';
import type { AppDispatch, RootState } from '../../store/store';
import { logout } from '../../store/authSlice';
import { authApi } from '../../services/authApi';
import { clearAuth } from '../../services/authStorage';

interface AdminSidebarProps {
  isMobileOpen?: boolean;
  onClose?: () => void;
}

const AdminSidebar: React.FC<AdminSidebarProps> = ({ isMobileOpen = false, onClose }) => {
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
      clearAuth();
      dispatch(logout());
      navigate('/login');
    }
  };

  const handleNav = () => {
    if (onClose) onClose();
  };

  return (
    <>
      {/* Backdrop for mobile */}
      <div
        className={`lg:hidden fixed inset-0 z-40 bg-black/30 backdrop-blur-sm transition-opacity ${isMobileOpen ? 'opacity-100 pointer-events-auto' : 'opacity-0 pointer-events-none'}`}
        onClick={onClose}
      />
      <aside
        className={`fixed lg:static inset-y-0 left-0 z-50 lg:z-20 w-64 flex-col justify-between border-r border-slate-200 bg-dashboard-surface-light flex-shrink-0 dark:border-slate-800 dark:bg-dashboard-surface-dark transform transition-transform duration-200 ${isMobileOpen ? 'translate-x-0' : '-translate-x-full lg:translate-x-0'} flex`}
      >
        <div className="flex flex-col h-full">
          {/* Logo */}
          <div className="flex h-16 items-center border-b border-slate-100 px-6 dark:border-slate-800/50">
            <div className="flex items-center gap-3">
              <div className="flex h-8 w-8 items-center justify-center rounded-lg bg-dashboard-primary text-white">
                <span className="material-symbols-outlined text-[20px]">school</span>
              </div>
              <h1 className="text-lg font-bold tracking-tight text-slate-900 dark:text-white">SKVI Admin</h1>
            </div>
            <button
              onClick={onClose}
              className="ml-auto rounded-md p-2 text-slate-500 hover:bg-slate-100 dark:text-slate-300 dark:hover:bg-slate-800 lg:hidden"
              aria-label="Close navigation"
            >
              <span className="material-symbols-outlined">close</span>
            </button>
          </div>

          {/* Navigation Links */}
          <nav className="flex flex-1 flex-col gap-1 overflow-y-auto px-4 py-6">
            <Link
              to="/admin/dashboard"
              onClick={handleNav}
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
              onClick={handleNav}
              className={`group flex items-center gap-3 rounded-lg px-3 py-2.5 text-sm font-medium transition-colors ${location.pathname.startsWith('/admin/courses')
                ? 'bg-dashboard-primary text-white shadow-dashboard-subtle'
                : 'text-slate-600 hover:bg-slate-100 hover:text-dashboard-primary dark:text-slate-400 dark:hover:bg-slate-800/50 dark:hover:text-dashboard-primary-300'
                }`}
            >
              <span className="material-symbols-outlined text-[22px] transition-transform group-hover:scale-110">library_books</span>
              <span className="text-sm font-medium">{t('admin.sidebar.courses')}</span>
            </Link>
            <Link
              to="/admin/lessons"
              onClick={handleNav}
              className={`group flex items-center gap-3 rounded-lg px-3 py-2.5 text-sm font-medium transition-colors ${location.pathname.startsWith('/admin/lessons')
                ? 'bg-dashboard-primary text-white shadow-dashboard-subtle'
                : 'text-slate-600 hover:bg-slate-100 hover:text-dashboard-primary dark:text-slate-400 dark:hover:bg-slate-800/50 dark:hover:text-dashboard-primary-300'
                }`}
            >
              <span className="material-symbols-outlined text-[22px] transition-transform group-hover:scale-110">video_library</span>
              <span className="text-sm font-medium">{t('admin.sidebar.lessons')}</span>
            </Link>
            <Link
              to="/admin/users"
              onClick={handleNav}
              className={`group flex items-center gap-3 rounded-lg px-3 py-2.5 text-sm font-medium transition-colors ${location.pathname.startsWith('/admin/users')
                ? 'bg-dashboard-primary text-white shadow-dashboard-subtle'
                : 'text-slate-600 hover:bg-slate-100 hover:text-dashboard-primary dark:text-slate-400 dark:hover:bg-slate-800/50 dark:hover:text-dashboard-primary-300'
                }`}
            >
              <span className="material-symbols-outlined text-[22px] transition-transform group-hover:scale-110">groups</span>
              <span className="text-sm font-medium">{t('admin.sidebar.users')}</span>
            </Link>
            <Link
              to="/admin/instructors"
              onClick={handleNav}
              className={`group flex items-center gap-3 rounded-lg px-3 py-2.5 text-sm font-medium transition-colors ${location.pathname.startsWith('/admin/instructors')
                ? 'bg-dashboard-primary text-white shadow-dashboard-subtle'
                : 'text-slate-600 hover:bg-slate-100 hover:text-dashboard-primary dark:text-slate-400 dark:hover:bg-slate-800/50 dark:hover:text-dashboard-primary-300'
                }`}
            >
              <span className="material-symbols-outlined text-[22px] transition-transform group-hover:scale-110">cast_for_education</span>
              <span className="text-sm font-medium">{t('admin.sidebar.instructors')}</span>
            </Link>
            <Link
              to="/admin/chat"
              onClick={handleNav}
              className={`group flex items-center gap-3 rounded-lg px-3 py-2.5 text-sm font-medium transition-colors ${location.pathname.startsWith('/admin/chat')
                ? 'bg-dashboard-primary text-white shadow-dashboard-subtle'
                : 'text-slate-600 hover:bg-slate-100 hover:text-dashboard-primary dark:text-slate-400 dark:hover:bg-slate-800/50 dark:hover:text-dashboard-primary-300'
                }`}
            >
              <span className="material-symbols-outlined text-[22px] transition-transform group-hover:scale-110">chat</span>
              <span className="text-sm font-medium">{t('admin.sidebar.chat')}</span>
            </Link>
            <Link
              to="/admin/articles"
              onClick={handleNav}
              className={`group flex items-center gap-3 rounded-lg px-3 py-2.5 text-sm font-medium transition-colors ${location.pathname.startsWith('/admin/articles')
                ? 'bg-dashboard-primary text-white shadow-dashboard-subtle'
                : 'text-slate-600 hover:bg-slate-100 hover:text-dashboard-primary dark:text-slate-400 dark:hover:bg-slate-800/50 dark:hover:text-dashboard-primary-300'
                }`}
            >
              <span className="material-symbols-outlined text-[22px] transition-transform group-hover:scale-110">article</span>
              <span className="text-sm font-medium">{t('admin.sidebar.articles')}</span>
            </Link>
            <Link
              to="/admin/categories"
              onClick={handleNav}
              className={`group flex items-center gap-3 rounded-lg px-3 py-2.5 text-sm font-medium transition-colors ${location.pathname.startsWith('/admin/categories')
                ? 'bg-dashboard-primary text-white shadow-dashboard-subtle'
                : 'text-slate-600 hover:bg-slate-100 hover:text-dashboard-primary dark:text-slate-400 dark:hover:bg-slate-800/50 dark:hover:text-dashboard-primary-300'
                }`}
            >
              <span className="material-symbols-outlined text-[22px] transition-transform group-hover:scale-110">category</span>
              <span className="text-sm font-medium">{t('admin.sidebar.categories')}</span>
            </Link>
            <Link
              to="/admin/quizzes"
              onClick={handleNav}
              className={`group flex items-center gap-3 rounded-lg px-3 py-2.5 text-sm font-medium transition-colors ${location.pathname.startsWith('/admin/quizzes')
                ? 'bg-dashboard-primary text-white shadow-dashboard-subtle'
                : 'text-slate-600 hover:bg-slate-100 hover:text-dashboard-primary dark:text-slate-400 dark:hover:bg-slate-800/50 dark:hover:text-dashboard-primary-300'
                }`}
            >
              <span className="material-symbols-outlined text-[22px] transition-transform group-hover:scale-110">quiz</span>
              <span className="text-sm font-medium">{t('admin.sidebar.quizzes', { defaultValue: 'Quizzes' })}</span>
            </Link>
            <Link
              to="/admin/testimonials"
              onClick={handleNav}
              className={`group flex items-center gap-3 rounded-lg px-3 py-2.5 text-sm font-medium transition-colors ${location.pathname.startsWith('/admin/testimonials')
                ? 'bg-dashboard-primary text-white shadow-dashboard-subtle'
                : 'text-slate-600 hover:bg-slate-100 hover:text-dashboard-primary dark:text-slate-400 dark:hover:bg-slate-800/50 dark:hover:text-dashboard-primary-300'
                }`}
            >
              <span className="material-symbols-outlined text-[22px] transition-transform group-hover:scale-110">rate_review</span>
              <span className="text-sm font-medium">{t('admin.sidebar.testimonials', { defaultValue: 'Testimonials' })}</span>
            </Link>
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
            <Link
              to="/admin/settings"
              onClick={handleNav}
              className={`group flex items-center gap-3 rounded-lg px-3 py-2.5 text-slate-600 transition-colors hover:bg-slate-100 hover:text-dashboard-primary dark:text-slate-400 dark:hover:bg-slate-800/50 dark:hover:text-dashboard-primary-300 ${location.pathname === '/admin/settings' ? 'bg-dashboard-primary text-white shadow-dashboard-subtle' : ''}`}
            >
              <span className="material-symbols-outlined text-[22px] transition-transform group-hover:scale-110">settings</span>
              <span className="text-sm font-medium">{t('admin.sidebar.settings')}</span>
            </Link>
          </nav>

          {/* User Mini Profile */}
          <div className="border-t border-slate-200 p-4 dark:border-slate-800">
            <Link
              to="/admin/profile"
              onClick={handleNav}
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
              onClick={handleLogout}
              className="mt-3 flex w-full items-center gap-2 rounded-lg border border-slate-200 px-3 py-2 text-sm font-medium text-red-600 transition-colors hover:bg-red-50 hover:border-red-200 dark:border-slate-700 dark:text-red-300 dark:hover:bg-red-900/20"
            >
              <span className="material-symbols-outlined text-[18px]">logout</span>
              Logout
            </button>
          </div>
        </div>
      </aside>
    </>
  );
};

export default AdminSidebar;
