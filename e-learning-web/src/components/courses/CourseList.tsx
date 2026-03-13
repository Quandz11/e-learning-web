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
        ? 'grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6'
        : 'grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6';

    if (loading) {
        const skeletonCount = showPagination ? pageSize : (limit ?? 3);
        return (
            <div className={gridClass}>
                {Array.from({ length: Math.min(skeletonCount, 12) }).map((_, i) => (
                    <div key={i} className="bg-white dark:bg-gray-800 rounded-2xl shadow-sm border border-gray-100 dark:border-gray-700 overflow-hidden animate-pulse">
                        <div className="aspect-square bg-gray-200 dark:bg-gray-700" />
                        <div className="p-5 space-y-3">
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
                    className="group flex flex-col bg-white dark:bg-gray-800 rounded-2xl shadow-sm hover:shadow-xl transition-all duration-300 border border-gray-100 dark:border-gray-700 overflow-hidden"
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
                            <div className="absolute top-3 left-3 bg-green-500 text-white text-xs font-bold px-2 py-1 rounded shadow-sm z-10">
                                {t('home.courses.free', { defaultValue: 'FREE' })}
                            </div>
                        )}
                        {/* Logic for "Popular" tag could be added here if needed, consistent with original HomePage */}
                        <div className="absolute inset-0 bg-black/0 group-hover:bg-black/10 transition-colors"></div>
                    </div>
                    <div className="p-5 flex flex-col flex-grow">
                        <div className="flex items-center gap-2 mb-3">
                            <span className="material-symbols-outlined text-yellow-400 text-sm">star</span>
                            <span className="text-xs font-bold text-gray-700 dark:text-gray-300">
                                4.8 (128 {t('home.courses.reviews', { defaultValue: 'reviews' })})
                            </span>
                        </div>
                        <h3 className="text-xl font-bold text-[#0c1c1d] dark:text-white mb-2 leading-tight line-clamp-2">
                            {course.title}
                        </h3>
                        <p className="text-sm text-gray-500 dark:text-gray-400 mb-4 line-clamp-2">
                            {stripHtml(course.description || '')}
                        </p>
                        <div className="mt-auto pt-4 border-t border-gray-100 dark:border-gray-700 flex items-center justify-between">
                            <div className="flex items-center gap-2">
                                {course.lecturer?.avatarUrl ? (
                                    <img
                                        src={course.lecturer.avatarUrl}
                                        alt={course.lecturer.fullName}
                                        className="w-6 h-6 rounded-full object-cover"
                                    />
                                ) : (
                                    <div className="w-6 h-6 rounded-full bg-gradient-to-br from-primary to-blue-600" />
                                )}
                                <span className="text-xs font-medium text-gray-600 dark:text-gray-300 truncate max-w-[120px]">
                                    {course.lecturer?.fullName || 'NhinAnChuaLanh Instructor'}
                                </span>
                            </div>
                            <span className="text-primary font-bold text-lg">
                                {course.isFree ? t('home.courses.free', { defaultValue: 'FREE' }) : `${course.price.toLocaleString('vi-VN')} VND`}
                            </span>
                        </div>
                    </div>
                </Link>
            ))}
        </div>

        {/* Pagination */}
        {showPagination && totalPages > 1 && (
            <div className="mt-10 flex items-center justify-center gap-2">
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
