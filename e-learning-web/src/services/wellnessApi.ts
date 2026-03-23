import { apiClient } from './apiClient';

export interface UpsertWellnessPlanPayload {
  packageType: string;
  startDate: string;
  endDate?: string;
  fastingHours: number;
  eatingHours: number;
  dailyFastStartMinuteOfDay: number;
  startWeightKg: number;
  targetWeightKg: number;
  timezone: string;
}

export interface UpdateWellnessSchedulePayload {
  startDate: string;
  endDate: string;
  fastingHours: number;
  eatingHours: number;
  dailyFastStartMinuteOfDay: number;
}

export interface UpsertWellnessDailyLogPayload {
  logDate: string;
  ateAtLocal?: string;
  waterMl: number;
  workoutMinutes: number;
  workoutType: string;
  currentWeightKg?: number;
  notes: string;
}

export interface WellnessCoachMoodPayload {
  mood: string;
  energy: string;
  hunger: string;
  thirst: string;
  stress?: string;
  sleepHours?: number;
  notes?: string;
}

export interface WellnessCoachMealPayload {
  ingredients: string[];
  servings: number;
  goal: string;
  dietaryPreference: string;
}

export interface WellnessPlan {
  id: string;
  packageType: string;
  startDate: string;
  endDate: string;
  fastingHours: number;
  eatingHours: number;
  dailyFastStartMinuteOfDay: number;
  timezone: string;
  startWeightKg: number;
  targetWeightKg: number;
  latestWeightKg?: number;
  status: string;
  totalDays: number;
  elapsedDays: number;
  createdAt: string;
}

export interface WellnessDailyLog {
  id: string;
  logDate: string;
  ateAtLocal?: string;
  waterMl: number;
  workoutMinutes: number;
  workoutType: string;
  currentWeightKg?: number;
  notes: string;
}

export interface WellnessFastingStatus {
  state: 'FASTING' | 'EATING';
  windowStartLocal: string;
  windowEndLocal: string;
  currentTimeLocal: string;
  progressPercent: number;
  remainingMinutes: number;
  label: string;
}

export interface WellnessResourceItem {
  id: string;
  resourceType: 'MEDITATION' | 'BREATHING' | 'WORKOUT' | string;
  title: string;
  url: string;
  description: string;
}

export interface WellnessResourceSet {
  meditation: WellnessResourceItem;
  breathing: WellnessResourceItem;
  workout: WellnessResourceItem;
  selectionStrategy: string;
}

export interface WellnessInsight {
  id: string;
  insightDate: string;
  summary: string;
  tip: string;
  risks: string;
  generatedBy: string;
}

export interface WellnessWeightProgress {
  startWeightKg: number;
  currentWeightKg: number;
  targetWeightKg: number;
  progressPercent: number;
}

export interface WellnessProgressTimelineItem {
  logDate: string;
  currentWeightKg?: number;
  waterMl: number;
  workoutMinutes: number;
  workoutType: string;
  hasCheckin: boolean;
}

export interface WellnessProgressTimeline {
  fromDate: string;
  toDate: string;
  requestedDays: number;
  loggedDays: number;
  latestWeightKg?: number;
  averageWaterMl: number;
  totalWorkoutMinutes: number;
  items: WellnessProgressTimelineItem[];
}

export interface WellnessUpgradeSuggestion {
  level: 'NONE' | 'LOW' | 'MEDIUM' | 'HIGH' | string;
  title: string;
  message: string;
  suggestedPackage: string;
  ctaPath: string;
}

export interface WellnessCheckoutPackage {
  code: string;
  name: string;
  description: string;
  priceVnd: number;
  durationDays: number;
  isFeatured: boolean;
  sortOrder: number;
}

export interface WellnessCheckoutConfig {
  packages: WellnessCheckoutPackage[];
  ctaPath: string;
}

export interface WellnessAccessState {
  isUnlocked: boolean;
  currentPackage?: string;
  allowedPackages: string[];
  requiredPackages: string[];
  ctaPath: string;
  reasonCode: string;
  message: string;
}

export interface WellnessCalendarDay {
  date: string;
  isToday: boolean;
  isInPlanRange: boolean;
  hasLog: boolean;
}

export interface WellnessDashboard {
  plan?: WellnessPlan;
  todayLog?: WellnessDailyLog;
  fastingStatus?: WellnessFastingStatus;
  todayResources?: WellnessResourceSet;
  todayInsight?: WellnessInsight;
  weightProgress?: WellnessWeightProgress;
  upgradeSuggestion?: WellnessUpgradeSuggestion;
  checkoutConfig?: WellnessCheckoutConfig;
  access?: WellnessAccessState;
}

export interface WellnessAdminSettings {
  id: string;
  packages: WellnessPackageAdmin[];
  ctaPath: string;
  updatedAt?: string;
}

export interface WellnessPackageAdmin {
  id: string;
  code: string;
  name: string;
  description: string;
  priceVnd: number;
  durationDays: number;
  isActive: boolean;
  isFeatured: boolean;
  sortOrder: number;
  updatedAt?: string;
}

export interface WellnessPackageUpsertPayload {
  code: string;
  name: string;
  description: string;
  priceVnd: number;
  durationDays: number;
  isActive: boolean;
  isFeatured: boolean;
  sortOrder: number;
}

export interface UpdateWellnessAdminSettingsPayload {
  packages: WellnessPackageUpsertPayload[];
  ctaPath: string;
}

export interface WellnessUserPackage {
  id: string;
  userId: string;
  packageId: string;
  packageCode: string;
  packageName: string;
  priceVnd: number;
  durationDays: number;
  status: string;
  source: string;
  grantedByUserId?: string;
  notes: string;
  grantedAt: string;
  startsAt: string;
  expiresAt?: string;
}

export interface GrantWellnessUserPackagePayload {
  packageCode: string;
  startsAt?: string;
  expiresAt?: string;
  source?: string;
  notes?: string;
}

export interface UpdateWellnessUserPackagePayload {
  status: string;
  expiresAt?: string;
  notes?: string;
}

export interface WellnessCoachReply {
  reply: string;
  createdAt: string;
}

export interface WellnessMealSuggestion {
  ingredients: string;
  servings: number;
  menu: string;
  nutritionNotes: string;
  createdAt: string;
}

export const wellnessApi = {
  getCheckoutConfig: async (): Promise<WellnessCheckoutConfig> => {
    return await apiClient<WellnessCheckoutConfig>('/wellness/checkout-config', { method: 'GET' });
  },

  getDashboard: async (): Promise<WellnessDashboard> => {
    return await apiClient<WellnessDashboard>('/wellness/dashboard', { method: 'GET' });
  },

  upsertPlan: async (payload: UpsertWellnessPlanPayload): Promise<WellnessPlan> => {
    return await apiClient<WellnessPlan>('/wellness/plan', {
      method: 'POST',
      body: JSON.stringify(payload),
    });
  },

  updateSchedule: async (planId: string, payload: UpdateWellnessSchedulePayload): Promise<WellnessPlan> => {
    return await apiClient<WellnessPlan>(`/wellness/plan/${planId}/schedule`, {
      method: 'PUT',
      body: JSON.stringify(payload),
    });
  },

  upsertDailyLog: async (planId: string, payload: UpsertWellnessDailyLogPayload): Promise<WellnessDailyLog> => {
    return await apiClient<WellnessDailyLog>(`/wellness/plan/${planId}/daily-log`, {
      method: 'PUT',
      body: JSON.stringify(payload),
    });
  },

  getCalendar: async (planId: string): Promise<WellnessCalendarDay[]> => {
    return await apiClient<WellnessCalendarDay[]>(`/wellness/plan/${planId}/calendar`, { method: 'GET' });
  },

  askMoodCoach: async (planId: string, payload: WellnessCoachMoodPayload): Promise<WellnessCoachReply> => {
    return await apiClient<WellnessCoachReply>(`/wellness/plan/${planId}/coach/mood`, {
      method: 'POST',
      body: JSON.stringify(payload),
    });
  },

  generateMeal: async (planId: string, payload: WellnessCoachMealPayload): Promise<WellnessMealSuggestion> => {
    return await apiClient<WellnessMealSuggestion>(`/wellness/plan/${planId}/coach/meal`, {
      method: 'POST',
      body: JSON.stringify(payload),
    });
  },

  getWeightProgress: async (planId: string): Promise<WellnessWeightProgress> => {
    return await apiClient<WellnessWeightProgress>(`/wellness/plan/${planId}/weight-progress`, { method: 'GET' });
  },

  getProgressTimeline: async (planId: string, days = 30): Promise<WellnessProgressTimeline> => {
    return await apiClient<WellnessProgressTimeline>(`/wellness/plan/${planId}/progress-timeline?days=${days}`, {
      method: 'GET',
    });
  },

  getAdminSettings: async (): Promise<WellnessAdminSettings> => {
    return await apiClient<WellnessAdminSettings>('/admin/wellness-settings', { method: 'GET' });
  },

  updateAdminSettings: async (payload: UpdateWellnessAdminSettingsPayload): Promise<WellnessAdminSettings> => {
    return await apiClient<WellnessAdminSettings>('/admin/wellness-settings', {
      method: 'PUT',
      body: JSON.stringify(payload),
    });
  },

  getUserPackages: async (userId: string): Promise<WellnessUserPackage[]> => {
    return await apiClient<WellnessUserPackage[]>(`/admin/users/${userId}/wellness-packages`, { method: 'GET' });
  },

  grantUserPackage: async (userId: string, payload: GrantWellnessUserPackagePayload): Promise<WellnessUserPackage> => {
    return await apiClient<WellnessUserPackage>(`/admin/users/${userId}/wellness-packages`, {
      method: 'POST',
      body: JSON.stringify(payload),
    });
  },

  updateUserPackage: async (
    userId: string,
    userPackageId: string,
    payload: UpdateWellnessUserPackagePayload,
  ): Promise<WellnessUserPackage> => {
    return await apiClient<WellnessUserPackage>(`/admin/users/${userId}/wellness-packages/${userPackageId}`, {
      method: 'PATCH',
      body: JSON.stringify(payload),
    });
  },
};
