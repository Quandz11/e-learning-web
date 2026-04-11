import React from 'react';
import { useTranslation } from 'react-i18next';
import type { DailyStudyTask } from '../../types/planner';

interface PlannerHeroCardProps {
  tasks: DailyStudyTask[];
  streakDays: number;
  guidanceMessage: string;
  hasStudyPlan?: boolean;
  onStartOnboarding?: () => void;
}

const PlannerHeroCard: React.FC<PlannerHeroCardProps> = ({ tasks, streakDays, guidanceMessage, hasStudyPlan = true, onStartOnboarding }) => {
  const { t } = useTranslation();

  const allDone = tasks.length > 0 && tasks.every((t) => t.isCompleted);
  const completedCount = tasks.filter((t) => t.isCompleted).length;

  if (allDone) {
    return (
      <div className="relative overflow-hidden rounded-2xl bg-gradient-to-br from-emerald-500 via-teal-500 to-cyan-500 p-6 text-white shadow-lg shadow-emerald-500/20">
        {/* Background decoration */}
        <div className="absolute -right-6 -top-6 h-32 w-32 rounded-full bg-white/10" />
        <div className="absolute -bottom-4 -left-4 h-24 w-24 rounded-full bg-white/5" />
        
        <div className="relative z-10">
          <div className="mb-3 flex items-center gap-2">
            <span className="text-3xl">🎉</span>
            <h2 className="text-xl font-bold">{t('planner.hero.congrats')}</h2>
          </div>
          <p className="mb-4 text-sm text-white/85 leading-relaxed">
            {t('planner.hero.allDoneMessage')}
          </p>
          <div className="flex items-center gap-4">
            <div className="flex items-center gap-2 rounded-full bg-white/20 px-3 py-1.5 backdrop-blur-sm">
              <span className="text-base">🔥</span>
              <span className="text-sm font-semibold">{t('planner.hero.streak', { count: streakDays })}</span>
            </div>
            <div className="flex items-center gap-2 rounded-full bg-white/20 px-3 py-1.5 backdrop-blur-sm">
              <span className="text-base">✅</span>
              <span className="text-sm font-semibold">{tasks.length} {t('planner.hero.tasksCompleted')}</span>
            </div>
          </div>
        </div>
      </div>
    );
  }

  if (!hasStudyPlan) {
    return (
      <div className="relative overflow-hidden rounded-3xl bg-gradient-to-br from-indigo-50 via-purple-50 to-blue-50 p-6 text-slate-900 shadow-sm border border-indigo-100 dark:border-slate-800 dark:from-slate-800 dark:via-slate-800/90 dark:to-slate-900 dark:text-white">
        <div className="absolute -right-8 -top-8 h-36 w-36 rounded-full bg-indigo-500/10 dark:bg-indigo-500/5" />
        <div className="absolute -bottom-6 right-12 h-20 w-20 rounded-full bg-purple-500/10 dark:bg-purple-500/5" />
        
        <div className="relative z-10">
          <div className="mb-3 flex items-center gap-2">
            <h2 className="text-lg font-bold">{t('planner.hero.setupStudyTitle', { defaultValue: 'Kích hoạt lộ trình cá nhân hóa' })}</h2>
          </div>
          <p className="mb-4 text-[13px] font-medium text-slate-700 dark:text-slate-300">
            {t('planner.hero.setupStudyDesc', { defaultValue: 'Bạn chưa thiết lập Lộ trình học tập. Tạo lộ trình ngay để hệ thống tự động phân bổ bài học mỗi ngày nhé.' })}
          </p>
          <button onClick={onStartOnboarding} className="px-5 py-2.5 inline-flex items-center gap-2 bg-indigo-600 text-white rounded-xl text-sm font-bold shadow-md shadow-indigo-600/20 transition-all hover:bg-indigo-700 focus:ring-2 focus:ring-indigo-600 focus:ring-offset-2 dark:bg-indigo-500 dark:hover:bg-indigo-600">
             {t('planner.hero.setupStudyBtn', { defaultValue: 'Tạo lộ trình ngay' })}
          </button>
        </div>
      </div>
    );
  }

  if (tasks.length === 0) {
    return (
      <div className="relative overflow-hidden rounded-3xl bg-gradient-to-br from-slate-50 to-slate-100 p-6 text-slate-900 shadow-sm border border-slate-200 dark:border-slate-800 dark:from-slate-800 dark:to-slate-900 dark:text-white">
        <div className="relative z-10 flex flex-col items-center justify-center text-center py-2">
          <span className="text-4xl mb-3 opacity-80">☕</span>
          <h2 className="text-lg font-bold mb-1">{t('planner.hero.noTasksTitle', { defaultValue: 'Hôm nay không có lịch học' })}</h2>
          <p className="text-[13px] text-slate-500 dark:text-slate-400 max-w-[280px]">
            {t('planner.hero.noTasksDesc', { defaultValue: 'Lộ trình của bạn hôm nay trống. Hãy dành thời gian nghỉ ngơi hoặc ôn tập tự do nhé!' })}
          </p>
        </div>
      </div>
    );
  }

  // Has tasks but not all done — show progress + guidance
  return (
    <div className="relative overflow-hidden rounded-3xl bg-gradient-to-br from-emerald-50 via-teal-50 to-cyan-50 p-6 text-slate-900 shadow-sm border border-emerald-100 dark:border-slate-800 dark:from-slate-800 dark:via-slate-800/90 dark:to-slate-900 dark:text-white">
      <div className="absolute -right-8 -top-8 h-36 w-36 rounded-full bg-emerald-500/10 dark:bg-emerald-500/5" />
      <div className="absolute -bottom-6 right-12 h-20 w-20 rounded-full bg-cyan-500/10 dark:bg-cyan-500/5" />
      
      <div className="relative z-10">
        <div className="mb-3 flex items-center justify-between">
          <div className="flex items-center gap-2">
            <span className="text-2xl">📋</span>
            <h2 className="text-lg font-bold">{t('planner.hero.todayPlan')}</h2>
          </div>
          {streakDays > 0 && (
            <div className="flex items-center gap-1.5 rounded-full bg-orange-500/10 px-2.5 py-1 text-orange-600 dark:bg-orange-500/20 dark:text-orange-300">
              <span className="text-sm">🔥</span>
              <span className="text-xs font-bold">{streakDays}</span>
            </div>
          )}
        </div>

        {/* Progress bar */}
        <div className="mb-3">
          <div className="mb-1.5 flex items-center justify-between text-[13px]">
            <span className="text-slate-600 font-medium dark:text-slate-400">{t('planner.hero.progress')}</span>
            <span className="font-bold text-emerald-700 dark:text-emerald-400">{completedCount}/{tasks.length}</span>
          </div>
          <div className="h-2.5 overflow-hidden rounded-full bg-white/60 dark:bg-slate-700 border border-slate-200/50 dark:border-slate-600/50">
            <div
              className="h-full rounded-full bg-gradient-to-r from-emerald-400 to-teal-500 shadow-sm transition-all duration-500"
              style={{ width: `${tasks.length > 0 ? (completedCount / tasks.length) * 100 : 0}%` }}
            />
          </div>
        </div>

        {guidanceMessage && (
          <p className="text-[13px] font-medium text-teal-800/80 leading-relaxed line-clamp-2 dark:text-slate-300">
            💡 {guidanceMessage}
          </p>
        )}
      </div>
    </div>
  );
};

export default PlannerHeroCard;
