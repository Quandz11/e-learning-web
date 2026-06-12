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
    <div className="rounded-2xl border border-slate-200 bg-white p-4 dark:border-slate-700/60 dark:bg-slate-800/80">
      <div className="flex items-center justify-between mb-3">
        {/* Header Left */}
        <div className="flex items-center gap-3">
          <div className={`flex h-10 w-10 shrink-0 items-center justify-center rounded-xl ${isEating ? 'bg-green-50 dark:bg-green-900/30' : 'bg-orange-50 dark:bg-orange-900/30'}`}>
            <span className={`material-symbols-outlined text-xl ${isEating ? 'text-green-500' : 'text-orange-500'}`}>
              {isEating ? 'restaurant' : 'timer'}
            </span>
          </div>
          <div>
            <h3 className="text-base font-bold text-slate-900 dark:text-white leading-tight">{t('planner.fasting.title')}</h3>
            <span className={`text-xs font-semibold ${isEating ? 'text-green-600 dark:text-green-400' : 'text-orange-600 dark:text-orange-400'}`}>
              {isEating ? t('planner.fasting.eatingWindow') : t('planner.fasting.fastingWindow')}
            </span>
          </div>
        </div>

        {/* Time remaining Right */}
        <div className="text-right">
          <div className="text-xl font-bold text-slate-900 dark:text-white tabular-nums leading-tight">
            {remainingH}<span className="text-sm font-medium text-slate-400">h</span>{' '}
            {remainingM}<span className="text-sm font-medium text-slate-400">m</span>
          </div>
          <p className="text-[10px] uppercase tracking-wider font-semibold text-slate-500 dark:text-slate-400">
            {isEating ? t('planner.fasting.eatingRemaining') : t('planner.fasting.fastingRemaining')}
          </p>
        </div>
      </div>

      {/* Progress bar */}
      <div className="mb-2">
        <div className="h-2 overflow-hidden rounded-full bg-slate-100 dark:bg-slate-700">
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
        <span className="font-medium text-[10px] uppercase tracking-wide">{fastingStatus.label}</span>
        <span>{fastingStatus.windowEndLocal?.slice(11, 16) || '--:--'}</span>
      </div>
    </div>
  );
};

export default PlannerFastingCard;
