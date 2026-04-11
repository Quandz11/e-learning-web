import React from 'react';
import { useTranslation } from 'react-i18next';

interface PlannerWaterCardProps {
  waterMl: number;
  goalMl: number;
  onLogWater: (amountMl: number) => void;
  isLogging?: boolean;
}

const PlannerWaterCard: React.FC<PlannerWaterCardProps> = ({ waterMl, goalMl, onLogWater, isLogging }) => {
  const { t } = useTranslation();
  const progress = Math.min((waterMl / goalMl) * 100, 100);
  const isComplete = waterMl >= goalMl;

  return (
    <div className="rounded-2xl border border-slate-200 bg-white p-5 dark:border-slate-700/60 dark:bg-slate-800/80">
      <div className="flex items-center justify-between mb-4">
        <div className="flex items-center gap-3">
          <div className="flex h-10 w-10 items-center justify-center rounded-xl bg-cyan-50 dark:bg-cyan-900/30">
            <span className="material-symbols-outlined text-cyan-500 text-xl">water_drop</span>
          </div>
          <div>
            <h3 className="text-base font-bold text-slate-900 dark:text-white">{t('planner.water.title')}</h3>
            <p className="text-xs text-slate-500 dark:text-slate-400">
              {t('planner.water.goal', { amount: goalMl })}
            </p>
          </div>
        </div>
        <div className="text-right">
          <span className="text-lg font-bold text-cyan-600 dark:text-cyan-400 tabular-nums">{waterMl}</span>
          <span className="text-xs text-slate-400 dark:text-slate-500">/{goalMl}ml</span>
        </div>
      </div>

      {/* Progress bar */}
      <div className="mb-4">
        <div className="h-2.5 overflow-hidden rounded-full bg-cyan-100 dark:bg-slate-700">
          <div
            className={`h-full rounded-full transition-all duration-500 ${
              isComplete
                ? 'bg-gradient-to-r from-emerald-400 to-green-500'
                : 'bg-gradient-to-r from-cyan-400 to-blue-500'
            }`}
            style={{ width: `${progress}%` }}
          />
        </div>
      </div>

      {/* Quick log buttons */}
      <div className="flex gap-2">
        <button
          onClick={() => onLogWater(250)}
          disabled={isLogging || isComplete}
          className="flex-1 rounded-xl border border-cyan-200 bg-cyan-50 py-2.5 text-sm font-semibold text-cyan-700 transition-all duration-200 hover:bg-cyan-100 hover:border-cyan-300 active:scale-[0.97] dark:border-cyan-800/50 dark:bg-cyan-900/20 dark:text-cyan-400 dark:hover:bg-cyan-900/30 disabled:opacity-40"
        >
          +250ml
        </button>
        <button
          onClick={() => onLogWater(500)}
          disabled={isLogging || isComplete}
          className="flex-1 rounded-xl bg-cyan-500 py-2.5 text-sm font-semibold text-white shadow-md shadow-cyan-500/20 transition-all duration-200 hover:bg-cyan-600 active:scale-[0.97] disabled:opacity-40"
        >
          +500ml
        </button>
      </div>

      {isComplete && (
        <div className="mt-3 flex items-center justify-center gap-1.5 text-xs font-medium text-emerald-600 dark:text-emerald-400">
          <span className="material-symbols-outlined text-sm">check_circle</span>
          {t('planner.water.goalReached')}
        </div>
      )}
    </div>
  );
};

export default PlannerWaterCard;
