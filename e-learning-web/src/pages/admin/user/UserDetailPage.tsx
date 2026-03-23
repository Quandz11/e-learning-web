import React, { useEffect, useState } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { useTranslation } from 'react-i18next';
import { toast } from 'react-hot-toast';
import AdminLayout from '../../../components/admin/AdminLayout';
import { userApi, type UserDto, type UserRole, type UserStatus } from '../../../services/userApi';
import { adminEnrollmentApi, type AdminEnrollmentResponse } from '../../../services/adminEnrollmentApi';
import {
    wellnessApi,
    type WellnessPackageAdmin,
    type WellnessUserPackage,
} from '../../../services/wellnessApi';
import { format } from 'date-fns';
import UserFormModal from './components/UserFormModal';
import ResetPasswordModal from './components/ResetPasswordModal';
import AddEnrollmentModal from './components/AddEnrollmentModal';

interface WellnessDraft {
    status: string;
    expiresAt: string;
    notes: string;
}

const UserDetailPage: React.FC = () => {
    const { id } = useParams<{ id: string }>();
    const navigate = useNavigate();
    const { t } = useTranslation();

    const [user, setUser] = useState<UserDto | null>(null);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState<string | null>(null);

    // Modal states
    const [showEditModal, setShowEditModal] = useState(false);
    const [showResetModal, setShowResetModal] = useState(false);

    // Tabs state
    const [activeTab, setActiveTab] = useState<'overview' | 'courses' | 'wellness' | 'activity'>('overview');

    // Enrollment management
    const [enrollments, setEnrollments] = useState<AdminEnrollmentResponse[]>([]);
    const [enrollmentsLoading, setEnrollmentsLoading] = useState(false);
    const [showAddCourseModal, setShowAddCourseModal] = useState(false);
    const [togglingId, setTogglingId] = useState<string | null>(null);
    const [removingId, setRemovingId] = useState<string | null>(null);

    // Wellness package management
    const [wellnessPackages, setWellnessPackages] = useState<WellnessUserPackage[]>([]);
    const [wellnessLoading, setWellnessLoading] = useState(false);
    const [wellnessDrafts, setWellnessDrafts] = useState<Record<string, WellnessDraft>>({});
    const [wellnessPackageOptions, setWellnessPackageOptions] = useState<WellnessPackageAdmin[]>([]);
    const [wellnessPackageOptionsLoading, setWellnessPackageOptionsLoading] = useState(false);
    const [assigningWellness, setAssigningWellness] = useState(false);
    const [updatingWellnessId, setUpdatingWellnessId] = useState<string | null>(null);
    const [grantPackageCode, setGrantPackageCode] = useState('');
    const [grantStartsAt, setGrantStartsAt] = useState('');
    const [grantExpiresAt, setGrantExpiresAt] = useState('');
    const [grantNotes, setGrantNotes] = useState('');

    const roleLabel = (value: UserRole) => t(`admin.users.roles.${value}`);
    const statusLabel = (value: UserStatus) => t(`admin.users.statuses.${value}`);

    const renderAccessExpiry = (enrollment: AdminEnrollmentResponse) => {
        if (!enrollment.accessExpiresAt) {
            return t('admin.courses.form.durationLifetime', { defaultValue: 'Lifetime' });
        }

        const expiresAt = new Date(enrollment.accessExpiresAt);
        const now = new Date();
        const diffDays = Math.ceil((expiresAt.getTime() - now.getTime()) / (1000 * 60 * 60 * 24));
        const base = format(expiresAt, 'dd/MM/yyyy');

        if (diffDays < 0) {
            return `${base} (${t('admin.users.enrollment.expired', { defaultValue: 'Expired' })})`;
        }

        return `${base} (${t('admin.users.enrollment.daysRemaining', { defaultValue: '{{days}} days left', days: diffDays })})`;
    };

    const toInputDateTime = (value?: string) => {
        if (!value) return '';
        const date = new Date(value);
        if (Number.isNaN(date.getTime())) return '';
        const timezoneOffset = date.getTimezoneOffset() * 60000;
        return new Date(date.getTime() - timezoneOffset).toISOString().slice(0, 16);
    };

    const toUtcIsoString = (value?: string) => {
        if (!value) return undefined;
        const date = new Date(value);
        return Number.isNaN(date.getTime()) ? undefined : date.toISOString();
    };

    const formatDateTime = (value?: string) => {
        if (!value) return '-';
        const date = new Date(value);
        if (Number.isNaN(date.getTime())) return '-';
        return format(date, 'dd/MM/yyyy HH:mm');
    };

    const formatVnd = (value: number) =>
        new Intl.NumberFormat('vi-VN', {
            style: 'currency',
            currency: 'VND',
            maximumFractionDigits: 0,
        }).format(value);

    const getWellnessStatusClassName = (status: string) => {
        if (status === 'ACTIVE') {
            return 'bg-green-100 text-green-700 dark:bg-green-900/30 dark:text-green-300';
        }

        if (status === 'REVOKED') {
            return 'bg-red-100 text-red-700 dark:bg-red-900/30 dark:text-red-300';
        }

        return 'bg-amber-100 text-amber-700 dark:bg-amber-900/30 dark:text-amber-300';
    };

    useEffect(() => {
        if (id) {
            void fetchUser(id);
        }
    }, [id]);

    const fetchUser = async (userId: string) => {
        try {
            setLoading(true);
            const data = await userApi.getById(userId);
            setUser(data);
        } catch (err: any) {
            setError(err.message || t('admin.users.errors.loadFailed'));
        } finally {
            setLoading(false);
        }
    };

    const handleEditSuccess = () => {
        if (id) void fetchUser(id);
    };

    const fetchEnrollments = async (userId: string) => {
        setEnrollmentsLoading(true);
        try {
            const data = await adminEnrollmentApi.getUserEnrollments(userId);
            setEnrollments(data);
        } catch {
            // silently fail
        } finally {
            setEnrollmentsLoading(false);
        }
    };

    const hydrateWellnessDrafts = (rows: WellnessUserPackage[]) => {
        const nextDrafts: Record<string, WellnessDraft> = {};
        rows.forEach((row) => {
            nextDrafts[row.id] = {
                status: row.status || 'ACTIVE',
                expiresAt: toInputDateTime(row.expiresAt),
                notes: row.notes || '',
            };
        });
        setWellnessDrafts(nextDrafts);
    };

    const fetchWellnessPackages = async (userId: string) => {
        setWellnessLoading(true);
        try {
            const data = await wellnessApi.getUserPackages(userId);
            setWellnessPackages(data);
            hydrateWellnessDrafts(data);
        } catch (err: any) {
            toast.error(
                err?.message
                || t('admin.users.wellness.errors.loadAssignments', { defaultValue: 'Unable to load wellness package assignments.' }),
            );
        } finally {
            setWellnessLoading(false);
        }
    };

    const fetchWellnessPackageOptions = async () => {
        setWellnessPackageOptionsLoading(true);
        try {
            const settings = await wellnessApi.getAdminSettings();
            const packages = (settings.packages ?? []).sort(
                (a, b) => a.sortOrder - b.sortOrder || a.durationDays - b.durationDays || a.code.localeCompare(b.code),
            );

            setWellnessPackageOptions(packages);

            const firstActiveCode = packages.find((pkg) => pkg.isActive)?.code ?? '';
            setGrantPackageCode((prev) => prev || firstActiveCode);
        } catch (err: any) {
            toast.error(
                err?.message
                || t('admin.users.wellness.errors.loadCatalog', { defaultValue: 'Unable to load wellness package catalog.' }),
            );
        } finally {
            setWellnessPackageOptionsLoading(false);
        }
    };

    useEffect(() => {
        if (activeTab === 'courses' && id) {
            void fetchEnrollments(id);
        }
    }, [activeTab, id]);

    useEffect(() => {
        if (activeTab === 'wellness' && id) {
            void fetchWellnessPackages(id);
            void fetchWellnessPackageOptions();
        }
    }, [activeTab, id]);

    const updateWellnessDraft = (row: WellnessUserPackage, patch: Partial<WellnessDraft>) => {
        setWellnessDrafts((prev) => {
            const current = prev[row.id] ?? {
                status: row.status || 'ACTIVE',
                expiresAt: toInputDateTime(row.expiresAt),
                notes: row.notes || '',
            };

            return {
                ...prev,
                [row.id]: {
                    ...current,
                    ...patch,
                },
            };
        });
    };

    const handleGrantWellnessPackage = async (event: React.FormEvent) => {
        event.preventDefault();
        if (!id) return;

        if (!grantPackageCode) {
            toast.error(t('admin.users.wellness.errors.packageRequired', { defaultValue: 'Please select a wellness package.' }));
            return;
        }

        setAssigningWellness(true);
        try {
            await wellnessApi.grantUserPackage(id, {
                packageCode: grantPackageCode,
                startsAt: toUtcIsoString(grantStartsAt),
                expiresAt: toUtcIsoString(grantExpiresAt),
                source: 'MANUAL',
                notes: grantNotes.trim() || undefined,
            });

            toast.success(t('admin.users.wellness.success.assigned', { defaultValue: 'Wellness package assigned.' }));
            setGrantStartsAt('');
            setGrantExpiresAt('');
            setGrantNotes('');
            await fetchWellnessPackages(id);
        } catch (err: any) {
            toast.error(
                err?.message
                || t('admin.users.wellness.errors.assignFailed', { defaultValue: 'Unable to assign wellness package.' }),
            );
        } finally {
            setAssigningWellness(false);
        }
    };

    const handleSaveWellnessAssignment = async (row: WellnessUserPackage) => {
        if (!id) return;
        const draft = wellnessDrafts[row.id];
        if (!draft) return;

        setUpdatingWellnessId(row.id);
        try {
            await wellnessApi.updateUserPackage(id, row.id, {
                status: draft.status,
                expiresAt: toUtcIsoString(draft.expiresAt),
                notes: draft.notes.trim(),
            });

            toast.success(t('admin.users.wellness.success.updated', { defaultValue: 'Wellness assignment updated.' }));
            await fetchWellnessPackages(id);
        } catch (err: any) {
            toast.error(
                err?.message
                || t('admin.users.wellness.errors.updateFailed', { defaultValue: 'Unable to update wellness assignment.' }),
            );
        } finally {
            setUpdatingWellnessId(null);
        }
    };

    const handleToggleStatus = async (enrollment: AdminEnrollmentResponse) => {
        if (!id) return;
        setTogglingId(enrollment.id);
        try {
            const newStatus = enrollment.status === 'ACTIVE' ? 'INACTIVE' : 'ACTIVE';
            await adminEnrollmentApi.setEnrollmentStatus(id, enrollment.id, newStatus);
            void fetchEnrollments(id);
        } catch {
            // ignore
        } finally {
            setTogglingId(null);
        }
    };

    const handleRemoveEnrollment = async (enrollment: AdminEnrollmentResponse) => {
        if (!id) return;
        if (!window.confirm(t('admin.users.enrollment.removeConfirm'))) return;
        setRemovingId(enrollment.id);
        try {
            await adminEnrollmentApi.removeEnrollment(id, enrollment.courseId);
            void fetchEnrollments(id);
        } catch {
            // ignore
        } finally {
            setRemovingId(null);
        }
    };

    const tabItems: Array<{ key: 'overview' | 'courses' | 'wellness' | 'activity'; label: string }> = [
        { key: 'overview', label: t('admin.users.detail.tabs.overview', { defaultValue: 'Overview' }) },
        { key: 'courses', label: t('admin.users.detail.tabs.courses', { defaultValue: 'Courses' }) },
        { key: 'wellness', label: t('admin.users.detail.tabs.wellness', { defaultValue: 'Wellness Packages' }) },
        { key: 'activity', label: t('admin.users.detail.tabs.activity', { defaultValue: 'Activity' }) },
    ];

    if (loading) {
        return (
            <AdminLayout>
                <div className="flex h-96 items-center justify-center">
                    <div className="h-8 w-8 animate-spin rounded-full border-4 border-dashboard-primary border-t-transparent"></div>
                </div>
            </AdminLayout>
        );
    }

    if (error || !user) {
        return (
            <AdminLayout>
                <div className="flex flex-col items-center justify-center py-10">
                    <p className="mb-4 text-red-500">{error || t('admin.users.detail.notFound')}</p>
                    <button
                        onClick={() => navigate('/admin/users')}
                        className="text-dashboard-primary hover:underline"
                    >
                        {t('common.backToList', { defaultValue: 'Back to List' })}
                    </button>
                </div>
            </AdminLayout>
        );
    }

    return (
        <AdminLayout>
            {/* Header Actions */}
            <div className="mb-6 flex flex-wrap items-center justify-between gap-4">
                <div className="flex items-center gap-2 text-sm text-slate-500 dark:text-slate-400">
                    <button onClick={() => navigate('/admin/users')} className="hover:text-dashboard-primary">
                        {t('admin.users.title')}
                    </button>
                    <span className="material-symbols-outlined text-[16px]">chevron_right</span>
                    <span className="text-slate-900 dark:text-white">{user.fullName || user.email}</span>
                </div>

                <div className="flex gap-2">
                    <button
                        onClick={() => setShowResetModal(true)}
                        className="rounded-lg border border-slate-200 px-4 py-2 text-sm font-medium text-slate-700 hover:bg-slate-100 dark:border-slate-700 dark:text-slate-200 dark:hover:bg-slate-800"
                    >
                        {t('admin.users.buttons.reset')}
                    </button>
                    <button
                        onClick={() => setShowEditModal(true)}
                        className="inline-flex items-center gap-2 rounded-lg bg-dashboard-primary px-4 py-2 text-sm font-semibold text-white shadow-sm shadow-dashboard-primary/30 transition hover:bg-dashboard-primary-dark"
                    >
                        <span className="material-symbols-outlined text-[18px]">edit</span>
                        {t('admin.users.buttons.edit')}
                    </button>
                </div>
            </div>

            <div className="grid grid-cols-1 gap-8 lg:grid-cols-3">
                {/* Left Column (2/3) - Main Info & Tabs */}
                <div className="lg:col-span-2 space-y-6">
                    {/* Profile Card */}
                    <div className="flex flex-col gap-6 rounded-2xl border border-slate-200 bg-white p-6 shadow-sm dark:border-slate-700 dark:bg-dashboard-surface-dark md:flex-row md:items-start">
                        <div className="h-24 w-24 flex-shrink-0 overflow-hidden rounded-full bg-slate-100 dark:bg-slate-800">
                            {user.avatarUrl ? (
                                <img src={user.avatarUrl} alt={user.fullName} className="h-full w-full object-cover" />
                            ) : (
                                <div className="flex h-full w-full items-center justify-center text-3xl font-bold text-slate-400">
                                    {(user.fullName?.[0] || user.email[0]).toUpperCase()}
                                </div>
                            )}
                        </div>
                        <div className="flex-1 space-y-4">
                            <div>
                                <h1 className="text-2xl font-bold text-slate-900 dark:text-white">{user.fullName || t('common.unnamed')}</h1>
                                <p className="text-slate-500 dark:text-slate-400">{user.email}</p>
                            </div>

                            <div className="flex flex-wrap gap-2">
                                <span className="inline-flex items-center gap-1 rounded-full bg-slate-100 px-2.5 py-1 text-xs font-semibold text-slate-700 dark:bg-slate-800 dark:text-slate-200">
                                    <span className="material-symbols-outlined text-[16px]">badge</span>
                                    {roleLabel(user.role)}
                                </span>
                                <span className={`inline-flex items-center gap-1 rounded-full px-2.5 py-1 text-xs font-semibold ${user.status === 'ACTIVE' ? 'bg-green-100 text-green-700 dark:bg-green-900/30 dark:text-green-300' : 'bg-amber-100 text-amber-700 dark:bg-amber-900/30 dark:text-amber-300'}`}>
                                    {statusLabel(user.status)}
                                </span>
                                {user.isEmailVerified && (
                                    <span className="inline-flex items-center gap-1 rounded-full bg-blue-50 px-2.5 py-1 text-xs font-semibold text-blue-700 dark:bg-blue-900/20 dark:text-blue-300">
                                        <span className="material-symbols-outlined text-[16px]">verified</span>
                                        {t('admin.users.detail.verifiedEmail')}
                                    </span>
                                )}
                            </div>

                            <div className="grid grid-cols-1 gap-4 text-sm sm:grid-cols-2">
                                <div>
                                    <span className="block text-slate-500 dark:text-slate-400">{t('admin.users.form.phone')}</span>
                                    <span className="font-medium text-slate-900 dark:text-white">{user.phone || '-'}</span>
                                </div>
                                <div>
                                    <span className="block text-slate-500 dark:text-slate-400">{t('admin.users.table.created')}</span>
                                    <span className="font-medium text-slate-900 dark:text-white">{format(new Date(user.createdAt), 'PPP')}</span>
                                </div>
                            </div>
                        </div>
                    </div>

                    {/* Tabs */}
                    <div className="rounded-xl border border-slate-200 bg-white shadow-sm dark:border-slate-800 dark:bg-dashboard-surface-dark">
                        <div className="flex border-b border-slate-200 px-6 dark:border-slate-800">
                            {tabItems.map((tab) => (
                                <button
                                    key={tab.key}
                                    onClick={() => setActiveTab(tab.key)}
                                    className={`mr-6 border-b-2 py-4 text-sm font-medium transition ${activeTab === tab.key
                                        ? 'border-dashboard-primary text-dashboard-primary'
                                        : 'border-transparent text-slate-500 hover:text-slate-700 dark:text-slate-400 dark:hover:text-slate-200'
                                        }`}
                                >
                                    {tab.label}
                                </button>
                            ))}
                        </div>
                        <div className="p-6">
                            {activeTab === 'overview' && (
                                <div className="space-y-4">
                                    <h3 className="text-lg font-semibold text-slate-900 dark:text-white">{t('admin.users.detail.additionalInfo')}</h3>
                                    <p className="text-slate-500 dark:text-slate-400">{t('admin.users.detail.additionalInfoDesc')}</p>
                                    {/* Suggestion: Add more fields if available in API */}
                                </div>
                            )}
                            {activeTab === 'courses' && (
                                <div>
                                    {/* Action bar */}
                                    <div className="mb-4 flex items-center justify-between">
                                        <h3 className="text-sm font-semibold text-slate-900 dark:text-white">
                                            {t('admin.users.enrollment.title')} ({enrollments.length})
                                        </h3>
                                        <button
                                            onClick={() => setShowAddCourseModal(true)}
                                            className="inline-flex items-center gap-1.5 rounded-lg bg-dashboard-primary px-3 py-1.5 text-xs font-semibold text-white hover:bg-dashboard-primary-dark"
                                        >
                                            <span className="material-symbols-outlined text-[15px]">add</span>
                                            {t('admin.users.enrollment.addCourse')}
                                        </button>
                                    </div>

                                    {enrollmentsLoading ? (
                                        <div className="flex h-32 items-center justify-center">
                                            <div className="h-6 w-6 animate-spin rounded-full border-4 border-dashboard-primary border-t-transparent" />
                                        </div>
                                    ) : enrollments.length === 0 ? (
                                        <div className="py-10 text-center text-slate-500 dark:text-slate-400">
                                            <span className="material-symbols-outlined mb-2 text-[40px] text-slate-300">school</span>
                                            <p className="text-sm">{t('admin.users.enrollment.empty')}</p>
                                        </div>
                                    ) : (
                                        <div className="overflow-x-auto">
                                            <table className="w-full text-sm">
                                                <thead>
                                                    <tr className="border-b border-slate-200 dark:border-slate-700">
                                                        <th className="pb-2 text-left text-xs font-semibold text-slate-500 dark:text-slate-400">{t('admin.users.enrollment.course')}</th>
                                                        <th className="pb-2 text-left text-xs font-semibold text-slate-500 dark:text-slate-400">{t('admin.users.enrollment.enrolledAt')}</th>
                                                        <th className="pb-2 text-left text-xs font-semibold text-slate-500 dark:text-slate-400">{t('admin.users.enrollment.expiresAt', { defaultValue: 'Expires At' })}</th>
                                                        <th className="pb-2 text-center text-xs font-semibold text-slate-500 dark:text-slate-400">{t('admin.users.enrollment.progress')}</th>
                                                        <th className="pb-2 text-center text-xs font-semibold text-slate-500 dark:text-slate-400">{t('admin.users.enrollment.status')}</th>
                                                        <th className="pb-2 text-right text-xs font-semibold text-slate-500 dark:text-slate-400"></th>
                                                    </tr>
                                                </thead>
                                                <tbody className="divide-y divide-slate-100 dark:divide-slate-800">
                                                    {enrollments.map(enrollment => (
                                                        <tr key={enrollment.id}>
                                                            <td className="py-3 pr-4">
                                                                <div className="flex items-center gap-2">
                                                                    {enrollment.courseThumbnail ? (
                                                                        <img src={enrollment.courseThumbnail} alt={enrollment.courseTitle} className="h-8 w-12 flex-shrink-0 rounded object-cover" />
                                                                    ) : (
                                                                        <div className="flex h-8 w-12 flex-shrink-0 items-center justify-center rounded bg-slate-100 dark:bg-slate-800">
                                                                            <span className="material-symbols-outlined text-[15px] text-slate-400">school</span>
                                                                        </div>
                                                                    )}
                                                                    <span className="font-medium text-slate-900 dark:text-white line-clamp-1">{enrollment.courseTitle}</span>
                                                                </div>
                                                            </td>
                                                            <td className="py-3 pr-4 text-slate-500 dark:text-slate-400">
                                                                {format(new Date(enrollment.enrolledAt), 'dd/MM/yyyy')}
                                                            </td>
                                                            <td className="py-3 pr-4 text-slate-500 dark:text-slate-400">
                                                                {renderAccessExpiry(enrollment)}
                                                            </td>
                                                            <td className="py-3 pr-4 text-center">
                                                                <div className="flex items-center justify-center gap-1.5">
                                                                    <div className="h-1.5 w-16 overflow-hidden rounded-full bg-slate-200 dark:bg-slate-700">
                                                                        <div
                                                                            className="h-full rounded-full bg-dashboard-primary"
                                                                            style={{ width: `${enrollment.progressPercentage}%` }}
                                                                        />
                                                                    </div>
                                                                    <span className="text-xs text-slate-500">{enrollment.progressPercentage}%</span>
                                                                </div>
                                                            </td>
                                                            <td className="py-3 pr-4 text-center">
                                                                <span className={`inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-medium ${
                                                                    enrollment.status === 'ACTIVE'
                                                                        ? 'bg-green-100 text-green-700 dark:bg-green-900/30 dark:text-green-300'
                                                                        : 'bg-red-100 text-red-700 dark:bg-red-900/30 dark:text-red-300'
                                                                }`}>
                                                                    {t(`admin.users.enrollment.statuses.${enrollment.status}`)}
                                                                </span>
                                                            </td>
                                                            <td className="py-3 text-right">
                                                                <div className="flex items-center justify-end gap-1">
                                                                    <button
                                                                        onClick={() => void handleToggleStatus(enrollment)}
                                                                        disabled={togglingId === enrollment.id}
                                                                        title={enrollment.status === 'ACTIVE' ? t('admin.users.enrollment.deactivate') : t('admin.users.enrollment.activate')}
                                                                        className="rounded-lg p-1.5 text-slate-500 hover:bg-slate-100 hover:text-slate-700 disabled:opacity-40 dark:hover:bg-slate-800"
                                                                    >
                                                                        <span className="material-symbols-outlined text-[18px]">
                                                                            {enrollment.status === 'ACTIVE' ? 'block' : 'check_circle'}
                                                                        </span>
                                                                    </button>
                                                                    <button
                                                                        onClick={() => void handleRemoveEnrollment(enrollment)}
                                                                        disabled={removingId === enrollment.id}
                                                                        title={t('admin.users.enrollment.remove')}
                                                                        className="rounded-lg p-1.5 text-red-400 hover:bg-red-50 hover:text-red-600 disabled:opacity-40 dark:hover:bg-red-900/20"
                                                                    >
                                                                        <span className="material-symbols-outlined text-[18px]">delete</span>
                                                                    </button>
                                                                </div>
                                                            </td>
                                                        </tr>
                                                    ))}
                                                </tbody>
                                            </table>
                                        </div>
                                    )}
                                </div>
                            )}
                            {activeTab === 'wellness' && (
                                <div className="space-y-6">
                                    <div className="rounded-xl border border-slate-200 bg-slate-50 p-4 dark:border-slate-700 dark:bg-slate-900/40">
                                        <div className="flex flex-wrap items-center justify-between gap-2">
                                            <h3 className="text-sm font-semibold text-slate-900 dark:text-white">
                                                {t('admin.users.wellness.assign.title', { defaultValue: 'Assign wellness package' })}
                                            </h3>
                                            <span className="text-xs text-slate-500 dark:text-slate-400">
                                                {t('admin.users.wellness.assign.subtitle', { defaultValue: 'Manually assign standalone wellness package to this user.' })}
                                            </span>
                                        </div>

                                        <form onSubmit={handleGrantWellnessPackage} className="mt-4 grid grid-cols-1 gap-3 sm:grid-cols-4">
                                            <div className="sm:col-span-2">
                                                <label className="mb-1 block text-xs font-semibold text-slate-700 dark:text-slate-300">
                                                    {t('admin.users.wellness.assign.package', { defaultValue: 'Package' })}
                                                </label>
                                                <select
                                                    value={grantPackageCode}
                                                    onChange={(event) => setGrantPackageCode(event.target.value)}
                                                    disabled={wellnessPackageOptionsLoading || assigningWellness}
                                                    className="w-full rounded-lg border border-slate-300 bg-white px-3 py-2 text-sm dark:border-slate-700 dark:bg-slate-800"
                                                >
                                                    <option value="">
                                                        {t('admin.users.wellness.assign.selectPackage', { defaultValue: 'Select package' })}
                                                    </option>
                                                    {wellnessPackageOptions
                                                        .filter((pkg) => pkg.isActive)
                                                        .map((pkg) => (
                                                            <option key={pkg.id} value={pkg.code}>
                                                                {pkg.name} ({formatVnd(pkg.priceVnd)} / {pkg.durationDays}d)
                                                            </option>
                                                        ))}
                                                </select>
                                            </div>

                                            <div>
                                                <label className="mb-1 block text-xs font-semibold text-slate-700 dark:text-slate-300">
                                                    {t('admin.users.wellness.assign.startsAt', { defaultValue: 'Starts At' })}
                                                </label>
                                                <input
                                                    type="datetime-local"
                                                    value={grantStartsAt}
                                                    onChange={(event) => setGrantStartsAt(event.target.value)}
                                                    className="w-full rounded-lg border border-slate-300 bg-white px-3 py-2 text-sm dark:border-slate-700 dark:bg-slate-800"
                                                />
                                            </div>

                                            <div>
                                                <label className="mb-1 block text-xs font-semibold text-slate-700 dark:text-slate-300">
                                                    {t('admin.users.wellness.assign.expiresAt', { defaultValue: 'Expires At' })}
                                                </label>
                                                <input
                                                    type="datetime-local"
                                                    value={grantExpiresAt}
                                                    onChange={(event) => setGrantExpiresAt(event.target.value)}
                                                    className="w-full rounded-lg border border-slate-300 bg-white px-3 py-2 text-sm dark:border-slate-700 dark:bg-slate-800"
                                                />
                                            </div>

                                            <div className="sm:col-span-3">
                                                <label className="mb-1 block text-xs font-semibold text-slate-700 dark:text-slate-300">
                                                    {t('admin.users.wellness.assign.notes', { defaultValue: 'Notes' })}
                                                </label>
                                                <input
                                                    value={grantNotes}
                                                    onChange={(event) => setGrantNotes(event.target.value)}
                                                    placeholder={t('admin.users.wellness.assign.notesPlaceholder', { defaultValue: 'Internal note for this manual assignment' })}
                                                    className="w-full rounded-lg border border-slate-300 bg-white px-3 py-2 text-sm dark:border-slate-700 dark:bg-slate-800"
                                                />
                                            </div>

                                            <div className="flex items-end justify-end">
                                                <button
                                                    type="submit"
                                                    disabled={assigningWellness || wellnessPackageOptionsLoading}
                                                    className="inline-flex h-10 items-center rounded-lg bg-dashboard-primary px-4 text-sm font-semibold text-white hover:bg-dashboard-primary-dark disabled:opacity-60"
                                                >
                                                    {assigningWellness
                                                        ? t('admin.users.wellness.assign.assigning', { defaultValue: 'Assigning...' })
                                                        : t('admin.users.wellness.assign.action', { defaultValue: 'Assign package' })}
                                                </button>
                                            </div>
                                        </form>
                                    </div>

                                    <div className="rounded-xl border border-slate-200 bg-white p-4 shadow-sm dark:border-slate-700 dark:bg-dashboard-surface-dark">
                                        <div className="mb-4 flex items-center justify-between">
                                            <h3 className="text-sm font-semibold text-slate-900 dark:text-white">
                                                {t('admin.users.wellness.assignments.title', { defaultValue: 'Assigned packages' })}
                                            </h3>
                                            <span className="rounded-full bg-slate-100 px-2.5 py-1 text-xs font-semibold text-slate-700 dark:bg-slate-800 dark:text-slate-200">
                                                {wellnessPackages.length}
                                            </span>
                                        </div>

                                        {wellnessLoading ? (
                                            <div className="flex h-32 items-center justify-center">
                                                <div className="h-6 w-6 animate-spin rounded-full border-4 border-dashboard-primary border-t-transparent" />
                                            </div>
                                        ) : wellnessPackages.length === 0 ? (
                                            <div className="py-8 text-center text-sm text-slate-500 dark:text-slate-400">
                                                {t('admin.users.wellness.assignments.empty', { defaultValue: 'No wellness package assignment yet.' })}
                                            </div>
                                        ) : (
                                            <div className="overflow-x-auto">
                                                <table className="w-full text-sm">
                                                    <thead>
                                                        <tr className="border-b border-slate-200 dark:border-slate-700">
                                                            <th className="pb-2 text-left text-xs font-semibold text-slate-500 dark:text-slate-400">
                                                                {t('admin.users.wellness.assignments.package', { defaultValue: 'Package' })}
                                                            </th>
                                                            <th className="pb-2 text-left text-xs font-semibold text-slate-500 dark:text-slate-400">
                                                                {t('admin.users.wellness.assignments.status', { defaultValue: 'Status' })}
                                                            </th>
                                                            <th className="pb-2 text-left text-xs font-semibold text-slate-500 dark:text-slate-400">
                                                                {t('admin.users.wellness.assignments.source', { defaultValue: 'Source' })}
                                                            </th>
                                                            <th className="pb-2 text-left text-xs font-semibold text-slate-500 dark:text-slate-400">
                                                                {t('admin.users.wellness.assignments.period', { defaultValue: 'Start / Expire' })}
                                                            </th>
                                                            <th className="pb-2 text-left text-xs font-semibold text-slate-500 dark:text-slate-400">
                                                                {t('admin.users.wellness.assignments.edit', { defaultValue: 'Edit' })}
                                                            </th>
                                                            <th className="pb-2 text-right text-xs font-semibold text-slate-500 dark:text-slate-400"></th>
                                                        </tr>
                                                    </thead>
                                                    <tbody className="divide-y divide-slate-100 dark:divide-slate-800">
                                                        {wellnessPackages.map((row) => {
                                                            const draft = wellnessDrafts[row.id] ?? {
                                                                status: row.status || 'ACTIVE',
                                                                expiresAt: toInputDateTime(row.expiresAt),
                                                                notes: row.notes || '',
                                                            };

                                                            return (
                                                                <tr key={row.id}>
                                                                    <td className="py-3 pr-4">
                                                                        <div className="font-medium text-slate-900 dark:text-white">{row.packageName}</div>
                                                                        <div className="text-xs text-slate-500 dark:text-slate-400">
                                                                            {row.packageCode} • {formatVnd(row.priceVnd)} • {row.durationDays}d
                                                                        </div>
                                                                    </td>
                                                                    <td className="py-3 pr-4">
                                                                        <span className={`inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-semibold ${getWellnessStatusClassName(draft.status)}`}>
                                                                            {draft.status}
                                                                        </span>
                                                                    </td>
                                                                    <td className="py-3 pr-4 text-xs text-slate-600 dark:text-slate-300">
                                                                        <div>{row.source}</div>
                                                                        <div>{formatDateTime(row.grantedAt)}</div>
                                                                    </td>
                                                                    <td className="py-3 pr-4 text-xs text-slate-600 dark:text-slate-300">
                                                                        <div>
                                                                            <span className="font-semibold text-slate-800 dark:text-slate-200">
                                                                                {t('admin.users.wellness.assignments.startsAt', { defaultValue: 'Start' })}:
                                                                            </span> {formatDateTime(row.startsAt)}
                                                                        </div>
                                                                        <div>
                                                                            <span className="font-semibold text-slate-800 dark:text-slate-200">
                                                                                {t('admin.users.wellness.assignments.expiresAt', { defaultValue: 'Expire' })}:
                                                                            </span> {formatDateTime(row.expiresAt)}
                                                                        </div>
                                                                    </td>
                                                                    <td className="py-3 pr-4">
                                                                        <div className="grid gap-2">
                                                                            <select
                                                                                value={draft.status}
                                                                                onChange={(event) => updateWellnessDraft(row, { status: event.target.value })}
                                                                                className="rounded-md border border-slate-300 bg-white px-2 py-1.5 text-xs dark:border-slate-700 dark:bg-slate-800"
                                                                            >
                                                                                <option value="ACTIVE">ACTIVE</option>
                                                                                <option value="REVOKED">REVOKED</option>
                                                                                <option value="EXPIRED">EXPIRED</option>
                                                                            </select>
                                                                            <input
                                                                                type="datetime-local"
                                                                                value={draft.expiresAt}
                                                                                onChange={(event) => updateWellnessDraft(row, { expiresAt: event.target.value })}
                                                                                className="rounded-md border border-slate-300 bg-white px-2 py-1.5 text-xs dark:border-slate-700 dark:bg-slate-800"
                                                                            />
                                                                            <input
                                                                                value={draft.notes}
                                                                                onChange={(event) => updateWellnessDraft(row, { notes: event.target.value })}
                                                                                placeholder={t('admin.users.wellness.assignments.notes', { defaultValue: 'Notes' })}
                                                                                className="rounded-md border border-slate-300 bg-white px-2 py-1.5 text-xs dark:border-slate-700 dark:bg-slate-800"
                                                                            />
                                                                        </div>
                                                                    </td>
                                                                    <td className="py-3 text-right">
                                                                        <button
                                                                            type="button"
                                                                            onClick={() => void handleSaveWellnessAssignment(row)}
                                                                            disabled={updatingWellnessId === row.id}
                                                                            className="rounded-lg bg-dashboard-primary px-3 py-1.5 text-xs font-semibold text-white hover:bg-dashboard-primary-dark disabled:opacity-60"
                                                                        >
                                                                            {updatingWellnessId === row.id
                                                                                ? t('common.saving', { defaultValue: 'Saving...' })
                                                                                : t('common.save', { defaultValue: 'Save' })}
                                                                        </button>
                                                                    </td>
                                                                </tr>
                                                            );
                                                        })}
                                                    </tbody>
                                                </table>
                                            </div>
                                        )}
                                    </div>
                                </div>
                            )}
                            {activeTab === 'activity' && (
                                <div className="text-center py-8 text-slate-500 dark:text-slate-400">
                                    <p>{t('admin.users.detail.activityEmpty')}</p>
                                </div>
                            )}
                        </div>
                    </div>
                </div>

                {/* Right Column (1/3) - Sidebar Stats */}
                <div className="space-y-6">
                    <div className="rounded-xl border border-slate-200 bg-white p-5 shadow-sm dark:border-slate-800 dark:bg-dashboard-surface-dark">
                        <h3 className="mb-4 text-sm font-semibold text-slate-900 dark:text-white">{t('admin.users.detail.stats.title')}</h3>
                        <div className="space-y-4">
                            {/* Stat Items placeholder */}
                            <div className="flex items-center justify-between">
                                <span className="text-sm text-slate-500 dark:text-slate-400">{t('admin.users.detail.stats.coursesEnrolled')}</span>
                                <span className="font-semibold text-slate-900 dark:text-white">
                                    {enrollments.filter(e => e.status === 'ACTIVE').length}
                                </span>
                            </div>
                            <div className="flex items-center justify-between">
                                <span className="text-sm text-slate-500 dark:text-slate-400">{t('admin.users.detail.stats.completionRate')}</span>
                                <span className="font-semibold text-slate-900 dark:text-white">
                                    {enrollments.length > 0
                                        ? `${Math.round(enrollments.reduce((sum, e) => sum + e.progressPercentage, 0) / enrollments.length)}%`
                                        : '0%'}
                                </span>
                            </div>
                            <div className="flex items-center justify-between">
                                <span className="text-sm text-slate-500 dark:text-slate-400">{t('admin.users.detail.stats.lastActive')}</span>
                                <span className="font-semibold text-slate-900 dark:text-white">
                                    {enrollments.length > 0
                                        ? format(new Date(Math.max(...enrollments.map(e => new Date(e.lastAccessedAt).getTime()))), 'dd/MM/yyyy')
                                        : '-'}
                                </span>
                            </div>
                        </div>
                    </div>

                    {/* Quick Notes or Tags could go here */}
                </div>
            </div>

            <UserFormModal
                isOpen={showEditModal}
                onClose={() => setShowEditModal(false)}
                onSuccess={handleEditSuccess}
                editingId={user.id}
                initialData={user}
            />

            <ResetPasswordModal
                isOpen={showResetModal}
                onClose={() => setShowResetModal(false)}
                userId={user.id}
            />

            {id && (
                <AddEnrollmentModal
                    isOpen={showAddCourseModal}
                    userId={id}
                    enrolledCourseIds={enrollments.map(e => e.courseId)}
                    onClose={() => setShowAddCourseModal(false)}
                    onSuccess={() => {
                        setShowAddCourseModal(false);
                        void fetchEnrollments(id);
                    }}
                />
            )}
        </AdminLayout>
    );
};

export default UserDetailPage;
