import React from 'react';
import { useTranslation } from 'react-i18next';
import type { LecturerDashboardStatsDto } from '../../services/lecturerApi';
import StatsCard from '../admin/StatsCard';

interface LecturerStatsCardsProps {
  stats: LecturerDashboardStatsDto;
}

const LecturerStatsCards: React.FC<LecturerStatsCardsProps> = ({ stats }) => {
  const { t } = useTranslation();

  const totalCourses = Number.isFinite(stats.totalCoursesTeaching) ? stats.totalCoursesTeaching : 0;
  const totalStudents = Number.isFinite(stats.totalStudentsActive) ? stats.totalStudentsActive : 0;
  const completionRate = Number.isFinite(stats.averageCompletionRate) ? stats.averageCompletionRate : 0;
  const revenue = Number.isFinite(stats.courseRevenueThisMonth) ? stats.courseRevenueThisMonth : 0;
  const completionTrend = Number.isFinite(stats.completionRateTrendPercentage)
    ? stats.completionRateTrendPercentage
    : 0;

  const formatCurrency = (amount: number) =>
    new Intl.NumberFormat('vi-VN', {
      style: 'decimal',
      minimumFractionDigits: 0,
      maximumFractionDigits: 0,
    }).format(amount);

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
      title: t('admin.dashboard.lecturer.stats.totalCourses'),
      value: totalCourses.toLocaleString('vi-VN'),
      trend: t('admin.dashboard.lecturer.stats.currentLoad'),
      trendType: 'neutral' as const,
      icon: 'library_books',
      chartColor: 'bg-dashboard-primary',
    },
    {
      title: t('admin.dashboard.lecturer.stats.activeStudents'),
      value: totalStudents.toLocaleString('vi-VN'),
      trend: t('admin.dashboard.lecturer.stats.currentStatus'),
      trendType: 'neutral' as const,
      icon: 'groups',
      chartColor: 'bg-blue-500',
    },
    {
      title: t('admin.dashboard.lecturer.stats.completionRate'),
      value: `${completionRate.toFixed(1)}%`,
      trend: formatTrend(completionTrend),
      trendType: getTrendType(completionTrend),
      icon: 'task_alt',
      chartColor: 'bg-emerald-500',
    },
    {
      title: t('admin.dashboard.lecturer.stats.revenue'),
      value: `${formatCurrency(revenue)} VND`,
      trend: formatTrend(completionTrend),
      trendType: getTrendType(completionTrend),
      icon: 'payments',
      chartColor: 'bg-amber-500',
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

export default LecturerStatsCards;
