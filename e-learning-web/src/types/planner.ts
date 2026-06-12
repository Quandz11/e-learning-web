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
  WellnessCheckoutPackage,
  WellnessDailyTask
} from '../services/wellnessApi';

// Re-export for convenience
export type { UserStudyPlan, DailyStudyTask, DailyStudyCheckIn };
export type { WellnessPlan, WellnessDailyLog, WellnessFastingStatus, WellnessCoachReply, WellnessMealSuggestion, WellnessCheckoutPackage, WellnessDailyTask };

/** Onboarding wizard step */
export type OnboardingStep = 1 | 2 | 3 | 4;

/** Onboarding wizard form data */
export interface OnboardingFormData {
  // Wellness (New Simplified)
  wellnessGoal?: 'weight_loss' | 'chronic_disease';
  fastingDuration?: '24h' | '36h' | '72h' | '5d' | '10d' | '21d';
  fastingStartDate?: string;
  wellnessPackageCode?: string;

  // Study (Legacy/Optional)
  goal?: string;
  currentKnowledge?: string;
  motivation?: string;
  timeBudgetMinutesPerDay?: number;
  preferredStudyTime?: 'morning' | 'afternoon' | 'evening' | 'flexible';
  primaryCourseId?: string;
  constraints?: string;
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
  wellnessTasks: WellnessDailyTask[];

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
  { id: 'hungry', emoji: '😋', labelKey: 'planner.moods.hungry' },
  { id: 'thirsty', emoji: '💧', labelKey: 'planner.moods.thirsty' },
  { id: 'emergency', emoji: '⚠️', labelKey: 'planner.moods.emergency' },
  { id: 'irritated', emoji: '😤', labelKey: 'planner.moods.irritated' },
  { id: 'cravings', emoji: '🍫', labelKey: 'planner.moods.cravings' },
  { id: 'stomachDiscomfort', emoji: '😬', labelKey: 'planner.moods.stomachDiscomfort' },
  { id: 'insomnia', emoji: '😫', labelKey: 'planner.moods.insomnia' },
  { id: 'fine', emoji: '✨', labelKey: 'planner.moods.fine' },
];


/** Study time presets for onboarding */
export const STUDY_TIME_PRESETS = [
  { value: 'morning' as const, labelKey: 'planner.onboarding.timeMorning', icon: '🌅' },
  { value: 'afternoon' as const, labelKey: 'planner.onboarding.timeAfternoon', icon: '☀️' },
  { value: 'evening' as const, labelKey: 'planner.onboarding.timeEvening', icon: '🌙' },
  { value: 'flexible' as const, labelKey: 'planner.onboarding.timeFlexible', icon: '🔄' },
];

/** Wellness goal presets */
export const WELLNESS_GOAL_PRESETS = [
  { 
    value: 'weight_loss' as const, 
    labelKey: 'planner.wellness.goals.weightLoss', 
    icon: '⚖️', 
    titleVi: 'Giảm cân',
    descVi: 'Tập trung vào việc giảm mỡ thừa và cải thiện vóc dáng.'
  },
  { 
    value: 'chronic_disease' as const, 
    labelKey: 'planner.wellness.goals.chronicDisease', 
    icon: '🏥', 
    titleVi: 'Cải thiện bệnh mãn tính',
    descVi: 'Hỗ trợ cải thiện các vấn đề sức khỏe lâu dài thông qua nhịn ăn.'
  },
];

/** Fasting duration presets */
export const FASTING_DURATION_PRESETS = [
  { value: '24h' as const, label: '24h', hours: 24, annotationVi: 'Giảm cân' },
  { value: '36h' as const, label: '36h', hours: 36, annotationVi: 'Giảm cân' },
  { value: '72h' as const, label: '72h', hours: 72, annotationVi: 'Cải thiện bệnh mãn tính' },
  { value: '5d' as const, label: '5 ngày', hours: 120, annotationVi: 'Cải thiện bệnh mãn tính' },
  { value: '10d' as const, label: '10 ngày', hours: 240, annotationVi: 'Cải thiện bệnh mãn tính' },
  { value: '21d' as const, label: '21 ngày', hours: 504, annotationVi: 'Cải thiện bệnh mãn tính' },
];
