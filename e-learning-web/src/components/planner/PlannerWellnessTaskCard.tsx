import React, { useState } from 'react';

import type { WellnessDailyTask } from '../../types/planner';

interface PlannerWellnessTaskCardProps {
  tasks: WellnessDailyTask[];
  onStartLearning: (task: WellnessDailyTask) => void;
  onCompleteTask: (taskId: string) => void;
  isSubmitting?: boolean;
}

const PlannerWellnessTaskCard: React.FC<PlannerWellnessTaskCardProps> = ({ tasks, onStartLearning, onCompleteTask, isSubmitting }) => {
  const [expandedId, setExpandedId] = useState<string | null>(null);

  if (tasks.length === 0) {
    return null;
  }

  const primaryTask = tasks.find((t) => !t.isCompleted) || tasks[0];
  const otherTasks = tasks.filter((t) => t.id !== primaryTask.id);

  return (
    <div className="rounded-2xl border border-emerald-200 bg-white dark:border-slate-700/60 dark:bg-slate-800/80 overflow-hidden shadow-sm">
      {/* Header */}
      <div className="flex items-center gap-3 p-5 pb-3">
        <div className="flex h-10 w-10 items-center justify-center rounded-xl bg-emerald-50 dark:bg-emerald-900/30">
          <span className="material-symbols-outlined text-emerald-500 text-xl">self_improvement</span>
        </div>
        <div className="flex-1">
          <h3 className="text-base font-bold text-slate-900 dark:text-white">Bài Học Hôm Nay</h3>
          <p className="text-xs text-slate-500 dark:text-slate-400">
            {tasks.filter((t) => t.isCompleted).length}/{tasks.length} bài học hoàn thành
          </p>
        </div>
      </div>

      {/* Primary task */}
      <div className="border-t border-slate-100 dark:border-slate-700/50 p-5">
        <div className="flex gap-4">
          <div className="flex h-14 w-14 flex-shrink-0 items-center justify-center rounded-xl bg-gradient-to-br from-emerald-50 to-emerald-100 dark:from-emerald-900/40 dark:to-emerald-800/40">
            <span className="material-symbols-outlined text-2xl text-emerald-600 dark:text-emerald-400">
              play_circle
            </span>
          </div>
          <div className="flex-1 min-w-0">
            <h4 className="text-sm font-bold text-slate-900 dark:text-white truncate">{primaryTask.lessonTitle}</h4>
            <div className="mt-1 flex items-center gap-3 text-xs text-slate-500 dark:text-slate-400">
              <span className="flex items-center gap-1">
                <span className="material-symbols-outlined text-[14px]">self_improvement</span>
                Wellness
              </span>
            </div>
            {primaryTask.description && (
              <p className="mt-2 text-xs text-slate-500 dark:text-slate-400 line-clamp-2">{primaryTask.description}</p>
            )}
          </div>
        </div>

        {!primaryTask.isCompleted ? (
          <div className="mt-4 grid gap-2 sm:grid-cols-2">
            <button
              onClick={() => onStartLearning(primaryTask)}
              disabled={isSubmitting || !primaryTask.courseId}
              className="w-full rounded-xl bg-emerald-500 py-3 text-sm font-bold uppercase tracking-wider text-white shadow-md shadow-emerald-500/20 transition-all duration-200 hover:bg-emerald-600 hover:shadow-lg hover:shadow-emerald-500/30 active:scale-[0.98] disabled:opacity-50"
            >
              <span className="flex items-center justify-center gap-2">
                <span className="material-symbols-outlined text-lg">play_arrow</span>
                Bắt đầu học
              </span>
            </button>
            <button
              onClick={() => onCompleteTask(primaryTask.id)}
              disabled={isSubmitting}
              className="w-full rounded-xl bg-slate-100 py-3 text-sm font-semibold text-slate-700 hover:bg-slate-200 dark:bg-slate-700 dark:text-slate-300 dark:hover:bg-slate-600 transition-colors disabled:opacity-50"
            >
              Đánh dấu hoàn thành
            </button>
          </div>
        ) : (
          <div className="mt-4 flex items-center justify-center gap-2 rounded-xl bg-emerald-50 py-3 text-sm font-semibold text-emerald-600 dark:bg-emerald-900/20 dark:text-emerald-400">
            <span className="material-symbols-outlined text-lg">check_circle</span>
            Đã hoàn thành
          </div>
        )}
      </div>

      {/* Other tasks accordion */}
      {otherTasks.length > 0 && (
        <div className="border-t border-slate-100 dark:border-slate-700/50">
          {otherTasks.map((task) => (
            <div key={task.id} className="border-b border-slate-50 last:border-b-0 dark:border-slate-700/30">
              <button
                onClick={() => setExpandedId(expandedId === task.id ? null : task.id)}
                className="flex w-full items-center gap-3 px-5 py-3 text-left hover:bg-slate-50 dark:hover:bg-slate-700/30 transition-colors"
              >
                <div className={`flex h-6 w-6 items-center justify-center rounded-full ${task.isCompleted ? 'bg-emerald-100 dark:bg-emerald-900/30' : 'border-2 border-slate-300 dark:border-slate-600'}`}>
                  {task.isCompleted && (
                    <span className="material-symbols-outlined text-sm text-emerald-500 dark:text-emerald-400">check</span>
                  )}
                </div>
                <span className={`flex-1 text-sm font-medium truncate ${task.isCompleted ? 'text-slate-400 line-through dark:text-slate-500' : 'text-slate-700 dark:text-slate-300'}`}>
                  {task.lessonTitle}
                </span>
                <span className={`material-symbols-outlined text-sm text-slate-400 transition-transform duration-200 ${expandedId === task.id ? 'rotate-180' : ''}`}>
                  expand_more
                </span>
              </button>

              {expandedId === task.id && (
                <div className="px-5 pb-3">
                  {task.description && (
                    <p className="mb-2 text-xs text-slate-500 dark:text-slate-400 pl-9">{task.description}</p>
                  )}
                  {!task.isCompleted && (
                    <div className="ml-9 flex flex-wrap gap-2">
                      <button
                        onClick={() => onStartLearning(task)}
                        disabled={isSubmitting || !task.courseId}
                        className="rounded-lg bg-emerald-500 px-4 py-2 text-xs font-semibold text-white hover:bg-emerald-600 transition-colors disabled:opacity-50"
                      >
                        Bắt đầu học
                      </button>
                      <button
                        onClick={() => onCompleteTask(task.id)}
                        disabled={isSubmitting}
                        className="rounded-lg bg-slate-100 px-4 py-2 text-xs font-semibold text-slate-700 hover:bg-slate-200 dark:bg-slate-700 dark:text-slate-300 dark:hover:bg-slate-600 transition-colors disabled:opacity-50"
                      >
                        Đánh dấu hoàn thành
                      </button>
                    </div>
                  )}
                </div>
              )}
            </div>
          ))}
        </div>
      )}
    </div>
  );
};

export default PlannerWellnessTaskCard;
