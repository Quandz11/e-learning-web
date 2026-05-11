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

      <div className="space-y-1.5">
        {MOOD_OPTIONS.map((mood) => {
          const isSelected = selectedMood === mood.id;
          return (
            <button
              key={mood.id}
              onClick={() => handleSelect(mood.id)}
              disabled={submitted || isSubmitting}
              className={`
                flex w-full items-center gap-3 rounded-2xl px-4 py-3 text-left transition-all duration-300
                ${
                  isSelected
                    ? 'bg-gradient-to-r from-purple-500 to-indigo-600 text-white shadow-lg shadow-purple-500/30 scale-[1.02] -translate-y-0.5 border-transparent'
                    : submitted
                      ? 'opacity-30 cursor-not-allowed bg-slate-50 dark:bg-slate-800 border-transparent grayscale'
                      : 'bg-slate-50 hover:bg-slate-100 hover:scale-[1.01] dark:bg-slate-800/80 dark:hover:bg-slate-700/80 border border-slate-100 dark:border-slate-700'
                }
              `}
            >
              <span className={`text-2xl flex-shrink-0 transition-transform ${isSelected ? 'scale-110 drop-shadow-md' : ''}`}>{mood.emoji}</span>
              <span className={`text-[13px] font-bold ${isSelected ? 'text-white' : 'text-slate-700 dark:text-slate-300'}`}>
                {t(mood.labelKey)}
              </span>
              {isSelected && (
                <span className="ml-auto material-symbols-outlined text-white text-[20px] drop-shadow-md animate-in zoom-in spin-in-12">check_circle</span>
              )}
            </button>
          );
        })}
      </div>

      {submitted && selectedMood && (
        <div className={`mt-5 overflow-hidden rounded-2xl border ${
          selectedMood === 'emergency' 
            ? 'border-orange-200 bg-orange-50/50 dark:border-orange-500/30 dark:bg-orange-500/10' 
            : 'border-purple-100 bg-purple-50/50 dark:border-purple-500/30 dark:bg-purple-500/10'
        } p-4 backdrop-blur-sm animate-in fade-in slide-in-from-top-2 duration-500`}>
          <div className="flex gap-3">
            <div className={`flex h-8 w-8 shrink-0 items-center justify-center rounded-full ${
              selectedMood === 'emergency' ? 'bg-orange-100 text-orange-600' : 'bg-purple-100 text-purple-600'
            }`}>
              <span className="material-symbols-outlined text-lg">smart_toy</span>
            </div>
            <div className="space-y-1">
              <p className={`text-[10px] font-bold uppercase tracking-wider ${
                selectedMood === 'emergency' ? 'text-orange-500' : 'text-purple-500'
              }`}>
                Coach Advice
              </p>
              <p className="text-[13px] leading-relaxed text-slate-700 dark:text-slate-300">
                {t(`planner.moodResponses.${selectedMood}`)}
              </p>
            </div>
          </div>
        </div>
      )}
    </div>

  );
};

export default PlannerDailyStatusCard;
