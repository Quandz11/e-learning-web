import React, { useState, useEffect } from 'react';
import { Link } from 'react-router-dom';
import { useTranslation } from 'react-i18next';
import { courseApi, type CourseResponse } from '../../services/courseApi';
import { stripHtml } from '../../utils/html';

interface CourseListProps {
    limit?: number;
    pageSize?: number;
    showFilter?: boolean;
    showPagination?: boolean;
    cols?: 3 | 4;
}

const CourseList: React.FC<CourseListProps> = ({
    limit,
    pageSize = 12,
    showPagination = false,
    cols = 3,
}) => {
    const { t } = useTranslation();
    const [allCourses, setAllCourses] = useState<CourseResponse[]>([]);
    const [courses, setCourses] = useState<CourseResponse[]>([]);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState<string | null>(null);
    const [page, setPage] = useState(1);

    useEffect(() => {
        const fetchCourses = async () => {
            try {
                setLoading(true);
                const fetched = await courseApi.getAll();
                const published = fetched.filter(c => c.isPublished);
                setAllCourses(published);
            } catch (err: any) {
                setError(err.message || 'Failed to load courses');
            } finally {
                setLoading(false);
            }
        };
        fetchCourses();
    }, []);

    useEffect(() => {
        if (showPagination) {
            const start = (page - 1) * pageSize;
            setCourses(allCourses.slice(start, start + pageSize));
        } else if (limit) {
            setCourses(allCourses.slice(0, limit));
        } else {
            setCourses(allCourses);
        }
    }, [allCourses, page, limit, pageSize, showPagination]);

    const totalPages = showPagination ? Math.ceil(allCourses.length / pageSize) : 1;
    const gridClass = cols === 4
        ? 'grid grid-cols-2 gap-3 sm:grid-cols-2 sm:gap-5 lg:grid-cols-3 lg:gap-6 xl:grid-cols-4'
        : 'grid grid-cols-2 gap-3 sm:gap-5 md:grid-cols-2 lg:grid-cols-3 lg:gap-6';

    if (loading) {
        const skeletonCount = showPagination ? pageSize : (limit ?? 3);
        return (
            <div className={gridClass}>
                {Array.from({ length: Math.min(skeletonCount, 12) }).map((_, i) => (
                    <div key={i} className="overflow-hidden rounded-2xl border border-gray-100 bg-white shadow-sm animate-pulse dark:border-gray-700 dark:bg-gray-800">
                        <div className="aspect-square bg-gray-200 dark:bg-gray-700" />
                        <div className="space-y-3 p-4 sm:p-5">
                            <div className="h-4 bg-gray-200 dark:bg-gray-700 rounded w-3/4" />
                            <div className="h-3 bg-gray-200 dark:bg-gray-700 rounded" />
                            <div className="h-3 bg-gray-200 dark:bg-gray-700 rounded w-5/6" />
                        </div>
                    </div>
                ))}
            </div>
        );
    }

    if (error) {
        return (
            <div className="text-center py-12 text-red-500">
                {error}
            </div>
        );
    }

    if (courses.length === 0) {
        return (
            <div className="text-center py-12 text-gray-500">
                {t('home.courses.noCourses', { defaultValue: 'No courses available yet' })}
            </div>
        );
    }

    return (
        <>
        <div className={gridClass}>
            {courses.map((course) => (
                <Link
                    key={course.id}
                    to={`/courses/${course.id}`}
                    className="group flex min-w-0 flex-col overflow-hidden rounded-2xl border border-gray-100 bg-white shadow-sm transition-all duration-300 hover:shadow-xl dark:border-gray-700 dark:bg-gray-800"
                >
                    <div className="relative aspect-square overflow-hidden bg-gradient-to-br from-primary/20 to-primary/5">
                        {course.thumbnailUrl ? (
                            <img
                                src={course.thumbnailUrl}
                                alt={course.title}
                                className="w-full h-full object-cover group-hover:scale-105 transition-transform duration-300"
                            />
                        ) : (
                            <div className="absolute inset-0 bg-gradient-to-br from-blue-500 via-purple-500 to-pink-500" />
                        )}
                        {course.isFree && (
                            <div className="absolute left-2.5 top-2.5 z-10 rounded bg-green-500 px-2 py-1 text-[11px] font-bold text-white shadow-sm sm:left-3 sm:top-3 sm:text-xs">
                                {t('home.courses.free', { defaultValue: 'FREE' })}
                            </div>
                        )}
                        {/* Logic for "Popular" tag could be added here if needed, consistent with original HomePage */}
                        <div className="absolute inset-0 bg-black/0 group-hover:bg-black/10 transition-colors"></div>
                    </div>
                    <div className="flex flex-grow flex-col p-3 sm:p-5">
                        <div className="mb-2 flex items-center gap-1.5 sm:mb-3 sm:gap-2">
                            <span className="material-symbols-outlined text-yellow-400 text-sm">star</span>
                            <span className="truncate text-[11px] sm:text-xs font-bold text-gray-700 dark:text-gray-300">
                                4.8 (128 {t('home.courses.reviews', { defaultValue: 'reviews' })})
                            </span>
                        </div>
                        <h3 className="mb-1.5 line-clamp-2 text-sm font-semibold leading-snug text-[#0c1c1d] dark:text-white sm:mb-2 sm:text-lg md:text-xl">
                            {course.title}
                        </h3>
                        <p className="mb-4 hidden line-clamp-2 text-sm text-gray-500 dark:text-gray-400 sm:mb-4 sm:block">
                            {stripHtml(course.description || '')}
                        </p>
                        <div className="mt-auto flex items-center justify-between border-t border-gray-100 pt-2.5 dark:border-gray-700 sm:gap-3 sm:pt-4">
                            <div className="hidden min-w-0 items-center gap-2 sm:flex">
                                {course.lecturer?.avatarUrl ? (
                                    <img
                                        src={course.lecturer.avatarUrl}
                                        alt={course.lecturer.fullName}
                                        className="w-6 h-6 rounded-full object-cover"
                                    />
                                ) : (
                                    <div className="w-6 h-6 rounded-full bg-gradient-to-br from-primary to-blue-600" />
                                )}
                                <span className="truncate text-xs font-medium text-gray-600 dark:text-gray-300 sm:max-w-[120px]">
                                    {course.lecturer?.fullName || 'NhinAnChuaLanh Instructor'}
                                </span>
                            </div>
                            <span className="ml-auto text-xs font-bold text-primary sm:text-base md:text-lg">
                                {course.isFree ? t('home.courses.free', { defaultValue: 'FREE' }) : `${course.price.toLocaleString('vi-VN')} VND`}
                            </span>
                        </div>
                    </div>
                </Link>
            ))}
        </div>

        {/* Pagination */}
        {showPagination && totalPages > 1 && (
            <div className="mt-8 flex flex-wrap items-center justify-center gap-2 sm:mt-10">
                <button
                    onClick={() => setPage(p => Math.max(1, p - 1))}
                    disabled={page === 1}
                    className="flex h-9 w-9 items-center justify-center rounded-lg border border-gray-300 bg-white text-gray-600 hover:bg-gray-50 disabled:opacity-40 dark:border-gray-600 dark:bg-gray-800 dark:text-gray-300 dark:hover:bg-gray-700"
                >
                    <span className="material-symbols-outlined text-[18px]">chevron_left</span>
                </button>

                {Array.from({ length: totalPages }).map((_, i) => {
                    const p = i + 1;
                    const show = p === 1 || p === totalPages || Math.abs(p - page) <= 1;
                    const showDot = !show && (p === page - 2 || p === page + 2);
                    if (showDot) return <span key={p} className="text-gray-400">…</span>;
                    if (!show) return null;
                    return (
                        <button
                            key={p}
                            onClick={() => setPage(p)}
                            className={`h-9 w-9 rounded-lg text-sm font-medium transition-colors ${
                                p === page
                                    ? 'bg-primary text-white shadow-sm'
                                    : 'border border-gray-300 bg-white text-gray-600 hover:bg-gray-50 dark:border-gray-600 dark:bg-gray-800 dark:text-gray-300'
                            }`}
                        >
                            {p}
                        </button>
                    );
                })}

                <button
                    onClick={() => setPage(p => Math.min(totalPages, p + 1))}
                    disabled={page === totalPages}
                    className="flex h-9 w-9 items-center justify-center rounded-lg border border-gray-300 bg-white text-gray-600 hover:bg-gray-50 disabled:opacity-40 dark:border-gray-600 dark:bg-gray-800 dark:text-gray-300 dark:hover:bg-gray-700"
                >
                    <span className="material-symbols-outlined text-[18px]">chevron_right</span>
                </button>
            </div>
        )}
        </>
    );
};

export default CourseList;
