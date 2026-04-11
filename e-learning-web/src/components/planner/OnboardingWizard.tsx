import React, { useState } from 'react';
import { useTranslation } from 'react-i18next';
import type { OnboardingFormData, OnboardingStep } from '../../types/planner';
import { STUDY_TIME_PRESETS } from '../../types/planner';

interface OnboardingWizardProps {
  onComplete: (data: OnboardingFormData) => Promise<void>;
  isSubmitting?: boolean;
}

const STEPS: OnboardingStep[] = [1, 2, 3, 4];

const OnboardingWizard: React.FC<OnboardingWizardProps> = ({ onComplete, isSubmitting }) => {
  const { t } = useTranslation();
  const [currentStep, setCurrentStep] = useState<OnboardingStep>(1);
  const [formData, setFormData] = useState<OnboardingFormData>({
    goal: '',
    currentKnowledge: '',
    motivation: '',
    timeBudgetMinutesPerDay: 30,
    preferredStudyTime: 'flexible',
    constraints: '',
  });
  const [error, setError] = useState<string | null>(null);

  const updateField = <K extends keyof OnboardingFormData>(key: K, value: OnboardingFormData[K]) => {
    setFormData((prev) => ({ ...prev, [key]: value }));
    if (error) setError(null);
  };

  const validateStep = (): boolean => {
    switch (currentStep) {
      case 1:
        if (!formData.goal.trim()) {
          setError(t('planner.onboarding.errors.goalRequired'));
          return false;
        }
        return true;
      case 2:
        if (!formData.currentKnowledge.trim()) {
          setError(t('planner.onboarding.errors.knowledgeRequired'));
          return false;
        }
        return true;
      case 3:
        if (formData.timeBudgetMinutesPerDay < 5) {
          setError(t('planner.onboarding.errors.timeMinimum'));
          return false;
        }
        return true;
      case 4:
        return true;
      default:
        return true;
    }
  };

  const handleNext = () => {
    if (!validateStep()) return;
    if (currentStep < 4) {
      setCurrentStep((prev) => (prev + 1) as OnboardingStep);
    }
  };

  const handleBack = () => {
    if (currentStep > 1) {
      setCurrentStep((prev) => (prev - 1) as OnboardingStep);
    }
  };

  const handleSubmit = async () => {
    if (!validateStep()) return;
    try {
      await onComplete(formData);
    } catch (err: any) {
      setError(err?.message || t('common.error'));
    }
  };

  const stepConfig = [
    { icon: '🎯', titleKey: 'planner.onboarding.step1Title', descKey: 'planner.onboarding.step1Desc' },
    { icon: '📚', titleKey: 'planner.onboarding.step2Title', descKey: 'planner.onboarding.step2Desc' },
    { icon: '⏰', titleKey: 'planner.onboarding.step3Title', descKey: 'planner.onboarding.step3Desc' },
    { icon: '🚀', titleKey: 'planner.onboarding.step4Title', descKey: 'planner.onboarding.step4Desc' },
  ];

  const currentConfig = stepConfig[currentStep - 1];

  return (
    <div className="mx-auto max-w-lg">
      {/* Progress dots */}
      <div className="mb-8 flex items-center justify-center gap-2">
        {STEPS.map((step) => (
          <div
            key={step}
            className={`h-2 rounded-full transition-all duration-300 ${
              step === currentStep
                ? 'w-8 bg-red-500'
                : step < currentStep
                  ? 'w-2 bg-red-300'
                  : 'w-2 bg-slate-200 dark:bg-slate-700'
            }`}
          />
        ))}
      </div>

      {/* Step header */}
      <div className="mb-6 text-center">
        <span className="mb-3 inline-block text-4xl">{currentConfig.icon}</span>
        <h2 className="text-2xl font-bold text-slate-900 dark:text-white">{t(currentConfig.titleKey)}</h2>
        <p className="mt-2 text-sm text-slate-500 dark:text-slate-400">{t(currentConfig.descKey)}</p>
      </div>

      {/* Error */}
      {error && (
        <div className="mb-4 rounded-xl border border-red-200 bg-red-50 p-3 text-sm text-red-700 dark:border-red-800/50 dark:bg-red-900/20 dark:text-red-300">
          {error}
        </div>
      )}

      {/* Step content */}
      <div className="mb-6 space-y-4">
        {currentStep === 1 && (
          <div>
            <label className="mb-1.5 block text-sm font-semibold text-slate-700 dark:text-slate-300">
              {t('planner.onboarding.goalLabel')}
            </label>
            <textarea
              className="w-full rounded-xl border border-slate-200 bg-white px-4 py-3 text-sm text-slate-900 placeholder-slate-400 focus:border-red-400 focus:outline-none focus:ring-1 focus:ring-red-400 dark:border-slate-700 dark:bg-slate-800 dark:text-white dark:placeholder-slate-500"
              rows={4}
              placeholder={t('planner.onboarding.goalPlaceholder')}
              value={formData.goal}
              onChange={(e) => updateField('goal', e.target.value)}
            />
          </div>
        )}

        {currentStep === 2 && (
          <>
            <div>
              <label className="mb-1.5 block text-sm font-semibold text-slate-700 dark:text-slate-300">
                {t('planner.onboarding.knowledgeLabel')}
              </label>
              <textarea
                className="w-full rounded-xl border border-slate-200 bg-white px-4 py-3 text-sm text-slate-900 placeholder-slate-400 focus:border-red-400 focus:outline-none focus:ring-1 focus:ring-red-400 dark:border-slate-700 dark:bg-slate-800 dark:text-white dark:placeholder-slate-500"
                rows={3}
                placeholder={t('planner.onboarding.knowledgePlaceholder')}
                value={formData.currentKnowledge}
                onChange={(e) => updateField('currentKnowledge', e.target.value)}
              />
            </div>
            <div>
              <label className="mb-1.5 block text-sm font-semibold text-slate-700 dark:text-slate-300">
                {t('planner.onboarding.motivationLabel')}
              </label>
              <textarea
                className="w-full rounded-xl border border-slate-200 bg-white px-4 py-3 text-sm text-slate-900 placeholder-slate-400 focus:border-red-400 focus:outline-none focus:ring-1 focus:ring-red-400 dark:border-slate-700 dark:bg-slate-800 dark:text-white dark:placeholder-slate-500"
                rows={2}
                placeholder={t('planner.onboarding.motivationPlaceholder')}
                value={formData.motivation}
                onChange={(e) => updateField('motivation', e.target.value)}
              />
            </div>
          </>
        )}

        {currentStep === 3 && (
          <>
            <div>
              <label className="mb-1.5 block text-sm font-semibold text-slate-700 dark:text-slate-300">
                {t('planner.onboarding.timeLabel')} — <span className="text-red-500 font-bold">{formData.timeBudgetMinutesPerDay} {t('planner.onboarding.minutes')}</span>
              </label>
              <input
                type="range"
                min={5}
                max={120}
                step={5}
                value={formData.timeBudgetMinutesPerDay}
                onChange={(e) => updateField('timeBudgetMinutesPerDay', Number(e.target.value))}
                className="w-full accent-red-500"
              />
              <div className="mt-1 flex justify-between text-xs text-slate-400">
                <span>5 min</span>
                <span>120 min</span>
              </div>
            </div>

            <div>
              <label className="mb-2 block text-sm font-semibold text-slate-700 dark:text-slate-300">
                {t('planner.onboarding.preferredTimeLabel')}
              </label>
              <div className="grid grid-cols-2 gap-2">
                {STUDY_TIME_PRESETS.map((preset) => (
                  <button
                    key={preset.value}
                    type="button"
                    onClick={() => updateField('preferredStudyTime', preset.value)}
                    className={`flex items-center gap-2 rounded-xl border px-4 py-3 text-sm font-medium transition-all duration-200 ${
                      formData.preferredStudyTime === preset.value
                        ? 'border-red-300 bg-red-50 text-red-700 dark:border-red-700/50 dark:bg-red-900/30 dark:text-red-400'
                        : 'border-slate-200 bg-white text-slate-700 hover:border-slate-300 dark:border-slate-700 dark:bg-slate-800 dark:text-slate-300 dark:hover:border-slate-600'
                    }`}
                  >
                    <span className="text-lg">{preset.icon}</span>
                    <span>{t(preset.labelKey)}</span>
                  </button>
                ))}
              </div>
            </div>
          </>
        )}

        {currentStep === 4 && (
          <div>
            <label className="mb-1.5 block text-sm font-semibold text-slate-700 dark:text-slate-300">
              {t('planner.onboarding.constraintsLabel')}
            </label>
            <textarea
              className="w-full rounded-xl border border-slate-200 bg-white px-4 py-3 text-sm text-slate-900 placeholder-slate-400 focus:border-red-400 focus:outline-none focus:ring-1 focus:ring-red-400 dark:border-slate-700 dark:bg-slate-800 dark:text-white dark:placeholder-slate-500"
              rows={3}
              placeholder={t('planner.onboarding.constraintsPlaceholder')}
              value={formData.constraints}
              onChange={(e) => updateField('constraints', e.target.value)}
            />
            <p className="mt-1 text-xs text-slate-400">{t('planner.onboarding.constraintsHint')}</p>
          </div>
        )}
      </div>

      {/* Navigation buttons */}
      <div className="flex gap-3">
        {currentStep > 1 && (
          <button
            onClick={handleBack}
            className="flex-1 rounded-xl border border-slate-200 py-3 text-sm font-semibold text-slate-700 transition-all hover:bg-slate-50 dark:border-slate-700 dark:text-slate-300 dark:hover:bg-slate-800"
          >
            {t('planner.onboarding.back')}
          </button>
        )}
        {currentStep < 4 ? (
          <button
            onClick={handleNext}
            className="flex-1 rounded-xl bg-red-500 py-3 text-sm font-bold text-white shadow-md shadow-red-500/20 transition-all hover:bg-red-600 active:scale-[0.98]"
          >
            {t('planner.onboarding.next')}
          </button>
        ) : (
          <button
            onClick={handleSubmit}
            disabled={isSubmitting}
            className="flex-1 rounded-xl bg-red-500 py-3 text-sm font-bold text-white shadow-md shadow-red-500/20 transition-all hover:bg-red-600 active:scale-[0.98] disabled:opacity-50 flex items-center justify-center gap-2"
          >
            {isSubmitting ? (
              <>
                <div className="h-4 w-4 animate-spin rounded-full border-2 border-white border-t-transparent" />
                <span>{t('planner.onboarding.creating')}</span>
              </>
            ) : (
              <>
                <span className="material-symbols-outlined text-lg">auto_awesome</span>
                <span>{t('planner.onboarding.createPlan')}</span>
              </>
            )}
          </button>
        )}
      </div>
    </div>
  );
};

export default OnboardingWizard;
