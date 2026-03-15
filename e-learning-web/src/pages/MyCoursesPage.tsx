import React, { useEffect, useState } from 'react';
import { Link } from 'react-router-dom';
import { useTranslation } from 'react-i18next';
import { enrollmentApi, type EnrollmentResponse } from '../services/enrollmentApi';

const MyCoursesPage: React.FC = () => {
    const { t } = useTranslation();
    const [enrollments, setEnrollments] = useState<EnrollmentResponse[]>([]);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState<string | null>(null);
    const [brokenThumbnails, setBrokenThumbnails] = useState<Record<string, boolean>>({});

    const apiBase = import.meta.env.VITE_API_URL || 'https://localhost:7145/api';
    const rootUrl = apiBase.replace(/\/api\/?$/, '');

    const getThumbnailUrl = (url?: string) => {
        if (!url) {
            return null;
        }

        if (url.startsWith('http://') || url.startsWith('https://') || url.startsWith('blob:') || url.startsWith('data:')) {
            return url;
        }

        return `${rootUrl}${url.startsWith('/') ? '' : '/'}${url}`;
    };

    useEffect(() => {
        const fetchEnrollments = async () => {
            try {
                setLoading(true);
                const data = await enrollmentApi.getUserEnrollments();
                setEnrollments(data);
            } catch (err: any) {
                setError(err.message || t('myCourses.loadFailed'));
            } finally {
                setLoading(false);
            }
        };
        void fetchEnrollments();
    }, []);

    return (
        <div className="min-h-screen bg-gray-50 dark:bg-gray-900 py-12 px-4 sm:px-6 lg:px-8">
            <div className="mx-auto max-w-7xl">
                {/* Header */}
                <div className="mb-10">
                    <h1 className="text-3xl font-bold text-gray-900 dark:text-white">
                        {t('myCourses.title')}
                    </h1>
                    <p className="mt-2 text-gray-600 dark:text-gray-400">
                        {t('myCourses.subtitle')}
                    </p>
                </div>

                {/* Loading */}
                {loading && (
                    <div className="grid grid-cols-1 gap-6 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4">
                        {Array.from({ length: 8 }).map((_, i) => (
                            <div key={i} className="animate-pulse rounded-2xl bg-white dark:bg-gray-800 overflow-hidden shadow-sm border border-gray-100 dark:border-gray-700">
                                <div className="aspect-video bg-gray-200 dark:bg-gray-700" />
                                <div className="p-4 space-y-3">
                                    <div className="h-4 bg-gray-200 dark:bg-gray-700 rounded w-3/4" />
                                    <div className="h-3 bg-gray-200 dark:bg-gray-700 rounded w-full" />
                                    <div className="h-2 bg-gray-200 dark:bg-gray-700 rounded-full" />
                                </div>
                            </div>
                        ))}
                    </div>
                )}

                {/* Error */}
                {!loading && error && (
                    <div className="flex flex-col items-center justify-center py-20">
                        <span className="material-symbols-outlined mb-4 text-[64px] text-red-300">error</span>
                        <p className="text-red-500">{error}</p>
                    </div>
                )}

                {/* Empty */}
                {!loading && !error && enrollments.length === 0 && (
                    <div className="flex flex-col items-center justify-center py-24 text-center">
                        <span className="material-symbols-outlined mb-4 text-[72px] text-gray-300 dark:text-gray-600">school</span>
                        <h2 className="mb-2 text-xl font-semibold text-gray-700 dark:text-gray-300">
                            {t('myCourses.emptyTitle')}
                        </h2>
                        <p className="mb-6 text-gray-500 dark:text-gray-400 max-w-sm">
                            {t('myCourses.emptyDesc')}
                        </p>
                        <Link
                            to="/courses"
                            className="inline-flex items-center gap-2 rounded-lg bg-primary px-6 py-3 text-sm font-bold text-white shadow-md shadow-primary/20 hover:bg-primary/90 transition-all hover:scale-105"
                        >
                            <span className="material-symbols-outlined text-[18px]">explore</span>
                            {t('myCourses.browseCourses')}
                        </Link>
                    </div>
                )}

                {/* Course Grid */}
                {!loading && !error && enrollments.length > 0 && (
                    <>
                        <p className="mb-6 text-sm text-gray-500 dark:text-gray-400">
                            {t('myCourses.count', { count: enrollments.length })}
                        </p>
                        <div className="grid grid-cols-2 gap-3 sm:grid-cols-2 sm:gap-5 lg:grid-cols-3 lg:gap-6 xl:grid-cols-4">
                            {enrollments.map((enrollment) => {
                                const isExpired = Boolean(
                                    enrollment.isExpired
                                    || (enrollment.accessExpiresAt && new Date(enrollment.accessExpiresAt).getTime() <= Date.now())
                                );
                                const expiresAtDate = enrollment.accessExpiresAt ? new Date(enrollment.accessExpiresAt) : null;
                                const daysRemaining = expiresAtDate
                                    ? Math.ceil((expiresAtDate.getTime() - Date.now()) / (1000 * 60 * 60 * 24))
                                    : null;
                                const isExpiringSoon = !isExpired && daysRemaining !== null && daysRemaining <= 7;

                                return (
                                <Link
                                    key={enrollment.id}
                                    to={isExpired ? `/courses/${enrollment.courseId.toLowerCase()}` : `/courses/${enrollment.courseId.toLowerCase()}/learn`}
                                    className="group flex flex-col rounded-2xl bg-white dark:bg-gray-800 shadow-sm hover:shadow-xl transition-all duration-300 border border-gray-100 dark:border-gray-700 overflow-hidden"
                                >
                                    {/* Thumbnail / Progress overlay */}
                                    <div className="relative aspect-square overflow-hidden bg-gradient-to-br from-primary/20 to-primary/5">
                                        {enrollment.courseThumbnail && !brokenThumbnails[enrollment.courseId] ? (
                                            <img
                                                src={getThumbnailUrl(enrollment.courseThumbnail) || undefined}
                                                alt={enrollment.courseTitle}
                                                className="absolute inset-0 h-full w-full object-cover"
                                                onError={() => setBrokenThumbnails((prev) => ({ ...prev, [enrollment.courseId]: true }))}
                                                loading="lazy"
                                            />
                                        ) : (
                                            <div className="absolute inset-0 bg-gradient-to-br from-blue-500 via-purple-500 to-pink-500" />
                                        )}
                                        <div className="absolute inset-0 bg-black/0 group-hover:bg-black/10 transition-colors" />

                                        {/* Progress badge */}
                                        {enrollment.progressPercentage > 0 && (
                                            <div className="absolute top-3 right-3 rounded-full bg-black/60 px-2.5 py-1 text-xs font-bold text-white backdrop-blur-sm">
                                                {enrollment.progressPercentage}%
                                            </div>
                                        )}

                                        {/* Completed badge */}
                                        {enrollment.completedAt && (
                                            <div className="absolute top-3 left-3 flex items-center gap-1 rounded-full bg-green-500 px-2.5 py-1 text-xs font-bold text-white">
                                                <span className="material-symbols-outlined text-[14px]">check_circle</span>
                                                {t('myCourses.completed')}
                                            </div>
                                        )}

                                        {!enrollment.completedAt && isExpired && (
                                            <div className="absolute top-3 left-3 rounded-full bg-red-500 px-2.5 py-1 text-xs font-bold text-white">
                                                {t('myCourses.expired', { defaultValue: 'Expired' })}
                                            </div>
                                        )}

                                        {!isExpired && !enrollment.completedAt && isExpiringSoon && (
                                            <div className="absolute top-3 left-3 rounded-full bg-amber-500 px-2.5 py-1 text-xs font-bold text-white">
                                                {t('myCourses.expiringSoon', { defaultValue: 'Expiring soon' })}
                                            </div>
                                        )}

                                        {!isExpired && !isExpiringSoon && !enrollment.accessExpiresAt && (
                                            <div className="absolute bottom-3 left-3 rounded-full bg-blue-500 px-2.5 py-1 text-xs font-bold text-white">
                                                {t('myCourses.lifetime', { defaultValue: 'Lifetime' })}
                                            </div>
                                        )}

                                        {/* Play icon overlay */}
                                        <div className="absolute inset-0 flex items-center justify-center opacity-0 group-hover:opacity-100 transition-opacity">
                                            <div className="flex h-12 w-12 items-center justify-center rounded-full bg-white/90 shadow-lg">
                                                <span className="material-symbols-outlined text-primary text-[28px]">play_arrow</span>
                                            </div>
                                        </div>
                                    </div>

                                    {/* Info */}
                                    <div className="flex flex-1 flex-col p-4">
                                        <h3 className="mb-1 line-clamp-2 text-sm font-bold text-gray-900 dark:text-white leading-snug group-hover:text-primary transition-colors">
                                            {enrollment.courseTitle}
                                        </h3>

                                        {/* Progress bar */}
                                        <div className="mt-auto pt-3">
                                            <div className="mb-1 flex items-center justify-between text-xs text-gray-500 dark:text-gray-400">
                                                <span>{t('myCourses.progress')}</span>
                                                <span className="font-medium">{enrollment.progressPercentage}%</span>
                                            </div>
                                            <div className="h-1.5 w-full overflow-hidden rounded-full bg-gray-200 dark:bg-gray-700">
                                                <div
                                                    className={`h-full rounded-full transition-all ${enrollment.progressPercentage === 100 ? 'bg-green-500' : 'bg-primary'}`}
                                                    style={{ width: `${enrollment.progressPercentage}%` }}
                                                />
                                            </div>

                                            <p className="mt-2 text-xs text-gray-400 dark:text-gray-500">
                                                {t('myCourses.enrolledAt')}{' '}
                                                {new Date(enrollment.enrolledAt).toLocaleDateString('vi-VN')}
                                            </p>

                                            <p className="mt-1 text-xs text-gray-500 dark:text-gray-400">
                                                {!enrollment.accessExpiresAt
                                                    ? t('myCourses.lifetime', { defaultValue: 'Lifetime' })
                                                    : isExpired
                                                        ? t('myCourses.expiredOn', {
                                                            defaultValue: 'Expired on {{date}}',
                                                            date: expiresAtDate?.toLocaleDateString('vi-VN') || '-',
                                                        })
                                                        : t('myCourses.expiresOn', {
                                                            defaultValue: 'Expires on {{date}}',
                                                            date: expiresAtDate?.toLocaleDateString('vi-VN') || '-',
                                                        })}
                                            </p>
                                        </div>
                                    </div>
                                </Link>
                                );
                            })}
                        </div>
                    </>
                )}
            </div>
        </div>
    );
};

export default MyCoursesPage;
