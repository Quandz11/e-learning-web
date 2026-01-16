import React from 'react';
import type { ReactNode } from 'react';

interface StatsCardProps {
  title: string;
  value: string;
  trend: string;
  trendType: 'positive' | 'negative' | 'neutral';
  chart: ReactNode;
}

const StatsCard: React.FC<StatsCardProps> = ({ title, value, trend, trendType, chart }) => {
  const getTrendStyles = () => {
    switch (trendType) {
      case 'positive':
        return 'bg-emerald-100 text-emerald-800 dark:bg-emerald-900/30 dark:text-emerald-400';
      case 'negative':
        return 'bg-red-100 text-red-800 dark:bg-red-900/30 dark:text-red-400';
      case 'neutral':
      default:
        return 'bg-slate-100 text-slate-800 dark:bg-slate-700 dark:text-slate-300';
    }
  };

  return (
    <div className="rounded-xl border border-slate-200 bg-dashboard-surface-light p-6 transition-shadow duration-300 hover:shadow-md dark:border-slate-800 dark:bg-dashboard-surface-dark shadow-dashboard-subtle">
      <div className="mb-4 flex items-start justify-between">
        <div>
          <p className="text-sm font-medium text-slate-500 dark:text-slate-400">{title}</p>
          <h3 className="mt-1 text-3xl font-bold text-slate-900 dark:text-white">{value}</h3>
        </div>
        <span className={`inline-flex items-center rounded px-2 py-0.5 text-xs font-medium ${getTrendStyles()}`}>
          {trend}
        </span>
      </div>
      <div className="h-12 w-full">
        {chart}
      </div>
    </div>
  );
};

export default StatsCard;
