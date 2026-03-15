import React, { useEffect, useState } from 'react';
import { useTranslation } from 'react-i18next';
import { agentApi, type AgentDashboardStatsDto } from '../../services/agentApi';
import RoleDashboardLayout, { type RoleSidebarItem } from '../../components/dashboard/RoleDashboardLayout';
import AgentStatsCards from '../../components/agent/AgentStatsCards';
import SalesChartPanel from '../../components/agent/SalesChartPanel';
import ReferralsPanel from '../../components/agent/ReferralsPanel';
import CommissionPanel from '../../components/agent/CommissionPanel';
import LeaderboardPanel from '../../components/agent/LeaderboardPanel';
import '../../styles/agent-dashboard.css';

const AgentDashboardPage: React.FC = () => {
  const { t } = useTranslation();
  const [stats, setStats] = useState<AgentDashboardStatsDto | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [activeTab, setActiveTab] = useState<'overview' | 'sales' | 'referrals' | 'commission' | 'leaderboard'>('overview');

  const menuItems: RoleSidebarItem[] = [
    { id: 'overview', label: t('admin.dashboard.agent.menu.overview'), icon: 'dashboard' },
    { id: 'sales', label: t('admin.dashboard.agent.menu.sales'), icon: 'monitoring' },
    { id: 'referrals', label: t('admin.dashboard.agent.menu.referrals'), icon: 'qr_code_2' },
    { id: 'commission', label: t('admin.dashboard.agent.menu.commission'), icon: 'payments' },
    { id: 'leaderboard', label: t('admin.dashboard.agent.menu.leaderboard'), icon: 'military_tech' },
  ];

  useEffect(() => {
    const fetchStats = async () => {
      try {
        setLoading(true);
        const data = await agentApi.getStats();
        setStats(data);
      } catch (err) {
        console.error('Failed to fetch agent dashboard stats:', err);
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
        brand={t('admin.dashboard.agent.brand')}
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
      brand={t('admin.dashboard.agent.brand')}
      menuItems={menuItems}
      activeTab={activeTab}
      onTabChange={(tabId) => setActiveTab(tabId as typeof activeTab)}
      searchPlaceholder={t('admin.header.searchPlaceholder')}
    >
      <div className="mb-8 flex flex-col justify-between gap-4 md:flex-row md:items-end">
        <div>
          <h2 className="text-2xl font-bold tracking-tight text-slate-900 dark:text-white">
            {t('admin.dashboard.agent.title')}
          </h2>
          <p className="mt-1 text-sm text-slate-500 dark:text-slate-400">
            {t('admin.dashboard.agent.overviewSubtitle')}
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
              <AgentStatsCards stats={stats} />
              <div className="agent-dashboard-panels">
                <SalesChartPanel />
                <ReferralsPanel limit={5} />
              </div>
              <div className="agent-dashboard-panels">
                <CommissionPanel />
                <LeaderboardPanel limit={5} />
              </div>
            </>
          )}

          {activeTab === 'sales' && <SalesChartPanel fullscreen />}
          {activeTab === 'referrals' && <ReferralsPanel limit={20} />}
          {activeTab === 'commission' && <CommissionPanel />}
          {activeTab === 'leaderboard' && <LeaderboardPanel limit={100} />}
        </>
      )}
    </RoleDashboardLayout>
  );
};

export default AgentDashboardPage;
