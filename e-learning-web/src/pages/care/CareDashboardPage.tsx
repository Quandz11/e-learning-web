import React, { useEffect, useState } from 'react';
import { useTranslation } from 'react-i18next';
import { careApi, type CareDashboardStatsDto } from '../../services/careApi';
import RoleDashboardLayout, { type RoleSidebarItem } from '../../components/dashboard/RoleDashboardLayout';
import CareStatsCards from '../../components/care/CareStatsCards';
import SupportTicketsPanel from '../../components/care/SupportTicketsPanel';
import CustomersPanel from '../../components/care/CustomersPanel';
import LeadRegistrationsPanel from '../../components/leads/LeadRegistrationsPanel';
import '../../styles/care-dashboard.css';

const CareDashboardPage: React.FC = () => {
  const { t } = useTranslation();
  const [stats, setStats] = useState<CareDashboardStatsDto | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [activeTab, setActiveTab] = useState<'overview' | 'tickets' | 'customers' | 'registrations'>('overview');

  const menuItems: RoleSidebarItem[] = [
    { id: 'overview', label: t('admin.dashboard.care.menu.overview'), icon: 'dashboard' },
    { id: 'tickets', label: t('admin.dashboard.care.menu.supportTickets'), icon: 'support_agent' },
    { id: 'customers', label: t('admin.dashboard.care.menu.customers'), icon: 'groups' },
    {
      id: 'registrations',
      label: t('admin.dashboard.care.menu.registrations', { defaultValue: 'Đăng ký tư vấn' }),
      icon: 'assignment',
    },
  ];

  useEffect(() => {
    const fetchStats = async () => {
      try {
        setLoading(true);
        const data = await careApi.getStats();
        setStats(data);
      } catch (err) {
        console.error('Failed to fetch care dashboard stats:', err);
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
        brand={t('admin.dashboard.care.brand')}
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
      brand={t('admin.dashboard.care.brand')}
      menuItems={menuItems}
      activeTab={activeTab}
      onTabChange={(tabId) => setActiveTab(tabId as typeof activeTab)}
      searchPlaceholder={t('admin.header.searchPlaceholder')}
    >
      <div className="mb-8 flex flex-col justify-between gap-4 md:flex-row md:items-end">
        <div>
          <h2 className="text-2xl font-bold tracking-tight text-slate-900 dark:text-white">
            {t('admin.dashboard.care.title')}
          </h2>
          <p className="mt-1 text-sm text-slate-500 dark:text-slate-400">
            {t('admin.dashboard.care.subtitle')}
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
              <CareStatsCards stats={stats} />
              <div className="care-dashboard-panels">
                <SupportTicketsPanel limit={5} />
                <CustomersPanel limit={5} />
              </div>
            </>
          )}

          {activeTab === 'tickets' && <SupportTicketsPanel limit={20} />}
          {activeTab === 'customers' && <CustomersPanel limit={20} />}
          {activeTab === 'registrations' && (
            <LeadRegistrationsPanel
              title={t('leadRegistrations.title', { defaultValue: 'Form đăng ký tư vấn' })}
              subtitle={t('leadRegistrations.subtitle', {
                defaultValue: 'Quản lý danh sách khách đăng ký từ trang chủ.',
              })}
            />
          )}
        </>
      )}
    </RoleDashboardLayout>
  );
};

export default CareDashboardPage;
