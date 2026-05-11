import React, { startTransition, useEffect, useMemo, useRef, useState } from 'react';
import { addDays, format, isSameDay, startOfDay } from 'date-fns';
import { Link } from 'react-router-dom';
import { toast } from 'react-hot-toast';
import { useTranslation } from 'react-i18next';
import { useSelector } from 'react-redux';
import type { RootState } from '../../store/store';
import {
    aiWidgetApi,
    type AiRoadmapAccessState,
    type AiChatMessage,
    type DailyStudyCheckIn,
    type DailyStudyTask,
    type UserStudyPlan
} from '../../services/aiWidgetApi';
import { enrollmentApi, type EnrollmentResponse } from '../../services/enrollmentApi';

type View = 'onboarding' | 'tasks' | 'checkin' | 'chat';
type DisplayMode = 'widget' | 'page';

interface AiCoachDashboardProps {
    mode?: DisplayMode;
    onClose?: () => void;
}

const scoreOptions = [1, 2, 3, 4, 5];

const quickStatusKeys = ['overloaded', 'confused', 'strong', 'focus'] as const;
const normalizePackageCode = (value?: string | null) => (value ?? '').trim().toUpperCase();
const buildWellnessCheckoutPath = (packageCode?: string | null) => {
    const normalizedCode = normalizePackageCode(packageCode);
    const params = new URLSearchParams();
    params.set('single', '1');
    params.set('source', 'wellness');
    if (normalizedCode) {
        params.set('wellnessPackage', normalizedCode);
    }
    return `/checkout?${params.toString()}`;
};

const AiCoachDashboard: React.FC<AiCoachDashboardProps> = ({ mode = 'page', onClose }) => {
    const { t, i18n } = useTranslation();
    const { isAuthenticated, user } = useSelector((state: RootState) => state.auth);
    const isStudent = user?.role?.toUpperCase() === 'STUDENT';

    const [statusChecked, setStatusChecked] = useState(false);
    const [isEnabled, setIsEnabled] = useState(false);
    const [access, setAccess] = useState<AiRoadmapAccessState | null>(null);
    const [loading, setLoading] = useState(false);
    const [view, setView] = useState<View>('onboarding');

    const [plan, setPlan] = useState<UserStudyPlan | null>(null);
    const [tasks, setTasks] = useState<DailyStudyTask[]>([]);
    const [latestCheckIn, setLatestCheckIn] = useState<DailyStudyCheckIn | null>(null);
    const [guidanceMessage, setGuidanceMessage] = useState('');
    const [openSupportAlerts, setOpenSupportAlerts] = useState(0);
    const [enrollments, setEnrollments] = useState<EnrollmentResponse[]>([]);
    const [chatHistory, setChatHistory] = useState<AiChatMessage[]>([]);
    const [chatInput, setChatInput] = useState('');

    const [goal, setGoal] = useState('');
    const [currentKnowledge, setCurrentKnowledge] = useState('');
    const [motivation, setMotivation] = useState('');
    const [timeBudgetMinutesPerDay, setTimeBudgetMinutesPerDay] = useState(45);
    const [preferredStudyTime, setPreferredStudyTime] = useState('evening');
    const [constraints, setConstraints] = useState('');
    const [primaryCourseId, setPrimaryCourseId] = useState('');

    const [selectedTaskId, setSelectedTaskId] = useState<string | null>(null);
    const [taskFeedback, setTaskFeedback] = useState('');
    const [taskActualMinutes, setTaskActualMinutes] = useState(30);
    const [taskDifficulty, setTaskDifficulty] = useState(3);
    const [taskConfidence, setTaskConfidence] = useState(3);
    const [taskNeedsSupport, setTaskNeedsSupport] = useState(false);

    const [moodScore, setMoodScore] = useState(3);
    const [energyScore, setEnergyScore] = useState(3);
    const [confidenceScore, setConfidenceScore] = useState(3);
    const [actualMinutesSpentToday, setActualMinutesSpentToday] = useState(30);
    const [minutesAvailableTomorrow, setMinutesAvailableTomorrow] = useState(45);
    const [checkInNotes, setCheckInNotes] = useState('');
    const [checkInNeedsSupport, setCheckInNeedsSupport] = useState(false);
    const [selectedDateKey, setSelectedDateKey] = useState(format(startOfDay(new Date()), 'yyyy-MM-dd'));

    const chatEndRef = useRef<HTMLDivElement>(null);

    const preferredStudyTimeOptions = useMemo(
        () => [
            { value: 'morning', label: t('aiCoach.preferredStudyTimeOptions.morning') },
            { value: 'afternoon', label: t('aiCoach.preferredStudyTimeOptions.afternoon') },
            { value: 'evening', label: t('aiCoach.preferredStudyTimeOptions.evening') },
            { value: 'flexible', label: t('aiCoach.preferredStudyTimeOptions.flexible') }
        ],
        [t]
    );

    const locale = i18n.resolvedLanguage?.toLowerCase().startsWith('vi') ? 'vi-VN' : 'en-US';
    const isUnlocked = access?.isUnlocked ?? true;
    const accessMessage = access?.message || t('aiCoach.states.packageRequired');
    const requiredPackageLabels = (access?.requiredPackages ?? [])
        .map((pkg) => t(`wellness.dashboard.packages.${pkg}`, { defaultValue: pkg }))
        .join(', ');
    const lockedDescription = requiredPackageLabels
        ? `${accessMessage} ${t('aiCoach.states.requiredPackages', { packages: requiredPackageLabels })}`
        : accessMessage;
    const requiredPackageCode = normalizePackageCode(access?.requiredPackages?.[0] ?? null);
    const ctaPath = requiredPackageCode ? buildWellnessCheckoutPath(requiredPackageCode) : '/wellness';
    const today = useMemo(() => startOfDay(new Date()), []);
    const selectedDate = useMemo(() => startOfDay(new Date(`${selectedDateKey}T00:00:00`)), [selectedDateKey]);
    const weekDates = useMemo(() => Array.from({ length: 7 }, (_, index) => addDays(today, index - 3)), [today]);
    const isTodaySelected = useMemo(() => isSameDay(selectedDate, today), [selectedDate, today]);
    const visibleTasks = useMemo(() => (isTodaySelected ? tasks : []), [isTodaySelected, tasks]);
    const featuredTask = useMemo(
        () => visibleTasks.find((task) => !task.isCompleted && task.status?.toUpperCase() !== 'SKIPPED') ?? null,
        [visibleTasks]
    );
    const secondaryTasks = useMemo(
        () => visibleTasks.filter((task) => task.id !== featuredTask?.id),
        [featuredTask?.id, visibleTasks]
    );
    const completedTasks = useMemo(() => tasks.filter((task) => task.isCompleted).length, [tasks]);
    const totalMinutes = useMemo(() => tasks.reduce((sum, task) => sum + task.estimatedMinutes, 0), [tasks]);
    const actualMinutes = useMemo(() => tasks.reduce((sum, task) => sum + (task.actualMinutesSpent ?? 0), 0), [tasks]);
    const completionRate = useMemo(() => (tasks.length > 0 ? Math.round((completedTasks / tasks.length) * 100) : 0), [completedTasks, tasks.length]);
    const planMinutes = plan?.timeBudgetMinutesPerDay ?? totalMinutes;
    const primaryEnrollment = useMemo(
        () => enrollments.find((item) => item.courseId === plan?.primaryCourseId) ?? enrollments[0] ?? null,
        [enrollments, plan?.primaryCourseId]
    );
    const selectedTask = useMemo(
        () => (selectedTaskId ? tasks.find((task) => task.id === selectedTaskId) ?? null : null),
        [selectedTaskId, tasks]
    );

    const quickStatusOptions = useMemo(
        () =>
            quickStatusKeys.map((key) => ({
                icon:
                    key === 'overloaded'
                        ? 'flare'
                        : key === 'confused'
                          ? 'live_help'
                          : key === 'strong'
                            ? 'rocket_launch'
                            : 'self_improvement',
                label: t(`aiCoach.page.quickStatus.${key}`, { defaultValue: key }),
                prompt: t(`aiCoach.page.quickStatusPrompts.${key}`, { defaultValue: key })
            })),
        [t]
    );

    useEffect(() => {
        if (isAuthenticated && isStudent) {
            void bootstrap();
            return;
        }

        setStatusChecked(true);
        setIsEnabled(false);
        setAccess(null);
        setPlan(null);
        setTasks([]);
        setLatestCheckIn(null);
        setGuidanceMessage('');
        setOpenSupportAlerts(0);
    }, [isAuthenticated, isStudent]);

    useEffect(() => {
        if (view === 'chat' && chatEndRef.current) {
            chatEndRef.current.scrollIntoView({ behavior: 'smooth' });
        }
    }, [chatHistory, view]);

    useEffect(() => {
        setSelectedDateKey(format(startOfDay(new Date()), 'yyyy-MM-dd'));
    }, [plan?.id]);

    const bootstrap = async () => {
        try {
            const status = await aiWidgetApi.getStatus();
            setIsEnabled(status.isEnabled);
            setAccess(status.access ?? null);

            if (!status.isEnabled) {
                startTransition(() => {
                    setPlan(null);
                    setTasks([]);
                    setLatestCheckIn(null);
                    setGuidanceMessage('');
                    setOpenSupportAlerts(0);
                });
                return;
            }

            if (status.access && !status.access.isUnlocked) {
                startTransition(() => {
                    setPlan(null);
                    setTasks([]);
                    setLatestCheckIn(null);
                    setGuidanceMessage('');
                    setOpenSupportAlerts(0);
                });
                return;
            }

            await Promise.all([loadEnrollments(), loadDashboard()]);
        } catch (error) {
            console.error('Failed to bootstrap AI coach', error);
            setAccess(null);
        } finally {
            setStatusChecked(true);
        }
    };

    const loadEnrollments = async () => {
        try {
            const data = await enrollmentApi.getUserEnrollments();
            startTransition(() => {
                setEnrollments(data.filter((item) => item.status?.toUpperCase() !== 'INACTIVE'));
            });
        } catch (error) {
            console.error('Failed to load enrollments for AI coach', error);
        }
    };

    const loadDashboard = async () => {
        try {
            setLoading(true);
            const dashboard = await aiWidgetApi.getDashboard();
            startTransition(() => {
                setPlan(dashboard.plan);
                setTasks(dashboard.todayTasks);
                setLatestCheckIn(dashboard.latestCheckIn);
                setGuidanceMessage(dashboard.guidanceMessage);
                setOpenSupportAlerts(dashboard.openSupportAlerts);
                setMinutesAvailableTomorrow(dashboard.plan?.timeBudgetMinutesPerDay ?? 45);
                setView(dashboard.plan ? 'tasks' : 'onboarding');
            });
        } catch (error) {
            console.error('Failed to load AI dashboard', error);
            startTransition(() => {
                setPlan(null);
                setTasks([]);
                setLatestCheckIn(null);
                setGuidanceMessage('');
                setOpenSupportAlerts(0);
                setView('onboarding');
            });
        } finally {
            setLoading(false);
        }
    };

    const loadChatHistory = async () => {
        try {
            const history = await aiWidgetApi.getChatHistory();
            startTransition(() => {
                setChatHistory(history);
            });
        } catch (error) {
            console.error('Failed to load AI chat history', error);
        }
    };

    const resetTaskForm = (task?: DailyStudyTask) => {
        setSelectedTaskId(task?.id ?? null);
        setTaskFeedback('');
        setTaskActualMinutes(task?.estimatedMinutes ?? 30);
        setTaskDifficulty(3);
        setTaskConfidence(3);
        setTaskNeedsSupport(false);
    };

    const handleInitPlan = async (event: React.FormEvent) => {
        event.preventDefault();

        try {
            setLoading(true);
            await aiWidgetApi.initPlan({
                goal,
                currentKnowledge,
                motivation,
                timeBudgetMinutesPerDay,
                preferredStudyTime,
                constraints,
                primaryCourseId: primaryCourseId || undefined
            });
            toast.success(t('aiCoach.toasts.planCreated'));
            await loadDashboard();
        } catch (error: any) {
            toast.error(error?.message || t('aiCoach.toasts.planCreateFailed'));
        } finally {
            setLoading(false);
        }
    };

    const handleSubmitTask = async (taskId: string, isCompleted: boolean) => {
        try {
            setLoading(true);
            const updated = await aiWidgetApi.submitTask(taskId, {
                isCompleted,
                feedback: taskFeedback,
                actualMinutesSpent: taskActualMinutes,
                difficultyRating: taskDifficulty,
                confidenceRating: taskConfidence,
                needsSupport: taskNeedsSupport
            });

            toast.success(updated.aiAdvice || t('aiCoach.toasts.taskUpdated'));
            resetTaskForm();
            await loadDashboard();
        } catch (error: any) {
            toast.error(error?.message || t('aiCoach.toasts.taskUpdateFailed'));
        } finally {
            setLoading(false);
        }
    };

    const handleSubmitCheckIn = async (event: React.FormEvent) => {
        event.preventDefault();

        try {
            setLoading(true);
            const result = await aiWidgetApi.submitCheckIn({
                moodScore,
                energyScore,
                confidenceScore,
                actualMinutesSpentToday,
                minutesAvailableTomorrow,
                notes: checkInNotes,
                needsSupport: checkInNeedsSupport
            });

            toast.success(result.coachAdvice || t('aiCoach.toasts.checkInSaved'));
            setLatestCheckIn(result);
            setView('tasks');
            await loadDashboard();
        } catch (error: any) {
            toast.error(error?.message || t('aiCoach.toasts.checkInFailed'));
        } finally {
            setLoading(false);
        }
    };

    const handleOpenChat = async () => {
        setView('chat');
        await loadChatHistory();
    };

    const sendPromptToCoach = async (prompt: string) => {
        setView('chat');
        startTransition(() => {
            setChatHistory((prev) => [
                ...prev,
                { id: `temp-${Date.now()}`, role: 'user', content: prompt, createdAt: new Date().toISOString() }
            ]);
        });

        try {
            setLoading(true);
            const { response } = await aiWidgetApi.chat(prompt);
            startTransition(() => {
                setChatHistory((prev) => [
                    ...prev,
                    { id: `ai-${Date.now()}`, role: 'model', content: response, createdAt: new Date().toISOString() }
                ]);
            });
        } catch (error) {
            toast.error(t('aiCoach.toasts.chatFailed'));
            startTransition(() => {
                setChatHistory((prev) => prev.filter((message) => !message.id.startsWith('temp-')));
            });
        } finally {
            setLoading(false);
        }
    };

    const handleSendChat = async (event: React.FormEvent) => {
        event.preventDefault();
        if (!chatInput.trim()) {
            return;
        }

        const prompt = chatInput.trim();
        setChatInput('');
        await sendPromptToCoach(prompt);
    };

    const formatCalendarDate = (date: Date, options: Intl.DateTimeFormatOptions) =>
        new Intl.DateTimeFormat(locale, options).format(date);

    const taskTypeMetaMap = useMemo(
        () => ({
            WATCH: {
                icon: 'play_circle',
                badge: 'from-rose-500/15 to-orange-500/10 text-rose-600 dark:text-rose-300',
                label: t('aiCoach.page.taskTypes.watch', { defaultValue: 'Video lesson' })
            },
            QUIZ: {
                icon: 'quiz',
                badge: 'from-cyan-500/15 to-sky-500/10 text-cyan-700 dark:text-cyan-300',
                label: t('aiCoach.page.taskTypes.quiz', { defaultValue: 'Quiz and recall' })
            },
            PRACTICE: {
                icon: 'edit_square',
                badge: 'from-amber-500/15 to-yellow-500/10 text-amber-700 dark:text-amber-300',
                label: t('aiCoach.page.taskTypes.practice', { defaultValue: 'Practice block' })
            },
            READ: {
                icon: 'auto_stories',
                badge: 'from-emerald-500/15 to-teal-500/10 text-emerald-700 dark:text-emerald-300',
                label: t('aiCoach.page.taskTypes.read', { defaultValue: 'Reading focus' })
            },
            DEFAULT: {
                icon: 'track_changes',
                badge: 'from-violet-500/15 to-fuchsia-500/10 text-violet-700 dark:text-violet-300',
                label: t('aiCoach.page.taskTypes.default', { defaultValue: 'Suggested task' })
            }
        }),
        [t]
    );

    const getTaskTypeMeta = (taskType: string) => taskTypeMetaMap[taskType.toUpperCase() as keyof typeof taskTypeMetaMap] ?? taskTypeMetaMap.DEFAULT;

    const renderScorePills = (
        label: string,
        value: number,
        setter: React.Dispatch<React.SetStateAction<number>>
    ) => (
        <div className="space-y-3">
            <div className="text-xs font-semibold uppercase tracking-[0.2em] text-slate-500 dark:text-slate-400">{label}</div>
            <div className="grid grid-cols-5 gap-2">
                {scoreOptions.map((option) => (
                    <button
                        key={`${label}-${option}`}
                        type="button"
                        onClick={() => setter(option)}
                        className={`rounded-2xl px-0 py-2 text-sm font-semibold transition ${
                            value === option
                                ? 'bg-slate-900 text-white shadow-lg shadow-slate-900/15 dark:bg-white dark:text-slate-900'
                                : 'bg-slate-100 text-slate-600 hover:bg-slate-200 dark:bg-slate-800 dark:text-slate-300 dark:hover:bg-slate-700'
                        }`}
                    >
                        {option}
                    </button>
                ))}
            </div>
        </div>
    );

    const renderTaskEditor = (task: DailyStudyTask) => (
        <div className="mt-5 rounded-[28px] border border-slate-200 bg-white/80 p-5 shadow-sm backdrop-blur dark:border-slate-800 dark:bg-slate-900/80">
            <div className="flex flex-wrap items-start justify-between gap-4">
                <div>
                    <div className="text-xs font-semibold uppercase tracking-[0.22em] text-slate-500 dark:text-slate-400">
                        {t('aiCoach.tasks.update')}
                    </div>
                    <h4 className="mt-2 text-lg font-semibold text-slate-900 dark:text-white">{task.title}</h4>
                    {task.reflectionPrompt && (
                        <p className="mt-2 text-sm text-slate-500 dark:text-slate-400">
                            {t('aiCoach.tasks.reflectionPrompt', { prompt: task.reflectionPrompt })}
                        </p>
                    )}
                </div>

                <button
                    type="button"
                    onClick={() => resetTaskForm()}
                    className="inline-flex items-center gap-2 rounded-full border border-slate-200 px-4 py-2 text-sm font-semibold text-slate-600 transition hover:border-slate-300 hover:text-slate-900 dark:border-slate-700 dark:text-slate-300 dark:hover:border-slate-600 dark:hover:text-white"
                >
                    <span className="material-symbols-outlined text-[18px]">close</span>
                    {t('common.cancel', { defaultValue: 'Cancel' })}
                </button>
            </div>

            <div className="mt-5 grid gap-4 lg:grid-cols-[minmax(0,1.2fr)_minmax(280px,0.8fr)]">
                <label className="block">
                    <span className="text-xs font-semibold uppercase tracking-[0.2em] text-slate-500 dark:text-slate-400">
                        {t('aiCoach.tasks.feedbackPlaceholder')}
                    </span>
                    <textarea
                        value={taskFeedback}
                        onChange={(event) => setTaskFeedback(event.target.value)}
                        placeholder={t('aiCoach.tasks.feedbackPlaceholder')}
                        className="mt-3 min-h-[140px] w-full rounded-[24px] border border-slate-200 bg-slate-50 px-4 py-4 text-sm text-slate-700 outline-none transition focus:border-primary focus:bg-white dark:border-slate-700 dark:bg-slate-950 dark:text-slate-200 dark:focus:bg-slate-900"
                    />
                </label>

                <div className="space-y-4 rounded-[24px] bg-slate-50 p-4 dark:bg-slate-950/60">
                    <div className="grid gap-4 sm:grid-cols-2">
                        <label className="block">
                            <span className="text-xs font-semibold uppercase tracking-[0.18em] text-slate-500 dark:text-slate-400">
                                {t('aiCoach.tasks.actualMinutesPlaceholder')}
                            </span>
                            <input
                                type="number"
                                min={0}
                                max={600}
                                value={taskActualMinutes}
                                onChange={(event) => setTaskActualMinutes(Number(event.target.value))}
                                className="mt-3 w-full rounded-2xl border border-slate-200 bg-white px-4 py-3 text-sm text-slate-700 outline-none transition focus:border-primary dark:border-slate-700 dark:bg-slate-900 dark:text-slate-200"
                            />
                        </label>

                        <div className="rounded-2xl border border-dashed border-primary/20 bg-primary/5 px-4 py-3 text-sm text-slate-600 dark:border-primary/20 dark:bg-primary/10 dark:text-slate-300">
                            <div className="text-xs font-semibold uppercase tracking-[0.18em] text-primary">
                                {t('aiCoach.page.metrics.completionRate', { defaultValue: 'Completion rate' })}
                            </div>
                            <div className="mt-2 text-2xl font-bold text-slate-900 dark:text-white">{completionRate}%</div>
                            <div className="mt-1 text-xs text-slate-500 dark:text-slate-400">
                                {completedTasks}/{Math.max(tasks.length, 1)} {t('aiCoach.page.metrics.tasks', { defaultValue: 'tasks' })}
                            </div>
                        </div>
                    </div>

                    {renderScorePills(t('aiCoach.page.metrics.difficulty', { defaultValue: 'Difficulty' }), taskDifficulty, setTaskDifficulty)}
                    {renderScorePills(t('aiCoach.page.metrics.confidence', { defaultValue: 'Confidence' }), taskConfidence, setTaskConfidence)}

                    <label className="flex items-start gap-3 rounded-2xl border border-slate-200 bg-white px-4 py-4 text-sm text-slate-600 dark:border-slate-700 dark:bg-slate-900 dark:text-slate-300">
                        <input
                            type="checkbox"
                            checked={taskNeedsSupport}
                            onChange={(event) => setTaskNeedsSupport(event.target.checked)}
                            className="mt-1 h-4 w-4 rounded border-slate-300 text-primary focus:ring-primary"
                        />
                        <span>{t('aiCoach.tasks.needSupport')}</span>
                    </label>

                    <div className="grid gap-3 sm:grid-cols-2">
                        <button
                            type="button"
                            disabled={loading}
                            onClick={() => void handleSubmitTask(task.id, true)}
                            className="inline-flex items-center justify-center gap-2 rounded-full bg-slate-900 px-5 py-3 text-sm font-semibold text-white transition hover:bg-slate-800 disabled:cursor-not-allowed disabled:opacity-60 dark:bg-white dark:text-slate-900 dark:hover:bg-slate-200"
                        >
                            <span className="material-symbols-outlined text-[18px]">check_circle</span>
                            {t('aiCoach.tasks.complete')}
                        </button>
                        <button
                            type="button"
                            disabled={loading}
                            onClick={() => void handleSubmitTask(task.id, false)}
                            className="inline-flex items-center justify-center gap-2 rounded-full border border-slate-200 px-5 py-3 text-sm font-semibold text-slate-700 transition hover:border-slate-300 hover:text-slate-900 disabled:cursor-not-allowed disabled:opacity-60 dark:border-slate-700 dark:text-slate-200 dark:hover:border-slate-600 dark:hover:text-white"
                        >
                            <span className="material-symbols-outlined text-[18px]">schedule</span>
                            {t('aiCoach.tasks.skip')}
                        </button>
                    </div>
                </div>
            </div>
        </div>
    );

    const renderInfoState = (icon: string, title: string, description?: string, action?: React.ReactNode) => (
        <div className="rounded-[32px] border border-white/70 bg-white/85 p-8 text-center shadow-sm backdrop-blur dark:border-slate-800 dark:bg-slate-900/85">
            <div className="mx-auto flex h-16 w-16 items-center justify-center rounded-full bg-slate-100 text-slate-700 dark:bg-slate-800 dark:text-slate-200">
                <span className="material-symbols-outlined text-[28px]">{icon}</span>
            </div>
            <h3 className="mt-5 text-xl font-semibold text-slate-900 dark:text-white">{title}</h3>
            {description && <p className="mx-auto mt-3 max-w-lg text-sm leading-7 text-slate-600 dark:text-slate-300">{description}</p>}
            {action && <div className="mt-5">{action}</div>}
        </div>
    );

    const renderPageOnboarding = () => (
        <div className="grid gap-6 lg:grid-cols-[minmax(0,1.15fr)_360px]">
            <form
                onSubmit={handleInitPlan}
                className="overflow-hidden rounded-[36px] border border-white/70 bg-white/88 shadow-[0_24px_70px_-30px_rgba(15,23,42,0.45)] backdrop-blur dark:border-slate-800 dark:bg-slate-900/88"
            >
                <div className="border-b border-slate-100 bg-[radial-gradient(circle_at_top_left,_rgba(244,114,182,0.16),_transparent_35%),radial-gradient(circle_at_top_right,_rgba(56,189,248,0.18),_transparent_30%),linear-gradient(180deg,_rgba(255,255,255,0.9),_rgba(255,255,255,0.72))] px-6 py-8 dark:border-slate-800 dark:bg-[radial-gradient(circle_at_top_left,_rgba(244,114,182,0.12),_transparent_35%),radial-gradient(circle_at_top_right,_rgba(56,189,248,0.14),_transparent_30%),linear-gradient(180deg,_rgba(15,23,42,0.92),_rgba(15,23,42,0.78))] sm:px-8">
                    <div className="inline-flex items-center gap-2 rounded-full border border-primary/15 bg-white/70 px-4 py-2 text-sm font-semibold text-primary shadow-sm dark:bg-slate-900/70">
                        <span className="material-symbols-outlined text-[18px]">auto_awesome</span>
                        {t('aiCoach.page.onboardingBadge', { defaultValue: 'Plan built from your real goal' })}
                    </div>
                    <h2 className="mt-5 text-3xl font-semibold tracking-tight text-slate-900 dark:text-white">
                        {t('aiCoach.onboarding.title')}
                    </h2>
                    <p className="mt-3 max-w-2xl text-sm leading-7 text-slate-600 dark:text-slate-300">
                        {t('aiCoach.page.onboardingDescription', {
                            defaultValue:
                                'The system combines your goal, current level, enrolled courses and daily signals to build a cleaner rhythm.'
                        })}
                    </p>
                </div>

                <div className="grid gap-5 px-6 py-6 sm:px-8">
                    <label className="block">
                        <span className="text-xs font-semibold uppercase tracking-[0.2em] text-slate-500 dark:text-slate-400">
                            {t('aiCoach.page.goalLabel', { defaultValue: 'Desired outcome' })}
                        </span>
                        <textarea
                            required
                            value={goal}
                            onChange={(event) => setGoal(event.target.value)}
                            placeholder={t('aiCoach.onboarding.goalPlaceholder')}
                            className="mt-3 min-h-[110px] w-full rounded-[26px] border border-slate-200 bg-slate-50 px-5 py-4 text-sm text-slate-700 outline-none transition focus:border-primary focus:bg-white dark:border-slate-700 dark:bg-slate-950 dark:text-slate-200 dark:focus:bg-slate-900"
                        />
                    </label>

                    <div className="grid gap-5 lg:grid-cols-2">
                        <label className="block">
                            <span className="text-xs font-semibold uppercase tracking-[0.2em] text-slate-500 dark:text-slate-400">
                                {t('aiCoach.page.currentLevelLabel', { defaultValue: 'Current knowledge' })}
                            </span>
                            <textarea
                                required
                                value={currentKnowledge}
                                onChange={(event) => setCurrentKnowledge(event.target.value)}
                                placeholder={t('aiCoach.onboarding.currentKnowledgePlaceholder')}
                                className="mt-3 min-h-[120px] w-full rounded-[26px] border border-slate-200 bg-slate-50 px-5 py-4 text-sm text-slate-700 outline-none transition focus:border-primary focus:bg-white dark:border-slate-700 dark:bg-slate-950 dark:text-slate-200 dark:focus:bg-slate-900"
                            />
                        </label>

                        <label className="block">
                            <span className="text-xs font-semibold uppercase tracking-[0.2em] text-slate-500 dark:text-slate-400">
                                {t('aiCoach.page.motivationLabel', { defaultValue: 'Main motivation' })}
                            </span>
                            <textarea
                                required
                                value={motivation}
                                onChange={(event) => setMotivation(event.target.value)}
                                placeholder={t('aiCoach.onboarding.motivationPlaceholder')}
                                className="mt-3 min-h-[120px] w-full rounded-[26px] border border-slate-200 bg-slate-50 px-5 py-4 text-sm text-slate-700 outline-none transition focus:border-primary focus:bg-white dark:border-slate-700 dark:bg-slate-950 dark:text-slate-200 dark:focus:bg-slate-900"
                            />
                        </label>
                    </div>

                    <div className="grid gap-5 lg:grid-cols-[minmax(0,1.1fr)_minmax(240px,0.9fr)]">
                        <div className="rounded-[28px] border border-slate-200 bg-slate-50 p-5 dark:border-slate-700 dark:bg-slate-950/60">
                            <div className="flex items-center justify-between gap-3">
                                <div>
                                    <div className="text-xs font-semibold uppercase tracking-[0.2em] text-slate-500 dark:text-slate-400">
                                        {t('aiCoach.page.timeBudgetLabel', { defaultValue: 'Daily time budget' })}
                                    </div>
                                    <div className="mt-2 text-3xl font-semibold text-slate-900 dark:text-white">{timeBudgetMinutesPerDay}</div>
                                </div>
                                <div className="rounded-2xl bg-white px-4 py-3 text-sm font-semibold text-slate-600 shadow-sm dark:bg-slate-900 dark:text-slate-300">
                                    {t('aiCoach.onboarding.minutesPerDay', { count: timeBudgetMinutesPerDay })}
                                </div>
                            </div>
                            <input
                                type="range"
                                min={15}
                                max={180}
                                step={5}
                                value={timeBudgetMinutesPerDay}
                                onChange={(event) => setTimeBudgetMinutesPerDay(Number(event.target.value))}
                                className="mt-5 h-2 w-full cursor-pointer appearance-none rounded-full bg-slate-200 accent-primary dark:bg-slate-700"
                            />
                            <div className="mt-3 flex items-center justify-between text-xs font-medium text-slate-500 dark:text-slate-400">
                                <span>15m</span>
                                <span>180m</span>
                            </div>
                        </div>

                        <div className="rounded-[28px] border border-slate-200 bg-slate-50 p-5 dark:border-slate-700 dark:bg-slate-950/60">
                            <div className="text-xs font-semibold uppercase tracking-[0.2em] text-slate-500 dark:text-slate-400">
                                {t('aiCoach.page.studyWindowLabel', { defaultValue: 'Preferred study window' })}
                            </div>
                            <div className="mt-4 grid grid-cols-2 gap-3">
                                {preferredStudyTimeOptions.map((option) => (
                                    <button
                                        key={option.value}
                                        type="button"
                                        onClick={() => setPreferredStudyTime(option.value)}
                                        className={`rounded-2xl px-4 py-3 text-sm font-semibold transition ${
                                            preferredStudyTime === option.value
                                                ? 'bg-slate-900 text-white shadow-lg shadow-slate-900/10 dark:bg-white dark:text-slate-900'
                                                : 'bg-white text-slate-600 hover:bg-slate-100 dark:bg-slate-900 dark:text-slate-300 dark:hover:bg-slate-800'
                                        }`}
                                    >
                                        {option.label}
                                    </button>
                                ))}
                            </div>
                        </div>
                    </div>

                    <div className="grid gap-5 lg:grid-cols-2">
                        <label className="block">
                            <span className="text-xs font-semibold uppercase tracking-[0.2em] text-slate-500 dark:text-slate-400">
                                {t('aiCoach.page.priorityCourseLabel', { defaultValue: 'Priority course' })}
                            </span>
                            <select
                                value={primaryCourseId}
                                onChange={(event) => setPrimaryCourseId(event.target.value)}
                                className="mt-3 w-full rounded-[24px] border border-slate-200 bg-slate-50 px-4 py-4 text-sm text-slate-700 outline-none transition focus:border-primary focus:bg-white dark:border-slate-700 dark:bg-slate-950 dark:text-slate-200 dark:focus:bg-slate-900"
                            >
                                <option value="">{t('aiCoach.onboarding.primaryCoursePlaceholder')}</option>
                                {enrollments.map((enrollment) => (
                                    <option key={enrollment.id} value={enrollment.courseId}>
                                        {enrollment.courseTitle}
                                    </option>
                                ))}
                            </select>
                        </label>

                        <label className="block">
                            <span className="text-xs font-semibold uppercase tracking-[0.2em] text-slate-500 dark:text-slate-400">
                                {t('aiCoach.page.constraintsLabel', { defaultValue: 'Constraints or blockers' })}
                            </span>
                            <textarea
                                value={constraints}
                                onChange={(event) => setConstraints(event.target.value)}
                                placeholder={t('aiCoach.onboarding.constraintsPlaceholder')}
                                className="mt-3 min-h-[120px] w-full rounded-[26px] border border-slate-200 bg-slate-50 px-5 py-4 text-sm text-slate-700 outline-none transition focus:border-primary focus:bg-white dark:border-slate-700 dark:bg-slate-950 dark:text-slate-200 dark:focus:bg-slate-900"
                            />
                        </label>
                    </div>

                    <div className="flex flex-wrap items-center justify-between gap-4 rounded-[28px] bg-slate-50 p-5 dark:bg-slate-950/60">
                        <div className="max-w-2xl text-sm leading-7 text-slate-600 dark:text-slate-300">
                            {t('aiCoach.page.onboardingNote', {
                                defaultValue:
                                    'The system does not invent the plan. It only adjusts inside your real courses, your actual time budget and the signals you send back each day.'
                            })}
                        </div>
                        <button
                            type="submit"
                            disabled={loading}
                            className="inline-flex items-center gap-2 rounded-full bg-slate-900 px-6 py-3 text-sm font-semibold text-white shadow-lg shadow-slate-900/15 transition hover:bg-slate-800 disabled:cursor-not-allowed disabled:opacity-60 dark:bg-white dark:text-slate-900 dark:hover:bg-slate-200"
                        >
                            <span className="material-symbols-outlined text-[18px]">auto_awesome</span>
                            {t('aiCoach.onboarding.submit')}
                        </button>
                    </div>
                </div>
            </form>

            <aside className="space-y-6">
                <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-1">
                    {[
                        {
                            label: t('aiCoach.page.previewCards.today', { defaultValue: 'Today lane' }),
                            value: primaryCourseId ? '1 core path' : 'Adaptive',
                            icon: 'calendar_today'
                        },
                        {
                            label: t('aiCoach.page.previewCards.checkIn', { defaultValue: 'End-of-day check-in' }),
                            value: t('aiCoach.page.previewCards.yes', { defaultValue: 'Enabled' }),
                            icon: 'monitor_heart'
                        },
                        {
                            label: t('aiCoach.page.previewCards.coach', { defaultValue: 'Coach' }),
                            value: t('aiCoach.page.previewCards.live', { defaultValue: 'Always on' }),
                            icon: 'person'
                        }
                    ].map((item) => (
                        <div key={item.label} className="rounded-[28px] border border-white/70 bg-white/85 p-5 shadow-sm backdrop-blur dark:border-slate-800 dark:bg-slate-900/85">
                            <div className="flex items-center justify-between gap-3">
                                <div>
                                    <div className="text-xs font-semibold uppercase tracking-[0.18em] text-slate-500 dark:text-slate-400">
                                        {item.label}
                                    </div>
                                    <div className="mt-2 text-xl font-semibold text-slate-900 dark:text-white">{item.value}</div>
                                </div>
                                <div className="flex h-12 w-12 items-center justify-center rounded-2xl bg-slate-100 text-slate-700 dark:bg-slate-800 dark:text-slate-200">
                                    <span className="material-symbols-outlined text-[22px]">{item.icon}</span>
                                </div>
                            </div>
                        </div>
                    ))}
                </div>
            </aside>
        </div>
    );

    const renderPageDashboard = () => {
        if (!statusChecked || (loading && !plan)) {
            return renderInfoState(
                'hourglass_top',
                t('common.loading', { defaultValue: 'Loading...' }),
                t('aiCoach.page.loadingDescription', {
                    defaultValue: 'Collecting progress, tasks and support signals to build your planner.'
                })
            );
        }

        if (!isStudent) {
            return renderInfoState('school', t('aiCoach.states.onlyStudents'));
        }

        if (!isEnabled) {
            return renderInfoState('person', t('aiCoach.states.disabled'));
        }

        if (!isUnlocked) {
            return renderInfoState(
                'lock',
                t('aiCoach.states.packageLockedTitle'),
                lockedDescription,
                <Link
                    to={ctaPath}
                    className="inline-flex items-center justify-center gap-2 rounded-full bg-primary px-5 py-2.5 text-sm font-semibold text-white transition hover:bg-primary/90"
                >
                    <span className="material-symbols-outlined text-[18px]">local_mall</span>
                    {t('aiCoach.states.openPricing')}
                </Link>
            );
        }

        if (!plan) {
            return renderPageOnboarding();
        }

        return (
            <div className="space-y-6">
                <div className="grid items-start gap-6 2xl:grid-cols-[minmax(0,1fr)_minmax(360px,420px)]">
                <div className="min-w-0 space-y-6">
                    <section className="overflow-hidden rounded-[34px] border border-white/70 bg-white/88 shadow-[0_24px_80px_-32px_rgba(15,23,42,0.35)] backdrop-blur dark:border-slate-800 dark:bg-slate-900/88">
                        <div className="space-y-6 border-b border-slate-100 bg-[radial-gradient(circle_at_top_left,_rgba(251,191,36,0.22),_transparent_28%),radial-gradient(circle_at_top_right,_rgba(56,189,248,0.16),_transparent_28%),linear-gradient(180deg,_rgba(255,255,255,0.92),_rgba(255,255,255,0.8))] px-5 py-6 dark:border-slate-800 dark:bg-[radial-gradient(circle_at_top_left,_rgba(251,191,36,0.12),_transparent_28%),radial-gradient(circle_at_top_right,_rgba(56,189,248,0.12),_transparent_28%),linear-gradient(180deg,_rgba(15,23,42,0.96),_rgba(15,23,42,0.82))] sm:px-6">
                            <div className="min-w-0">
                                <div className="inline-flex items-center gap-2 rounded-full border border-primary/15 bg-white/75 px-4 py-2 text-xs font-semibold uppercase tracking-[0.24em] text-primary shadow-sm dark:bg-slate-900/75">
                                    <span className="material-symbols-outlined text-[16px]">track_changes</span>
                                    {t('aiCoach.page.planBadge', { defaultValue: 'Adaptive daily plan' })}
                                </div>
                                <h2 className="mt-4 break-words text-3xl font-semibold tracking-tight text-slate-900 dark:text-white">
                                    {plan.goal}
                                </h2>
                                <p className="mt-3 max-w-3xl break-words text-sm leading-7 text-slate-600 dark:text-slate-300">
                                    {guidanceMessage ||
                                        t('aiCoach.page.goalFallback', {
                                            defaultValue: 'The system keeps this goal on track and adjusts tomorrow from your daily feedback.'
                                        })}
                                </p>
                            </div>

                            <div className="grid gap-3 sm:grid-cols-3">
                                {[
                                    {
                                        label: t('aiCoach.page.metrics.streak', { defaultValue: 'Streak' }),
                                        value: plan.currentStreakDays,
                                        suffix: t('aiCoach.page.metrics.days', { defaultValue: 'days' }),
                                        icon: 'local_fire_department'
                                    },
                                    {
                                        label: t('aiCoach.page.metrics.focusMinutes', { defaultValue: 'Time budget' }),
                                        value: planMinutes,
                                        suffix: 'min',
                                        icon: 'timer'
                                    },
                                    {
                                        label: t('aiCoach.page.metrics.version', { defaultValue: 'Plan version' }),
                                        value: plan.planVersion,
                                        suffix: '',
                                        icon: 'tune'
                                    }
                                ].map((metric) => (
                                    <div key={metric.label} className="rounded-[26px] border border-white/80 bg-white/80 p-4 shadow-sm dark:border-slate-800 dark:bg-slate-950/70">
                                        <div className="flex items-center justify-between gap-3">
                                            <div>
                                                <div className="text-xs font-semibold uppercase tracking-[0.18em] text-slate-500 dark:text-slate-400">
                                                    {metric.label}
                                                </div>
                                                <div className="mt-2 text-2xl font-semibold text-slate-900 dark:text-white">
                                                    {metric.value}
                                                    {metric.suffix ? <span className="ml-1 text-sm font-medium text-slate-500 dark:text-slate-400">{metric.suffix}</span> : null}
                                                </div>
                                            </div>
                                            <div className="flex h-12 w-12 items-center justify-center rounded-2xl bg-slate-100 text-slate-700 dark:bg-slate-800 dark:text-slate-200">
                                                <span className="material-symbols-outlined text-[22px]">{metric.icon}</span>
                                            </div>
                                        </div>
                                    </div>
                                ))}
                            </div>
                        </div>

                        <div className="flex flex-wrap items-center gap-3 px-5 py-4 sm:px-6">
                            {weekDates.map((date) => {
                                const active = isSameDay(date, selectedDate);
                                const isToday = isSameDay(date, today);
                                return (
                                    <button
                                        key={format(date, 'yyyy-MM-dd')}
                                        type="button"
                                        onClick={() => setSelectedDateKey(format(date, 'yyyy-MM-dd'))}
                                        className={`min-w-[78px] rounded-[24px] px-4 py-3 text-left transition ${
                                            active
                                                ? 'bg-slate-900 text-white shadow-lg shadow-slate-900/15 dark:bg-white dark:text-slate-900'
                                                : 'bg-slate-50 text-slate-700 hover:bg-slate-100 dark:bg-slate-950/60 dark:text-slate-200 dark:hover:bg-slate-900'
                                        }`}
                                    >
                                        <div className={`text-[11px] font-semibold uppercase tracking-[0.22em] ${active ? 'text-white/75 dark:text-slate-500' : 'text-slate-400 dark:text-slate-500'}`}>
                                            {formatCalendarDate(date, { weekday: 'short' })}
                                        </div>
                                        <div className="mt-2 flex items-center gap-2">
                                            <span className="text-2xl font-semibold">{formatCalendarDate(date, { day: 'numeric' })}</span>
                                            {isToday && (
                                                <span className={`rounded-full px-2 py-0.5 text-[10px] font-semibold uppercase tracking-[0.18em] ${active ? 'bg-white/15 text-white dark:bg-slate-900 dark:text-white' : 'bg-primary/10 text-primary'}`}>
                                                    {t('aiCoach.page.todayPill', { defaultValue: 'Today' })}
                                                </span>
                                            )}
                                        </div>
                                    </button>
                                );
                            })}
                        </div>
                    </section>

                    {!isTodaySelected ? (
                        <section className="rounded-[32px] border border-dashed border-slate-300 bg-white/75 px-6 py-10 text-center shadow-sm dark:border-slate-700 dark:bg-slate-900/75">
                            <div className="mx-auto flex h-16 w-16 items-center justify-center rounded-full bg-slate-100 text-slate-700 dark:bg-slate-800 dark:text-slate-200">
                                <span className="material-symbols-outlined text-[28px]">schedule</span>
                            </div>
                            <h3 className="mt-5 text-2xl font-semibold text-slate-900 dark:text-white">
                                {t('aiCoach.page.futureStateTitle', { defaultValue: 'This day will unlock when it is due.' })}
                            </h3>
                            <p className="mx-auto mt-3 max-w-2xl text-sm leading-7 text-slate-600 dark:text-slate-300">
                                {t('aiCoach.page.futureStateDescription', {
                                    defaultValue:
                                        'The planner only shows the amount of work that matters today. Finish today and submit check-in to unlock the next day.'
                                })}
                            </p>
                            <button
                                type="button"
                                onClick={() => setSelectedDateKey(format(today, 'yyyy-MM-dd'))}
                                className="mt-6 inline-flex items-center gap-2 rounded-full bg-slate-900 px-5 py-3 text-sm font-semibold text-white transition hover:bg-slate-800 dark:bg-white dark:text-slate-900 dark:hover:bg-slate-200"
                            >
                                <span className="material-symbols-outlined text-[18px]">today</span>
                                {t('aiCoach.page.backToToday', { defaultValue: 'Back to today' })}
                            </button>
                        </section>
                    ) : (
                        <>
                            {featuredTask ? (
                                <section className="overflow-hidden rounded-[34px] border border-white/70 bg-white/88 shadow-[0_24px_80px_-36px_rgba(15,23,42,0.45)] backdrop-blur dark:border-slate-800 dark:bg-slate-900/88">
                                    <div className="grid gap-0 lg:grid-cols-[320px_minmax(0,1fr)]">
                                        <div className="relative min-h-[280px] overflow-hidden bg-slate-200 dark:bg-slate-800">
                                            {primaryEnrollment?.courseThumbnail ? (
                                                <img
                                                    src={primaryEnrollment.courseThumbnail}
                                                    alt={featuredTask.title}
                                                    className="h-full w-full object-cover"
                                                />
                                            ) : (
                                                <div className="absolute inset-0 bg-[radial-gradient(circle_at_top_left,_rgba(251,191,36,0.35),_transparent_32%),radial-gradient(circle_at_bottom_right,_rgba(56,189,248,0.4),_transparent_30%),linear-gradient(160deg,_#0f172a,_#1e293b)]" />
                                            )}
                                            <div className="absolute inset-x-0 bottom-0 bg-gradient-to-t from-slate-950/70 via-slate-950/20 to-transparent p-6 text-white">
                                                <div className={`inline-flex items-center gap-2 rounded-full bg-white/12 px-3 py-2 text-xs font-semibold uppercase tracking-[0.2em] backdrop-blur ${getTaskTypeMeta(featuredTask.taskType).badge}`}>
                                                    <span className="material-symbols-outlined text-[16px]">{getTaskTypeMeta(featuredTask.taskType).icon}</span>
                                                    {getTaskTypeMeta(featuredTask.taskType).label}
                                                </div>
                                                <div className="mt-4 text-sm font-medium text-white/80">
                                                    {featuredTask.relatedCourseTitle || plan.primaryCourseTitle || t('aiCoach.page.generalTrack', { defaultValue: 'General track' })}
                                                </div>
                                            </div>
                                        </div>

                                        <div className="min-w-0 flex flex-col justify-between p-6 sm:p-8">
                                            <div className="min-w-0">
                                                <div className="text-xs font-semibold uppercase tracking-[0.22em] text-slate-500 dark:text-slate-400">
                                                    {t('aiCoach.page.todayHeadline', {
                                                        defaultValue: 'Today, {{date}}',
                                                        date: formatCalendarDate(today, { month: 'long', day: 'numeric' })
                                                    })}
                                                </div>
                                                <h3 className="mt-4 break-words text-3xl font-semibold tracking-tight text-slate-900 dark:text-white">
                                                    {featuredTask.title}
                                                </h3>
                                                <p className="mt-4 break-words text-sm leading-7 text-slate-600 dark:text-slate-300">{featuredTask.content}</p>

                                                <div className="mt-5 flex flex-wrap items-center gap-3 text-sm text-slate-500 dark:text-slate-400">
                                                    <span className="inline-flex items-center gap-2 rounded-full bg-slate-100 px-3 py-2 dark:bg-slate-800">
                                                        <span className="material-symbols-outlined text-[16px]">schedule</span>
                                                        {t('aiCoach.tasks.minutes', { count: featuredTask.estimatedMinutes })}
                                                    </span>
                                                    {featuredTask.relatedLessonTitle && (
                                                        <span className="inline-flex items-center gap-2 rounded-full bg-slate-100 px-3 py-2 dark:bg-slate-800">
                                                            <span className="material-symbols-outlined text-[16px]">book_2</span>
                                                            {featuredTask.relatedLessonTitle}
                                                        </span>
                                                    )}
                                                    {featuredTask.isCompleted && (
                                                        <span className="inline-flex items-center gap-2 rounded-full bg-emerald-500/10 px-3 py-2 font-semibold text-emerald-700 dark:text-emerald-300">
                                                            <span className="material-symbols-outlined text-[16px]">check_circle</span>
                                                            {t('aiCoach.page.completedBadge', { defaultValue: 'Completed' })}
                                                        </span>
                                                    )}
                                                </div>
                                            </div>

                                            <div className="mt-8 flex flex-wrap items-center gap-3">
                                                <Link
                                                    to={featuredTask.relatedCourseId ? `/courses/${featuredTask.relatedCourseId}/learn` : '/my-courses'}
                                                    className="inline-flex items-center gap-2 rounded-full bg-[#ef4444] px-6 py-3 text-sm font-semibold text-white shadow-lg shadow-rose-500/25 transition hover:bg-[#dc2626]"
                                                >
                                                    <span className="material-symbols-outlined text-[18px]">play_arrow</span>
                                                    {t('aiCoach.page.startFocusTask', { defaultValue: 'Start focus task' })}
                                                </Link>
                                                <button
                                                    type="button"
                                                    onClick={() => resetTaskForm(featuredTask)}
                                                    className="inline-flex items-center gap-2 rounded-full border border-slate-200 px-5 py-3 text-sm font-semibold text-slate-700 transition hover:border-slate-300 hover:text-slate-900 dark:border-slate-700 dark:text-slate-200 dark:hover:border-slate-600 dark:hover:text-white"
                                                >
                                                    <span className="material-symbols-outlined text-[18px]">edit_note</span>
                                                    {t('aiCoach.tasks.update')}
                                                </button>
                                            </div>
                                        </div>
                                    </div>
                                </section>
                            ) : (
                                <section className="rounded-[32px] border border-white/70 bg-white/88 px-6 py-10 text-center shadow-sm backdrop-blur dark:border-slate-800 dark:bg-slate-900/88">
                                    <div className="mx-auto flex h-16 w-16 items-center justify-center rounded-full bg-emerald-500/10 text-emerald-600 dark:text-emerald-300">
                                        <span className="material-symbols-outlined text-[28px]">verified</span>
                                    </div>
                                    <h3 className="mt-5 text-2xl font-semibold text-slate-900 dark:text-white">{t('aiCoach.tasks.empty')}</h3>
                                    <p className="mx-auto mt-3 max-w-2xl text-sm leading-7 text-slate-600 dark:text-slate-300">
                                        {t('aiCoach.page.emptyDayDescription', {
                                            defaultValue: 'Keep using your daily log so the plan can keep rhythm and adjust tomorrow.'
                                        })}
                                    </p>
                                </section>
                            )}

                            {selectedTask ? renderTaskEditor(selectedTask) : null}

                            <section className="space-y-4">
                                <div className="flex items-center justify-between gap-4">
                                    <div>
                                        <div className="text-xs font-semibold uppercase tracking-[0.22em] text-slate-500 dark:text-slate-400">
                                            {t('aiCoach.page.taskRailEyebrow', { defaultValue: 'Daily flow' })}
                                        </div>
                                        <h3 className="mt-2 text-2xl font-semibold text-slate-900 dark:text-white">
                                            {t('aiCoach.page.taskRailTitle', { defaultValue: 'Remaining touchpoints today' })}
                                        </h3>
                                    </div>
                                    {openSupportAlerts > 0 && (
                                        <div className="rounded-full bg-amber-500/10 px-4 py-2 text-sm font-semibold text-amber-700 dark:text-amber-300">
                                            {t('aiCoach.tasks.openSupportAlerts', { count: openSupportAlerts })}
                                        </div>
                                    )}
                                </div>

                                {secondaryTasks.length > 0 ? (
                                    <div className="space-y-4">
                                        {secondaryTasks.map((task) => {
                                            const meta = getTaskTypeMeta(task.taskType);
                                            return (
                                                <article
                                                    key={task.id}
                                                    className="grid gap-5 rounded-[30px] border border-white/70 bg-white/88 p-5 shadow-sm backdrop-blur transition hover:shadow-md dark:border-slate-800 dark:bg-slate-900/88 lg:grid-cols-[auto_minmax(0,1fr)_auto]"
                                                >
                                                    <div className={`flex h-16 w-16 items-center justify-center rounded-[22px] bg-gradient-to-br ${meta.badge}`}>
                                                        <span className="material-symbols-outlined text-[28px]">{meta.icon}</span>
                                                    </div>
                                                    <div className="min-w-0">
                                                        <div className="text-sm font-semibold text-slate-500 dark:text-slate-400">{meta.label}</div>
                                                        <h4 className="mt-1 break-words text-xl font-semibold text-slate-900 dark:text-white">{task.title}</h4>
                                                        <p className="mt-2 break-words text-sm leading-7 text-slate-600 dark:text-slate-300">{task.content}</p>
                                                        <div className="mt-4 flex flex-wrap items-center gap-3 text-sm text-slate-500 dark:text-slate-400">
                                                            <span>{t('aiCoach.tasks.minutes', { count: task.estimatedMinutes })}</span>
                                                            {task.relatedLessonTitle && <span>{task.relatedLessonTitle}</span>}
                                                            {task.userFeedback && (
                                                                <span className="rounded-full bg-slate-100 px-3 py-1.5 text-xs font-semibold text-slate-600 dark:bg-slate-800 dark:text-slate-300">
                                                                    {t('aiCoach.page.feedbackLogged', { defaultValue: 'Feedback logged' })}
                                                                </span>
                                                            )}
                                                        </div>
                                                    </div>
                                                    <div className="flex flex-col items-start gap-3 lg:items-end">
                                                        <button
                                                            type="button"
                                                            onClick={() => resetTaskForm(task)}
                                                            className="inline-flex items-center gap-2 rounded-full border border-slate-200 px-4 py-2 text-sm font-semibold text-slate-700 transition hover:border-slate-300 hover:text-slate-900 dark:border-slate-700 dark:text-slate-200 dark:hover:border-slate-600 dark:hover:text-white"
                                                        >
                                                            <span className="material-symbols-outlined text-[18px]">edit_note</span>
                                                            {task.isCompleted
                                                                ? t('aiCoach.page.reviewTask', { defaultValue: 'Review' })
                                                                : t('aiCoach.page.updateTask', { defaultValue: 'Update' })}
                                                        </button>
                                                        {task.relatedCourseId && (
                                                            <Link
                                                                to={`/courses/${task.relatedCourseId}/learn`}
                                                                className="inline-flex items-center gap-2 text-sm font-semibold text-primary hover:text-primary-light"
                                                            >
                                                                {t('aiCoach.page.openLesson', { defaultValue: 'Open lesson' })}
                                                                <span className="material-symbols-outlined text-[18px]">arrow_forward</span>
                                                            </Link>
                                                        )}
                                                    </div>
                                                </article>
                                            );
                                        })}
                                    </div>
                                ) : featuredTask ? null : (
                                    <div className="rounded-[28px] border border-dashed border-slate-300 bg-white/75 px-6 py-8 text-sm leading-7 text-slate-600 dark:border-slate-700 dark:bg-slate-900/75 dark:text-slate-300">
                                        {t('aiCoach.page.noMoreItems', {
                                            defaultValue: 'No extra steps are left today. Use your daily log and coach support to close the day cleanly.'
                                        })}
                                    </div>
                                )}
                            </section>
                        </>
                    )}
                </div>

                <aside className="grid gap-6 md:grid-cols-2 2xl:sticky 2xl:top-24 2xl:grid-cols-1 2xl:self-start">
                    <section className="rounded-[32px] border border-white/70 bg-white/88 p-6 shadow-sm backdrop-blur dark:border-slate-800 dark:bg-slate-900/88">
                        <div className="flex items-center justify-between gap-3">
                            <div>
                                <div className="text-xs font-semibold uppercase tracking-[0.22em] text-slate-500 dark:text-slate-400">
                                    {t('aiCoach.page.sidebarTitle', { defaultValue: 'Statistics' })}
                                </div>
                                <h3 className="mt-2 break-words text-2xl font-semibold text-slate-900 dark:text-white">
                                    {t('aiCoach.page.sidebarHeadline', { defaultValue: 'Today pulse' })}
                                </h3>
                            </div>
                            <div className="flex h-12 w-12 items-center justify-center rounded-2xl bg-slate-100 text-slate-700 dark:bg-slate-800 dark:text-slate-200">
                                <span className="material-symbols-outlined text-[22px]">monitoring</span>
                            </div>
                        </div>

                        <div className="mt-5 space-y-3">
                            {[
                                {
                                    label: t('aiCoach.page.metrics.tasksDone', { defaultValue: 'Tasks handled' }),
                                    value: `${completedTasks}/${Math.max(tasks.length, 1)}`,
                                    icon: 'task_alt',
                                    accent: 'bg-rose-500/10 text-rose-600 dark:text-rose-300'
                                },
                                {
                                    label: t('aiCoach.page.metrics.plannedMinutes', { defaultValue: 'Focus minutes' }),
                                    value: `${actualMinutes}/${planMinutes} min`,
                                    icon: 'timer',
                                    accent: 'bg-emerald-500/10 text-emerald-600 dark:text-emerald-300'
                                },
                                {
                                    label: t('aiCoach.page.metrics.supportSignals', { defaultValue: 'Support signals' }),
                                    value: `${openSupportAlerts}`,
                                    icon: 'notifications_active',
                                    accent: 'bg-sky-500/10 text-sky-600 dark:text-sky-300'
                                }
                            ].map((item) => (
                                <div key={item.label} className="flex items-center gap-4 rounded-[24px] border border-slate-200 bg-slate-50 p-4 dark:border-slate-700 dark:bg-slate-950/60">
                                    <div className={`flex h-14 w-14 items-center justify-center rounded-2xl ${item.accent}`}>
                                        <span className="material-symbols-outlined text-[24px]">{item.icon}</span>
                                    </div>
                                    <div>
                                        <div className="text-sm text-slate-500 dark:text-slate-400">{item.label}</div>
                                        <div className="mt-1 text-2xl font-semibold text-slate-900 dark:text-white">{item.value}</div>
                                    </div>
                                </div>
                            ))}
                        </div>

                        <div className="mt-5">
                            <div className="mb-2 flex items-center justify-between text-xs font-semibold uppercase tracking-[0.18em] text-slate-500 dark:text-slate-400">
                                <span>{t('aiCoach.page.metrics.completionRate', { defaultValue: 'Completion rate' })}</span>
                                <span>{completionRate}%</span>
                            </div>
                            <div className="h-3 rounded-full bg-slate-100 dark:bg-slate-800">
                                <div className="h-3 rounded-full bg-gradient-to-r from-rose-500 via-orange-500 to-amber-400" style={{ width: `${completionRate}%` }} />
                            </div>
                        </div>
                    </section>

                    <section className="overflow-hidden rounded-[32px] border border-slate-900 bg-slate-950 text-white shadow-[0_26px_80px_-32px_rgba(15,23,42,0.92)]">
                        <div className="bg-[radial-gradient(circle_at_top_left,_rgba(244,114,182,0.28),_transparent_30%),radial-gradient(circle_at_bottom_right,_rgba(56,189,248,0.24),_transparent_34%)] p-6">
                            <div className="flex items-center justify-between gap-3">
                                <div>
                                    <div className="text-xs font-semibold uppercase tracking-[0.22em] text-white/60">
                                        {t('aiCoach.page.coachLaneEyebrow', { defaultValue: 'Coach lane' })}
                                    </div>
                                    <p className="mt-2 break-words text-2xl font-semibold text-white">
                                        {t('aiCoach.page.coachLaneTitle', { defaultValue: 'Coach support in the loop' })}
                                    </p>
                                </div>
                                <button
                                    type="button"
                                    onClick={() => void handleOpenChat()}
                                    className="inline-flex items-center gap-2 rounded-full bg-white/10 px-4 py-2 text-sm font-semibold text-white transition hover:bg-white/15"
                                >
                                    <span className="material-symbols-outlined text-[18px]">forum</span>
                                    {t('aiCoach.tabs.coach')}
                                </button>
                            </div>

                            <p className="mt-4 break-words text-sm leading-7 text-white/75">
                                {guidanceMessage ||
                                    t('aiCoach.page.coachFallback', {
                                        defaultValue: 'The coach reads task feedback, mood and tomorrow capacity to keep your plan realistic.'
                                    })}
                            </p>

                            <div className="mt-5 grid gap-3">
                                {quickStatusOptions.map((option) => (
                                    <button
                                        key={option.label}
                                        type="button"
                                        disabled={loading}
                                        onClick={() => void sendPromptToCoach(option.prompt)}
                                        className="flex items-center gap-3 rounded-[22px] border border-white/10 bg-white/6 px-4 py-3 text-left text-sm font-medium text-white/85 transition hover:bg-white/10 disabled:cursor-not-allowed disabled:opacity-60"
                                    >
                                        <span className="material-symbols-outlined text-[20px]">{option.icon}</span>
                                        <span>{option.label}</span>
                                    </button>
                                ))}
                            </div>

                            <div className="mt-5 rounded-[24px] border border-white/10 bg-black/20 p-4">
                                <div className="mb-3 text-xs font-semibold uppercase tracking-[0.18em] text-white/55">
                                    {t('aiCoach.page.chatPreviewTitle', { defaultValue: 'Latest conversation' })}
                                </div>
                                <div className="max-h-64 space-y-3 overflow-y-auto pr-1">
                                    {chatHistory.length > 0 ? (
                                        chatHistory.slice(-4).map((message) => (
                                            <div
                                                key={message.id}
                                                className={`rounded-[20px] break-words px-4 py-3 text-sm leading-6 ${
                                                    message.role === 'user'
                                                        ? 'ml-8 bg-white text-slate-900'
                                                        : 'mr-8 bg-white/10 text-white/85'
                                                }`}
                                            >
                                                {message.content}
                                            </div>
                                        ))
                                    ) : (
                                        <div className="rounded-[20px] break-words bg-white/8 px-4 py-4 text-sm leading-6 text-white/70">
                                            {t('aiCoach.page.chatPreviewEmpty', {
                                                defaultValue: 'No conversation yet. Use a quick status or ask the coach directly.'
                                            })}
                                        </div>
                                    )}
                                    <div ref={chatEndRef} />
                                </div>
                                <form onSubmit={handleSendChat} className="mt-4 flex gap-3">
                                    <input
                                        value={chatInput}
                                        onChange={(event) => setChatInput(event.target.value)}
                                        placeholder={t('aiCoach.chat.placeholder')}
                                        className="min-w-0 flex-1 rounded-full border border-white/10 bg-white/10 px-4 py-3 text-sm text-white outline-none placeholder:text-white/45 focus:border-white/20"
                                    />
                                    <button
                                        type="submit"
                                        disabled={loading || !chatInput.trim()}
                                        className="inline-flex items-center justify-center rounded-full bg-white px-4 py-3 text-sm font-semibold text-slate-900 transition hover:bg-slate-100 disabled:cursor-not-allowed disabled:opacity-60"
                                    >
                                        {t('aiCoach.chat.send')}
                                    </button>
                                </form>
                            </div>
                        </div>
                    </section>

                </aside>

            </div>

            <section className="rounded-[32px] border border-white/70 bg-white/88 p-6 shadow-sm backdrop-blur dark:border-slate-800 dark:bg-slate-900/88">
                <div className="flex items-center justify-between gap-3">
                    <div>
                        <div className="text-xs font-semibold uppercase tracking-[0.22em] text-slate-500 dark:text-slate-400">
                            {t('aiCoach.tabs.checkIn')}
                        </div>
                        <h3 className="mt-2 text-2xl font-semibold text-slate-900 dark:text-white">
                            {t('aiCoach.page.checkInHeadline', { defaultValue: 'Close the day and shape tomorrow' })}
                        </h3>
                    </div>
                    <div className="flex h-12 w-12 items-center justify-center rounded-2xl bg-slate-100 text-slate-700 dark:bg-slate-800 dark:text-slate-200">
                        <span className="material-symbols-outlined text-[22px]">favorite</span>
                    </div>
                </div>

                <form onSubmit={handleSubmitCheckIn} className="mt-5 space-y-5">
                    {renderScorePills(t('aiCoach.checkIn.mood'), moodScore, setMoodScore)}
                    {renderScorePills(t('aiCoach.checkIn.energy'), energyScore, setEnergyScore)}
                    {renderScorePills(t('aiCoach.checkIn.confidence'), confidenceScore, setConfidenceScore)}

                    <div className="grid gap-4 sm:grid-cols-2">
                        <label className="block">
                            <span className="text-xs font-semibold uppercase tracking-[0.18em] text-slate-500 dark:text-slate-400">
                                {t('aiCoach.checkIn.actualMinutesPlaceholder')}
                            </span>
                            <input
                                type="number"
                                min={0}
                                max={720}
                                value={actualMinutesSpentToday}
                                onChange={(event) => setActualMinutesSpentToday(Number(event.target.value))}
                                className="mt-3 w-full rounded-2xl border border-slate-200 bg-slate-50 px-4 py-3 text-sm text-slate-700 outline-none transition focus:border-primary dark:border-slate-700 dark:bg-slate-950 dark:text-slate-200"
                            />
                        </label>

                        <label className="block">
                            <span className="text-xs font-semibold uppercase tracking-[0.18em] text-slate-500 dark:text-slate-400">
                                {t('aiCoach.checkIn.tomorrowMinutesPlaceholder')}
                            </span>
                            <input
                                type="number"
                                min={0}
                                max={720}
                                value={minutesAvailableTomorrow}
                                onChange={(event) => setMinutesAvailableTomorrow(Number(event.target.value))}
                                className="mt-3 w-full rounded-2xl border border-slate-200 bg-slate-50 px-4 py-3 text-sm text-slate-700 outline-none transition focus:border-primary dark:border-slate-700 dark:bg-slate-950 dark:text-slate-200"
                            />
                        </label>
                    </div>

                    <label className="block">
                        <span className="text-xs font-semibold uppercase tracking-[0.18em] text-slate-500 dark:text-slate-400">
                            {t('aiCoach.page.checkInNotesLabel', { defaultValue: 'Daily signal' })}
                        </span>
                        <textarea
                            value={checkInNotes}
                            onChange={(event) => setCheckInNotes(event.target.value)}
                            placeholder={t('aiCoach.checkIn.notesPlaceholder')}
                            className="mt-3 min-h-[120px] w-full rounded-[24px] border border-slate-200 bg-slate-50 px-4 py-4 text-sm text-slate-700 outline-none transition focus:border-primary dark:border-slate-700 dark:bg-slate-950 dark:text-slate-200"
                        />
                    </label>

                    <label className="flex items-start gap-3 rounded-[24px] border border-slate-200 bg-slate-50 px-4 py-4 text-sm text-slate-600 dark:border-slate-700 dark:bg-slate-950 dark:text-slate-300">
                        <input
                            type="checkbox"
                            checked={checkInNeedsSupport}
                            onChange={(event) => setCheckInNeedsSupport(event.target.checked)}
                            className="mt-1 h-4 w-4 rounded border-slate-300 text-primary focus:ring-primary"
                        />
                        <span>{t('aiCoach.checkIn.needSupport')}</span>
                    </label>

                    {latestCheckIn?.coachAdvice && (
                        <div className="rounded-[24px] border border-primary/15 bg-primary/5 px-4 py-4 text-sm leading-7 text-slate-700 dark:border-primary/20 dark:bg-primary/10 dark:text-slate-200">
                            <div className="text-xs font-semibold uppercase tracking-[0.18em] text-primary">
                                {t('aiCoach.page.latestCoachAdvice', { defaultValue: 'Latest coach note' })}
                            </div>
                            <p className="mt-2">{latestCheckIn.coachAdvice}</p>
                        </div>
                    )}

                    <button
                        type="submit"
                        disabled={loading}
                        className="inline-flex w-full items-center justify-center gap-2 rounded-full bg-slate-900 px-5 py-3 text-sm font-semibold text-white transition hover:bg-slate-800 disabled:cursor-not-allowed disabled:opacity-60 dark:bg-white dark:text-slate-900 dark:hover:bg-slate-200"
                    >
                        <span className="material-symbols-outlined text-[18px]">done_all</span>
                        {t('aiCoach.checkIn.submit')}
                    </button>
                </form>
            </section>
            </div>
        );
    };

    const renderWidgetDashboard = () => {
        if (!statusChecked) {
            return (
                <div className="w-[min(92vw,380px)] rounded-[28px] border border-white/70 bg-white/92 p-6 shadow-2xl backdrop-blur dark:border-slate-800 dark:bg-slate-900/92">
                    <div className="text-sm font-semibold text-slate-900 dark:text-white">{t('common.loading', { defaultValue: 'Loading...' })}</div>
                </div>
            );
        }

        if (!isStudent) {
            return (
                <div className="w-[min(92vw,380px)] rounded-[28px] border border-white/70 bg-white/92 p-6 shadow-2xl backdrop-blur dark:border-slate-800 dark:bg-slate-900/92">
                    <div className="text-sm text-slate-700 dark:text-slate-300">{t('aiCoach.states.onlyStudents')}</div>
                </div>
            );
        }

        if (!isEnabled) {
            return (
                <div className="w-[min(92vw,380px)] rounded-[28px] border border-white/70 bg-white/92 p-6 shadow-2xl backdrop-blur dark:border-slate-800 dark:bg-slate-900/92">
                    <div className="text-sm text-slate-700 dark:text-slate-300">{t('aiCoach.states.disabled')}</div>
                </div>
            );
        }

        if (!isUnlocked) {
            return (
                <div className="w-[min(92vw,380px)] rounded-[28px] border border-white/70 bg-white/92 p-6 shadow-2xl backdrop-blur dark:border-slate-800 dark:bg-slate-900/92">
                    <div className="text-sm font-semibold text-slate-900 dark:text-white">
                        {t('aiCoach.states.packageLockedTitle')}
                    </div>
                    <p className="mt-2 text-sm leading-6 text-slate-700 dark:text-slate-300">{lockedDescription}</p>
                    <Link
                        to={ctaPath}
                        className="mt-4 inline-flex items-center justify-center gap-2 rounded-full bg-primary px-4 py-2 text-xs font-semibold text-white transition hover:bg-primary/90"
                    >
                        <span className="material-symbols-outlined text-[16px]">local_mall</span>
                        {t('aiCoach.states.openPricing')}
                    </Link>
                </div>
            );
        }

        return (
            <div className="w-[min(92vw,380px)] overflow-hidden rounded-[28px] border border-white/70 bg-white/92 shadow-2xl backdrop-blur dark:border-slate-800 dark:bg-slate-900/92">
                <div className="border-b border-slate-100 bg-[radial-gradient(circle_at_top_left,_rgba(251,191,36,0.18),_transparent_34%),radial-gradient(circle_at_top_right,_rgba(56,189,248,0.16),_transparent_30%)] px-5 py-5 dark:border-slate-800">
                    <div className="flex items-start justify-between gap-4">
                        <div className="min-w-0">
                            <div className="inline-flex items-center gap-2 rounded-full bg-white/75 px-3 py-2 text-xs font-semibold uppercase tracking-[0.18em] text-primary shadow-sm dark:bg-slate-900/75">
                                <span className="material-symbols-outlined text-[16px]">person</span>
                                {t('aiCoach.title')}
                            </div>
                            <h3 className="mt-3 break-words text-xl font-semibold text-slate-900 dark:text-white">
                                {plan?.goal || t('aiCoach.startHint')}
                            </h3>
                            {plan && (
                                <p className="mt-2 text-sm text-slate-600 dark:text-slate-300">
                                    {t('aiCoach.streak', { count: plan.currentStreakDays })}
                                </p>
                            )}
                        </div>

                        <div className="flex items-center gap-2">
                            <Link
                                to="/my-learning-plan"
                                className="inline-flex items-center gap-2 rounded-full border border-slate-200 bg-white/75 px-3 py-2 text-xs font-semibold uppercase tracking-[0.16em] text-slate-700 shadow-sm dark:border-slate-700 dark:bg-slate-900/75 dark:text-slate-200"
                            >
                                <span className="material-symbols-outlined text-[16px]">open_in_full</span>
                                {t('aiCoach.navigation.openPage')}
                            </Link>
                            {onClose && (
                                <button
                                    type="button"
                                    onClick={onClose}
                                    className="inline-flex h-10 w-10 items-center justify-center rounded-full border border-slate-200 bg-white/75 text-slate-600 shadow-sm transition hover:text-slate-900 dark:border-slate-700 dark:bg-slate-900/75 dark:text-slate-300 dark:hover:text-white"
                                >
                                    <span className="material-symbols-outlined text-[18px]">close</span>
                                </button>
                            )}
                        </div>
                    </div>
                </div>

                {!plan ? (
                    <form onSubmit={handleInitPlan} className="space-y-4 p-5">
                        <textarea
                            required
                            value={goal}
                            onChange={(event) => setGoal(event.target.value)}
                            placeholder={t('aiCoach.onboarding.goalPlaceholder')}
                            className="min-h-[90px] w-full rounded-[22px] border border-slate-200 bg-slate-50 px-4 py-3 text-sm text-slate-700 outline-none transition focus:border-primary dark:border-slate-700 dark:bg-slate-950 dark:text-slate-200"
                        />
                        <textarea
                            required
                            value={currentKnowledge}
                            onChange={(event) => setCurrentKnowledge(event.target.value)}
                            placeholder={t('aiCoach.onboarding.currentKnowledgePlaceholder')}
                            className="min-h-[90px] w-full rounded-[22px] border border-slate-200 bg-slate-50 px-4 py-3 text-sm text-slate-700 outline-none transition focus:border-primary dark:border-slate-700 dark:bg-slate-950 dark:text-slate-200"
                        />
                        <textarea
                            required
                            value={motivation}
                            onChange={(event) => setMotivation(event.target.value)}
                            placeholder={t('aiCoach.onboarding.motivationPlaceholder')}
                            className="min-h-[90px] w-full rounded-[22px] border border-slate-200 bg-slate-50 px-4 py-3 text-sm text-slate-700 outline-none transition focus:border-primary dark:border-slate-700 dark:bg-slate-950 dark:text-slate-200"
                        />
                        <button
                            type="submit"
                            disabled={loading}
                            className="inline-flex w-full items-center justify-center gap-2 rounded-full bg-slate-900 px-5 py-3 text-sm font-semibold text-white transition hover:bg-slate-800 disabled:cursor-not-allowed disabled:opacity-60 dark:bg-white dark:text-slate-900 dark:hover:bg-slate-200"
                        >
                            <span className="material-symbols-outlined text-[18px]">auto_awesome</span>
                            {t('aiCoach.onboarding.submit')}
                        </button>
                    </form>
                ) : (
                    <div className="p-5">
                        <div className="mb-4 flex gap-2 rounded-full bg-slate-100 p-1 dark:bg-slate-800">
                            {([
                                { key: 'tasks', label: t('aiCoach.tabs.today') },
                                { key: 'checkin', label: t('aiCoach.tabs.checkIn') },
                                { key: 'chat', label: t('aiCoach.tabs.coach') }
                            ] as Array<{ key: View; label: string }>).map((item) => (
                                <button
                                    key={item.key}
                                    type="button"
                                    onClick={() => {
                                        setView(item.key);
                                        if (item.key === 'chat') {
                                            void handleOpenChat();
                                        }
                                    }}
                                    className={`flex-1 rounded-full px-3 py-2 text-sm font-semibold transition ${
                                        view === item.key
                                            ? 'bg-white text-slate-900 shadow-sm dark:bg-slate-900 dark:text-white'
                                            : 'text-slate-500 dark:text-slate-300'
                                    }`}
                                >
                                    {item.label}
                                </button>
                            ))}
                        </div>

                        {view === 'tasks' && (
                            <div className="space-y-4">
                                {tasks.length > 0 ? (
                                    tasks.map((task) => (
                                        <div key={task.id} className="rounded-[24px] border border-slate-200 bg-slate-50 p-4 dark:border-slate-700 dark:bg-slate-950/60">
                                            <div className="flex items-start justify-between gap-3">
                                                <div className="min-w-0">
                                                    <div className="text-xs font-semibold uppercase tracking-[0.18em] text-slate-500 dark:text-slate-400">
                                                        {getTaskTypeMeta(task.taskType).label}
                                                    </div>
                                                    <h4 className="mt-2 break-words text-lg font-semibold text-slate-900 dark:text-white">{task.title}</h4>
                                                </div>
                                                <span className="rounded-full bg-white px-3 py-1 text-xs font-semibold text-slate-600 shadow-sm dark:bg-slate-900 dark:text-slate-300">
                                                    {t('aiCoach.tasks.minutes', { count: task.estimatedMinutes })}
                                                </span>
                                            </div>
                                            <p className="mt-3 break-words text-sm leading-7 text-slate-600 dark:text-slate-300">{task.content}</p>
                                            <div className="mt-4 flex gap-3">
                                                <button
                                                    type="button"
                                                    onClick={() => resetTaskForm(task)}
                                                    className="inline-flex items-center gap-2 rounded-full bg-slate-900 px-4 py-2 text-sm font-semibold text-white transition hover:bg-slate-800 dark:bg-white dark:text-slate-900 dark:hover:bg-slate-200"
                                                >
                                                    {t('aiCoach.tasks.update')}
                                                </button>
                                            </div>
                                            {selectedTaskId === task.id && renderTaskEditor(task)}
                                        </div>
                                    ))
                                ) : (
                                    <div className="rounded-[24px] border border-dashed border-slate-300 px-4 py-6 text-sm text-slate-600 dark:border-slate-700 dark:text-slate-300">
                                        {t('aiCoach.tasks.empty')}
                                    </div>
                                )}
                            </div>
                        )}

                        {view === 'checkin' && (
                            <form onSubmit={handleSubmitCheckIn} className="space-y-4">
                                {renderScorePills(t('aiCoach.checkIn.mood'), moodScore, setMoodScore)}
                                {renderScorePills(t('aiCoach.checkIn.energy'), energyScore, setEnergyScore)}
                                {renderScorePills(t('aiCoach.checkIn.confidence'), confidenceScore, setConfidenceScore)}
                                <textarea
                                    value={checkInNotes}
                                    onChange={(event) => setCheckInNotes(event.target.value)}
                                    placeholder={t('aiCoach.checkIn.notesPlaceholder')}
                                    className="min-h-[110px] w-full rounded-[22px] border border-slate-200 bg-slate-50 px-4 py-3 text-sm text-slate-700 outline-none transition focus:border-primary dark:border-slate-700 dark:bg-slate-950 dark:text-slate-200"
                                />
                                <button
                                    type="submit"
                                    disabled={loading}
                                    className="inline-flex w-full items-center justify-center gap-2 rounded-full bg-slate-900 px-5 py-3 text-sm font-semibold text-white transition hover:bg-slate-800 disabled:cursor-not-allowed disabled:opacity-60 dark:bg-white dark:text-slate-900 dark:hover:bg-slate-200"
                                >
                                    {t('aiCoach.checkIn.submit')}
                                </button>
                            </form>
                        )}

                        {view === 'chat' && (
                            <div className="space-y-4">
                                <div className="space-y-3 rounded-[24px] bg-slate-50 p-4 dark:bg-slate-950/60">
                                    {chatHistory.length > 0 ? (
                                        chatHistory.slice(-6).map((message) => (
                                            <div
                                                key={message.id}
                                                className={`rounded-[20px] break-words px-4 py-3 text-sm leading-6 ${
                                                    message.role === 'user'
                                                        ? 'ml-8 bg-slate-900 text-white dark:bg-white dark:text-slate-900'
                                                        : 'mr-8 bg-white text-slate-700 shadow-sm dark:bg-slate-900 dark:text-slate-200'
                                                }`}
                                            >
                                                {message.content}
                                            </div>
                                        ))
                                    ) : (
                                        <div className="rounded-[20px] break-words bg-white px-4 py-4 text-sm leading-7 text-slate-600 shadow-sm dark:bg-slate-900 dark:text-slate-300">
                                            {guidanceMessage || t('aiCoach.page.chatPreviewEmpty', { defaultValue: 'Ask the coach to get support for your current situation.' })}
                                        </div>
                                    )}
                                    <div ref={chatEndRef} />
                                </div>
                                <div className="grid gap-2">
                                    {quickStatusOptions.slice(0, 2).map((option) => (
                                        <button
                                            key={option.label}
                                            type="button"
                                            onClick={() => void sendPromptToCoach(option.prompt)}
                                            className="flex items-center gap-3 rounded-[18px] border border-slate-200 px-4 py-3 text-left text-sm font-medium text-slate-700 transition hover:border-slate-300 hover:text-slate-900 dark:border-slate-700 dark:text-slate-200 dark:hover:border-slate-600 dark:hover:text-white"
                                        >
                                            <span className="material-symbols-outlined text-[18px]">{option.icon}</span>
                                            {option.label}
                                        </button>
                                    ))}
                                </div>
                                <form onSubmit={handleSendChat} className="flex gap-3">
                                    <input
                                        value={chatInput}
                                        onChange={(event) => setChatInput(event.target.value)}
                                        placeholder={t('aiCoach.chat.placeholder')}
                                        className="min-w-0 flex-1 rounded-full border border-slate-200 bg-slate-50 px-4 py-3 text-sm text-slate-700 outline-none transition focus:border-primary dark:border-slate-700 dark:bg-slate-950 dark:text-slate-200"
                                    />
                                    <button
                                        type="submit"
                                        disabled={loading || !chatInput.trim()}
                                        className="inline-flex items-center justify-center rounded-full bg-slate-900 px-4 py-3 text-sm font-semibold text-white transition hover:bg-slate-800 disabled:cursor-not-allowed disabled:opacity-60 dark:bg-white dark:text-slate-900 dark:hover:bg-slate-200"
                                    >
                                        {t('aiCoach.chat.send')}
                                    </button>
                                </form>
                            </div>
                        )}
                    </div>
                )}
            </div>
        );
    };

    return mode === 'page' ? renderPageDashboard() : renderWidgetDashboard();
};

export default AiCoachDashboard;
    
