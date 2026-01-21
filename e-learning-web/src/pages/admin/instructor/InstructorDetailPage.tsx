import React, { useEffect, useState } from 'react';
import { Link, useParams } from 'react-router-dom';
import { useTranslation } from 'react-i18next';
import AdminLayout from '../../../components/admin/AdminLayout';
import { instructorApi, type InstructorDetailDto, type InstructorCourseDto } from '../../../services/instructorApi';
import { format } from 'date-fns';

type TabType = 'overview' | 'courses' | 'activity';

const InstructorDetailPage: React.FC = () => {
    const { id } = useParams<{ id: string }>();
    const { t } = useTranslation();
    const [instructor, setInstructor] = useState<InstructorDetailDto | null>(null);
    const [courses, setCourses] = useState<InstructorCourseDto[]>([]);
    const [activeTab, setActiveTab] = useState<TabType>('overview');
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState<string | null>(null);

    useEffect(() => {
        if (id) {
            void loadInstructor();
        }
        // eslint-disable-next-line react-hooks/exhaustive-deps
    }, [id]);

    useEffect(() => {
        if (id && activeTab === 'courses' && courses.length === 0) {
            void loadCourses();
        }
        // eslint-disable-next-line react-hooks/exhaustive-deps
    }, [activeTab, id]);

    const loadInstructor = async () => {
        if (!id) return;
        try {
            setLoading(true);
            const data = await instructorApi.getById(id);
            setInstructor(data);
        } catch (err: any) {
            setError(err.message || t('admin.instructors.errors.loadFailed'));
        } finally {
            setLoading(false);
        }
    };

    const loadCourses = async () => {
        if (!id) return;
        try {
            const data = await instructorApi.getCourses(id);
            setCourses(data);
        } catch (err: any) {
            console.error('Failed to load courses:', err);
        }
    };

    if (loading) {
        return (
            <AdminLayout>
                <div className="flex items-center justify-center py-12">
                    <div className="text-slate-500">{t('admin.instructors.detail.loading')}</div>
                </div>
            </AdminLayout>
        );
    }

    if (error || !instructor) {
        return (
            <AdminLayout>
                <div className="rounded-lg border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-700">
                    {error || t('admin.instructors.detail.notFound')}
                </div>
            </AdminLayout>
        );
    }

    const statusLabel = t(`admin.instructors.statuses.${instructor.status}`);

    return (
        <AdminLayout>
            {/* Breadcrumb */}
            <div className="mb-4 flex items-center gap-2 text-sm text-slate-500">
                <Link to="/admin/instructors" className="hover:text-dashboard-primary">
                    {t('admin.instructors.title')}
                </Link>
                <span>/</span>
                <span className="text-slate-900 dark:text-white">{instructor.fullName || instructor.email}</span>
            </div>

            {/* Header */}
            <div className="mb-6 flex flex-wrap items-start justify-between gap-4">
                <div className="flex items-start gap-4">
                    <div className="h-16 w-16 rounded-full border border-slate-200 bg-dashboard-primary/10 flex items-center justify-center text-2xl font-semibold text-dashboard-primary dark:border-slate-700">
                        {instructor.fullName ? instructor.fullName.charAt(0).toUpperCase() : instructor.email.charAt(0).toUpperCase()}
                    </div>
                    <div>
                        <h1 className="text-2xl font-bold text-slate-900 dark:text-white">
                            {instructor.fullName || t('common.unnamed')}
                        </h1>
                        <p className="text-sm text-slate-500 dark:text-slate-400">{instructor.email}</p>
                        <div className="mt-2 flex items-center gap-2">
                            <span className={`inline-flex items-center gap-1 rounded-full px-2 py-1 text-xs font-semibold ${instructor.status === 'ACTIVE' ? 'bg-green-100 text-green-700 dark:bg-green-900/30 dark:text-green-300' : 'bg-amber-100 text-amber-700 dark:bg-amber-900/30 dark:text-amber-300'}`}>
                                {statusLabel}
                            </span>
                            {instructor.isEmailVerified && (
                                <span className="inline-flex items-center gap-1 rounded-full bg-blue-100 px-2 py-1 text-xs font-semibold text-blue-700 dark:bg-blue-900/30 dark:text-blue-300">
                                    {t('admin.users.detail.verifiedEmail')}
                                </span>
                            )}
                        </div>
                    </div>
                </div>
                <Link
                    to="/admin/instructors"
                    className="inline-flex items-center gap-2 rounded-lg border border-slate-200 px-4 py-2 text-sm text-slate-700 transition hover:bg-slate-100 dark:border-slate-700 dark:text-slate-200 dark:hover:bg-slate-800"
                >
                    <span className="material-symbols-outlined text-[18px]">arrow_back</span>
                    {t('common.backToList')}
                </Link>
            </div>

            {/* Tabs */}
            <div className="mb-6 border-b border-slate-200 dark:border-slate-800">
                <div className="flex gap-6">
                    <button
                        onClick={() => setActiveTab('overview')}
                        className={`pb-3 text-sm font-medium transition ${activeTab === 'overview' ? 'border-b-2 border-dashboard-primary text-dashboard-primary' : 'text-slate-500 hover:text-slate-700 dark:text-slate-400 dark:hover:text-slate-200'}`}
                    >
                        {t('admin.instructors.detail.tabs.overview')}
                    </button>
                    <button
                        onClick={() => setActiveTab('courses')}
                        className={`pb-3 text-sm font-medium transition ${activeTab === 'courses' ? 'border-b-2 border-dashboard-primary text-dashboard-primary' : 'text-slate-500 hover:text-slate-700 dark:text-slate-400 dark:hover:text-slate-200'}`}
                    >
                        {t('admin.instructors.detail.tabs.courses')}
                    </button>
                    <button
                        onClick={() => setActiveTab('activity')}
                        className={`pb-3 text-sm font-medium transition ${activeTab === 'activity' ? 'border-b-2 border-dashboard-primary text-dashboard-primary' : 'text-slate-500 hover:text-slate-700 dark:text-slate-400 dark:hover:text-slate-200'}`}
                    >
                        {t('admin.instructors.detail.tabs.activity')}
                    </button>
                </div>
            </div>

            {/* Tab Content */}
            {activeTab === 'overview' && (
                <div className="space-y-6">
                    {/* Stats Cards */}
                    <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-4">
                        <div className="rounded-xl border border-slate-200 bg-white p-4 dark:border-slate-800 dark:bg-dashboard-surface-dark">
                            <div className="text-sm text-slate-500 dark:text-slate-400">{t('admin.instructors.detail.stats.totalCourses')}</div>
                            <div className="mt-1 text-2xl font-bold text-slate-900 dark:text-white">{instructor.stats.totalCourses}</div>
                            <div className="mt-1 text-xs text-slate-500">
                                {instructor.stats.publishedCourses} {t('admin.instructors.detail.stats.published')}
                            </div>
                        </div>
                        <div className="rounded-xl border border-slate-200 bg-white p-4 dark:border-slate-800 dark:bg-dashboard-surface-dark">
                            <div className="text-sm text-slate-500 dark:text-slate-400">{t('admin.instructors.detail.stats.totalStudents')}</div>
                            <div className="mt-1 text-2xl font-bold text-slate-900 dark:text-white">{instructor.stats.totalStudents}</div>
                        </div>
                        <div className="rounded-xl border border-slate-200 bg-white p-4 dark:border-slate-800 dark:bg-dashboard-surface-dark">
                            <div className="text-sm text-slate-500 dark:text-slate-400">{t('admin.instructors.detail.stats.totalRevenue')}</div>
                            <div className="mt-1 text-2xl font-bold text-slate-900 dark:text-white">
                                {new Intl.NumberFormat('vi-VN', { style: 'currency', currency: 'VND' }).format(instructor.stats.totalRevenue)}
                            </div>
                        </div>
                        <div className="rounded-xl border border-slate-200 bg-white p-4 dark:border-slate-800 dark:bg-dashboard-surface-dark">
                            <div className="text-sm text-slate-500 dark:text-slate-400">{t('admin.instructors.detail.stats.lastActive')}</div>
                            <div className="mt-1 text-2xl font-bold text-slate-900 dark:text-white">
                                {instructor.stats.lastActive ? format(new Date(instructor.stats.lastActive), 'dd/MM/yyyy') : '-'}
                            </div>
                        </div>
                    </div>

                    {/* Additional Info */}
                    <div className="rounded-xl border border-slate-200 bg-white p-6 dark:border-slate-800 dark:bg-dashboard-surface-dark">
                        <h2 className="mb-4 text-lg font-bold text-slate-900 dark:text-white">
                            {t('admin.users.detail.additionalInfo')}
                        </h2>
                        <div className="grid gap-4 md:grid-cols-2">
                            <div>
                                <div className="text-sm text-slate-500 dark:text-slate-400">{t('admin.instructors.form.phone')}</div>
                                <div className="mt-1 text-slate-900 dark:text-white">{instructor.phone || '-'}</div>
                            </div>
                            <div>
                                <div className="text-sm text-slate-500 dark:text-slate-400">{t('admin.instructors.table.created')}</div>
                                <div className="mt-1 text-slate-900 dark:text-white">{format(new Date(instructor.createdAt), 'dd/MM/yyyy HH:mm')}</div>
                            </div>
                            <div>
                                <div className="text-sm text-slate-500 dark:text-slate-400">{t('admin.instructors.detail.stats.updated')}</div>
                                <div className="mt-1 text-slate-900 dark:text-white">{format(new Date(instructor.updatedAt), 'dd/MM/yyyy HH:mm')}</div>
                            </div>
                            <div>
                                <div className="text-sm text-slate-500 dark:text-slate-400">2FA</div>
                                <div className="mt-1 text-slate-900 dark:text-white">
                                    {instructor.isTwoFactorEnabled ? t('admin.settings.security.statusEnabled') : t('admin.instructors.detail.stats.disabled')}
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            )}

            {activeTab === 'courses' && (
                <div className="space-y-4">
                    {courses.length === 0 ? (
                        <div className="rounded-xl border border-slate-200 bg-white p-8 text-center dark:border-slate-800 dark:bg-dashboard-surface-dark">
                            <p className="text-slate-500 dark:text-slate-400">{t('admin.instructors.detail.coursesEmpty')}</p>
                        </div>
                    ) : (
                        <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-3">
                            {courses.map((course) => (
                                <Link
                                    key={course.id}
                                    to={`/admin/courses/${course.id}`}
                                    className="group rounded-xl border border-slate-200 bg-white p-4 transition hover:border-dashboard-primary dark:border-slate-800 dark:bg-dashboard-surface-dark"
                                >
                                    {course.thumbnailUrl && (
                                        <img src={course.thumbnailUrl} alt={course.title} className="mb-3 h-32 w-full rounded-lg object-cover" />
                                    )}
                                    <h3 className="font-semibold text-slate-900 group-hover:text-dashboard-primary dark:text-white">
                                        {course.title}
                                    </h3>
                                    <p className="mt-1 line-clamp-2 text-sm text-slate-500 dark:text-slate-400">{course.description}</p>
                                    <div className="mt-3 flex items-center justify-between">
                                        <span className={`text-sm font-semibold ${course.isFree ? 'text-green-600' : 'text-dashboard-primary'}`}>
                                            {course.isFree ? t('courseDetail.free') : new Intl.NumberFormat('vi-VN', { style: 'currency', currency: 'VND' }).format(course.price)}
                                        </span>
                                        <span className="text-xs text-slate-500">{course.enrollmentCount} {t('admin.instructors.detail.stats.enrollments')}</span>
                                    </div>
                                    <div className="mt-2">
                                        <span className={`inline-flex items-center gap-1 rounded-full px-2 py-1 text-xs font-semibold ${course.isPublished ? 'bg-green-100 text-green-700 dark:bg-green-900/30 dark:text-green-300' : 'bg-amber-100 text-amber-700 dark:bg-amber-900/30 dark:text-amber-300'}`}>
                                            {course.isPublished ? t('admin.courses.status.published') : t('admin.courses.status.draft')}
                                        </span>
                                    </div>
                                </Link>
                            ))}
                        </div>
                    )}
                </div>
            )}

            {activeTab === 'activity' && (
                <div className="rounded-xl border border-slate-200 bg-white p-8 text-center dark:border-slate-800 dark:bg-dashboard-surface-dark">
                    <p className="text-slate-500 dark:text-slate-400">{t('admin.users.detail.activityEmpty')}</p>
                </div>
            )}
        </AdminLayout>
    );
};

export default InstructorDetailPage;
