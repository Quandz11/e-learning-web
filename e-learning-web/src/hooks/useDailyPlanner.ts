/**
 * useDailyPlanner — Custom hook merging AI study plan + Wellness dashboard data.
 * Provides unified state and action handlers for the daily planner view.
 */

import { useState, useCallback, useEffect, useMemo } from 'react';
import { aiWidgetApi } from '../services/aiWidgetApi';
import type { InitializeStudyPlanPayload, SubmitStudyTaskPayload, DailyStudyCheckInPayload } from '../services/aiWidgetApi';
import { wellnessApi } from '../services/wellnessApi';
import type { UpsertWellnessDailyLogPayload, WellnessCoachMoodPayload, WellnessCoachMealPayload, UpsertWellnessPlanPayload } from '../services/wellnessApi';
import type { DailyPlannerState, OnboardingFormData, PlannerStats } from '../types/planner';

const DEFAULT_WATER_GOAL = 1750;

const emptyStats: PlannerStats = {
  tasksCompleted: 0,
  tasksTotal: 0,
  waterMl: 0,
  waterGoalMl: DEFAULT_WATER_GOAL,
  streakDays: 0,
  currentPhase: '',
  fastingProgressPercent: 0,
};

export function useDailyPlanner() {
  const [state, setState] = useState<DailyPlannerState>({
    isLoading: true,
    error: null,
    studyPlan: null,
    todayTasks: [],
    latestCheckIn: null,
    guidanceMessage: '',
    wellnessPlan: null,
    todayLog: null,
    fastingStatus: null,
    mealSuggestion: null,
    coachReply: null,
    wellnessAccess: null,
    checkoutConfig: null,
    wellnessTasks: [],
    stats: emptyStats,
    hasAnyPlan: false,
    needsOnboarding: true,
    selectedDate: new Date(),
  });

  const computeStats = useCallback(
    (
      tasks: typeof state.todayTasks,
      wellnessTasks: typeof state.wellnessTasks,
      log: typeof state.todayLog,
      plan: typeof state.studyPlan,
      fasting: typeof state.fastingStatus
    ): PlannerStats => {
      const tasksCompleted = tasks.filter((t) => t.isCompleted).length + wellnessTasks.filter((t) => t.isCompleted).length;
      return {
        tasksCompleted,
        tasksTotal: tasks.length + wellnessTasks.length,
        waterMl: log?.waterMl ?? 0,
        waterGoalMl: DEFAULT_WATER_GOAL,
        streakDays: plan?.currentStreakDays ?? 0,
        currentPhase: fasting?.state ?? '',
        fastingProgressPercent: fasting?.progressPercent ?? 0,
      };
    },
    []
  );

  /** Bootstrap: load both AI + Wellness dashboards */
  const bootstrap = useCallback(async () => {
    setState((prev) => ({ ...prev, isLoading: true, error: null }));

    try {
      // Parallel fetch of both dashboards
      const [aiDashboard, wellnessDashboard] = await Promise.allSettled([
        aiWidgetApi.getDashboard(),
        wellnessApi.getDashboard(),
      ]);

      const aiData = aiDashboard.status === 'fulfilled' ? aiDashboard.value : null;
      const wellnessData = wellnessDashboard.status === 'fulfilled' ? wellnessDashboard.value : null;

      const studyPlan = aiData?.plan ?? null;
      const todayTasks = aiData?.todayTasks ?? [];
      const latestCheckIn = aiData?.latestCheckIn ?? null;
      const guidanceMessage = aiData?.guidanceMessage ?? '';

      const wellnessPlan = wellnessData?.plan ?? null;
      const todayLog = wellnessData?.todayLog ?? null;
      const fastingStatus = wellnessData?.fastingStatus ?? null;
      const wellnessAccess = wellnessData?.access ?? null;
      const checkoutConfig = wellnessData?.checkoutConfig ?? null;
      const wellnessTasks = wellnessData?.todayTasks ?? [];

      const hasAnyPlan = !!studyPlan || !!wellnessPlan;
      // Nếu chưa có bất kỳ kế hoạch nào, luôn yêu cầu onboarding
      const needsOnboarding = !hasAnyPlan;

      const stats = computeStats(todayTasks, wellnessTasks, todayLog, studyPlan, fastingStatus);

      setState((prev) => ({
        ...prev,
        isLoading: false,
        studyPlan,
        todayTasks,
        latestCheckIn,
        guidanceMessage,
        wellnessPlan,
        todayLog,
        fastingStatus,
        wellnessAccess,
        checkoutConfig,
        wellnessTasks,
        stats,
        hasAnyPlan,
        needsOnboarding,
      }));
    } catch (err: any) {
      setState((prev) => ({
        ...prev,
        isLoading: false,
        error: err?.message || 'Failed to load planner data',
      }));
    }
  }, [computeStats]);

  /** Initialize study plan (onboarding) */
  const initStudyPlan = useCallback(
    async (data: OnboardingFormData) => {
      // If it's a wellness-only setup (has wellness fields but no goal)
      if (data.wellnessGoal && !data.goal) {
        return await initWellnessPlan(data);
      }

      const payload: InitializeStudyPlanPayload = {
        goal: data.goal ?? '',
        currentKnowledge: data.currentKnowledge ?? '',
        motivation: data.motivation ?? '',
        timeBudgetMinutesPerDay: data.timeBudgetMinutesPerDay ?? 30,
        preferredStudyTime: data.preferredStudyTime ?? 'flexible',
        constraints: data.constraints ?? '',
        primaryCourseId: data.primaryCourseId,
      };

      const plan = await aiWidgetApi.initPlan(payload);
      // Reload everything after plan creation
      await bootstrap();
      return plan;
    },
    [bootstrap]
  );

  /** Initialize wellness plan (simplified onboarding) */
  const initWellnessPlan = useCallback(
    async (data: OnboardingFormData) => {
      // Find duration hours
      const fastingHours = data.fastingDuration === '24h' ? 24
        : data.fastingDuration === '36h' ? 36
          : data.fastingDuration === '72h' ? 72
            : data.fastingDuration === '5d' ? 120
              : data.fastingDuration === '10d' ? 240
                : data.fastingDuration === '21d' ? 504 : 24;

      // Resolve package code
      let packageType = data.wellnessPackageCode || '';

      if (!packageType) {
        const currentOwnedPackage = (state.wellnessAccess?.currentPackage || '').trim().toUpperCase();
        if (currentOwnedPackage) {
          packageType = currentOwnedPackage;
        }
        // Fallback 1: Use first available package from config if in free mode
        else if (state.checkoutConfig?.packages && state.checkoutConfig.packages.length > 0) {
          packageType = state.checkoutConfig.packages[0].code;
        }
        // Fallback 2: Hardcoded defaults
        else {
          packageType = data.wellnessGoal === 'chronic_disease' ? 'PLAN_30_DAYS' : 'TRIAL_3_DAYS';
        }
      }

      const payload: UpsertWellnessPlanPayload = {
        packageType,
        startDate: data.fastingStartDate || new Date().toISOString().split('T')[0],
        fastingHours: fastingHours,

        eatingHours: fastingHours < 24 ? (24 - fastingHours)
          : fastingHours === 24 ? 1
            : 4,
        dailyFastStartMinuteOfDay: 1200,
        startWeightKg: 0,
        targetWeightKg: 0,
        timezone: Intl.DateTimeFormat().resolvedOptions().timeZone,
      };

      const plan = await wellnessApi.upsertPlan(payload);
      await bootstrap();
      return plan;
    },
    [bootstrap]
  );

  /** Save wellness plan (setup) */
  const saveWellnessPlan = useCallback(
    async (payload: UpsertWellnessPlanPayload) => {
      const plan = await wellnessApi.upsertPlan(payload);
      await bootstrap();
      return plan;
    },
    [bootstrap]
  );

  /** Submit a study task */
  const submitTask = useCallback(
    async (taskId: string, payload: SubmitStudyTaskPayload) => {
      const updatedTask = await aiWidgetApi.submitTask(taskId, payload);
      setState((prev) => {
        const updatedTasks = prev.todayTasks.map((t) => (t.id === taskId ? updatedTask : t));
        const stats = computeStats(updatedTasks, prev.wellnessTasks, prev.todayLog, prev.studyPlan, prev.fastingStatus);
        return { ...prev, todayTasks: updatedTasks, stats };
      });
      return updatedTask;
    },
    [computeStats]
  );

  /** Submit a wellness task */
  const submitWellnessTask = useCallback(
    async (taskId: string) => {
      if (!state.wellnessPlan?.id) return;
      const updatedTask = await wellnessApi.completeTask(state.wellnessPlan.id, taskId);
      setState((prev) => {
        const updatedTasks = prev.wellnessTasks.map((t) => (t.id === taskId ? updatedTask : t));
        const stats = computeStats(prev.todayTasks, updatedTasks, prev.todayLog, prev.studyPlan, prev.fastingStatus);
        return { ...prev, wellnessTasks: updatedTasks, stats };
      });
      return updatedTask;
    },
    [state.wellnessPlan?.id, computeStats]
  );

  /** Submit daily check-in */
  const submitCheckIn = useCallback(async (payload: DailyStudyCheckInPayload) => {
    const checkIn = await aiWidgetApi.submitCheckIn(payload);
    setState((prev) => ({ ...prev, latestCheckIn: checkIn }));
    return checkIn;
  }, []);

  /** Log water intake */
  const logWater = useCallback(
    async (amountMl: number) => {
      if (!state.wellnessPlan?.id) return;
      const currentWater = state.todayLog?.waterMl ?? 0;
      const newWater = currentWater + amountMl;

      // Extract local YYYY-MM-DD from selectedDate to correctly align with user's expected day
      const year = state.selectedDate.getFullYear();
      const month = String(state.selectedDate.getMonth() + 1).padStart(2, '0');
      const day = String(state.selectedDate.getDate()).padStart(2, '0');
      const formattedLogDate = `${year}-${month}-${day}`;

      const payload: UpsertWellnessDailyLogPayload = {
        logDate: formattedLogDate,
        waterMl: newWater,
        workoutMinutes: state.todayLog?.workoutMinutes ?? 0,
        workoutType: state.todayLog?.workoutType ?? '',
        notes: state.todayLog?.notes ?? '',
      };

      const updatedLog = await wellnessApi.upsertDailyLog(state.wellnessPlan.id, payload);
      setState((prev) => {
        const stats = computeStats(prev.todayTasks, prev.wellnessTasks, updatedLog, prev.studyPlan, prev.fastingStatus);
        return { ...prev, todayLog: updatedLog, stats };
      });
      return updatedLog;
    },
    [state.wellnessPlan?.id, state.todayLog, computeStats]
  );

  /** Ask mood coach */
  const askMoodCoach = useCallback(
    async (payload: WellnessCoachMoodPayload) => {
      if (!state.wellnessPlan?.id) return null;
      const reply = await wellnessApi.askMoodCoach(state.wellnessPlan.id, payload);
      setState((prev) => ({ ...prev, coachReply: reply }));
      return reply;
    },
    [state.wellnessPlan?.id]
  );

  /** Generate meal suggestion */
  const generateMeal = useCallback(
    async (payload: WellnessCoachMealPayload) => {
      if (!state.wellnessPlan?.id) return null;
      const meal = await wellnessApi.generateMeal(state.wellnessPlan.id, payload);
      setState((prev) => ({ ...prev, mealSuggestion: meal }));
      return meal;
    },
    [state.wellnessPlan?.id]
  );

  /** Select a different date (for calendar strip) */
  const selectDate = useCallback((date: Date) => {
    setState((prev) => ({ ...prev, selectedDate: date }));
  }, []);

  // Auto-bootstrap on mount
  useEffect(() => {
    void bootstrap();
  }, [bootstrap]);

  // Memoized return value
  return useMemo(
    () => ({
      ...state,
      // Actions
      bootstrap,
      initStudyPlan,
      saveWellnessPlan,
      submitTask,
      submitWellnessTask,
      submitCheckIn,
      logWater,
      askMoodCoach,
      generateMeal,
      selectDate,
      initWellnessPlan,
    }),
    [state, bootstrap, initStudyPlan, saveWellnessPlan, submitTask, submitWellnessTask, submitCheckIn, logWater, askMoodCoach, generateMeal, selectDate, initWellnessPlan]
  );
}
