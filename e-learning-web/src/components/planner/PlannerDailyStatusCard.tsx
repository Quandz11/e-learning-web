import React, { useState } from 'react';
import { useTranslation } from 'react-i18next';
import { MOOD_OPTIONS } from '../../types/planner';

interface PlannerDailyStatusCardProps {
  onSubmitMood: (moodId: string) => void;
  isSubmitting?: boolean;
}

const PlannerDailyStatusCard: React.FC<PlannerDailyStatusCardProps> = ({ onSubmitMood, isSubmitting }) => {
  const { t } = useTranslation();
  const [selectedMood, setSelectedMood] = useState<string | null>(null);
  const [submitted, setSubmitted] = useState(false);

  const handleSelect = (moodId: string) => {
    if (submitted) return;
    setSelectedMood(moodId);
    setSubmitted(true);
    onSubmitMood(moodId);
  };

  return (
    <div className="rounded-2xl border border-slate-200 bg-white p-5 dark:border-slate-700/60 dark:bg-slate-800/80">
      <div className="flex items-center gap-3 mb-4">
        <div className="flex h-10 w-10 items-center justify-center rounded-xl bg-purple-50 dark:bg-purple-900/30">
          <span className="material-symbols-outlined text-purple-500 text-xl">sentiment_satisfied</span>
        </div>
        <div>
          <h3 className="text-base font-bold text-slate-900 dark:text-white">{t('planner.dailyStatus.title')}</h3>
          <p className="text-xs text-slate-500 dark:text-slate-400">{t('planner.dailyStatus.subtitle')}</p>
        </div>
      </div>

      {!submitted ? (
        <div className="space-y-1.5">
          {MOOD_OPTIONS.map((mood) => (
            <button
              key={mood.id}
              onClick={() => handleSelect(mood.id)}
              disabled={isSubmitting}
              className="flex w-full items-center gap-3 rounded-2xl px-4 py-3 text-left transition-all duration-300 bg-slate-50 hover:bg-slate-100 hover:scale-[1.01] dark:bg-slate-800/80 dark:hover:bg-slate-700/80 border border-slate-100 dark:border-slate-700"
            >
              <span className="text-2xl flex-shrink-0">{mood.emoji}</span>
              <span className="text-[13px] font-bold text-slate-700 dark:text-slate-300">
                {t(mood.labelKey)}
              </span>
              <span className="ml-auto material-symbols-outlined text-slate-300 dark:text-slate-600 text-[20px]">chevron_right</span>
            </button>
          ))}
        </div>
      ) : (
        <div className="animate-in fade-in zoom-in-95 duration-500">
          <div className={`overflow-hidden rounded-2xl border ${
            selectedMood === 'emergency' 
              ? 'border-orange-200 bg-orange-50/50 dark:border-orange-500/30 dark:bg-orange-500/10' 
              : 'border-purple-100 bg-purple-50/50 dark:border-purple-500/30 dark:bg-purple-500/10'
          } p-6 backdrop-blur-sm relative`}>
            {/* Background Decorative Icon */}
            <div className="absolute -right-4 -bottom-4 opacity-[0.03] dark:opacity-[0.05]">
              <span className="material-symbols-outlined text-8xl">person</span>
            </div>

            <div className="flex flex-col gap-4 items-center text-center">
              <div className={`flex h-14 w-14 items-center justify-center rounded-2xl shadow-inner ${
                selectedMood === 'emergency' ? 'bg-orange-100 text-orange-600' : 'bg-purple-100 text-purple-600'
              }`}>
                <span className="material-symbols-outlined text-3xl">person</span>
              </div>

              
              <div className="space-y-2">
                <div className="flex items-center justify-center gap-2">
                  <p className={`text-xs font-bold uppercase tracking-[0.2em] ${
                    selectedMood === 'emergency' ? 'text-orange-500' : 'text-purple-500'
                  }`}>
                    Coach Advice
                  </p>
                  <span className="h-1 w-1 rounded-full bg-slate-300 dark:bg-slate-600"></span>
                  <p className="text-xs font-medium text-slate-500">
                    {MOOD_OPTIONS.find(m => m.id === selectedMood)?.emoji} {t(`planner.moods.${selectedMood}`)}
                  </p>
                </div>
                
                <h4 className="text-[15px] font-bold text-slate-900 dark:text-white leading-relaxed">
                  {t(`planner.moodResponses.${selectedMood}`)}
                </h4>
              </div>

              <button 
                onClick={() => setSubmitted(false)}
                className="mt-2 text-[11px] font-bold text-slate-400 hover:text-purple-500 transition-colors uppercase tracking-wider flex items-center gap-1"
              >
                <span className="material-symbols-outlined text-sm">refresh</span>
                {t('common.change') || 'Thay đổi trạng thái'}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>


  );
};

export default PlannerDailyStatusCard;
