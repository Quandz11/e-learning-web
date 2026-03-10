import React, { useState, useEffect } from 'react';
import { Link } from 'react-router-dom';
import { useTranslation } from 'react-i18next';
import { courseApi, type CourseResponse } from '../services/courseApi';
import { stripHtml } from '../utils/html';

const CoursesPage: React.FC = () => {
    const { t } = useTranslation();

    const [courses, setCourses] = useState<CourseResponse[]>([]);
    const [filteredCourses, setFilteredCourses] = useState<CourseResponse[]>([]);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState<string | null>(null);
    const [searchQuery, setSearchQuery] = useState('');
    const [priceFilter, setPriceFilter] = useState<'all' | 'free' | 'paid'>('all');

    useEffect(() => {
        const fetchCourses = async () => {
            try {
                setLoading(true);
                const allCourses = await courseApi.getAll();
                const published = allCourses.filter(c => c.isPublished);
                setCourses(published);
                setFilteredCourses(published);
            } catch (err: any) {
                setError(err.message || 'Failed to load courses');
            } finally {
                setLoading(false);
            }
        };
        fetchCourses();
    }, []);

    useEffect(() => {
        let result = [...courses];

        // Search filter
        if (searchQuery) {
            result = result.filter(c =>
                c.title.toLowerCase().includes(searchQuery.toLowerCase()) ||
                (c.description || '').toLowerCase().includes(searchQuery.toLowerCase())
            );
        }

        // Price filter
        if (priceFilter === 'free') {
            result = result.filter(c => c.isFree);
        } else if (priceFilter === 'paid') {
            result = result.filter(c => !c.isFree);
        }

        setFilteredCourses(result);
    }, [searchQuery, priceFilter, courses]);

    return (
        <div className="min-h-screen">
            {/* Main Content */}
            <main className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-12">
                {/* Page Header */}
                <div className="mb-8">
                    <h1 className="text-4xl font-bold text-[#0c1c1d] dark:text-white mb-2">
                        {t('courses.userTitle', { defaultValue: 'All Courses' })}
                    </h1>
                    <p className="text-gray-600 dark:text-gray-400">
                        {t('courses.userSubtitle', { defaultValue: 'Explore our comprehensive collection of courses' })}
                    </p>
                </div>

                {/* Search and Filters */}
                <div className="mb-8 flex flex-col md:flex-row gap-4">
                    {/* Search Box */}
                    <div className="flex-1 relative">
                        <div className="absolute inset-y-0 left-0 pl-4 flex items-center pointer-events-none">
                            <span className="material-symbols-outlined text-gray-400">search</span>
                        </div>
                        <input
                            type="text"
                            value={searchQuery}
                            onChange={(e) => setSearchQuery(e.target.value)}
                            className="block w-full pl-12 pr-4 py-3 rounded-lg border border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-800 text-gray-900 dark:text-white placeholder:text-gray-400 focus:ring-2 focus:ring-primary"
                            placeholder={t('admin.courses.searchPlaceholder')}
                        />
                    </div>

                    {/* Filter Buttons */}
                    <div className="flex gap-2">
                        <button
                            onClick={() => setPriceFilter('all')}
                            className={`px-4 py-3 rounded-lg font-medium transition-colors ${priceFilter === 'all'
                                ? 'bg-primary text-white'
                                : 'bg-white dark:bg-gray-800 text-gray-700 dark:text-gray-300 border border-gray-200 dark:border-gray-700 hover:border-primary'
                                }`}
                        >
                            {t('admin.courses.filters.all')}
                        </button>
                        <button
                            onClick={() => setPriceFilter('free')}
                            className={`px-4 py-3 rounded-lg font-medium transition-colors ${priceFilter === 'free'
                                ? 'bg-primary text-white'
                                : 'bg-white dark:bg-gray-800 text-gray-700 dark:text-gray-300 border border-gray-200 dark:border-gray-700 hover:border-primary'
                                }`}
                        >
                            {t('admin.courses.filters.free')}
                        </button>
                        <button
                            onClick={() => setPriceFilter('paid')}
                            className={`px-4 py-3 rounded-lg font-medium transition-colors ${priceFilter === 'paid'
                                ? 'bg-primary text-white'
                                : 'bg-white dark:bg-gray-800 text-gray-700 dark:text-gray-300 border border-gray-200 dark:border-gray-700 hover:border-primary'
                                }`}
                        >
                            {t('admin.courses.filters.premium')}
                        </button>
                    </div>
                </div>

                {/* Results Count */}
                <div className="mb-6 text-sm text-gray-600 dark:text-gray-400">
                    {t('admin.courses.resultsCount', { count: filteredCourses.length })}
                </div>

                {/* Course Grid */}
                {loading ? (
                    <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
                        {[0, 1, 2, 3, 4, 5].map((i) => (
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
                ) : error ? (
                    <div className="text-center py-12 text-red-500">{error}</div>
                ) : filteredCourses.length === 0 ? (
                    <div className="text-center py-12">
                        <span className="material-symbols-outlined text-6xl text-gray-300 dark:text-gray-600 mb-4">school_off</span>
                        <p className="text-gray-500">{t('admin.courses.noCourses')}</p>
                    </div>
                ) : (
                    <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
                        {filteredCourses.map((course) => (
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
                                            FREE
                                        </div>
                                    )}
                                    <div className="absolute inset-0 bg-black/0 group-hover:bg-black/10 transition-colors" />
                                </div>
                                <div className="p-5 flex flex-col flex-grow">
                                    <div className="flex items-center gap-2 mb-3">
                                        <span className="material-symbols-outlined text-yellow-400 text-sm">star</span>
                                        <span className="text-xs font-bold text-gray-700 dark:text-gray-300">4.8 (128)</span>
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
                                                {course.lecturer?.fullName || 'SKVI Instructor'}
                                            </span>
                                        </div>
                                        <span className="text-primary font-bold text-lg">
                                            {course.isFree ? 'FREE' : `${course.price.toLocaleString('vi-VN')} VND`}
                                        </span>
                                    </div>
                                </div>
                            </Link>
                        ))}
                    </div>
                )}
            </main>
        </div>
    );
};

export default CoursesPage;
