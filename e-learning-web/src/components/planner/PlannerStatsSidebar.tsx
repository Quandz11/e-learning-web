import React from 'react';
import { useTranslation } from 'react-i18next';
import type { PlannerStats } from '../../types/planner';

interface PlannerStatsSidebarProps {
  stats: PlannerStats;
}

const PlannerStatsSidebar: React.FC<PlannerStatsSidebarProps> = ({ stats }) => {
  const { t } = useTranslation();
  const taskPercent = stats.tasksTotal > 0 ? Math.round((stats.tasksCompleted / stats.tasksTotal) * 100) : 0;
  const waterPercent = stats.waterGoalMl > 0 ? Math.min(Math.round((stats.waterMl / stats.waterGoalMl) * 100), 100) : 0;

  return (
    <div className="sticky top-24 space-y-4">
      {/* Stats header */}
      <div className="rounded-2xl border border-slate-200 bg-white p-5 dark:border-slate-700/60 dark:bg-slate-800/80">
        <h3 className="mb-4 text-sm font-bold uppercase tracking-wider text-slate-500 dark:text-slate-400">
          {t('planner.stats.title')}
        </h3>

        <div className="space-y-5">
          {/* Tasks */}
          <div>
            <div className="mb-2 flex items-center justify-between">
              <div className="flex items-center gap-2">
                <div className="flex h-8 w-8 items-center justify-center rounded-lg bg-blue-50 dark:bg-blue-900/30">
                  <span className="material-symbols-outlined text-blue-500 text-base">school</span>
                </div>
                <span className="text-sm font-medium text-slate-700 dark:text-slate-300">{t('planner.stats.tasks')}</span>
              </div>
              <span className="text-sm font-bold text-slate-900 dark:text-white tabular-nums">
                {stats.tasksCompleted}/{stats.tasksTotal}
              </span>
            </div>
            <div className="h-2 overflow-hidden rounded-full bg-slate-100 dark:bg-slate-700">
              <div
                className="h-full rounded-full bg-gradient-to-r from-blue-400 to-indigo-500 transition-all duration-500"
                style={{ width: `${taskPercent}%` }}
              />
            </div>
          </div>

          {/* Water */}
          <div>
            <div className="mb-2 flex items-center justify-between">
              <div className="flex items-center gap-2">
                <div className="flex h-8 w-8 items-center justify-center rounded-lg bg-cyan-50 dark:bg-cyan-900/30">
                  <span className="material-symbols-outlined text-cyan-500 text-base">water_drop</span>
                </div>
                <span className="text-sm font-medium text-slate-700 dark:text-slate-300">{t('planner.stats.water')}</span>
              </div>
              <span className="text-sm font-bold text-slate-900 dark:text-white tabular-nums">
                {stats.waterMl}ml
              </span>
            </div>
            <div className="h-2 overflow-hidden rounded-full bg-slate-100 dark:bg-slate-700">
              <div
                className="h-full rounded-full bg-gradient-to-r from-cyan-400 to-blue-500 transition-all duration-500"
                style={{ width: `${waterPercent}%` }}
              />
            </div>
          </div>

          {/* Fasting progress */}
          {stats.fastingProgressPercent > 0 && (
            <div>
              <div className="mb-2 flex items-center justify-between">
                <div className="flex items-center gap-2">
                  <div className="flex h-8 w-8 items-center justify-center rounded-lg bg-orange-50 dark:bg-orange-900/30">
                    <span className="material-symbols-outlined text-orange-500 text-base">timer</span>
                  </div>
                  <span className="text-sm font-medium text-slate-700 dark:text-slate-300">{t('planner.stats.fasting')}</span>
                </div>
                <span className="text-sm font-bold text-slate-900 dark:text-white tabular-nums">
                  {stats.fastingProgressPercent}%
                </span>
              </div>
              <div className="h-2 overflow-hidden rounded-full bg-slate-100 dark:bg-slate-700">
                <div
                  className="h-full rounded-full bg-gradient-to-r from-orange-400 to-amber-500 transition-all duration-500"
                  style={{ width: `${stats.fastingProgressPercent}%` }}
                />
              </div>
            </div>
          )}
        </div>
      </div>

      {/* Streak */}
      {stats.streakDays > 0 && (
        <div className="rounded-2xl border border-slate-200 bg-gradient-to-br from-orange-50 to-amber-50 p-5 dark:border-orange-800/30 dark:from-orange-900/20 dark:to-amber-900/20">
          <div className="flex items-center gap-3">
            <span className="text-3xl">🔥</span>
            <div>
              <div className="text-2xl font-bold text-orange-600 dark:text-orange-400 tabular-nums">{stats.streakDays}</div>
              <div className="text-xs font-medium text-orange-600/70 dark:text-orange-400/70">{t('planner.stats.streakDays')}</div>
            </div>
          </div>
        </div>
      )}

      {/* Quick Coach Access */}
      <div className="rounded-2xl border border-slate-200 bg-white p-5 dark:border-slate-700/60 dark:bg-slate-800/80">
        <div className="flex items-center gap-3 mb-3">
          <div className="flex h-10 w-10 items-center justify-center rounded-xl bg-gradient-to-br from-violet-500 to-purple-600 shadow-md shadow-violet-500/20">
            <span className="material-symbols-outlined text-white text-xl">smart_toy</span>
          </div>
          <div>
            <h4 className="text-sm font-bold text-slate-900 dark:text-white">{t('planner.stats.coachTitle')}</h4>
            <p className="text-xs text-slate-500 dark:text-slate-400">{t('planner.stats.coachDesc')}</p>
          </div>
        </div>
      </div>
    </div>
  );
};

export default PlannerStatsSidebar;
