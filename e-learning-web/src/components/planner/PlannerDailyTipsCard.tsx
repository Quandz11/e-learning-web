import React from 'react';
import { useTranslation } from 'react-i18next';

interface PlannerDailyTipsCardProps {
  guidanceMessage: string;
}

const tips = [
  { icon: '🌙', colorClass: 'from-indigo-500/10 to-purple-500/10 dark:from-indigo-900/30 dark:to-purple-900/30', labelKey: 'planner.tips.sleep' },
  { icon: '🔥', colorClass: 'from-orange-500/10 to-red-500/10 dark:from-orange-900/30 dark:to-red-900/30', labelKey: 'planner.tips.fatBurning' },
  { icon: '💧', colorClass: 'from-cyan-500/10 to-blue-500/10 dark:from-cyan-900/30 dark:to-blue-900/30', labelKey: 'planner.tips.hydration' },
];

const PlannerDailyTipsCard: React.FC<PlannerDailyTipsCardProps> = ({ guidanceMessage }) => {
  const { t } = useTranslation();

  return (
    <div className="rounded-2xl border border-slate-200 bg-white p-5 dark:border-slate-700/60 dark:bg-slate-800/80">
      <div className="flex items-center gap-3 mb-4">
        <div className="flex h-10 w-10 items-center justify-center rounded-xl bg-amber-50 dark:bg-amber-900/30">
          <span className="material-symbols-outlined text-amber-500 text-xl">lightbulb</span>
        </div>
        <h3 className="text-base font-bold text-slate-900 dark:text-white">{t('planner.tips.title')}</h3>
      </div>

      {guidanceMessage ? (
        <div className="rounded-xl bg-gradient-to-br from-amber-50 to-orange-50 p-4 dark:from-amber-900/20 dark:to-orange-900/20">
          <p className="text-sm text-slate-700 dark:text-slate-300 leading-relaxed whitespace-pre-line">
            {guidanceMessage}
          </p>
        </div>
      ) : (
        <div className="grid grid-cols-3 gap-2">
          {tips.map((tip) => (
            <div
              key={tip.labelKey}
              className={`flex flex-col items-center gap-2 rounded-xl bg-gradient-to-br ${tip.colorClass} p-3 text-center`}
            >
              <span className="text-2xl">{tip.icon}</span>
              <span className="text-xs font-medium text-slate-700 dark:text-slate-300">{t(tip.labelKey)}</span>
            </div>
          ))}
        </div>
      )}
    </div>
  );
};

export default PlannerDailyTipsCard;
