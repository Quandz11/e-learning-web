import React, { useMemo, useState } from 'react';
import { useTranslation } from 'react-i18next';
import { useNavigate } from 'react-router-dom';
import toast from 'react-hot-toast';
import { useDailyPlanner } from '../../hooks/useDailyPlanner';
import PlannerCalendarStrip from './PlannerCalendarStrip';
import PlannerHeroCard from './PlannerHeroCard';
import PlannerStudyCard from './PlannerStudyCard';
import PlannerFastingCard from './PlannerFastingCard';
import PlannerWaterCard from './PlannerWaterCard';
import PlannerDailyTipsCard from './PlannerDailyTipsCard';
import PlannerDailyStatusCard from './PlannerDailyStatusCard';
import PlannerStatsSidebar from './PlannerStatsSidebar';
import PlannerWellnessTaskCard from './PlannerWellnessTaskCard';
import PlannerSidebarLeft from './sidebars/PlannerSidebarLeft';
import PlannerMealCard from './sidebars/PlannerMealCard';
import OnboardingWizard from './OnboardingWizard';
import WellnessOnboardingWizard from './WellnessOnboardingWizard';
import type { DailyStudyTask, WellnessDailyTask, OnboardingFormData } from '../../types/planner';

const DailyPlannerView: React.FC = () => {
  const { t } = useTranslation();
  const navigate = useNavigate();
  const planner = useDailyPlanner();
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [forceOnboarding, setForceOnboarding] = useState(false);
  const [onboardingType, setOnboardingType] = useState<'study' | 'wellness'>('wellness');
  const wellnessPackagesForOnboarding = useMemo(() => {
    const packages = planner.checkoutConfig?.packages ?? [];
    const allowedCodes = new Set((planner.wellnessAccess?.allowedPackages ?? []).map((code) => code.trim().toUpperCase()));

    if (allowedCodes.size === 0) {
      return packages;
    }

    const preferredCode = (planner.wellnessAccess?.currentPackage ?? '').trim().toUpperCase();
    const filtered = packages.filter((pkg) => allowedCodes.has(pkg.code.trim().toUpperCase()));
    if (filtered.length <= 1 || !preferredCode) {
      return filtered;
    }

    return [...filtered].sort((left, right) => {
      const leftPreferred = left.code.trim().toUpperCase() === preferredCode ? -1 : 0;
      const rightPreferred = right.code.trim().toUpperCase() === preferredCode ? -1 : 0;
      return leftPreferred - rightPreferred;
    });
  }, [planner.checkoutConfig?.packages, planner.wellnessAccess?.allowedPackages, planner.wellnessAccess?.currentPackage]);

  /** Handle onboarding completion */
  const handleOnboardingComplete = async (data: OnboardingFormData) => {
    setIsSubmitting(true);
    try {
      await planner.initStudyPlan(data);
      toast.success(t('planner.toast.planCreated'));
      setForceOnboarding(false);
    } catch (err: any) {
      toast.error(err?.message || t('planner.toast.planCreateFailed'));
    } finally {
      setIsSubmitting(false);
    }
  };

  /** Handle task completion */
  const handleCompleteTask = async (taskId: string) => {
    setIsSubmitting(true);
    try {
      await planner.submitTask(taskId, {
        isCompleted: true,
        feedback: '',
        needsSupport: false,
      });
      toast.success(t('planner.toast.taskCompleted'));
    } catch (err: any) {
      toast.error(err?.message || t('planner.toast.taskCompleteFailed'));
    } finally {
      setIsSubmitting(false);
    }
  };

  const handleStartLearning = (task: DailyStudyTask) => {
    if (!task.relatedCourseId) {
      navigate('/my-courses');
      return;
    }

    const basePath = `/courses/${task.relatedCourseId}/learn`;
    const target = task.relatedLessonPartId
      ? `${basePath}?partId=${encodeURIComponent(task.relatedLessonPartId)}`
      : basePath;
    navigate(target);
  };

  const handleStartWellnessLearning = (task: WellnessDailyTask) => {
    if (!task.courseId) {
      navigate('/my-courses');
      return;
    }

    const target = `/courses/${task.courseId}/learn?partId=${encodeURIComponent(task.lessonId)}`;
    navigate(target);
  };

  /** Handle water logging */
  const handleLogWater = async (amountMl: number) => {
    try {
      await planner.logWater(amountMl);
      toast.success(t('wellness.dashboard.success.waterUpdated', { amount: amountMl }));
    } catch (err: any) {
      toast.error(err?.message || t('common.error'));
    }
  };

  /** Handle mood submission */
  const handleMoodSubmit = async (moodId: string) => {
    try {
      await planner.askMoodCoach({
        mood: moodId,
        energy: 'normal',
        hunger: 'normal',
        thirst: 'normal',
      });
      toast.success(t('planner.toast.moodSubmitted'));
    } catch {
      // silent — the card handles UI state
    }
  };

  // Loading state handling injected directly into the layout shell below
  // to avoid white-screen blocking.

  // Onboarding flow (only blocks if we KNOW we need onboarding and loading is done)
  // Or if user manually interacts with the HeroCard to start onboarding
  if (!planner.isLoading && (planner.needsOnboarding || forceOnboarding)) {
    return (
      <div className="mx-auto max-w-2xl py-8 px-4">
        <div className="mb-8 text-center">
          <h1 className="text-3xl font-bold text-slate-900 dark:text-white">
            {onboardingType === 'wellness' ? t('planner.onboarding.wellnessTitle', { defaultValue: 'Thiết lập Lộ trình Cá nhân hóa' }) : t('planner.onboarding.title')}
          </h1>
          <p className="mt-2 text-slate-500 dark:text-slate-400">
            {onboardingType === 'wellness' ? t('planner.onboarding.wellnessSubtitle', { defaultValue: 'Chọn gói nhịn ăn phù hợp để bắt đầu hành trình' }) : t('planner.onboarding.subtitle')}
          </p>
        </div>
        
        {onboardingType === 'wellness' ? (
          <WellnessOnboardingWizard 
            onComplete={handleOnboardingComplete} 
            isSubmitting={isSubmitting} 
            isPaidFeature={planner.checkoutConfig?.isPersonalizedRoadmapPaid} 
            isUnlocked={planner.wellnessAccess?.isUnlocked}
            packages={wellnessPackagesForOnboarding}
          />
        ) : (
          <OnboardingWizard onComplete={handleOnboardingComplete} isSubmitting={isSubmitting} />
        )}

        <div className="mt-8 flex justify-center gap-4">
           <button 
             onClick={() => setOnboardingType(onboardingType === 'wellness' ? 'study' : 'wellness')}
             className="text-xs font-bold uppercase tracking-widest text-slate-400 hover:text-slate-600 dark:hover:text-slate-200 transition-colors"
           >
              {onboardingType === 'wellness' ? 'Chuyển sang lộ trình học tập' : 'Chuyển sang lộ trình sức khỏe'}
           </button>
        </div>
        {forceOnboarding && (
          <div className="mt-6 text-center">
             <button onClick={() => setForceOnboarding(false)} className="text-sm font-semibold text-slate-500 hover:text-slate-800 transition-colors dark:text-slate-400 dark:hover:text-white">
                Hủy tạo lộ trình, quay lại Dashboard
             </button>
          </div>
        )}
      </div>
    );
  }

  // Main daily planner view
  const isWellnessUnlocked = planner.wellnessAccess?.isUnlocked;

  return (
    <div className="mx-auto max-w-[1500px] px-4 py-6">
      <div className="grid gap-6 lg:grid-cols-[260px_minmax(0,1fr)_320px]">
        {/* Left Sidebar — Navigation & Checkout */}
        <PlannerSidebarLeft />

        {/* Main content — scrollable */}
        <div className="space-y-5 relative min-h-[50vh]">
          {/* Internal Loading Overlay so layout doesn't bounce */}
          {planner.isLoading && (
            <div className="absolute inset-0 z-50 flex items-center justify-center bg-slate-50/80 dark:bg-slate-900/80 backdrop-blur-sm rounded-3xl">
              <div className="text-center">
                <div className="mb-4 inline-block">
                  <div className="h-10 w-10 animate-spin rounded-full border-4 border-emerald-500 border-t-transparent shadow-emerald-500/30" />
                </div>
                <p className="text-sm font-bold uppercase tracking-widest text-emerald-700 dark:text-emerald-400">Loading...</p>
              </div>
            </div>
          )}

          {/* Calendar strip */}
          <PlannerCalendarStrip
            selectedDate={planner.selectedDate}
            onSelectDate={planner.selectDate}
          />

          {/* Hero card */}
          <PlannerHeroCard
            tasks={planner.todayTasks}
            streakDays={planner.stats.streakDays}
            guidanceMessage={planner.guidanceMessage}
            hasStudyPlan={!!planner.studyPlan}
            onStartOnboarding={() => setForceOnboarding(true)}
          />

          {/* Study tasks */}
          {!planner.wellnessPlan && planner.todayTasks.length > 0 && (
            <PlannerStudyCard
              tasks={planner.todayTasks}
              onStartLearning={handleStartLearning}
              onCompleteTask={handleCompleteTask}
              isSubmitting={isSubmitting}
            />
          )}

          {/* Wellness Tasks */}
          {planner.wellnessTasks.length > 0 && (
            <PlannerWellnessTaskCard
              tasks={planner.wellnessTasks}
              onStartLearning={handleStartWellnessLearning}
              onCompleteTask={(taskId) => planner.submitWellnessTask(taskId)}
              isSubmitting={isSubmitting}
            />
          )}

          {/* Wellness Access handling */}
          {!isWellnessUnlocked ? (
            <div className="rounded-3xl border border-slate-200 bg-white p-8 text-center shadow-sm dark:border-slate-700/60 dark:bg-slate-800">
              <span className="material-symbols-outlined text-4xl text-slate-300 dark:text-slate-600 mb-3">lock</span>
              <h3 className="text-xl font-bold text-slate-900 dark:text-white mb-2">{t('wellness.dashboard.locked.title', { defaultValue: 'Tính năng giới hạn' })}</h3>
              <p className="text-sm text-slate-500 dark:text-slate-400">
                {t('wellness.dashboard.locked.desc', { defaultValue: 'Hãy xem các gói nâng cấp ở thanh menu bên trái để kích hoạt trợ lý Wellness nhé.' })}
              </p>
            </div>
          ) : null}

          {planner.wellnessPlan && (
            <>
              {/* Fasting schedule */}
              <div id="wellness-progress">
                <PlannerFastingCard fastingStatus={planner.fastingStatus} />
              </div>

              {/* Water tracking */}
              <div id="wellness-log-form">
                <PlannerWaterCard
                  waterMl={planner.stats.waterMl}
                  goalMl={planner.stats.waterGoalMl}
                  onLogWater={handleLogWater}
                />
              </div>
            </>
          )}

          {/* Daily tips */}
          <PlannerDailyTipsCard guidanceMessage={planner.guidanceMessage} />

          {/* Daily status check-in */}
          {planner.wellnessPlan && (
            <PlannerDailyStatusCard
              onSubmitMood={handleMoodSubmit}
              isSubmitting={isSubmitting}
            />
          )}
        </div>

        {/* Right Sidebar — Stats & Utilities */}
        <div className="hidden lg:block space-y-5">
          <PlannerStatsSidebar stats={planner.stats} />
          {planner.wellnessPlan && <PlannerMealCard />}
        </div>
      </div>

      {/* Mobile stats — shown below content on small screens */}
      <div className="mt-6 lg:hidden space-y-5">
        <PlannerStatsSidebar stats={planner.stats} />
        {planner.wellnessPlan && <PlannerMealCard />}
      </div>
    </div>
  );
};

export default DailyPlannerView;
