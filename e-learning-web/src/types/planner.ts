/**
 * Unified planner types merging AI Study + Wellness data models.
 * Used by useDailyPlanner hook and all planner UI components.
 */

import type { UserStudyPlan, DailyStudyTask, DailyStudyCheckIn } from '../services/aiWidgetApi';
import type {
  WellnessPlan,
  WellnessDailyLog,
  WellnessFastingStatus,
  WellnessCoachReply,
  WellnessMealSuggestion,
  WellnessDashboard,
  WellnessCheckoutPackage
} from '../services/wellnessApi';

// Re-export for convenience
export type { UserStudyPlan, DailyStudyTask, DailyStudyCheckIn };
export type { WellnessPlan, WellnessDailyLog, WellnessFastingStatus, WellnessCoachReply, WellnessMealSuggestion, WellnessCheckoutPackage };

/** Onboarding wizard step */
export type OnboardingStep = 1 | 2 | 3 | 4;

/** Onboarding wizard form data */
export interface OnboardingFormData {
  goal: string;
  currentKnowledge: string;
  motivation: string;
  timeBudgetMinutesPerDay: number;
  preferredStudyTime: 'morning' | 'afternoon' | 'evening' | 'flexible';
  primaryCourseId?: string;
  constraints: string;
}

/** Mood option for daily status check-in */
export interface MoodOption {
  id: string;
  emoji: string;
  labelKey: string; // i18n key
}

/** Stats displayed in the sidebar */
export interface PlannerStats {
  tasksCompleted: number;
  tasksTotal: number;
  waterMl: number;
  waterGoalMl: number;
  streakDays: number;
  currentPhase: string;
  fastingProgressPercent: number;
}

/** Combined planner state from both AI + Wellness dashboards */
export interface DailyPlannerState {
  // Loading & errors
  isLoading: boolean;
  error: string | null;

  // AI Study data
  studyPlan: UserStudyPlan | null;
  todayTasks: DailyStudyTask[];
  latestCheckIn: DailyStudyCheckIn | null;
  guidanceMessage: string;

  // Wellness data
  wellnessPlan: WellnessPlan | null;
  todayLog: WellnessDailyLog | null;
  fastingStatus: WellnessFastingStatus | null;
  mealSuggestion: WellnessMealSuggestion | null;
  coachReply: WellnessCoachReply | null;
  wellnessAccess: WellnessDashboard['access'] | null;
  checkoutConfig: WellnessDashboard['checkoutConfig'] | null;

  // Computed
  stats: PlannerStats;
  hasAnyPlan: boolean;
  needsOnboarding: boolean;

  // Selected date
  selectedDate: Date;
}

/** Calendar day used by PlannerCalendarStrip */
export interface CalendarDay {
  date: Date;
  dayOfWeek: string;
  dayOfMonth: number;
  isToday: boolean;
  isSelected: boolean;
  hasActivity: boolean;
}

/** Predefined mood options for DailyStatusCard */
export const MOOD_OPTIONS: MoodOption[] = [
  { id: 'thirsty', emoji: '💧', labelKey: 'planner.moods.thirsty' },
  { id: 'hungry', emoji: '😋', labelKey: 'planner.moods.hungry' },
  { id: 'stomach', emoji: '😬', labelKey: 'planner.moods.stomachWeird' },
  { id: 'noProgress', emoji: '😤', labelKey: 'planner.moods.noProgress' },
  { id: 'tired', emoji: '😴', labelKey: 'planner.moods.tired' },
  { id: 'motivated', emoji: '💪', labelKey: 'planner.moods.motivated' },
  { id: 'cravings', emoji: '🍫', labelKey: 'planner.moods.cravings' },
  { id: 'sleepTrouble', emoji: '😫', labelKey: 'planner.moods.sleepTrouble' },
  { id: 'great', emoji: '✨', labelKey: 'planner.moods.great' },
];

/** Study time presets for onboarding */
export const STUDY_TIME_PRESETS = [
  { value: 'morning' as const, labelKey: 'planner.onboarding.timeMorning', icon: '🌅' },
  { value: 'afternoon' as const, labelKey: 'planner.onboarding.timeAfternoon', icon: '☀️' },
  { value: 'evening' as const, labelKey: 'planner.onboarding.timeEvening', icon: '🌙' },
  { value: 'flexible' as const, labelKey: 'planner.onboarding.timeFlexible', icon: '🔄' },
];
