import React from 'react';
import { useTranslation } from 'react-i18next';
import type { WellnessFastingStatus } from '../../types/planner';

interface PlannerFastingCardProps {
  fastingStatus: WellnessFastingStatus | null;
}

const PlannerFastingCard: React.FC<PlannerFastingCardProps> = ({ fastingStatus }) => {
  const { t } = useTranslation();

  if (!fastingStatus) return null;

  const isEating = fastingStatus.state === 'EATING';
  const remainingH = Math.floor(fastingStatus.remainingMinutes / 60);
  const remainingM = fastingStatus.remainingMinutes % 60;

  return (
    <div className="rounded-2xl border border-slate-200 bg-white p-5 dark:border-slate-700/60 dark:bg-slate-800/80">
      {/* Header */}
      <div className="flex items-center justify-between mb-4">
        <div className="flex items-center gap-3">
          <div className={`flex h-10 w-10 items-center justify-center rounded-xl ${isEating ? 'bg-green-50 dark:bg-green-900/30' : 'bg-orange-50 dark:bg-orange-900/30'}`}>
            <span className={`material-symbols-outlined text-xl ${isEating ? 'text-green-500' : 'text-orange-500'}`}>
              {isEating ? 'restaurant' : 'timer'}
            </span>
          </div>
          <div>
            <h3 className="text-base font-bold text-slate-900 dark:text-white">{t('planner.fasting.title')}</h3>
            <span className={`text-xs font-semibold ${isEating ? 'text-green-600 dark:text-green-400' : 'text-orange-600 dark:text-orange-400'}`}>
              {isEating ? t('planner.fasting.eatingWindow') : t('planner.fasting.fastingWindow')}
            </span>
          </div>
        </div>
      </div>

      {/* Time remaining */}
      <div className="mb-4 text-center">
        <div className="text-3xl font-bold text-slate-900 dark:text-white tabular-nums">
          {remainingH}<span className="text-lg text-slate-400">h</span>{' '}
          {remainingM}<span className="text-lg text-slate-400">min</span>
        </div>
        <p className="text-xs text-slate-500 dark:text-slate-400 mt-1">
          {isEating ? t('planner.fasting.eatingRemaining') : t('planner.fasting.fastingRemaining')}
        </p>
      </div>

      {/* Progress bar */}
      <div className="mb-3">
        <div className="h-3 overflow-hidden rounded-full bg-slate-100 dark:bg-slate-700">
          <div
            className={`h-full rounded-full transition-all duration-700 ${
              isEating
                ? 'bg-gradient-to-r from-green-400 to-emerald-500'
                : 'bg-gradient-to-r from-orange-400 to-amber-500'
            }`}
            style={{ width: `${fastingStatus.progressPercent}%` }}
          />
        </div>
      </div>

      {/* Schedule labels */}
      <div className="flex items-center justify-between text-xs text-slate-500 dark:text-slate-400">
        <span>{fastingStatus.windowStartLocal?.slice(11, 16) || '--:--'}</span>
        <span className="font-medium">{fastingStatus.label}</span>
        <span>{fastingStatus.windowEndLocal?.slice(11, 16) || '--:--'}</span>
      </div>
    </div>
  );
};

export default PlannerFastingCard;
