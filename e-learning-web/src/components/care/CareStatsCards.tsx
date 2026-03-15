import React from 'react';
import { useTranslation } from 'react-i18next';
import type { CareDashboardStatsDto } from '../../services/careApi';
import StatsCard from '../admin/StatsCard';

interface CareStatsCardsProps {
  stats: CareDashboardStatsDto;
}

const CareStatsCards: React.FC<CareStatsCardsProps> = ({ stats }) => {
  const { t } = useTranslation();

  const totalCustomers = Number.isFinite(stats.totalCustomers) ? stats.totalCustomers : 0;
  const activeTickets = Number.isFinite(stats.activeTickets) ? stats.activeTickets : 0;
  const averageSatisfaction = Number.isFinite(stats.averageSatisfaction) ? stats.averageSatisfaction : 0;
  const unresolvedTickets = Number.isFinite(stats.unresolvedTickets) ? stats.unresolvedTickets : 0;
  const satisfactionTrend = Number.isFinite(stats.satisfactionTrend) ? stats.satisfactionTrend : 0;

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
      title: t('admin.dashboard.care.stats.totalCustomers'),
      value: totalCustomers.toLocaleString('vi-VN'),
      trend: formatTrend(satisfactionTrend),
      trendType: getTrendType(satisfactionTrend),
      icon: 'groups',
      chartColor: 'bg-dashboard-primary',
    },
    {
      title: t('admin.dashboard.care.stats.activeTickets'),
      value: activeTickets.toLocaleString('vi-VN'),
      trend: t('admin.dashboard.care.stats.currentStatus'),
      trendType: 'neutral' as const,
      icon: 'support_agent',
      chartColor: 'bg-amber-500',
    },
    {
      title: t('admin.dashboard.care.stats.averageSatisfaction'),
      value: `${averageSatisfaction.toFixed(1)} / 5`,
      trend: formatTrend(satisfactionTrend),
      trendType: getTrendType(satisfactionTrend),
      icon: 'grade',
      chartColor: 'bg-blue-500',
    },
    {
      title: t('admin.dashboard.care.stats.unresolvedTickets'),
      value: unresolvedTickets.toLocaleString('vi-VN'),
      trend: t('admin.dashboard.care.stats.pending'),
      trendType: 'neutral' as const,
      icon: 'warning',
      chartColor: 'bg-red-500',
    },
  ];

  return (
    <div className="mb-8 grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-2 xl:grid-cols-4 sm:gap-6">
      {statCards.map((card, index) => (
        <StatsCard
          key={index}
          title={card.title}
          value={card.value}
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

export default CareStatsCards;
