import React from 'react';
import { Link } from 'react-router-dom';
import { useTranslation } from 'react-i18next';

const AdminSidebar: React.FC = () => {
  const { t } = useTranslation();

  return (
    <aside className="hidden w-64 flex-col justify-between border-r border-slate-200 bg-dashboard-surface-light z-20 flex-shrink-0 dark:border-slate-800 dark:bg-dashboard-surface-dark lg:flex">
      <div className="flex flex-col h-full">
        {/* Logo */}
        <div className="flex h-16 items-center border-b border-slate-100 px-6 dark:border-slate-800/50">
          <div className="flex items-center gap-3">
            <div className="flex h-8 w-8 items-center justify-center rounded-lg bg-dashboard-primary text-white">
              <span className="material-symbols-outlined text-[20px]">school</span>
            </div>
            <h1 className="text-lg font-bold tracking-tight text-slate-900 dark:text-white">EduAdmin</h1>
          </div>
        </div>

        {/* Navigation Links */}
        <nav className="flex flex-1 flex-col gap-1 overflow-y-auto px-4 py-6">
          <Link
            to="/admin/dashboard"
            className="group flex items-center gap-3 rounded-lg bg-dashboard-primary px-3 py-2.5 text-white shadow-dashboard-subtle"
          >
            <span className="material-symbols-outlined text-[22px] transition-transform group-hover:scale-110">dashboard</span>
            <span className="text-sm font-medium">{t('admin.sidebar.dashboard')}</span>
          </Link>
          <a
            href="#"
            className="group flex items-center gap-3 rounded-lg px-3 py-2.5 text-slate-600 transition-colors hover:bg-slate-100 hover:text-dashboard-primary dark:text-slate-400 dark:hover:bg-slate-800/50 dark:hover:text-dashboard-primary-300"
          >
            <span className="material-symbols-outlined text-[22px] transition-transform group-hover:scale-110">groups</span>
            <span className="text-sm font-medium">{t('admin.sidebar.students')}</span>
          </a>
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
            <span className="material-symbols-outlined text-[22px] transition-transform group-hover:scale-110">library_books</span>
            <span className="text-sm font-medium">{t('admin.sidebar.courses')}</span>
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
          <div className="flex cursor-pointer items-center gap-3 rounded-lg p-2 transition-colors hover:bg-slate-50 dark:hover:bg-slate-800">
            <div
              className="h-10 w-10 rounded-full border border-slate-200 bg-cover bg-center dark:border-slate-700"
              style={{
                backgroundImage:
                  "url('https://lh3.googleusercontent.com/aida-public/AB6AXuCiWkrZRkAp9pybU7c7JtJL8DGumbRwaafOM-G0R1ao7fSHQ0u6qYDvFJcJAT7kUZ4LHoqqHCDrJ_K7l0R_tzvnAeSf8CuJTdPw91xHUHVfKV79G7XfSZDYyBRv0R5zwFtDS-SHX-OtPnw5bxwdq47XssRKAD6sfGDCVR8ImWVIpupelYprkfOAsupwYVkWwO7l4C_BWzmJUFBXD-TJqEbeAld21qA3yHuhBxEbxXseAHeLcqCJdhgongSsRWWfhbabsayeT5PNfA')",
              }}
            ></div>
            <div className="flex flex-col overflow-hidden">
              <span className="truncate text-sm font-bold text-slate-900 dark:text-white">Tom Cook</span>
              <span className="truncate text-xs text-slate-500 dark:text-slate-400">Super Admin</span>
            </div>
            <span className="material-symbols-outlined ml-auto text-[18px] text-slate-400">more_vert</span>
          </div>
        </div>
      </div>
    </aside>
  );
};

export default AdminSidebar;
