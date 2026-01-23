import React, { useState, useEffect } from 'react';
import { useParams, useNavigate, Link } from 'react-router-dom';
import { useSelector } from 'react-redux';
import type { RootState } from '../store/store';
import { courseApi, type CourseResponse } from '../services/courseApi';
import { enrollmentApi } from '../services/enrollmentApi';
import { useTranslation } from 'react-i18next';

const StudentCourseDetailPage: React.FC = () => {
    const { t } = useTranslation();
    const { id } = useParams<{ id: string }>();
    const navigate = useNavigate();
    const { isAuthenticated } = useSelector((state: RootState) => state.auth);

    const [course, setCourse] = useState<CourseResponse | null>(null);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState<string | null>(null);
    const [expandedSections, setExpandedSections] = useState<Set<string>>(new Set());
    const [isEnrolled, setIsEnrolled] = useState(false);
    const [enrolling, setEnrolling] = useState(false);

    useEffect(() => {
        const fetchCourse = async () => {
            if (!id) return;
            try {
                setLoading(true);
                const data = await courseApi.getById(id);
                setCourse(data);
                if (data.sections.length > 0) {
                    setExpandedSections(new Set([data.sections[0].id || '0']));
                }
            } catch (err: any) {
                setError(err.message || t('courseDetail.loadError'));
            } finally {
                setLoading(false);
            }
        };
        fetchCourse();
    }, [id]);

    // Check enrollment status
    useEffect(() => {
        const checkEnrollment = async () => {
            if (!id || !isAuthenticated || !course) return;

            try {
                const enrolled = await enrollmentApi.checkEnrollment(id);
                setIsEnrolled(enrolled);
            } catch (err) {
                console.error('Failed to check enrollment:', err);
            }
        };
        checkEnrollment();
    }, [id, isAuthenticated, course]);

    const toggleSection = (sectionId: string) => {
        setExpandedSections(prev => {
            const newSet = new Set(prev);
            if (newSet.has(sectionId)) {
                newSet.delete(sectionId);
            } else {
                newSet.add(sectionId);
            }
            return newSet;
        });
    };

    const handleEnroll = async () => {
        if (!isAuthenticated) {
            navigate('/login', { state: { from: `/courses/${id}` } });
            return;
        }

        if (!course) return;

        if (course.isFree) {
            try {
                setEnrolling(true);
                await enrollmentApi.enrollInCourse(course.id);
                setIsEnrolled(true);
                navigate(`/courses/${id}/learn`);
            } catch (err: any) {
                alert(err.message || 'Failed to enroll in course');
            } finally {
                setEnrolling(false);
            }
        } else {
            alert(t('courseDetail.paymentRequired'));
        }
    };

    const totalLessons = course?.sections.reduce((sum, s) => sum + s.lessons.length, 0) || 0;
    const totalDuration = course?.sections.reduce(
        (sum, s) => sum + s.lessons.reduce((lSum, l) => lSum + (l.duration || 0), 0),
        0
    ) || 0;

    if (loading) {
        return (
            <div className="min-h-screen bg-background-light dark:bg-background-dark flex items-center justify-center">
                <div className="text-center">
                    <div className="inline-block h-12 w-12 animate-spin rounded-full border-4 border-solid border-primary border-r-transparent" />
                    <p className="mt-4 text-gray-600 dark:text-gray-300">{t('courseDetail.loading')}</p>
                </div>
            </div>
        );
    }

    if (error || !course) {
        return (
            <div className="min-h-screen bg-background-light dark:bg-background-dark flex items-center justify-center">
                <div className="text-center">
                    <span className="material-symbols-outlined text-6xl text-red-500 mb-4">error</span>
                    <p className="text-red-500">{error || 'Course not found'}</p>
                    <Link to="/courses" className="mt-4 inline-block text-primary hover:underline">
                        ← {t('common.backToList')}
                    </Link>
                </div>
            </div>
        );
    }

    // Determine button state
    const getEnrollButtonText = () => {
        if (enrolling) return t('courseDetail.enrolling');
        if (isEnrolled) return t('courseDetail.startLearning');
        return course.isFree ? t('courseDetail.enrollFree') : t('courseDetail.enrollPremium');
    };

    const handleButtonClick = () => {
        if (isEnrolled) {
            navigate(`/courses/${id}/learn`);
        } else {
            handleEnroll();
        }
    };

    return (
        <div className="min-h-screen bg-background-light dark:bg-background-dark">
            {/* Header */}
            <header className="sticky top-0 z-50 w-full bg-background-light/95 dark:bg-background-dark/95 backdrop-blur-md border-b border-gray-200 dark:border-gray-800">
                <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
                    <div className="flex items-center justify-between h-20">
                        <Link to="/" className="flex items-center gap-3">
                            <span className="material-symbols-outlined text-primary text-4xl">school</span>
                            <h2 className="text-[#0c1c1d] dark:text-white text-xl font-bold tracking-tight">
                                SKVI Learning<span className="text-primary">.</span>
                            </h2>
                        </Link>
                        <button
                            onClick={() => navigate('/courses')}
                            className="flex items-center gap-2 text-gray-600 dark:text-gray-300 hover:text-primary transition-colors"
                        >
                            <span className="material-symbols-outlined">arrow_back</span>
                            <span className="hidden sm:inline">{t('common.backToList')}</span>
                        </button>
                    </div>
                </div>
            </header>

            {/* Hero Section */}
            <div className="bg-gradient-to-br from-primary/10 to-blue-500/10 dark:from-primary/20 dark:to-blue-500/20 border-b border-gray-200 dark:border-gray-800">
                <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-12">
                    <div className="grid lg:grid-cols-3 gap-8">
                        {/* Course Info */}
                        <div className="lg:col-span-2 space-y-6">
                            <div>
                                <div className="flex items-center gap-2 mb-3">
                                    {course.isFree ? (
                                        <span className="px-3 py-1 rounded-full bg-green-500 text-white text-xs font-bold">
                                            {t('courseDetail.freeCourse')}
                                        </span>
                                    ) : (
                                        <span className="px-3 py-1 rounded-full bg-primary text-white text-xs font-bold">
                                            {t('courseDetail.premium')}
                                        </span>
                                    )}
                                    {isEnrolled && (
                                        <span className="px-3 py-1 rounded-full bg-blue-500 text-white text-xs font-bold">
                                            ✓ {t('courseDetail.enrolled')}
                                        </span>
                                    )}
                                    <span className={`px-3 py-1 rounded-full text-xs font-bold ${course.isPublished
                                        ? 'bg-success/10 text-success border border-success/20'
                                        : 'bg-gray-100 text-gray-500'
                                        }`}>
                                        {course.isPublished ? t('courseDetail.meta.statusPublished') : t('courseDetail.meta.statusDraft')}
                                    </span>
                                </div>
                                <h1 className="text-4xl lg:text-5xl font-bold text-[#0c1c1d] dark:text-white mb-4">
                                    {course.title}
                                </h1>
                                <p className="text-lg text-gray-600 dark:text-gray-300 leading-relaxed">
                                    {course.description}
                                </p>
                            </div>

                            {/* Stats */}
                            <div className="flex flex-wrap gap-6 text-sm">
                                <div className="flex items-center gap-2">
                                    <span className="material-symbols-outlined text-yellow-400">star</span>
                                    <span className="font-bold text-gray-900 dark:text-white">4.8</span>
                                    <span className="text-gray-600 dark:text-gray-400">(128 reviews)</span>
                                </div>
                                <div className="flex items-center gap-2">
                                    <span className="material-symbols-outlined text-primary">groups</span>
                                    <span className="text-gray-900 dark:text-white font-medium">1,240 students</span>
                                </div>
                                <div className="flex items-center gap-2">
                                    <span className="material-symbols-outlined text-primary">schedule</span>
                                    <span className="text-gray-900 dark:text-white font-medium">{t('courseDetail.durationMinutes', { minutes: totalDuration })}</span>
                                </div>
                                <div className="flex items-center gap-2">
                                    <span className="material-symbols-outlined text-primary">play_circle</span>
                                    <span className="text-gray-900 dark:text-white font-medium">{totalLessons} {t('courseDetail.lessons')}</span>
                                </div>
                            </div>

                            {/* Instructor */}
                            {course.lecturer && (
                                <div className="flex items-center gap-3 p-4 bg-white dark:bg-gray-800 rounded-lg border border-gray-200 dark:border-gray-700">
                                    {course.lecturer.avatarUrl ? (
                                        <img
                                            src={course.lecturer.avatarUrl}
                                            alt={course.lecturer.fullName}
                                            className="w-14 h-14 rounded-full object-cover"
                                        />
                                    ) : (
                                        <div className="w-14 h-14 rounded-full bg-gradient-to-br from-primary to-blue-600 flex items-center justify-center text-white font-bold text-xl">
                                            {course.lecturer.fullName.charAt(0)}
                                        </div>
                                    )}
                                    <div>
                                        <p className="text-sm text-gray-500 dark:text-gray-400">{t('courseDetail.instructor')}</p>
                                        <p className="font-bold text-gray-900 dark:text-white">{course.lecturer.fullName}</p>
                                    </div>
                                </div>
                            )}
                        </div>

                        {/* Enrollment Card */}
                        <div className="lg:col-span-1">
                            <div className="sticky top-24 bg-white dark:bg-gray-800 rounded-2xl shadow-xl border border-gray-200 dark:border-gray-700 overflow-hidden">
                                {/* Preview Image */}
                                <div className="aspect-video bg-gradient-to-br from-primary/20 to-blue-500/20 relative">
                                    {course.thumbnailUrl ? (
                                        <img src={course.thumbnailUrl} alt={course.title} className="w-full h-full object-cover" />
                                    ) : (
                                        <div className="absolute inset-0 flex items-center justify-center">
                                            <span className="material-symbols-outlined text-6xl text-primary/50">school</span>
                                        </div>
                                    )}
                                </div>

                                <div className="p-6 space-y-4">
                                    {/* Price */}
                                    <div className="text-center">
                                        <p className="text-4xl font-bold text-primary">
                                            {course.isFree ? t('courseDetail.free') : `${course.price.toLocaleString('vi-VN')} VND`}
                                        </p>
                                    </div>

                                    {/* Enroll/Start Learning Button */}
                                    <button
                                        onClick={handleButtonClick}
                                        disabled={enrolling}
                                        className={`w-full py-4 ${isEnrolled
                                            ? 'bg-blue-600 hover:bg-blue-700'
                                            : 'bg-primary hover:bg-primary/90'
                                            } text-white font-bold rounded-lg transition-all shadow-lg shadow-primary/30 hover:shadow-xl hover:scale-105 disabled:opacity-50 disabled:cursor-not-allowed`}
                                    >
                                        {getEnrollButtonText()}
                                    </button>

                                    {/* Features */}
                                    <div className="space-y-3 pt-4 border-t border-gray-200 dark:border-gray-700">
                                        <div className="flex items-center gap-3 text-sm">
                                            <span className="material-symbols-outlined text-primary">all_inclusive</span>
                                            <span className="text-gray-700 dark:text-gray-300">{t('courseDetail.features.lifetimeAccess')}</span>
                                        </div>
                                        <div className="flex items-center gap-3 text-sm">
                                            <span className="material-symbols-outlined text-primary">phone_iphone</span>
                                            <span className="text-gray-700 dark:text-gray-300">{t('courseDetail.features.mobileAccess')}</span>
                                        </div>
                                        <div className="flex items-center gap-3 text-sm">
                                            <span className="material-symbols-outlined text-primary">workspace_premium</span>
                                            <span className="text-gray-700 dark:text-gray-300">{t('courseDetail.features.certificate')}</span>
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>

            {/* Main Content */}
            <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-12">
                <div className="grid lg:grid-cols-3 gap-8">
                    {/* Left Column - Course Content */}
                    <div className="lg:col-span-2 space-y-8">
                        {/* Curriculum */}
                        <div>
                            <h2 className="text-2xl font-bold text-gray-900 dark:text-white mb-6">
                                {t('courseDetail.curriculumTab')}
                            </h2>
                            <div className="border border-gray-200 dark:border-gray-700 rounded-xl divide-y divide-gray-200 dark:divide-gray-700 overflow-hidden">
                                {course.sections.map((section, sIdx) => {
                                    const sectionId = section.id || `${sIdx}`;
                                    const isExpanded = expandedSections.has(sectionId);
                                    const sectionDuration = section.lessons.reduce((sum, l) => sum + (l.duration || 0), 0);

                                    return (
                                        <div key={sectionId} className="bg-white dark:bg-gray-800">
                                            <button
                                                onClick={() => toggleSection(sectionId)}
                                                className="w-full p-4 flex justify-between items-center hover:bg-gray-50 dark:hover:bg-gray-700 transition-colors"
                                            >
                                                <div className="flex items-center gap-3">
                                                    <span className={`material-symbols-outlined text-gray-400 transition-transform ${isExpanded ? 'rotate-180' : ''}`}>
                                                        expand_more
                                                    </span>
                                                    <span className="font-bold text-gray-900 dark:text-white text-left">
                                                        {section.title}
                                                    </span>
                                                </div>
                                                <span className="text-sm text-gray-500">
                                                    {section.lessons.length} {t('courseDetail.lessons')} • {sectionDuration} min
                                                </span>
                                            </button>

                                            {isExpanded && (
                                                <div className="px-4 pb-4 space-y-2 bg-gray-50 dark:bg-gray-900/50">
                                                    {section.lessons.map((lesson, lIdx) => (
                                                        <div
                                                            key={lesson.id || `${sIdx}-${lIdx}`}
                                                            className="flex items-center justify-between p-3 bg-white dark:bg-gray-800 rounded-lg"
                                                        >
                                                            <div className="flex items-center gap-3">
                                                                <span className="material-symbols-outlined text-primary text-sm">play_circle</span>
                                                                <span className="text-sm text-gray-700 dark:text-gray-300">{lesson.title}</span>
                                                            </div>
                                                            <div className="flex items-center gap-2">
                                                                {lesson.duration && (
                                                                    <span className="text-xs text-gray-500">{lesson.duration} min</span>
                                                                )}
                                                                <span className="material-symbols-outlined text-gray-400 text-sm">
                                                                    {isEnrolled ? 'play_arrow' : 'lock'}
                                                                </span>
                                                            </div>
                                                        </div>
                                                    ))}
                                                </div>
                                            )}
                                        </div>
                                    );
                                })}
                            </div>
                        </div>
                    </div>

                    {/* Right Column - Additional Info */}
                    <div className="lg:col-span-1 space-y-6">
                        {/* What You'll Learn */}
                        <div className="bg-white dark:bg-gray-800 p-6 rounded-xl border border-gray-200 dark:border-gray-700">
                            <h3 className="text-lg font-bold text-gray-900 dark:text-white mb-4">
                                {t('courseDetail.sections.whatLearn')}
                            </h3>
                            <ul className="space-y-3">
                                {['Master the fundamentals', 'Build real-world projects', 'Learn best practices', 'Get certified'].map((item, i) => (
                                    <li key={i} className="flex items-start gap-2 text-sm">
                                        <span className="material-symbols-outlined text-success text-lg shrink-0">check_circle</span>
                                        <span className="text-gray-700 dark:text-gray-300">{item}</span>
                                    </li>
                                ))}
                            </ul>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    );
};

export default StudentCourseDetailPage;
