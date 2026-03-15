import React from 'react';
import { useTranslation } from 'react-i18next';
import type { AgentDashboardStatsDto } from '../../services/agentApi';
import StatsCard from '../admin/StatsCard';

interface AgentStatsCardsProps {
  stats: AgentDashboardStatsDto;
}

const AgentStatsCards: React.FC<AgentStatsCardsProps> = ({ stats }) => {
  const { t } = useTranslation();

  const formatCurrency = (amount: number) => {
    return new Intl.NumberFormat('vi-VN', {
      style: 'decimal',
      minimumFractionDigits: 0,
      maximumFractionDigits: 0,
    }).format(amount);
  };

  const formatTrend = (value: number) => {
    const sign = value >= 0 ? '+' : '';
    return `${sign}${value.toFixed(1)}%`;
  };

  const getTrendType = (value: number): 'positive' | 'negative' | 'neutral' => {
    if (value > 0) return 'positive';
    if (value < 0) return 'negative';
    return 'neutral';
  };

  const statCards = [
    {
      title: t('admin.dashboard.agent.stats.totalSalesThisMonth'),
      value: `${formatCurrency(stats.totalSalesThisMonth)} VND`,
      trend: formatTrend(stats.salesGrowthPercentage),
      trendType: getTrendType(stats.salesGrowthPercentage),
      icon: 'monitoring',
      chartColor: 'bg-dashboard-primary',
    },
    {
      title: t('admin.dashboard.agent.stats.commissionPending'),
      value: `${formatCurrency(stats.commissionPending)} VND`,
      trend: formatTrend(stats.commissionGrowthPercentage),
      trendType: getTrendType(stats.commissionGrowthPercentage),
      icon: 'payments',
      chartColor: 'bg-amber-500',
    },
    {
      title: t('admin.dashboard.agent.stats.activeReferrals'),
      value: stats.totalActiveReferrals.toLocaleString('vi-VN'),
      trend: t('admin.dashboard.agent.stats.currentStatus'),
      trendType: 'neutral' as const,
      icon: 'qr_code_2',
      chartColor: 'bg-blue-500',
    },
    {
      title: t('admin.dashboard.agent.stats.leaderboardRank'),
      value: `#${stats.leaderboardRank}`,
      trend: t('admin.dashboard.agent.stats.currentPosition'),
      trendType: 'neutral' as const,
      icon: 'military_tech',
      chartColor: 'bg-emerald-500',
    },
  ];

  return (
    <div className="mb-8 grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-2 xl:grid-cols-4 sm:gap-6">
      {statCards.map((card, index) => (
        <StatsCard
          key={index}
          title={card.title}
          value={String(card.value)}
          trend={card.trend}
          trendType={card.trendType}
          chart={
            <div className="flex h-full items-center justify-between gap-2">
              <span className="material-symbols-outlined text-3xl text-dashboard-primary">
                {card.icon}
              </span>
              <div className="flex h-full flex-1 items-end gap-1">
                <div className={`h-[35%] w-full rounded-t-sm ${card.chartColor} opacity-20`} />
                <div className={`h-[55%] w-full rounded-t-sm ${card.chartColor} opacity-35`} />
                <div className={`h-[45%] w-full rounded-t-sm ${card.chartColor} opacity-50`} />
                <div className={`h-[70%] w-full rounded-t-sm ${card.chartColor} opacity-70`} />
                <div className={`h-[95%] w-full rounded-t-sm ${card.chartColor}`} />
              </div>
            </div>
          }
        />
      ))}
    </div>
  );
};

export default AgentStatsCards;
