import React, { useEffect, useState } from 'react';
import { useTranslation } from 'react-i18next';
import { lecturerApi, type LecturerDashboardStatsDto } from '../../services/lecturerApi';
import RoleDashboardLayout, { type RoleSidebarItem } from '../../components/dashboard/RoleDashboardLayout';
import LecturerStatsCards from '../../components/lecturer/LecturerStatsCards';
import CoursesPanel from '../../components/lecturer/CoursesPanel';
import StudentProgressPanel from '../../components/lecturer/StudentProgressPanel';
import AnalyticsPanel from '../../components/lecturer/AnalyticsPanel';
import '../../styles/lecturer-dashboard.css';

const LecturerDashboardPage: React.FC = () => {
  const { t } = useTranslation();
  const [stats, setStats] = useState<LecturerDashboardStatsDto | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [activeTab, setActiveTab] = useState<'overview' | 'courses' | 'students' | 'analytics'>('overview');

  const menuItems: RoleSidebarItem[] = [
    { id: 'overview', label: t('admin.dashboard.lecturer.menu.overview'), icon: 'dashboard' },
    { id: 'courses', label: t('admin.dashboard.lecturer.menu.courses'), icon: 'library_books' },
    { id: 'students', label: t('admin.dashboard.lecturer.menu.students'), icon: 'groups' },
    { id: 'analytics', label: t('admin.dashboard.lecturer.menu.analytics'), icon: 'monitoring' },
  ];

  useEffect(() => {
    const fetchStats = async () => {
      try {
        setLoading(true);
        const data = await lecturerApi.getStats();
        setStats(data);
      } catch (err) {
        console.error('Failed to fetch lecturer dashboard stats:', err);
        setError(err instanceof Error ? err.message : 'Failed to load dashboard stats');
      } finally {
        setLoading(false);
      }
    };

    void fetchStats();
  }, []);

  if (error) {
    return (
      <RoleDashboardLayout
        brand={t('admin.dashboard.lecturer.brand')}
        menuItems={menuItems}
        activeTab={activeTab}
        onTabChange={(tabId) => setActiveTab(tabId as typeof activeTab)}
        searchPlaceholder={t('admin.header.searchPlaceholder')}
      >
        <div className="flex h-64 items-center justify-center">
          <div className="text-center">
            <span className="material-symbols-outlined text-4xl text-red-500">error</span>
            <p className="mt-2 text-sm text-red-500">{error}</p>
          </div>
        </div>
      </RoleDashboardLayout>
    );
  }

  return (
    <RoleDashboardLayout
      brand={t('admin.dashboard.lecturer.brand')}
      menuItems={menuItems}
      activeTab={activeTab}
      onTabChange={(tabId) => setActiveTab(tabId as typeof activeTab)}
      searchPlaceholder={t('admin.header.searchPlaceholder')}
    >
      <div className="mb-8 flex flex-col justify-between gap-4 md:flex-row md:items-end">
        <div>
          <h2 className="text-2xl font-bold tracking-tight text-slate-900 dark:text-white">
            {t('admin.dashboard.lecturer.title')}
          </h2>
          <p className="mt-1 text-sm text-slate-500 dark:text-slate-400">
            {t('admin.dashboard.lecturer.subtitle')}
          </p>
        </div>
        <div className="flex w-full md:w-auto flex-col sm:flex-row gap-2 sm:gap-3">
          <button className="flex h-11 items-center justify-center gap-2 rounded-lg border border-slate-200 bg-white px-4 py-2 text-sm font-medium text-slate-700 shadow-sm transition-colors hover:bg-slate-50 dark:border-slate-700 dark:bg-dashboard-surface-dark dark:text-slate-200 dark:hover:bg-slate-800" type="button">
            <span className="material-symbols-outlined text-[18px]">calendar_today</span>
            <span>{t('admin.dashboard.last30Days')}</span>
          </button>
          <button className="flex h-11 items-center justify-center gap-2 rounded-lg bg-dashboard-primary px-4 py-2 text-sm font-medium text-white shadow-sm shadow-dashboard-primary/20 transition-colors hover:bg-dashboard-primary-dark" type="button">
            <span className="material-symbols-outlined text-[18px]">download</span>
            <span>{t('admin.dashboard.exportReport')}</span>
          </button>
        </div>
      </div>

      {loading ? (
        <div className="flex h-64 items-center justify-center">
          <div className="text-center">
            <div className="inline-block h-8 w-8 animate-spin rounded-full border-4 border-solid border-dashboard-primary border-r-transparent" />
            <p className="mt-2 text-sm text-slate-500 dark:text-slate-400">{t('common.loading')}</p>
          </div>
        </div>
      ) : (
        <>
          {activeTab === 'overview' && stats && (
            <>
              <LecturerStatsCards stats={stats} />
              <div className="lecturer-dashboard-panels">
                <CoursesPanel limit={5} />
                <StudentProgressPanel limit={5} />
              </div>
            </>
          )}

          {activeTab === 'courses' && <CoursesPanel limit={20} />}
          {activeTab === 'students' && <StudentProgressPanel limit={20} />}
          {activeTab === 'analytics' && <AnalyticsPanel />}
        </>
      )}
    </RoleDashboardLayout>
  );
};

export default LecturerDashboardPage;
