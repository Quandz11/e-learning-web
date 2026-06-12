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
  preparationDays: number;
  fastingDays: number;
  refeedDays: number;
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
  phase: 'PREPARE' | 'FASTING' | 'REFEED' | string;
  phaseDayIndex: number;
  phaseTotalDays: number;
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
  isPersonalizedRoadmapPaid: boolean;
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

export interface WellnessDailyTask {
  id: string;
  taskDate: string;
  lessonId: string;
  courseId?: string;
  lessonTitle: string;
  description: string;
  isCompleted: boolean;
  completedAt?: string;
  sortOrder: number;
}

export interface WellnessDashboard {
  plan?: WellnessPlan;
  todayLog?: WellnessDailyLog;
  fastingStatus?: WellnessFastingStatus;
  todayResources?: WellnessResourceSet;
  todayInsight?: WellnessInsight;
  todayTasks?: WellnessDailyTask[];
  weightProgress?: WellnessWeightProgress;
  upgradeSuggestion?: WellnessUpgradeSuggestion;
  checkoutConfig?: WellnessCheckoutConfig;
  access?: WellnessAccessState;
}

export interface WellnessAdminSettings {
  id: string;
  packages: WellnessPackageAdmin[];
  ctaPath: string;
  isPersonalizedRoadmapPaid: boolean;
  updatedAt?: string;
}

export interface WellnessPackageLessonAdmin {
  id: string;
  lessonId: string;
  lessonTitle: string;
  dayIndex: number;
  sortOrder: number;
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
  lessons?: WellnessPackageLessonAdmin[];
}

export interface WellnessPackageLessonUpsertPayload {
  lessonId: string;
  dayIndex: number;
  sortOrder: number;
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
  lessons?: WellnessPackageLessonUpsertPayload[];
}

export interface UpdateWellnessAdminSettingsPayload {
  packages: WellnessPackageUpsertPayload[];
  ctaPath: string;
  isPersonalizedRoadmapPaid: boolean;
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

type CacheEntry<T> = {
  value: T;
  expiresAt: number;
};

const DASHBOARD_CACHE_TTL_MS = 30_000;
const CALENDAR_CACHE_TTL_MS = 30_000;
const TIMELINE_CACHE_TTL_MS = 30_000;

let dashboardCache: CacheEntry<WellnessDashboard> | null = null;
const calendarCache = new Map<string, CacheEntry<WellnessCalendarDay[]>>();
const timelineCache = new Map<string, CacheEntry<WellnessProgressTimeline>>();

const nowMs = () => Date.now();

const getFreshCache = <T>(entry?: CacheEntry<T> | null): T | null => {
  if (!entry) return null;
  if (entry.expiresAt <= nowMs()) return null;
  return entry.value;
};

const setCache = <T>(ttlMs: number, value: T): CacheEntry<T> => ({
  value,
  expiresAt: nowMs() + ttlMs,
});

const buildTimelineCacheKey = (planId: string, days: number, includeFuture: boolean) =>
  `${planId}:${days}:${includeFuture ? 'future' : 'history'}`;

const clearWellnessDashboardCache = (planId?: string) => {
  dashboardCache = null;

  if (!planId) {
    calendarCache.clear();
    timelineCache.clear();
    return;
  }

  calendarCache.delete(planId);
  for (const key of timelineCache.keys()) {
    if (key.startsWith(`${planId}:`)) {
      timelineCache.delete(key);
    }
  }
};

export const wellnessApi = {
  getCheckoutConfig: async (): Promise<WellnessCheckoutConfig> => {
    return await apiClient<WellnessCheckoutConfig>('/wellness/checkout-config', { method: 'GET' });
  },

  getDashboard: async (): Promise<WellnessDashboard> => {
    const cached = getFreshCache(dashboardCache);
    if (cached) {
      return cached;
    }

    const response = await apiClient<WellnessDashboard>('/wellness/dashboard', { method: 'GET' });
    dashboardCache = setCache(DASHBOARD_CACHE_TTL_MS, response);
    return response;
  },

  upsertPlan: async (payload: UpsertWellnessPlanPayload): Promise<WellnessPlan> => {
    const response = await apiClient<WellnessPlan>('/wellness/plan', {
      method: 'POST',
      body: JSON.stringify(payload),
    });
    clearWellnessDashboardCache(response.id);
    return response;
  },

  updateSchedule: async (planId: string, payload: UpdateWellnessSchedulePayload): Promise<WellnessPlan> => {
    const response = await apiClient<WellnessPlan>(`/wellness/plan/${planId}/schedule`, {
      method: 'PUT',
      body: JSON.stringify(payload),
    });
    clearWellnessDashboardCache(planId);
    return response;
  },

  upsertDailyLog: async (planId: string, payload: UpsertWellnessDailyLogPayload): Promise<WellnessDailyLog> => {
    const response = await apiClient<WellnessDailyLog>(`/wellness/plan/${planId}/daily-log`, {
      method: 'PUT',
      body: JSON.stringify(payload),
    });
    clearWellnessDashboardCache(planId);
    return response;
  },

  getCalendar: async (planId: string): Promise<WellnessCalendarDay[]> => {
    const cached = getFreshCache(calendarCache.get(planId));
    if (cached) {
      return cached;
    }

    const response = await apiClient<WellnessCalendarDay[]>(`/wellness/plan/${planId}/calendar`, { method: 'GET' });
    calendarCache.set(planId, setCache(CALENDAR_CACHE_TTL_MS, response));
    return response;
  },

  askMoodCoach: async (planId: string, payload: WellnessCoachMoodPayload): Promise<WellnessCoachReply> => {
    const response = await apiClient<WellnessCoachReply>(`/wellness/plan/${planId}/coach/mood`, {
      method: 'POST',
      body: JSON.stringify(payload),
    });
    clearWellnessDashboardCache(planId);
    return response;
  },

  generateMeal: async (planId: string, payload: WellnessCoachMealPayload): Promise<WellnessMealSuggestion> => {
    const response = await apiClient<WellnessMealSuggestion>(`/wellness/plan/${planId}/coach/meal`, {
      method: 'POST',
      body: JSON.stringify(payload),
    });
    clearWellnessDashboardCache(planId);
    return response;
  },

  getWeightProgress: async (planId: string): Promise<WellnessWeightProgress> => {
    return await apiClient<WellnessWeightProgress>(`/wellness/plan/${planId}/weight-progress`, { method: 'GET' });
  },

  getProgressTimeline: async (planId: string, days = 30, includeFuture = false): Promise<WellnessProgressTimeline> => {
    const cacheKey = buildTimelineCacheKey(planId, days, includeFuture);
    const cached = getFreshCache(timelineCache.get(cacheKey));
    if (cached) {
      return cached;
    }

    const params = new URLSearchParams();
    params.set('days', String(days));
    if (includeFuture) {
      params.set('includeFuture', 'true');
    }
    const response = await apiClient<WellnessProgressTimeline>(`/wellness/plan/${planId}/progress-timeline?${params.toString()}`, {
      method: 'GET',
    });
    timelineCache.set(cacheKey, setCache(TIMELINE_CACHE_TTL_MS, response));
    return response;
  },

  completeTask: async (planId: string, taskId: string): Promise<WellnessDailyTask> => {
    const response = await apiClient<WellnessDailyTask>(`/wellness/plan/${planId}/tasks/${taskId}/complete`, {
      method: 'PUT',
    });
    clearWellnessDashboardCache(planId);
    return response;
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
