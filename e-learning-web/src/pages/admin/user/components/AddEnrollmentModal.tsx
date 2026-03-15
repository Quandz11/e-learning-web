import React, { useState, useEffect } from 'react';
import { useTranslation } from 'react-i18next';
import { courseApi, type CourseResponse } from '../../../../services/courseApi';
import { adminEnrollmentApi } from '../../../../services/adminEnrollmentApi';

interface Props {
    isOpen: boolean;
    userId: string;
    enrolledCourseIds: string[];
    onClose: () => void;
    onSuccess: () => void;
}

const AddEnrollmentModal: React.FC<Props> = ({ isOpen, userId, enrolledCourseIds, onClose, onSuccess }) => {
    const { t } = useTranslation();
    const [courses, setCourses] = useState<CourseResponse[]>([]);
    const [search, setSearch] = useState('');
    const [loading, setLoading] = useState(false);
    const [saving, setSaving] = useState<string | null>(null);
    const [error, setError] = useState<string | null>(null);
    const [durationMode, setDurationMode] = useState<'7' | '30' | '90' | 'lifetime' | 'custom'>('lifetime');
    const [customDurationDays, setCustomDurationDays] = useState('');

    useEffect(() => {
        if (isOpen) {
            void loadCourses();
            setSearch('');
            setError(null);
            setDurationMode('lifetime');
            setCustomDurationDays('');
        }
    }, [isOpen]);

    const resolveDurationDays = (): number | null => {
        if (durationMode === '7') return 7;
        if (durationMode === '30') return 30;
        if (durationMode === '90') return 90;
        if (durationMode === 'lifetime') return null;

        const parsed = Number(customDurationDays);
        if (!Number.isInteger(parsed) || parsed < 1 || parsed > 3650) {
            throw new Error(t('admin.users.enrollment.durationInvalid', { defaultValue: 'Duration must be between 1 and 3650 days' }));
        }

        return parsed;
    };

    const loadCourses = async () => {
        setLoading(true);
        try {
            const data = await courseApi.getAll();
            setCourses(data);
        } catch {
            setError(t('admin.users.enrollment.loadCoursesFailed'));
        } finally {
            setLoading(false);
        }
    };

    const handleAdd = async (course: CourseResponse) => {
        setSaving(course.id);
        setError(null);
        try {
            const accessDurationDays = resolveDurationDays();
            await adminEnrollmentApi.addEnrollment(userId, course.id, accessDurationDays);
            onSuccess();
        } catch (err: any) {
            setError(err?.message || t('admin.users.enrollment.addFailed'));
        } finally {
            setSaving(null);
        }
    };

    if (!isOpen) return null;

    const filtered = courses.filter(c =>
        c.title.toLowerCase().includes(search.toLowerCase())
    );
    const alreadyEnrolled = new Set(enrolledCourseIds);

    return (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4">
            <div className="w-full max-w-lg rounded-2xl bg-white shadow-2xl dark:bg-dashboard-surface-dark">
                {/* Header */}
                <div className="flex items-center justify-between border-b border-slate-200 px-6 py-4 dark:border-slate-700">
                    <h2 className="text-base font-semibold text-slate-900 dark:text-white">
                        {t('admin.users.enrollment.addCourse')}
                    </h2>
                    <button
                        onClick={onClose}
                        className="rounded-lg p-1 text-slate-400 hover:bg-slate-100 hover:text-slate-700 dark:hover:bg-slate-800"
                    >
                        <span className="material-symbols-outlined text-[20px]">close</span>
                    </button>
                </div>

                {/* Search */}
                <div className="px-6 py-4">
                    <input
                        type="text"
                        value={search}
                        onChange={e => setSearch(e.target.value)}
                        placeholder={t('admin.users.enrollment.searchCourses')}
                        className="w-full rounded-lg border border-slate-300 bg-white px-3 py-2 text-sm text-slate-900 focus:border-dashboard-primary focus:outline-none dark:border-slate-600 dark:bg-slate-800 dark:text-white"
                        autoFocus
                    />
                </div>

                <div className="px-6 pb-2">
                    <label className="mb-2 block text-xs font-semibold uppercase tracking-wide text-slate-500 dark:text-slate-400">
                        {t('admin.users.enrollment.accessDuration', { defaultValue: 'Access duration' })}
                    </label>
                    <div className="grid grid-cols-2 gap-2 sm:grid-cols-5">
                        {[
                            { value: '7', label: t('admin.courses.form.duration7', { defaultValue: '7 days' }) },
                            { value: '30', label: t('admin.courses.form.duration30', { defaultValue: '30 days' }) },
                            { value: '90', label: t('admin.courses.form.duration90', { defaultValue: '90 days' }) },
                            { value: 'lifetime', label: t('admin.courses.form.durationLifetime', { defaultValue: 'Lifetime' }) },
                            { value: 'custom', label: t('admin.courses.form.durationCustom', { defaultValue: 'Custom' }) },
                        ].map((option) => (
                            <label
                                key={option.value}
                                className={`flex cursor-pointer items-center justify-center rounded-lg border px-2 py-1.5 text-xs font-semibold transition ${durationMode === option.value
                                    ? 'border-dashboard-primary bg-dashboard-primary/10 text-dashboard-primary'
                                    : 'border-slate-200 text-slate-600 hover:bg-slate-50 dark:border-slate-700 dark:text-slate-300 dark:hover:bg-slate-800'
                                    }`}
                            >
                                <input
                                    type="radio"
                                    name="enrollment-duration"
                                    value={option.value}
                                    checked={durationMode === option.value}
                                    onChange={() => setDurationMode(option.value as '7' | '30' | '90' | 'lifetime' | 'custom')}
                                    className="sr-only"
                                />
                                {option.label}
                            </label>
                        ))}
                    </div>
                    {durationMode === 'custom' && (
                        <input
                            type="number"
                            min={1}
                            max={3650}
                            value={customDurationDays}
                            onChange={(e) => setCustomDurationDays(e.target.value)}
                            placeholder={t('admin.courses.form.durationCustomPlaceholder', { defaultValue: 'Enter days (1-3650)' })}
                            className="mt-2 w-full rounded-lg border border-slate-300 bg-white px-3 py-2 text-sm text-slate-900 focus:border-dashboard-primary focus:outline-none dark:border-slate-600 dark:bg-slate-800 dark:text-white"
                        />
                    )}
                </div>

                {/* Error */}
                {error && (
                    <div className="mx-6 mb-2 rounded-lg bg-red-50 px-4 py-2 text-sm text-red-600 dark:bg-red-900/20 dark:text-red-400">
                        {error}
                    </div>
                )}

                {/* Course List */}
                <div className="max-h-80 overflow-y-auto px-6 pb-4">
                    {loading ? (
                        <div className="flex h-32 items-center justify-center">
                            <div className="h-6 w-6 animate-spin rounded-full border-4 border-dashboard-primary border-t-transparent" />
                        </div>
                    ) : filtered.length === 0 ? (
                        <p className="py-8 text-center text-sm text-slate-500 dark:text-slate-400">
                            {t('admin.users.enrollment.noCoursesFound')}
                        </p>
                    ) : (
                        <ul className="divide-y divide-slate-100 dark:divide-slate-800">
                            {filtered.map(course => {
                                const enrolled = alreadyEnrolled.has(course.id);
                                return (
                                    <li key={course.id} className="flex items-center gap-3 py-3">
                                        {course.thumbnailUrl ? (
                                            <img
                                                src={course.thumbnailUrl}
                                                alt={course.title}
                                                className="h-10 w-16 flex-shrink-0 rounded object-cover"
                                            />
                                        ) : (
                                            <div className="flex h-10 w-16 flex-shrink-0 items-center justify-center rounded bg-slate-100 dark:bg-slate-800">
                                                <span className="material-symbols-outlined text-[18px] text-slate-400">school</span>
                                            </div>
                                        )}
                                        <div className="min-w-0 flex-1">
                                            <p className="truncate text-sm font-medium text-slate-900 dark:text-white">{course.title}</p>
                                            <p className="text-xs text-slate-500 dark:text-slate-400">
                                                {course.isFree ? t('admin.users.enrollment.free') : `${course.price.toLocaleString()}đ`}
                                            </p>
                                        </div>
                                        {enrolled ? (
                                            <span className="rounded-full bg-green-100 px-2.5 py-1 text-xs font-medium text-green-700 dark:bg-green-900/30 dark:text-green-300">
                                                {t('admin.users.enrollment.alreadyEnrolled')}
                                            </span>
                                        ) : (
                                            <button
                                                onClick={() => void handleAdd(course)}
                                                disabled={saving === course.id}
                                                className="rounded-lg bg-dashboard-primary px-3 py-1.5 text-xs font-semibold text-white hover:bg-dashboard-primary-dark disabled:opacity-50"
                                            >
                                                {saving === course.id ? '...' : t('admin.users.enrollment.add')}
                                            </button>
                                        )}
                                    </li>
                                );
                            })}
                        </ul>
                    )}
                </div>
            </div>
        </div>
    );
};

export default AddEnrollmentModal;
