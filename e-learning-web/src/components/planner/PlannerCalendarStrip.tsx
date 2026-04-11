import React, { useMemo } from 'react';
import { useTranslation } from 'react-i18next';
import type { CalendarDay } from '../../types/planner';

interface PlannerCalendarStripProps {
  selectedDate: Date;
  onSelectDate: (date: Date) => void;
}

const DAY_KEYS = ['sun', 'mon', 'tue', 'wed', 'thu', 'fri', 'sat'] as const;

const PlannerCalendarStrip: React.FC<PlannerCalendarStripProps> = ({ selectedDate, onSelectDate }) => {
  const { t } = useTranslation();

  const weekDays = useMemo((): CalendarDay[] => {
    const today = new Date();
    today.setHours(0, 0, 0, 0);

    // Find Monday of current week
    const dayOfWeek = today.getDay();
    const monday = new Date(today);
    monday.setDate(today.getDate() - ((dayOfWeek + 6) % 7));

    return Array.from({ length: 7 }, (_, i) => {
      const date = new Date(monday);
      date.setDate(monday.getDate() + i);
      const isToday = date.toDateString() === today.toDateString();
      const isSelected = date.toDateString() === selectedDate.toDateString();

      return {
        date,
        dayOfWeek: t(`planner.calendar.${DAY_KEYS[date.getDay()]}`),
        dayOfMonth: date.getDate(),
        isToday,
        isSelected,
        hasActivity: false,
      };
    });
  }, [selectedDate, t]);

  const monthLabel = useMemo(() => {
    const formatter = new Intl.DateTimeFormat(undefined, { month: 'long', year: 'numeric' });
    return formatter.format(selectedDate);
  }, [selectedDate]);

  return (
    <div className="rounded-2xl border border-slate-200 bg-white p-4 dark:border-slate-700/60 dark:bg-slate-800/80 backdrop-blur-sm">
      {/* Month label */}
      <div className="mb-3 flex items-center justify-between">
        <h3 className="text-sm font-semibold capitalize text-slate-900 dark:text-white">{monthLabel}</h3>
        <span className="text-xs font-medium text-slate-500 dark:text-slate-400">
          {t('planner.calendar.thisWeek')}
        </span>
      </div>

      {/* Days row */}
      <div className="grid grid-cols-7 gap-1">
        {weekDays.map((day) => {
          const isActive = day.isSelected || day.isToday;
          return (
            <button
              key={day.date.toISOString()}
              onClick={() => onSelectDate(day.date)}
              className={`
                group flex flex-col items-center gap-0.5 rounded-xl py-2.5 transition-all duration-200
                ${
                  day.isSelected
                    ? 'bg-red-500 text-white shadow-md shadow-red-500/25 scale-105'
                    : day.isToday
                      ? 'bg-red-50 text-red-600 dark:bg-red-900/20 dark:text-red-400 ring-1 ring-red-200 dark:ring-red-800/50'
                      : 'text-slate-600 hover:bg-slate-100 dark:text-slate-400 dark:hover:bg-slate-700/50'
                }
              `}
            >
              <span className={`text-[10px] font-medium uppercase tracking-wider ${isActive ? '' : 'text-slate-400 dark:text-slate-500'}`}>
                {day.dayOfWeek}
              </span>
              <span className={`text-lg font-bold leading-none ${day.isSelected ? 'text-white' : ''}`}>
                {day.dayOfMonth}
              </span>
              {day.hasActivity && !day.isSelected && (
                <div className="mt-0.5 h-1 w-1 rounded-full bg-green-400" />
              )}
            </button>
          );
        })}
      </div>
    </div>
  );
};

export default PlannerCalendarStrip;
