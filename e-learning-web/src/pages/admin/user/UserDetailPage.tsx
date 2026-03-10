import React, { useEffect, useState } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { useTranslation } from 'react-i18next';
import AdminLayout from '../../../components/admin/AdminLayout';
import { userApi, type UserDto, type UserRole, type UserStatus } from '../../../services/userApi';
import { adminEnrollmentApi, type AdminEnrollmentResponse } from '../../../services/adminEnrollmentApi';
import { format } from 'date-fns';
import UserFormModal from './components/UserFormModal';
import ResetPasswordModal from './components/ResetPasswordModal';
import AddEnrollmentModal from './components/AddEnrollmentModal';

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
    const [activeTab, setActiveTab] = useState<'overview' | 'courses' | 'activity'>('overview');

    // Enrollment management
    const [enrollments, setEnrollments] = useState<AdminEnrollmentResponse[]>([]);
    const [enrollmentsLoading, setEnrollmentsLoading] = useState(false);
    const [showAddCourseModal, setShowAddCourseModal] = useState(false);
    const [togglingId, setTogglingId] = useState<string | null>(null);
    const [removingId, setRemovingId] = useState<string | null>(null);

    const roleLabel = (value: UserRole) => t(`admin.users.roles.${value}`);
    const statusLabel = (value: UserStatus) => t(`admin.users.statuses.${value}`);

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

    useEffect(() => {
        if (activeTab === 'courses' && id) {
            void fetchEnrollments(id);
        }
    }, [activeTab, id]);

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
                            {(['overview', 'courses', 'activity'] as const).map((tab) => (
                                <button
                                    key={tab}
                                    onClick={() => setActiveTab(tab)}
                                    className={`mr-6 border-b-2 py-4 text-sm font-medium transition ${activeTab === tab
                                        ? 'border-dashboard-primary text-dashboard-primary'
                                        : 'border-transparent text-slate-500 hover:text-slate-700 dark:text-slate-400 dark:hover:text-slate-200'
                                        }`}
                                >
                                    {t(`admin.users.detail.tabs.${tab}`)}
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
