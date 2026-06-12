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
  const isComplete = waterMl >= goalMl;

  return (
    <div className="rounded-2xl border border-slate-200 bg-white p-4 dark:border-slate-700/60 dark:bg-slate-800/80">
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-3">
          <div className="flex h-10 w-10 shrink-0 items-center justify-center rounded-xl bg-cyan-50 dark:bg-cyan-900/30">
            <span className="material-symbols-outlined text-cyan-500 text-xl">water_drop</span>
          </div>
          <div>
            <h3 className="text-base font-bold text-slate-900 dark:text-white leading-tight">{t('planner.water.title')}</h3>
            <p className="text-xs font-medium text-slate-500 dark:text-slate-400 mt-0.5">
              <span className="text-cyan-600 dark:text-cyan-400 font-bold">{waterMl}</span> / {goalMl}ml
            </p>
          </div>
        </div>

        <div className="flex items-center gap-3">
          {isComplete && (
            <span className="material-symbols-outlined text-emerald-500" title={t('planner.water.goalReached')}>check_circle</span>
          )}
          <button
            onClick={() => onLogWater(500)}
            disabled={isLogging || isComplete}
            className="flex items-center gap-1.5 rounded-xl bg-cyan-50 px-3 py-2 text-sm font-semibold text-cyan-700 transition-all hover:bg-cyan-100 active:scale-95 disabled:opacity-40 dark:bg-cyan-900/30 dark:text-cyan-400 dark:hover:bg-cyan-900/50"
            title={t('planner.water.add500ml', { defaultValue: 'Add 500ml' })}
          >
            <span className="material-symbols-outlined text-[20px]">local_drink</span>
            <span>+500ml</span>
          </button>
        </div>
      </div>
    </div>
  );
};

export default PlannerWaterCard;
