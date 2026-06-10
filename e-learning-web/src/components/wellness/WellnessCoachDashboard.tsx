import React, { useEffect, useMemo, useState } from 'react';
import { toast } from 'react-hot-toast';
import { useTranslation } from 'react-i18next';
import { useSelector } from 'react-redux';
import { Link, useNavigate } from 'react-router-dom';
import type { RootState } from '../../store/store';
import { extractErrorMessage } from '../../utils/errorHandler';
import {
  wellnessApi,
  type WellnessCalendarDay,
  type WellnessCheckoutPackage,
  type WellnessDashboard,
  type WellnessMealSuggestion,
  type WellnessProgressTimeline,
} from '../../services/wellnessApi';

const TIMELINE_WINDOWS = [14, 30, 60];
const DEFAULT_WATER_GOAL = 2000;
const today = new Date().toISOString().slice(0, 10);

const toDate = (value?: string) => (value ? value.slice(0, 10) : '');
const toDateTime = (value?: string) => (value ? value.slice(0, 16) : '');
const toIso = (value: string | Date) => new Date(value).toISOString().slice(0, 10);
const normalizePackageCode = (value?: string | null) => (value ?? '').trim().toUpperCase();
const toPackageLabel = (code: string) => normalizePackageCode(code).replace(/_/g, ' ');
const clampPercent = (value: number) => Math.max(0, Math.min(100, Number.isFinite(value) ? value : 0));
const msg = (error: unknown, fallback: string) => extractErrorMessage(error) || fallback;
const addDays = (date: Date, n: number) => {
  const x = new Date(date);
  x.setDate(x.getDate() + n);
  return x;
};
const startOfWeek = (date: Date) => {
  const x = new Date(date);
  const day = x.getDay();
  x.setDate(x.getDate() + (day === 0 ? -6 : 1 - day));
  x.setHours(0, 0, 0, 0);
  return x;
};
const timeToMinute = (value: string) => {
  const [h, m] = value.split(':').map(Number);
  if (Number.isNaN(h) || Number.isNaN(m)) return 20 * 60;
  return Math.max(0, Math.min(1439, h * 60 + m));
};
const minuteToTime = (value: number) => `${String(Math.floor(value / 60)).padStart(2, '0')}:${String(value % 60).padStart(2, '0')}`;
type WellnessPhase = 'PREPARE' | 'FASTING' | 'REFEED';
type QuickStatus = 'good' | 'hungry' | 'tired' | 'thirsty' | 'busy';

const resolvePhase = (phase?: string): WellnessPhase => {
  const normalized = (phase ?? '').trim().toUpperCase();
  if (normalized === 'FASTING') return 'FASTING';
  if (normalized === 'REFEED') return 'REFEED';
  return 'PREPARE';
};

const clampRatio = (value: number) => Math.max(0, Math.min(1, value));

const getRefeedColor = (phaseDayIndex: number, phaseTotalDays: number) => {
  if (phaseTotalDays <= 1) return 'hsl(28 92% 44%)';
  const ratio = clampRatio((phaseDayIndex - 1) / (phaseTotalDays - 1));
  const lightness = 42 + ratio * 33;
  return `hsl(28 92% ${lightness}%)`;
};

const getPhaseColor = (phase?: string, phaseDayIndex = 1, phaseTotalDays = 1) => {
  const resolvedPhase = resolvePhase(phase);
  if (resolvedPhase === 'FASTING') return '#EF4444';
  if (resolvedPhase === 'REFEED') return getRefeedColor(phaseDayIndex, phaseTotalDays);
  return '#FACC15';
};

const getPhaseLabel = (phase: string | undefined, t: (key: string, options?: Record<string, unknown>) => string) => {
  const resolved = resolvePhase(phase);
  if (resolved === 'FASTING') return t('wellness.dashboard.timeline.phases.fastingLabel');
  if (resolved === 'REFEED') return t('wellness.dashboard.timeline.phases.refeedLabel');
  return t('wellness.dashboard.timeline.phases.prepareLabel');
};

const getPhaseProgressLabel = (
  phaseDayIndex: number,
  phaseTotalDays: number,
  t: (key: string, options?: Record<string, unknown>) => string,
) => {
  return t('wellness.dashboard.timeline.phases.dayProgress', {
    day: Math.max(1, phaseDayIndex),
    total: Math.max(1, phaseTotalDays),
  });
};

const inputLabelClassName = 'text-[11px] font-semibold uppercase tracking-[0.08em] text-slate-500';

const buildCheckoutPath = (packageCode: string) => {
  const params = new URLSearchParams();
  params.set('single', '1');
  params.set('source', 'wellness');
  params.set('wellnessPackage', normalizePackageCode(packageCode));
  return `/checkout?${params.toString()}`;
};

interface CheckoutOption {
  code: string;
  name: string;
  priceVnd?: number;
  durationDays?: number;
  isFeatured?: boolean;
}

const WellnessCoachDashboard: React.FC = () => {
  const navigate = useNavigate();
  const { user } = useSelector((state: RootState) => state.auth);
  const { t, i18n } = useTranslation();
  const locale = i18n.resolvedLanguage?.startsWith('vi') ? 'vi-VN' : 'en-US';

  const [loading, setLoading] = useState(true);
  const [submitting, setSubmitting] = useState(false);
  const [submittingAction, setSubmittingAction] = useState<'plan' | 'log' | null>(null);
  const [checkoutPackage, setCheckoutPackage] = useState<string | null>(null);
  const [dashboard, setDashboard] = useState<WellnessDashboard | null>(null);
  const [calendar, setCalendar] = useState<WellnessCalendarDay[]>([]);
  const [weekAnchor, setWeekAnchor] = useState(() => startOfWeek(new Date()));

  const [packageType, setPackageType] = useState('');
  const [startDate, setStartDate] = useState(today);
  const [endDate, setEndDate] = useState('');
  const [fastingHours, setFastingHours] = useState(16);
  const [eatingHours, setEatingHours] = useState(8);
  const [fastStart, setFastStart] = useState('20:00');
  const [startWeight, setStartWeight] = useState('70');
  const [targetWeight, setTargetWeight] = useState('65');
  const [timezone, setTimezone] = useState(Intl.DateTimeFormat().resolvedOptions().timeZone || 'Asia/Ho_Chi_Minh');

  const [logDate, setLogDate] = useState(today);
  const [ateAtLocal, setAteAtLocal] = useState('');
  const [waterMl, setWaterMl] = useState('0');
  const [waterGoalMl, setWaterGoalMl] = useState(String(DEFAULT_WATER_GOAL));
  const [workoutMinutes, setWorkoutMinutes] = useState('30');
  const [workoutType, setWorkoutType] = useState(() => t('wellness.dashboard.defaults.workoutType'));
  const [currentWeight, setCurrentWeight] = useState('');
  const [notes, setNotes] = useState('');
  const [selectedQuickStatus, setSelectedQuickStatus] = useState<QuickStatus | null>(null);

  const [timelineDays, setTimelineDays] = useState(30);
  const [timelineIncludeFuture, setTimelineIncludeFuture] = useState(false);
  const [timeline, setTimeline] = useState<WellnessProgressTimeline | null>(null);
  const [timelinePlanId, setTimelinePlanId] = useState<string | null>(null);
  const [timelineQueryKey, setTimelineQueryKey] = useState('');
  const [timelineLoading, setTimelineLoading] = useState(false);
  const [selectedTimelineDate, setSelectedTimelineDate] = useState(today);

  const [mealIngredients, setMealIngredients] = useState('');
  const [mealSuggestion, setMealSuggestion] = useState<WellnessMealSuggestion | null>(null);
  const [mealSubmitting, setMealSubmitting] = useState(false);

  const plan = dashboard?.plan;
  const access = dashboard?.access;
  const isUnlocked = Boolean(access?.isUnlocked);
  const canUse = Boolean(plan?.id && isUnlocked);

  const name = user?.fullName?.trim() || user?.email || t('wellness.dashboard.defaults.userName');
  const fastProgress = clampPercent(dashboard?.fastingStatus?.progressPercent ?? 0);
  const planProgress = plan ? clampPercent((plan.elapsedDays / Math.max(plan.totalDays, 1)) * 100) : 0;
  const waterDone = Math.max(0, Number(waterMl || 0));
  const waterGoal = Math.max(1, Number(waterGoalMl || DEFAULT_WATER_GOAL));
  const waterProgress = clampPercent((waterDone / waterGoal) * 100);

  const checkoutConfig = dashboard?.checkoutConfig;
  const checkoutCatalog = useMemo<WellnessCheckoutPackage[]>(() => {
    return (checkoutConfig?.packages ?? [])
      .map((pkg) => ({ ...pkg, code: normalizePackageCode(pkg.code) }))
      .filter((pkg) => Boolean(pkg.code))
      .sort((a, b) => a.sortOrder - b.sortOrder || a.durationDays - b.durationDays || a.code.localeCompare(b.code));
  }, [checkoutConfig?.packages]);

  const checkoutCatalogMap = useMemo(() => new Map(checkoutCatalog.map((pkg) => [pkg.code, pkg])), [checkoutCatalog]);
  const resolvePackageName = (code?: string | null) => {
    const normalizedCode = normalizePackageCode(code);
    if (!normalizedCode) return '';
    const fromCatalog = checkoutCatalogMap.get(normalizedCode)?.name?.trim();
    return fromCatalog || t(`wellness.dashboard.packages.${normalizedCode}`, { defaultValue: toPackageLabel(normalizedCode) });
  };

  const accessMessage = access?.message || t('wellness.dashboard.locked.subtitle');
  const requiredPackageLabels = (access?.requiredPackages ?? []).map(resolvePackageName).filter(Boolean).join(', ');
  const currentPackageLabel = access?.currentPackage ? resolvePackageName(access.currentPackage) : '';

  const checkoutPackages = useMemo<CheckoutOption[]>(() => {
    const catalog = checkoutCatalog.map((pkg) => ({
      code: pkg.code,
      name: pkg.name?.trim() || resolvePackageName(pkg.code),
      priceVnd: pkg.priceVnd,
      durationDays: pkg.durationDays,
      isFeatured: pkg.isFeatured,
    }));

    if (isUnlocked || !(access?.requiredPackages?.length)) return catalog;

    const required = Array.from(new Set((access?.requiredPackages ?? []).map(normalizePackageCode).filter(Boolean)));
    return required.map((code) => catalog.find((pkg) => pkg.code === code) || { code, name: resolvePackageName(code) });
  }, [access?.requiredPackages, checkoutCatalog, isUnlocked]);

  const recommendedLockedPackage = checkoutPackages.find((pkg) => pkg.isFeatured)?.code || checkoutPackages[0]?.code || '';

  const weekDays = useMemo(() => {
    const map = new Map<string, WellnessCalendarDay>();
    calendar.forEach((d) => map.set(toIso(d.date), d));
    return Array.from({ length: 7 }, (_, i) => {
      const date = addDays(weekAnchor, i);
      const iso = toIso(date);
      return { date, day: map.get(iso), iso };
    });
  }, [calendar, weekAnchor]);

  const timelineItems = timeline?.items ?? [];
  const timelineMap = useMemo(() => {
    const map = new Map<string, (typeof timelineItems)[number]>();
    timelineItems.forEach((item) => map.set(toDate(item.logDate), item));
    return map;
  }, [timelineItems]);
  const selectedTimelineItem = timelineMap.get(selectedTimelineDate) || timelineItems[timelineItems.length - 1] || null;
  const checkpointDone = timelineItems.filter((item) => item.hasCheckin).length;
  const completionRate = timelineItems.length > 0 ? Math.round((checkpointDone / timelineItems.length) * 100) : Math.round(planProgress);
  const phaseDistribution = useMemo(() => {
    const preparationDays = Math.max(0, Number(plan?.preparationDays ?? 0));
    const fastingDays = Math.max(0, Number(plan?.fastingDays ?? 0));
    const refeedDays = Math.max(0, Number(plan?.refeedDays ?? 0));
    return { preparationDays, fastingDays, refeedDays };
  }, [plan?.fastingDays, plan?.preparationDays, plan?.refeedDays]);
  const hasCheckin = Boolean(dashboard?.todayLog) || timelineItems.some((item) => item.hasCheckin);
  const flowSteps = useMemo(() => {
    return [
      {
        id: 'wellness-plan',
        icon: 'tune',
        title: t('wellness.dashboard.flow.plan.title'),
        hint: t('wellness.dashboard.flow.plan.hint'),
        done: Boolean(plan?.id),
      },
      {
        id: 'wellness-log',
        icon: 'edit_calendar',
        title: t('wellness.dashboard.flow.log.title'),
        hint: t('wellness.dashboard.flow.log.hint'),
        done: hasCheckin,
      },
      {
        id: 'wellness-timeline',
        icon: 'insights',
        title: t('wellness.dashboard.flow.timeline.title'),
        hint: t('wellness.dashboard.flow.timeline.hint'),
        done: timelineItems.length > 0,
      },
    ];
  }, [hasCheckin, plan?.id, t, timelineItems.length]);

  const quickStatusGuidance = useMemo(
    () => ({
      good: {
        icon: 'sentiment_satisfied',
        iconClassName: 'text-emerald-600',
      },
      hungry: {
        icon: 'restaurant',
        iconClassName: 'text-amber-600',
      },
      tired: {
        icon: 'bedtime',
        iconClassName: 'text-indigo-600',
      },
      thirsty: {
        icon: 'local_drink',
        iconClassName: 'text-cyan-600',
      },
      busy: {
        icon: 'work_history',
        iconClassName: 'text-slate-600',
      },
    }),
    [],
  );

  const goCheckout = (pkgCode: string) => {
    const toastId = toast.loading(t('wellness.dashboard.status.openingCheckout', { defaultValue: 'Opening checkout...' }));
    const normalized = normalizePackageCode(pkgCode);
    setPackageType(normalized);
    setCheckoutPackage(normalized);
    try {
      if (!normalized) {
        toast.error(t('wellness.dashboard.errors.checkoutNotConfigured'), { id: toastId });
        return;
      }
      toast.success(t('wellness.dashboard.status.redirectingCheckout', { defaultValue: 'Redirecting to checkout...' }), { id: toastId });
      navigate(buildCheckoutPath(normalized));
    } catch (error: unknown) {
      toast.error(msg(error, t('wellness.dashboard.errors.createCheckout')), { id: toastId });
    } finally {
      setCheckoutPackage(null);
    }
  };

  const loadTimeline = async (planId: string, days: number, includeFuture: boolean) => {
    setTimelineLoading(true);
    try {
      const data = await wellnessApi.getProgressTimeline(planId, days, includeFuture);
      setTimeline(data);
      setTimelinePlanId(planId);
      setTimelineQueryKey(`${planId}:${days}:${includeFuture ? 'future' : 'history'}`);
    } catch (error: unknown) {
      toast.error(msg(error, t('wellness.dashboard.errors.loadTimeline')));
      setTimeline(null);
      setTimelinePlanId(null);
      setTimelineQueryKey('');
    } finally {
      setTimelineLoading(false);
    }
  };

  const hydratePlan = (nextPlan: NonNullable<WellnessDashboard['plan']>) => {
    setPackageType(normalizePackageCode(nextPlan.packageType) || checkoutPackages[0]?.code || '');
    setStartDate(toDate(nextPlan.startDate));
    setEndDate(toDate(nextPlan.endDate));
    setFastingHours(nextPlan.fastingHours);
    setEatingHours(nextPlan.eatingHours);
    setFastStart(minuteToTime(nextPlan.dailyFastStartMinuteOfDay));
    setStartWeight(String(nextPlan.startWeightKg));
    setTargetWeight(String(nextPlan.targetWeightKg));
    setTimezone(nextPlan.timezone || timezone);
  };

  const load = async (silent = false) => {
    if (!silent) {
      setLoading(true);
    }
    try {
      const data = await wellnessApi.getDashboard();
      setDashboard(data);

      if (data.plan?.id && data.access?.isUnlocked) {
        const [cal, timelineData] = await Promise.all([
          wellnessApi.getCalendar(data.plan.id),
          wellnessApi.getProgressTimeline(data.plan.id, timelineDays, timelineIncludeFuture),
        ]);

        setCalendar(cal);
        setTimeline(timelineData);
        setTimelinePlanId(data.plan.id);
        setTimelineQueryKey(`${data.plan.id}:${timelineDays}:${timelineIncludeFuture ? 'future' : 'history'}`);
        hydratePlan(data.plan);

        const activeDate = data.todayLog ? toDate(data.todayLog.logDate) : today;
        setLogDate(activeDate);
        setSelectedTimelineDate(activeDate);
        setAteAtLocal(data.todayLog?.ateAtLocal ? toDateTime(data.todayLog.ateAtLocal) : '');
        setWaterMl(String(data.todayLog?.waterMl ?? 0));
        setWaterGoalMl(String(Math.max(DEFAULT_WATER_GOAL, data.todayLog?.waterMl ?? DEFAULT_WATER_GOAL)));
        setWorkoutMinutes(String(data.todayLog?.workoutMinutes ?? 30));
        setWorkoutType(data.todayLog?.workoutType || t('wellness.dashboard.defaults.workoutType'));
        setCurrentWeight(data.todayLog?.currentWeightKg ? String(data.todayLog.currentWeightKg) : '');
        setNotes(data.todayLog?.notes || '');

        const current = cal.find((x) => x.isToday)?.date;
        setWeekAnchor(startOfWeek(current ? new Date(current) : new Date()));
      } else {
        setCalendar([]);
        setTimeline(null);
        setTimelinePlanId(null);
        setTimelineQueryKey('');
        setSelectedTimelineDate(today);
        if (data.plan) hydratePlan(data.plan);
      }
    } catch (error: unknown) {
      toast.error(msg(error, t('wellness.dashboard.errors.loadDashboard')));
    } finally {
      if (!silent) {
        setLoading(false);
      }
    }
  };

  useEffect(() => {
    void load();
  }, []);

  useEffect(() => {
    if (!canUse || !plan?.id) return;
    const expectedKey = `${plan.id}:${timelineDays}:${timelineIncludeFuture ? 'future' : 'history'}`;
    if (timeline && timelinePlanId === plan.id && timelineQueryKey === expectedKey) return;
    void loadTimeline(plan.id, timelineDays, timelineIncludeFuture);
  }, [canUse, plan?.id, timeline, timelineDays, timelineIncludeFuture, timelinePlanId, timelineQueryKey]);

  useEffect(() => {
    if (!timelineItems.length) return;
    if (timelineMap.has(selectedTimelineDate)) return;
    const fallbackDate = toDate(timelineItems[timelineItems.length - 1].logDate);
    setSelectedTimelineDate(fallbackDate);
    setLogDate(fallbackDate);
  }, [selectedTimelineDate, timelineItems, timelineMap]);

  useEffect(() => {
    if (checkoutPackages.length === 0) return;
    if (!packageType || !checkoutPackages.some((pkg) => pkg.code === packageType)) {
      const current = normalizePackageCode(plan?.packageType) || normalizePackageCode(access?.currentPackage);
      setPackageType(checkoutPackages.find((pkg) => pkg.code === current)?.code || checkoutPackages[0].code);
    }
  }, [access?.currentPackage, checkoutPackages, packageType, plan?.packageType]);

  const scrollToId = (id: string) => {
    if (typeof document === 'undefined') return;
    document.getElementById(id)?.scrollIntoView({ behavior: 'smooth', block: 'start' });
  };

  const pickTimelineDate = (isoDate: string) => {
    setSelectedTimelineDate(isoDate);
    setLogDate(isoDate);
    const item = timelineMap.get(isoDate);
    if (!item) return;
    setWaterMl(String(item.waterMl ?? 0));
    setWorkoutMinutes(String(item.workoutMinutes ?? 0));
    setWorkoutType(item.workoutType || t('wellness.dashboard.defaults.workoutType'));
    setCurrentWeight(item.currentWeightKg ? String(item.currentWeightKg) : '');
  };

  const applyQuickStatus = (status: QuickStatus) => {
    setSelectedQuickStatus(status);
    setNotes(t(`wellness.dashboard.quickStatusNotes.${status}`));
    toast.success(t('wellness.dashboard.quick.applied', { defaultValue: 'Quick status updated.' }));
  };

  const bumpWater = (amount: number) => {
    setWaterMl((prev) => String(Math.max(0, Number(prev || 0) + amount)));
    toast.success(t('wellness.dashboard.success.waterUpdated', { amount }));
  };

  const savePlan = async (event: React.FormEvent) => {
    event.preventDefault();
    if (!isUnlocked) {
      toast.error(accessMessage || t('wellness.dashboard.errors.packageRequired'));
      return;
    }

    const normalizedPackageType = normalizePackageCode(packageType);
    if (!normalizedPackageType) {
      toast.error(t('wellness.dashboard.errors.packageRequired'));
      return;
    }

    setSubmittingAction('plan');
    setSubmitting(true);
    const toastId = toast.loading(t('wellness.dashboard.status.savingPlan', { defaultValue: 'Saving roadmap...' }));
    try {
      await wellnessApi.upsertPlan({
        packageType: normalizedPackageType,
        startDate: `${startDate}T00:00:00`,
        endDate: endDate ? `${endDate}T00:00:00` : undefined,
        fastingHours: Number(fastingHours),
        eatingHours: Number(eatingHours),
        dailyFastStartMinuteOfDay: timeToMinute(fastStart),
        startWeightKg: Number(startWeight),
        targetWeightKg: Number(targetWeight),
        timezone,
      });
      toast.success(t('wellness.dashboard.success.savePlan'), { id: toastId });
      await load(true);
    } catch (error: unknown) {
      toast.error(msg(error, t('wellness.dashboard.errors.savePlan')), { id: toastId });
    } finally {
      setSubmittingAction(null);
      setSubmitting(false);
    }
  };

  const saveLog = async (event: React.FormEvent) => {
    event.preventDefault();
    if (!canUse || !plan?.id) {
      toast.error(accessMessage || t('wellness.dashboard.errors.packageRequired'));
      return;
    }

    setSubmittingAction('log');
    setSubmitting(true);
    const toastId = toast.loading(t('wellness.dashboard.status.savingLog', { defaultValue: 'Saving daily log...' }));
    try {
      await wellnessApi.upsertDailyLog(plan.id, {
        logDate: `${logDate}T00:00:00`,
        ateAtLocal: ateAtLocal ? `${ateAtLocal}:00` : undefined,
        waterMl: Number(waterMl || 0),
        workoutMinutes: Number(workoutMinutes || 0),
        workoutType,
        currentWeightKg: currentWeight ? Number(currentWeight) : undefined,
        notes,
      });
      toast.success(t('wellness.dashboard.success.saveLog'), { id: toastId });
      await load(true);
    } catch (error: unknown) {
      toast.error(msg(error, t('wellness.dashboard.errors.saveLog')), { id: toastId });
    } finally {
      setSubmittingAction(null);
      setSubmitting(false);
    }
  };

  const generateMealSuggestion = async (event: React.FormEvent) => {
    event.preventDefault();
    if (!canUse || !plan?.id) {
      toast.error(accessMessage || t('wellness.dashboard.errors.packageRequired'));
      return;
    }

    const ingredients = mealIngredients.split(/[\n,]/).map((item) => item.trim()).filter(Boolean);
    if (ingredients.length === 0) {
      toast.error(t('wellness.dashboard.errors.mealIngredients'));
      return;
    }

    setMealSubmitting(true);
    const toastId = toast.loading(t('wellness.dashboard.status.generatingMeal', { defaultValue: 'Generating meal formula...' }));
    try {
      const response = await wellnessApi.generateMeal(plan.id, {
        ingredients,
        servings: 1,
        goal: 'LOW_CARB_STANDARD',
        dietaryPreference: 'LOW_CARB',
      });
      setMealSuggestion(response);
      toast.success(t('wellness.dashboard.success.mealReady'), { id: toastId });
    } catch (error: unknown) {
      toast.error(msg(error, t('wellness.dashboard.errors.mealCoach')), { id: toastId });
    } finally {
      setMealSubmitting(false);
    }
  };

  if (loading) {
    return (
      <div className="rounded-3xl border border-slate-200 bg-white p-8 text-sm text-slate-700 shadow-dashboard-subtle">
        <span className="material-symbols-outlined mr-2 align-middle text-base">hourglass_top</span>
        {t('wellness.dashboard.loading')}
      </div>
    );
  }

  return (
    <section className="grid gap-5 xl:grid-cols-[250px_minmax(0,1fr)_300px] [&_button]:cursor-pointer [&_button:disabled]:cursor-not-allowed">
      <aside className="space-y-4 rounded-3xl border border-slate-200 bg-white p-5 shadow-dashboard-subtle xl:sticky xl:top-24 xl:h-[calc(100vh-7rem)] xl:overflow-auto">
        <div className="rounded-2xl border border-slate-100 bg-[linear-gradient(155deg,#f8fafc_0%,#eef6ff_50%,#fff7ed_100%)] p-4">
          <div className="text-[11px] font-semibold uppercase tracking-[0.12em] text-slate-500">{t('wellness.dashboard.brand')}</div>
          <div className="mt-3 flex items-center gap-3">
            <div className="grid h-10 w-10 place-items-center rounded-full bg-primary text-xs font-bold text-white">{name.slice(0, 1).toUpperCase()}</div>
            <div>
              <div className="text-sm font-semibold text-slate-900">{name}</div>
              <Link to="/profile" className="inline-flex items-center gap-1 text-xs font-medium text-primary">
                <span className="material-symbols-outlined text-sm">person</span>
                {t('wellness.dashboard.viewProfile')}
              </Link>
            </div>
          </div>
        </div>

        <div className="grid gap-2">
          {flowSteps.map((step, index) => (
            <button
              key={step.id}
              type="button"
              onClick={() => scrollToId(step.id)}
              className={`inline-flex items-start gap-2 rounded-xl border px-3 py-2 text-left ${step.done ? 'border-emerald-200 bg-emerald-50' : 'border-slate-200 bg-slate-50'}`}
            >
              <span className={`grid h-6 w-6 shrink-0 place-items-center rounded-full text-[11px] font-black ${step.done ? 'bg-emerald-600 text-white' : 'bg-slate-200 text-slate-700'}`}>
                {step.done ? <span className="material-symbols-outlined text-sm leading-none">check</span> : index + 1}
              </span>
              <span className="min-w-0">
                <span className="block text-xs font-semibold text-slate-800">{step.title}</span>
                <span className="block text-[11px] text-slate-600">{step.hint}</span>
              </span>
            </button>
          ))}
        </div>

        <div className="rounded-2xl border border-primary/20 bg-primary/5 p-4">
          <div className="inline-flex items-center gap-2 text-sm font-bold text-primary-dark"><span className="material-symbols-outlined text-sm">workspace_premium</span>{t('wellness.dashboard.upgrade.title')}</div>
          <p className="mt-1 text-xs text-slate-700">{t('wellness.dashboard.upgrade.subtitle')}</p>
          <div className="mt-3 grid gap-2">
            {checkoutPackages.map((pkg) => (
              <button key={pkg.code} type="button" onClick={() => goCheckout(pkg.code)} disabled={checkoutPackage !== null} className={`rounded-xl px-3 py-2 text-xs font-semibold text-white ${pkg.code === recommendedLockedPackage ? 'bg-primary' : 'bg-slate-900'} disabled:opacity-60`}>
                {checkoutPackage === pkg.code ? t('wellness.dashboard.status.openingCheckout') : pkg.name}
              </button>
            ))}
          </div>
        </div>
      </aside>

      <main className="space-y-5">
        <div className="rounded-3xl border border-slate-200 bg-[linear-gradient(135deg,#fff7ed_0%,#ffffff_45%,#ecfeff_100%)] p-5 shadow-dashboard-subtle">
          <div className="flex flex-wrap items-center justify-between gap-3">
            <div>
              <div className="inline-flex items-center gap-2 rounded-full border border-primary/20 bg-white px-3 py-1 text-[11px] font-semibold uppercase tracking-[0.12em] text-primary"><span className="material-symbols-outlined text-sm">auto_awesome</span>{t('wellness.dashboard.header.title')}</div>
              <p className="mt-2 text-sm text-slate-700">{t('wellness.dashboard.header.subtitle')}</p>
            </div>
            <button type="button" onClick={() => scrollToId('wellness-meal')} className="inline-flex items-center gap-2 rounded-full border border-slate-300 bg-white px-4 py-2 text-xs font-semibold text-slate-700"><span className="material-symbols-outlined text-sm text-primary">restaurant_menu</span>{t('wellness.dashboard.meal.title')}</button>
          </div>
        </div>

        {isUnlocked ? (
          <>
            <div className="rounded-3xl border border-amber-200 bg-amber-50/60 p-5 shadow-dashboard-subtle">
              <div className="inline-flex items-center gap-2 text-sm font-semibold text-slate-800">
                <span className="material-symbols-outlined text-sm text-amber-600">route</span>
                {t('wellness.dashboard.flow.title')}
              </div>
              <p className="mt-1 text-xs text-slate-700">{t('wellness.dashboard.flow.subtitle')}</p>
              <div className="mt-3 grid gap-2 md:grid-cols-2">
                {flowSteps.map((step, index) => (
                  <button
                    key={step.id}
                    type="button"
                    onClick={() => scrollToId(step.id)}
                    className={`rounded-xl border px-3 py-3 text-left ${step.done ? 'border-emerald-200 bg-emerald-50' : 'border-amber-200 bg-white'}`}
                  >
                    <div className="inline-flex items-center gap-2 text-xs font-semibold text-slate-800">
                      <span className="grid h-6 w-6 place-items-center rounded-full bg-slate-900 text-[11px] font-black text-white">{index + 1}</span>
                      <span className="material-symbols-outlined text-sm text-primary">{step.icon}</span>
                      {step.title}
                    </div>
                    <div className="mt-1 text-[11px] text-slate-600">{step.hint}</div>
                  </button>
                ))}
              </div>
            </div>

            <div className="grid gap-5">
            <div id="wellness-progress" className="order-4 rounded-3xl border border-slate-200 bg-white p-5 shadow-dashboard-subtle">
              <div className="flex items-center justify-between">
                <div className="inline-flex items-center gap-2 text-sm font-semibold text-slate-700"><span className="material-symbols-outlined text-sm text-primary">calendar_month</span>{t('wellness.dashboard.calendar.title')}</div>
                <div className="flex gap-2">
                  <button type="button" onClick={() => setWeekAnchor((prev) => addDays(prev, -7))} aria-label={t('wellness.dashboard.calendar.previous')} className="grid h-9 w-9 place-items-center rounded-full border border-slate-300"><span className="material-symbols-outlined text-sm">chevron_left</span></button>
                  <button type="button" onClick={() => setWeekAnchor((prev) => addDays(prev, 7))} aria-label={t('wellness.dashboard.calendar.next')} className="grid h-9 w-9 place-items-center rounded-full border border-slate-300"><span className="material-symbols-outlined text-sm">chevron_right</span></button>
                </div>
              </div>
              <div className="mt-4 grid grid-cols-7 gap-2">
                {weekDays.map((item) => {
                  const active = item.iso === selectedTimelineDate;
                  const style = active ? 'border-primary bg-primary text-white' : item.day?.hasLog ? 'border-cyan-300 bg-cyan-50 text-cyan-700' : 'border-slate-200 bg-slate-50 text-slate-700';
                  return (
                    <button key={item.iso} type="button" onClick={() => pickTimelineDate(item.iso)} className={`rounded-xl border px-2 py-2 text-center ${style}`}>
                      <div className="text-[11px] font-semibold">{item.date.toLocaleDateString(locale, { weekday: 'short' })}</div>
                      <div className="mt-1 text-base font-black">{item.date.getDate()}</div>
                    </button>
                  );
                })}
              </div>
            </div>

            <div className="order-5 grid gap-5 lg:grid-cols-[1.2fr_0.8fr]">
              <div className="rounded-3xl border border-slate-200 bg-white p-5 shadow-dashboard-subtle">
                <div className="flex items-start justify-between gap-3">
                  <div>
                    <div className="text-sm font-semibold text-slate-700">{t('wellness.dashboard.sidebar.fasting')}</div>
                    <p className="mt-1 text-xs text-slate-600">{dashboard?.fastingStatus?.label}</p>
                  </div>
                  <div className="text-right">
                    <div className="text-2xl font-black text-slate-900">{Math.floor((dashboard?.fastingStatus?.remainingMinutes ?? 0) / 60)}h {(dashboard?.fastingStatus?.remainingMinutes ?? 0) % 60}m</div>
                    <button type="button" onClick={() => scrollToId('wellness-plan')} className="mt-2 inline-flex items-center gap-1 rounded-full border border-slate-300 px-3 py-1 text-[11px] font-semibold text-slate-700"><span className="material-symbols-outlined text-sm">schedule</span>{t('wellness.dashboard.form.fastStart')}</button>
                  </div>
                </div>
                <div className="mt-4 h-4 rounded-full bg-slate-100"><div className="h-4 rounded-full bg-gradient-to-r from-cyan-500 to-blue-500" style={{ width: `${fastProgress}%` }} /></div>
                <div className="mt-2 flex justify-between text-[11px] text-slate-600"><span>{fastStart}</span><span>{minuteToTime((timeToMinute(fastStart) + fastingHours * 60) % 1440)}</span></div>

                <div className="mt-4 flex flex-wrap gap-2">
                  <button type="button" onClick={() => applyQuickStatus('good')} className="inline-flex items-center gap-1 rounded-full border border-slate-300 bg-slate-50 px-3 py-2 text-xs font-semibold text-slate-700"><span className="material-symbols-outlined text-sm">sentiment_satisfied</span>{t('wellness.dashboard.quickStatus.good')}</button>
                  <button type="button" onClick={() => applyQuickStatus('hungry')} className="inline-flex items-center gap-1 rounded-full border border-slate-300 bg-slate-50 px-3 py-2 text-xs font-semibold text-slate-700"><span className="material-symbols-outlined text-sm">restaurant</span>{t('wellness.dashboard.quickStatus.hungry')}</button>
                  <button type="button" onClick={() => applyQuickStatus('tired')} className="inline-flex items-center gap-1 rounded-full border border-slate-300 bg-slate-50 px-3 py-2 text-xs font-semibold text-slate-700"><span className="material-symbols-outlined text-sm">bedtime</span>{t('wellness.dashboard.quickStatus.tired')}</button>
                  <button type="button" onClick={() => applyQuickStatus('thirsty')} className="inline-flex items-center gap-1 rounded-full border border-slate-300 bg-slate-50 px-3 py-2 text-xs font-semibold text-slate-700"><span className="material-symbols-outlined text-sm">local_drink</span>{t('wellness.dashboard.quickStatus.thirsty')}</button>
                  <button type="button" onClick={() => applyQuickStatus('busy')} className="inline-flex items-center gap-1 rounded-full border border-slate-300 bg-slate-50 px-3 py-2 text-xs font-semibold text-slate-700"><span className="material-symbols-outlined text-sm">work_history</span>{t('wellness.dashboard.quickStatus.busy')}</button>
                </div>
                {selectedQuickStatus && (
                  <div className="mt-4 rounded-2xl border border-slate-200 bg-slate-50/80 p-4">
                    <div className="inline-flex items-center gap-2 text-xs font-semibold uppercase tracking-[0.08em] text-slate-500">
                      <span className={`material-symbols-outlined text-base ${quickStatusGuidance[selectedQuickStatus].iconClassName}`}>{quickStatusGuidance[selectedQuickStatus].icon}</span>
                      {t('wellness.dashboard.quickGuidance.title')}
                    </div>
                    <div className="mt-2 text-sm font-semibold text-slate-900">{t(`wellness.dashboard.quickGuidance.${selectedQuickStatus}.headline`)}</div>
                    <div className="mt-1 text-xs text-slate-700">{t(`wellness.dashboard.quickGuidance.${selectedQuickStatus}.fix`)}</div>
                    <div className="mt-2 rounded-xl border border-emerald-200 bg-emerald-50 px-3 py-2 text-xs font-medium text-emerald-800">
                      {t(`wellness.dashboard.quickGuidance.${selectedQuickStatus}.encourage`)}
                    </div>
                  </div>
                )}
              </div>

              <div className="rounded-3xl border border-slate-200 bg-white p-5 shadow-dashboard-subtle">
                <div className="inline-flex items-center gap-2 text-sm font-semibold text-slate-700"><span className="material-symbols-outlined text-sm text-cyan-600">local_drink</span>{t('wellness.dashboard.sidebar.water')}</div>
                <div className="mt-2 text-lg font-black text-slate-900">{waterDone}/{waterGoal} ml</div>
                <div className="mt-3 h-3 rounded-full bg-slate-100"><div className="h-3 rounded-full bg-gradient-to-r from-cyan-500 to-sky-500" style={{ width: `${waterProgress}%` }} /></div>
                <div className="mt-3 grid grid-cols-2 gap-2">
                  <button type="button" onClick={() => bumpWater(250)} className="rounded-xl border border-slate-300 bg-slate-50 px-3 py-2 text-xs font-semibold text-slate-700">{t('wellness.dashboard.water.add250')}</button>
                  <button type="button" onClick={() => bumpWater(500)} className="rounded-xl border border-slate-300 bg-slate-50 px-3 py-2 text-xs font-semibold text-slate-700">{t('wellness.dashboard.water.add500')}</button>
                  <label className="flex flex-col gap-1">
                    <span className={inputLabelClassName}>{t('wellness.dashboard.log.water')}</span>
                    <input type="number" aria-label={t('wellness.dashboard.log.water')} value={waterMl} onChange={(event) => setWaterMl(event.target.value)} className="rounded-xl border border-slate-300 px-3 py-2 text-xs" />
                  </label>
                  <label className="flex flex-col gap-1">
                    <span className={inputLabelClassName}>{t('wellness.dashboard.log.waterGoal')}</span>
                    <input type="number" aria-label={t('wellness.dashboard.log.waterGoal')} value={waterGoalMl} onChange={(event) => setWaterGoalMl(event.target.value)} className="rounded-xl border border-slate-300 px-3 py-2 text-xs" />
                  </label>
                </div>
              </div>
            </div>

            <div id="wellness-timeline" className="order-1 rounded-3xl border border-slate-200 bg-white p-5 shadow-dashboard-subtle">
              <div className="flex flex-wrap items-start justify-between gap-3">
                <div>
                  <div className="inline-flex items-center gap-2 text-sm font-semibold text-slate-700"><span className="material-symbols-outlined text-sm text-primary">insights</span>{t('wellness.dashboard.timeline.title')}</div>
                  <p className="mt-1 text-xs text-slate-600">{t('wellness.dashboard.timeline.subtitle')}</p>
                  <div className="mt-2 flex flex-wrap items-center gap-2 text-[11px] font-semibold text-slate-600">
                    <span className="inline-flex items-center gap-1 rounded-full border border-amber-200 bg-amber-50 px-2 py-1">
                      <span className="h-2 w-2 rounded-full bg-amber-400" />
                      {t('wellness.dashboard.timeline.phases.prepare', { days: phaseDistribution.preparationDays })}
                    </span>
                    <span className="inline-flex items-center gap-1 rounded-full border border-red-200 bg-red-50 px-2 py-1">
                      <span className="h-2 w-2 rounded-full bg-red-500" />
                      {t('wellness.dashboard.timeline.phases.fasting', { days: phaseDistribution.fastingDays })}
                    </span>
                    <span className="inline-flex items-center gap-1 rounded-full border border-orange-200 bg-orange-50 px-2 py-1">
                      <span className="h-2 w-2 rounded-full bg-orange-600" />
                      {t('wellness.dashboard.timeline.phases.refeed', { days: phaseDistribution.refeedDays })}
                    </span>
                  </div>
                </div>
                <div className="flex flex-wrap justify-end gap-2">
                  <div className="flex gap-2">
                    {TIMELINE_WINDOWS.map((days) => (
                      <button
                        key={days}
                        type="button"
                        onClick={() => setTimelineDays(days)}
                        className={`rounded-full border px-3 py-1 text-xs font-semibold ${timelineDays === days ? 'border-primary bg-primary text-white' : 'border-slate-300 text-slate-700'}`}
                      >
                        {days}d
                      </button>
                    ))}
                  </div>
                  <div className="flex gap-2">
                    <button
                      type="button"
                      onClick={() => setTimelineIncludeFuture(false)}
                      className={`rounded-full border px-3 py-1 text-xs font-semibold ${!timelineIncludeFuture ? 'border-primary bg-primary text-white' : 'border-slate-300 text-slate-700'}`}
                    >
                      {t('wellness.dashboard.timeline.modes.history')}
                    </button>
                    <button
                      type="button"
                      onClick={() => setTimelineIncludeFuture(true)}
                      className={`rounded-full border px-3 py-1 text-xs font-semibold ${timelineIncludeFuture ? 'border-primary bg-primary text-white' : 'border-slate-300 text-slate-700'}`}
                    >
                      {t('wellness.dashboard.timeline.modes.future')}
                    </button>
                  </div>
                </div>
              </div>

              {timelineLoading ? (
                <div className="mt-4 rounded-2xl border border-slate-200 bg-slate-50 p-4 text-sm text-slate-600">{t('wellness.dashboard.timeline.loading')}</div>
              ) : (
                <>
                  <div className="mt-4 flex h-28 items-end gap-1 rounded-2xl border border-slate-200 bg-white p-3">
                    {timelineItems.map((item, index) => {
                      const iso = toDate(item.logDate);
                      const active = iso === selectedTimelineDate;
                      const phaseColor = getPhaseColor(item.phase, item.phaseDayIndex, item.phaseTotalDays);
                      const phaseLabel = getPhaseLabel(item.phase, t);
                      const phaseProgressLabel = getPhaseProgressLabel(item.phaseDayIndex, item.phaseTotalDays, t);
                      return (
                        <button
                          key={`${item.logDate}-${index}`}
                          type="button"
                          onClick={() => pickTimelineDate(iso)}
                          className="flex min-w-0 flex-1 flex-col items-center gap-1"
                          title={`${phaseLabel} - ${phaseProgressLabel}`}
                          aria-label={`${phaseLabel} - ${phaseProgressLabel}`}
                        >
                          <div
                            className={`w-full max-w-[14px] rounded-t transition-all ${active ? 'ring-2 ring-primary/80 ring-offset-1' : ''}`}
                            style={{
                              height: `${active ? 100 : 84}%`,
                              backgroundColor: phaseColor,
                              opacity: item.hasCheckin ? 1 : 0.75,
                            }}
                          />
                          <div className="text-[10px] text-slate-500">{new Date(item.logDate).toLocaleDateString(locale, { month: 'numeric', day: 'numeric' })}</div>
                          <div className="text-[9px] font-semibold text-slate-400">{phaseProgressLabel}</div>
                        </button>
                      );
                    })}
                  </div>

                  {selectedTimelineItem && (
                    <div className="mt-4 grid gap-2 sm:grid-cols-4">
                      <div className="rounded-xl border border-slate-200 bg-slate-50 p-3">
                        <div className="text-[11px] font-semibold uppercase text-slate-500">{t('wellness.dashboard.timeline.metrics.phase')}</div>
                        <div className="mt-1 text-sm font-black text-slate-900">
                          {getPhaseLabel(selectedTimelineItem.phase, t)} - {getPhaseProgressLabel(selectedTimelineItem.phaseDayIndex, selectedTimelineItem.phaseTotalDays, t)}
                        </div>
                      </div>
                      <div className="rounded-xl border border-slate-200 bg-slate-50 p-3"><div className="text-[11px] font-semibold uppercase text-slate-500">{t('wellness.dashboard.log.water')}</div><div className="mt-1 text-lg font-black text-slate-900">{selectedTimelineItem.waterMl} ml</div></div>
                      <div className="rounded-xl border border-slate-200 bg-slate-50 p-3"><div className="text-[11px] font-semibold uppercase text-slate-500">{t('wellness.dashboard.log.workoutMinutes')}</div><div className="mt-1 text-lg font-black text-slate-900">{selectedTimelineItem.workoutMinutes} min</div></div>
                      <div className="rounded-xl border border-slate-200 bg-slate-50 p-3"><div className="text-[11px] font-semibold uppercase text-slate-500">{t('wellness.dashboard.log.currentWeight')}</div><div className="mt-1 text-lg font-black text-slate-900">{selectedTimelineItem.currentWeightKg ?? '-'} kg</div></div>
                    </div>
                  )}
                </>
              )}
            </div>

            <form id="wellness-plan" onSubmit={savePlan} className="order-2 rounded-3xl border border-slate-200 bg-white p-5 shadow-dashboard-subtle">
              <div className="mb-3 inline-flex items-center gap-2 text-sm font-semibold text-slate-700"><span className="material-symbols-outlined text-sm text-primary">tune</span>{t('wellness.dashboard.actions.savePlan')}</div>
              <div className="grid gap-3 sm:grid-cols-2 lg:grid-cols-4">
                <label className="flex flex-col gap-1">
                  <span className={inputLabelClassName}>{t('wellness.dashboard.form.package')}</span>
                  <select aria-label={t('wellness.dashboard.form.package')} value={packageType} onChange={(event) => setPackageType(event.target.value)} className="rounded-xl border border-slate-200 px-3 py-2 text-sm">{checkoutPackages.map((pkg) => <option key={pkg.code} value={pkg.code}>{pkg.name}</option>)}</select>
                </label>
                <label className="flex flex-col gap-1">
                  <span className={inputLabelClassName}>{t('wellness.dashboard.form.startDate')}</span>
                  <input aria-label={t('wellness.dashboard.form.startDate')} type="date" value={startDate} onChange={(event) => setStartDate(event.target.value)} className="rounded-xl border border-slate-200 px-3 py-2 text-sm" />
                </label>
                <label className="flex flex-col gap-1">
                  <span className={inputLabelClassName}>{t('wellness.dashboard.form.endDate')}</span>
                  <input aria-label={t('wellness.dashboard.form.endDate')} type="date" value={endDate} onChange={(event) => setEndDate(event.target.value)} className="rounded-xl border border-slate-200 px-3 py-2 text-sm" />
                </label>
                <label className="flex flex-col gap-1">
                  <span className={inputLabelClassName}>{t('wellness.dashboard.form.fastingHours')}</span>
                  <input aria-label={t('wellness.dashboard.form.fastingHours')} type="number" min={12} max={24} value={fastingHours} onChange={(event) => setFastingHours(Number(event.target.value))} className="rounded-xl border border-slate-200 px-3 py-2 text-sm" />
                </label>
                <label className="flex flex-col gap-1">
                  <span className={inputLabelClassName}>{t('wellness.dashboard.form.eatingHours')}</span>
                  <input aria-label={t('wellness.dashboard.form.eatingHours')} type="number" min={1} max={12} value={eatingHours} onChange={(event) => setEatingHours(Number(event.target.value))} className="rounded-xl border border-slate-200 px-3 py-2 text-sm" />
                </label>
                <label className="flex flex-col gap-1">
                  <span className={inputLabelClassName}>{t('wellness.dashboard.form.fastStart')}</span>
                  <input aria-label={t('wellness.dashboard.form.fastStart')} type="time" value={fastStart} onChange={(event) => setFastStart(event.target.value)} className="rounded-xl border border-slate-200 px-3 py-2 text-sm" />
                </label>
                <label className="flex flex-col gap-1">
                  <span className={inputLabelClassName}>{t('wellness.dashboard.form.startWeight')}</span>
                  <input aria-label={t('wellness.dashboard.form.startWeight')} type="number" step="0.1" value={startWeight} onChange={(event) => setStartWeight(event.target.value)} className="rounded-xl border border-slate-200 px-3 py-2 text-sm" />
                </label>
                <label className="flex flex-col gap-1">
                  <span className={inputLabelClassName}>{t('wellness.dashboard.form.targetWeight')}</span>
                  <input aria-label={t('wellness.dashboard.form.targetWeight')} type="number" step="0.1" value={targetWeight} onChange={(event) => setTargetWeight(event.target.value)} className="rounded-xl border border-slate-200 px-3 py-2 text-sm" />
                </label>
                <label className="flex flex-col gap-1">
                  <span className={inputLabelClassName}>{t('wellness.dashboard.form.timezone')}</span>
                  <input aria-label={t('wellness.dashboard.form.timezone')} value={timezone} onChange={(event) => setTimezone(event.target.value)} className="rounded-xl border border-slate-200 px-3 py-2 text-sm" />
                </label>
              </div>
              <button type="submit" disabled={submitting} className="mt-3 inline-flex items-center gap-1 rounded-full bg-primary px-4 py-2 text-xs font-semibold text-white"><span className="material-symbols-outlined text-sm">{submittingAction === 'plan' ? 'hourglass_top' : 'save'}</span>{submittingAction === 'plan' ? t('wellness.dashboard.status.savingPlan') : t('wellness.dashboard.actions.savePlan')}</button>
            </form>

            <form id="wellness-log" onSubmit={saveLog} className="order-3 rounded-3xl border border-slate-200 bg-white p-5 shadow-dashboard-subtle">
              <div className="mb-3 inline-flex items-center gap-2 text-sm font-semibold text-slate-700"><span className="material-symbols-outlined text-sm text-primary">edit_calendar</span>{t('wellness.dashboard.actions.saveLog')}</div>
              <div className="grid gap-3 sm:grid-cols-2 lg:grid-cols-3">
                <label className="flex flex-col gap-1">
                  <span className={inputLabelClassName}>{t('wellness.dashboard.log.logDate')}</span>
                  <input aria-label={t('wellness.dashboard.log.logDate')} type="date" value={logDate} onChange={(event) => setLogDate(event.target.value)} className="rounded-xl border border-slate-200 px-3 py-2 text-sm" />
                </label>
                <label className="flex flex-col gap-1">
                  <span className={inputLabelClassName}>{t('wellness.dashboard.log.ateAt')}</span>
                  <input aria-label={t('wellness.dashboard.log.ateAt')} type="datetime-local" value={ateAtLocal} onChange={(event) => setAteAtLocal(event.target.value)} className="rounded-xl border border-slate-200 px-3 py-2 text-sm" />
                </label>
                <label className="flex flex-col gap-1">
                  <span className={inputLabelClassName}>{t('wellness.dashboard.log.water')}</span>
                  <input aria-label={t('wellness.dashboard.log.water')} type="number" value={waterMl} onChange={(event) => setWaterMl(event.target.value)} className="rounded-xl border border-slate-200 px-3 py-2 text-sm" />
                </label>
                <label className="flex flex-col gap-1">
                  <span className={inputLabelClassName}>{t('wellness.dashboard.log.workoutMinutes')}</span>
                  <input aria-label={t('wellness.dashboard.log.workoutMinutes')} type="number" value={workoutMinutes} onChange={(event) => setWorkoutMinutes(event.target.value)} className="rounded-xl border border-slate-200 px-3 py-2 text-sm" />
                </label>
                <label className="flex flex-col gap-1">
                  <span className={inputLabelClassName}>{t('wellness.dashboard.log.workoutType')}</span>
                  <input aria-label={t('wellness.dashboard.log.workoutType')} value={workoutType} onChange={(event) => setWorkoutType(event.target.value)} className="rounded-xl border border-slate-200 px-3 py-2 text-sm" />
                </label>
                <label className="flex flex-col gap-1">
                  <span className={inputLabelClassName}>{t('wellness.dashboard.log.currentWeight')}</span>
                  <input aria-label={t('wellness.dashboard.log.currentWeight')} type="number" step="0.1" value={currentWeight} onChange={(event) => setCurrentWeight(event.target.value)} className="rounded-xl border border-slate-200 px-3 py-2 text-sm" />
                </label>
              </div>
              <label className="mt-3 flex flex-col gap-1">
                <span className={inputLabelClassName}>{t('wellness.dashboard.log.notes')}</span>
                <textarea aria-label={t('wellness.dashboard.log.notes')} value={notes} onChange={(event) => setNotes(event.target.value)} className="min-h-[90px] w-full rounded-xl border border-slate-200 px-3 py-2 text-sm" />
              </label>
              <button type="submit" disabled={submitting} className="mt-3 inline-flex items-center gap-1 rounded-full bg-slate-900 px-4 py-2 text-xs font-semibold text-white"><span className="material-symbols-outlined text-sm">{submittingAction === 'log' ? 'hourglass_top' : 'check_circle'}</span>{submittingAction === 'log' ? t('wellness.dashboard.status.savingLog') : t('wellness.dashboard.actions.saveLog')}</button>
            </form>

            <div id="wellness-meal" className="order-6">
              <form onSubmit={generateMealSuggestion} className="rounded-3xl border border-slate-200 bg-white p-5 shadow-dashboard-subtle">
                <div className="mb-3 inline-flex items-center gap-2 text-sm font-semibold text-slate-700"><span className="material-symbols-outlined text-sm text-emerald-600">restaurant_menu</span>{t('wellness.dashboard.meal.title')}</div>
                <label className="flex flex-col gap-1">
                  <span className={inputLabelClassName}>{t('wellness.dashboard.meal.form.ingredients')}</span>
                  <textarea aria-label={t('wellness.dashboard.meal.form.ingredients')} placeholder={t('wellness.dashboard.meal.placeholders.ingredients')} value={mealIngredients} onChange={(event) => setMealIngredients(event.target.value)} className="min-h-[90px] w-full rounded-xl border border-slate-200 px-3 py-2 text-sm" />
                </label>
                <button type="submit" disabled={mealSubmitting} className="mt-3 inline-flex items-center gap-1 rounded-full bg-emerald-600 px-4 py-2 text-xs font-semibold text-white"><span className="material-symbols-outlined text-sm">{mealSubmitting ? 'hourglass_top' : 'auto_awesome'}</span>{mealSubmitting ? t('wellness.dashboard.status.generatingMeal') : t('wellness.dashboard.meal.actions.generate')}</button>
                {mealSuggestion && <div className="mt-3 rounded-2xl border border-emerald-200 bg-emerald-50 p-3 text-sm text-slate-700"><p className="whitespace-pre-line">{mealSuggestion.menu}</p><p className="mt-2 text-xs">{mealSuggestion.nutritionNotes}</p></div>}
              </form>
            </div>
            </div>
          </>
        ) : (
          <div className="rounded-3xl border border-primary/25 bg-primary/5 p-6 shadow-dashboard-subtle">
            <div className="inline-flex items-center gap-2 text-xs font-semibold uppercase tracking-[0.12em] text-primary"><span className="material-symbols-outlined text-sm">lock</span>{t('wellness.dashboard.locked.badge')}</div>
            <h3 className="mt-2 text-2xl font-black tracking-tight text-primary-dark">{t('wellness.dashboard.locked.title')}</h3>
            <p className="mt-2 text-sm text-slate-700">{accessMessage}</p>
            {!!requiredPackageLabels && <p className="mt-2 text-xs font-semibold text-slate-600">{t('wellness.dashboard.locked.required', { packages: requiredPackageLabels })}</p>}
            {!!currentPackageLabel && <p className="mt-1 text-xs text-slate-600">{t('wellness.dashboard.locked.current', { package: currentPackageLabel })}</p>}
          </div>
        )}
      </main>

      <aside className="space-y-4 rounded-3xl border border-slate-200 bg-white p-5 shadow-dashboard-subtle xl:sticky xl:top-24 xl:h-[calc(100vh-7rem)] xl:overflow-auto">
        <div className="inline-flex items-center gap-2 text-lg font-black tracking-tight text-slate-900"><span className="material-symbols-outlined text-lg text-primary">monitoring</span>{t('wellness.dashboard.timeline.title')}</div>
        <div className="space-y-3">
          <div className="flex items-center gap-3 rounded-2xl border border-slate-200 bg-white p-3"><span className="material-symbols-outlined rounded-xl bg-cyan-50 p-2 text-cyan-600">schedule</span><div><div className="text-[11px] font-semibold uppercase text-slate-500">{t('wellness.dashboard.sidebar.fasting')}</div><div className="text-lg font-black text-slate-900">{Math.round(fastProgress)}%</div></div></div>
          <div className="flex items-center gap-3 rounded-2xl border border-slate-200 bg-white p-3"><span className="material-symbols-outlined rounded-xl bg-sky-50 p-2 text-sky-600">local_drink</span><div><div className="text-[11px] font-semibold uppercase text-slate-500">{t('wellness.dashboard.sidebar.water')}</div><div className="text-lg font-black text-slate-900">{waterDone}/{waterGoal} ml</div></div></div>
          <div className="flex items-center gap-3 rounded-2xl border border-slate-200 bg-white p-3"><span className="material-symbols-outlined rounded-xl bg-emerald-50 p-2 text-emerald-600">task_alt</span><div><div className="text-[11px] font-semibold uppercase text-slate-500">{t('wellness.dashboard.sidebar.checkpoint')}</div><div className="text-lg font-black text-slate-900">{checkpointDone}/{timelineItems.length || 0}</div></div></div>
          <div className="flex items-center gap-3 rounded-2xl border border-slate-200 bg-white p-3"><span className="material-symbols-outlined rounded-xl bg-violet-50 p-2 text-violet-600">query_stats</span><div><div className="text-[11px] font-semibold uppercase text-slate-500">{t('wellness.dashboard.sidebar.completion')}</div><div className="text-lg font-black text-slate-900">{completionRate}%</div></div></div>
        </div>
        <button type="button" onClick={() => goCheckout(recommendedLockedPackage)} disabled={checkoutPackage !== null} className="inline-flex w-full items-center justify-center gap-1 rounded-full bg-slate-900 px-4 py-2 text-xs font-semibold text-white disabled:opacity-60"><span className="material-symbols-outlined text-sm">{checkoutPackage !== null ? 'hourglass_top' : 'upgrade'}</span>{checkoutPackage !== null ? t('wellness.dashboard.status.openingCheckout') : t('wellness.dashboard.actions.upgrade')}</button>
      </aside>
    </section>
  );
};

export default WellnessCoachDashboard;
