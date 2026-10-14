import React, { useState, useEffect, useRef } from 'react';
import { useParams, useNavigate, useLocation } from 'react-router-dom';
import { useSelector } from 'react-redux';
import type { RootState } from '../store/store';
import { courseApi, type CourseResponse } from '../services/courseApi';
import { enrollmentApi, isEnrollmentExpiredError, type CourseProgressResponse } from '../services/enrollmentApi';
import { type LessonPartDto } from '../services/lessonApi';
import SecureVideoPlayer from '../components/SecureVideoPlayer';
import PdfViewer from '../components/PdfViewer';
import { useTranslation } from 'react-i18next';

interface FlatLessonPart extends LessonPartDto {
    lessonId: string;
    lessonTitle: string;
    globalIndex: number;
}

const LearningPage: React.FC = () => {
    const { t } = useTranslation();
    const { id } = useParams<{ id: string }>();
    const navigate = useNavigate();
    const location = useLocation();
    const { isAuthenticated } = useSelector((state: RootState) => state.auth);
    const partIdFromQuery = React.useMemo(
        () => new URLSearchParams(location.search).get('partId') || '',
        [location.search]
    );

    const [course, setCourse] = useState<CourseResponse | null>(null);
    const [progress, setProgress] = useState<CourseProgressResponse | null>(null);
    const [currentPartIndex, setCurrentPartIndex] = useState(0);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState<string | null>(null);
    const [isEnrollmentExpired, setIsEnrollmentExpired] = useState(false);
    const [isMarkingComplete, setIsMarkingComplete] = useState(false);

    // Expand lessons in sidebar
    const [expandedLessons, setExpandedLessons] = useState<Set<string>>(new Set());
    const [isCurriculumOpen, setIsCurriculumOpen] = useState(false);

    const progressSaveInterval = useRef<number | null>(null);
    const videoRef = useRef<HTMLVideoElement | null>(null);

    // Flatten all parts for easy navigation
    const allParts = React.useMemo(() => {
        if (!course?.lessons) return [] as FlatLessonPart[];
        let parts: FlatLessonPart[] = [];
        let globalIdx = 0;
        course.lessons.forEach(lesson => {
            if (lesson.parts) {
                lesson.parts.forEach(part => {
                    parts.push({
                        ...part,
                        lessonId: lesson.id,
                        lessonTitle: lesson.title,
                        globalIndex: globalIdx++
                    });
                });
            }
        });
        return parts;
    }, [course]);

    const currentPart = allParts[currentPartIndex];

    useEffect(() => {
        const fetchData = async () => {
            if (!id) return;

            try {
                setLoading(true);
                setIsEnrollmentExpired(false);

                const [courseData, progressData] = await Promise.all([
                    courseApi.getById(id),
                    isAuthenticated
                        ? enrollmentApi.getCourseProgress(id).catch((err: any) => {
                            if ((err?.status === 404 || err?.status === 403)) return null;
                            throw err;
                        })
                        : Promise.resolve(null),
                ]);

                setCourse(courseData);

                // Access check: course must be free or user must be authenticated
                const isFreeCourse = courseData.isFree === true;
                if (!isFreeCourse && !isAuthenticated) {
                    navigate('/login', { state: { from: `/courses/${id}/learn` } });
                    return;
                }

                if (progressData) {
                    setProgress(progressData);
                }

                // Expand all lessons by default
                if (courseData.lessons) {
                    setExpandedLessons(new Set(courseData.lessons.map(l => l.id)));
                }

                // Allow deep-linking to a specific part from the detail page query (?partId=...)
                let initialPartIndex = 0;

                const findPartIndex = (targetPartId: string) => {
                    let idx = 0;
                    let found = -1;
                    if (courseData.lessons) {
                        for (const lesson of courseData.lessons) {
                            if (lesson.parts) {
                                for (const part of lesson.parts) {
                                    if (part.id === targetPartId) {
                                        found = idx;
                                        break;
                                    }
                                    idx++;
                                }
                            }
                            if (found !== -1) break;
                        }
                    }
                    return found;
                };

                if (partIdFromQuery) {
                    const directIndex = findPartIndex(partIdFromQuery);
                    if (directIndex !== -1) {
                        initialPartIndex = directIndex;
                    }
                } else if (progressData && progressData.partProgress && progressData.partProgress.length > 0) {
                    // Fallback to last in-progress part
                    const inProgress = progressData.partProgress
                        .filter(p => !p.isCompleted && p.watchedDuration > 0)
                        .sort((a, b) => new Date(b.lastWatchedAt).getTime() - new Date(a.lastWatchedAt).getTime());

                    if (inProgress.length > 0) {
                        const resumeIndex = findPartIndex(inProgress[0].lessonPartId);
                        if (resumeIndex !== -1) {
                            initialPartIndex = resumeIndex;
                        }
                    }
                }

                setCurrentPartIndex(initialPartIndex);
            } catch (err: any) {
                if (isEnrollmentExpiredError(err)) {
                    setIsEnrollmentExpired(true);
                    setError(t('learn.enrollmentExpired', { defaultValue: 'Your access to this course has expired.' }));
                    return;
                }

                const errorMessage = typeof err?.message === 'string' ? err.message : '';
                setError(errorMessage || t('learn.loadError'));
                if (errorMessage.includes('Enrollment not found') || errorMessage.includes('Not Found')) {
                    setTimeout(() => navigate(`/courses/${id}`), 2000);
                }
            } finally {
                setLoading(false);
            }
        };

        fetchData();
    }, [id, isAuthenticated, navigate, partIdFromQuery]);

    // Auto-save progress every 10 seconds
    useEffect(() => {
        if (!id || !currentPart || !videoRef.current || currentPart.type !== 'Video' || !isAuthenticated) return;

        progressSaveInterval.current = window.setInterval(async () => {
            const video = videoRef.current;
            if (video && !video.paused && id && currentPart?.id && isAuthenticated) {
                try {
                    await enrollmentApi.updateLessonProgress(id, currentPart.id, Math.floor(video.currentTime));
                } catch (err) {
                    if (isEnrollmentExpiredError(err)) {
                        setIsEnrollmentExpired(true);
                        setError(t('learn.enrollmentExpired', { defaultValue: 'Your access to this course has expired.' }));
                        return;
                    }

                    console.error('Failed to save progress:', err);
                }
            }
        }, 10000);

        return () => {
            if (progressSaveInterval.current) {
                clearInterval(progressSaveInterval.current);
            }
        };
    }, [id, currentPart]);

    // Update last accessed
    useEffect(() => {
        if (!id || !isAuthenticated) return;
        enrollmentApi.updateLastAccessed(id);
        return () => {
            if (id && isAuthenticated) enrollmentApi.updateLastAccessed(id);
        };
    }, [id, isAuthenticated]);

    const handleMarkComplete = async () => {
        if (!id || !currentPart?.id || isMarkingComplete) return;

        if (!isAuthenticated) {
            alert(t('learn.loginToTrackProgress'));
            return;
        }

        try {
            setIsMarkingComplete(true);
            await enrollmentApi.markLessonComplete(id, currentPart.id);

            const newProgress = await enrollmentApi.getCourseProgress(id);
            setProgress(newProgress);

            // Auto-advance after progress is updated
            if (currentPartIndex < allParts.length - 1) {
                setCurrentPartIndex(prev => prev + 1);
            }
        } catch (err) {
            if (isEnrollmentExpiredError(err)) {
                setIsEnrollmentExpired(true);
                setError(t('learn.enrollmentExpired', { defaultValue: 'Your access to this course has expired.' }));
                return;
            }

            console.error('Failed to mark lesson complete:', err);
            alert(t('learn.markCompleteError'));
        } finally {
            setIsMarkingComplete(false);
        }
    };

    const toggleLesson = (lessonId: string) => {
        setExpandedLessons(prev => {
            const newSet = new Set(prev);
            if (newSet.has(lessonId)) {
                newSet.delete(lessonId);
            } else {
                newSet.add(lessonId);
            }
            return newSet;
        });
    };

    if (loading) {
        return (
            <div className="min-h-screen bg-white flex items-center justify-center">
                <div className="text-center">
                    <div className="inline-block h-12 w-12 animate-spin rounded-full border-4 border-solid border-primary border-r-transparent" />
                    <p className="mt-4 text-gray-600">{t('learn.loading')}</p>
                </div>
            </div>
        );
    }

    if (error || !course || !currentPart) {
        return (
            <div className="min-h-screen bg-white flex items-center justify-center">
                <div className="text-center">
                    <span className={`material-symbols-outlined text-6xl mb-4 ${isEnrollmentExpired ? 'text-amber-500' : 'text-red-500'}`}>{isEnrollmentExpired ? 'schedule' : 'error'}</span>
                    <p className={`${isEnrollmentExpired ? 'text-amber-600' : 'text-red-500'} mb-4`}>{error || t('learn.contentNotFound')}</p>
                    <button
                        onClick={() => navigate(`/courses/${id}`)}
                        className="px-6 py-3 bg-primary text-white rounded-lg hover:bg-primary/90"
                    >
                        {isEnrollmentExpired
                            ? t('learn.reenrollCourse', { defaultValue: 'Go to course page' })
                            : t('learn.backToCourse')}
                    </button>
                </div>
            </div>
        );
    }

    const currentPartProgress = progress?.partProgress?.find(p => p.lessonPartId === currentPart.id);
    const isCurrentPartCompleted = currentPartProgress?.isCompleted || false;
    const completedCount = progress?.partProgress?.filter(p => p.isCompleted).length || 0;
    const progressPercentage = allParts.length > 0 ? Math.round((completedCount / allParts.length) * 100) : 0;

    return (
        <div className="min-h-screen bg-white flex flex-col lg:flex-row">
            {/* Mobile Backdrop */}
            <div
                className={`fixed inset-x-0 bottom-0 top-16 sm:top-20 z-30 bg-black/40 transition-opacity lg:hidden ${isCurriculumOpen ? 'opacity-100 pointer-events-auto' : 'opacity-0 pointer-events-none'}`}
                onClick={() => setIsCurriculumOpen(false)}
            />

            {/* Sidebar */}
            <aside
                className={`
                    fixed left-0 top-16 bottom-0 sm:top-20 z-40 w-[88vw] max-w-sm bg-gray-50 border-r border-gray-200 flex flex-col overflow-hidden
                    transform transition-transform duration-200
                    ${isCurriculumOpen ? 'translate-x-0' : '-translate-x-full'}
                    lg:static lg:top-auto lg:bottom-auto lg:translate-x-0 lg:w-96
                `}
            >
                {/* Course Header */}
                <div className="p-6 bg-white border-b border-gray-200">
                    <div className="mb-4 flex items-center justify-between gap-2">
                        <button
                            onClick={() => navigate(`/courses/${id}`)}
                            className="text-gray-600 hover:text-gray-900 flex items-center gap-2 text-sm"
                        >
                            <span className="material-symbols-outlined text-lg">arrow_back</span>
                            {t('learn.backToCourse')}
                        </button>
                        <button
                            onClick={() => setIsCurriculumOpen(false)}
                            className="lg:hidden h-10 w-10 rounded-lg border border-gray-200 text-gray-700"
                            aria-label="Close curriculum"
                        >
                            <span className="material-symbols-outlined text-[20px]">close</span>
                        </button>
                    </div>
                    <h1 className="text-xl font-bold text-gray-900 mb-2">{course.title}</h1>
                    <p className="text-sm text-gray-600">{course.lecturer?.fullName}</p>
                </div>

                {/* Progress */}
                <div className="p-6 bg-white border-b border-gray-200">
                    <div className="space-y-2">
                        <div className="flex justify-between text-sm">
                            <span className="text-gray-600">{t('learn.progress')}</span>
                            <span className="text-primary font-medium">{completedCount}/{allParts.length}</span>
                        </div>
                        <div className="w-full bg-gray-200 rounded-full h-2">
                            <div
                                className="bg-primary h-2 rounded-full transition-all duration-300"
                                style={{ width: `${progressPercentage}%` }}
                            />
                        </div>
                        <p className="text-xs text-gray-500">{progressPercentage}% {t('learn.completed')}</p>
                    </div>
                </div>

                {/* Current Content Info */}
                <div className="p-6 bg-white border-b border-gray-200">
                    <div className="mb-3">
                        <p className="text-xs text-gray-500 mb-1">{currentPart.lessonTitle}</p>
                        <h2 className="text-base font-bold text-gray-900">{currentPart.title}</h2>
                        <p className="text-xs text-gray-500 mt-1">
                            {t('learn.lesson')} {currentPartIndex + 1} / {allParts.length}
                        </p>
                    </div>

                    {/* Navigation Buttons */}
                    <div className="flex gap-2 mb-3">
                        <button
                            onClick={() => setCurrentPartIndex(prev => Math.max(0, prev - 1))}
                            disabled={currentPartIndex === 0}
                            className="flex-1 px-3 py-2 bg-gray-100 text-gray-900 rounded-lg hover:bg-gray-200 disabled:opacity-50 disabled:cursor-not-allowed transition-colors flex items-center justify-center gap-1 text-sm"
                        >
                            <span className="material-symbols-outlined text-lg">arrow_back</span>
                            {t('learn.previous')}
                        </button>
                        <button
                            onClick={() => setCurrentPartIndex(prev => Math.min(allParts.length - 1, prev + 1))}
                            disabled={currentPartIndex === allParts.length - 1}
                            className="flex-1 px-3 py-2 bg-gray-100 text-gray-900 rounded-lg hover:bg-gray-200 disabled:opacity-50 disabled:cursor-not-allowed transition-colors flex items-center justify-center gap-1 text-sm"
                        >
                            {t('learn.next')}
                            <span className="material-symbols-outlined text-lg">arrow_forward</span>
                        </button>
                    </div>

                    {/* Mark Complete Button */}
                    <button
                        onClick={handleMarkComplete}
                        disabled={isCurrentPartCompleted || isMarkingComplete}
                        className="w-full px-4 py-2.5 bg-primary text-white rounded-lg hover:bg-primary/90 disabled:opacity-50 disabled:cursor-not-allowed transition-colors flex items-center justify-center gap-2 text-sm font-medium"
                    >
                        {isCurrentPartCompleted ? (
                            <>
                                <span className="material-symbols-outlined text-lg">check_circle</span>
                                {t('learn.completed')}
                            </>
                        ) : (
                            <>
                                <span className="material-symbols-outlined text-lg">check_circle</span>
                                {t('learn.markComplete')}
                            </>
                        )}
                    </button>
                </div>

                {/* Curriculum / Playlist */}
                <div className="flex-1 overflow-y-auto">
                    <div className="p-4">
                        <h3 className="text-sm font-semibold text-gray-900 mb-3 px-2">{t('learn.curriculum')}</h3>

                        <div className="space-y-2">
                            {course.lessons?.map((lesson, lessonIdx) => {
                                const lessonId = lesson.id || `lesson-${lessonIdx}`;
                                const isExpanded = expandedLessons.has(lessonId);

                                // Check if any part in this lesson is current
                                const hasCurrentPart = lesson.parts?.some(p => p.id === currentPart.id);

                                return (
                                    <div key={lessonId} className={`border rounded-lg overflow-hidden bg-white ${hasCurrentPart ? 'border-primary/30' : 'border-gray-200'}`}>
                                        {/* Lesson Header */}
                                        <button
                                            onClick={() => toggleLesson(lessonId)}
                                            className="w-full px-3 py-2 bg-gray-50 hover:bg-gray-100 transition-colors flex items-center justify-between text-left"
                                        >
                                            <span className="font-medium text-sm text-gray-900 line-clamp-1">{lesson.title}</span>
                                            <span className="material-symbols-outlined text-gray-500 text-lg">
                                                {isExpanded ? 'expand_less' : 'expand_more'}
                                            </span>
                                        </button>

                                        {/* Parts */}
                                        {isExpanded && lesson.parts && (
                                            <div className="bg-white">
                                                {lesson.parts.map((part) => {
                                                    // Find index in global allParts
                                                    const globalIdx = allParts.findIndex(p => p.id === part.id);
                                                    const partProg = progress?.partProgress?.find(p => p.lessonPartId === part.id);
                                                    const isCompleted = partProg?.isCompleted || false;
                                                    const isCurrent = globalIdx === currentPartIndex;

                                                    return (
                                                        <button
                                                            key={part.id}
                                                            onClick={() => {
                                                                setCurrentPartIndex(globalIdx);
                                                                setIsCurriculumOpen(false);
                                                            }}
                                                            className={`w-full px-3 py-2 flex items-center gap-2 hover:bg-gray-50 transition-colors border-t border-gray-100 ${isCurrent ? 'bg-blue-50 border-l-4 border-l-primary' : ''
                                                                }`}
                                                        >
                                                            {/* Completion Icon */}
                                                            <span className={`material-symbols-outlined text-base flex-shrink-0 ${isCompleted ? 'text-green-500' : 'text-gray-400'
                                                                }`}>
                                                                {isCompleted ? 'check_circle' : 'radio_button_unchecked'}
                                                            </span>

                                                            {/* Part Info */}
                                                            <div className="flex-1 text-left min-w-0">
                                                                <p className={`text-xs font-medium truncate ${isCurrent ? 'text-primary' : 'text-gray-900'
                                                                    }`}>
                                                                    {part.title}
                                                                </p>
                                                                {part.type === 'Video' && part.videoDuration && (
                                                                    <p className="text-xs text-gray-500">
                                                                        {Math.floor(part.videoDuration / 60)}:{String(part.videoDuration % 60).padStart(2, '0')}
                                                                    </p>
                                                                )}
                                                            </div>

                                                            {/* Type Icon */}
                                                            <div className="flex-shrink-0">
                                                                <span className="material-symbols-outlined text-sm text-gray-400">
                                                                    {part.type === 'Video' ? 'play_circle' : 'description'}
                                                                </span>
                                                            </div>
                                                        </button>
                                                    );
                                                })}
                                            </div>
                                        )}
                                    </div>
                                );
                            })}
                        </div>
                    </div>
                </div>
            </aside>

            {/* Main Content */}
            <main className="flex-1 flex flex-col bg-white overflow-hidden min-h-0">
                {/* Guest Mode Info */}
                {!isAuthenticated && (
                    <div className="bg-amber-50 border-b border-amber-100 px-4 py-2 flex items-center gap-2">
                        <span className="material-symbols-outlined text-amber-500 text-[18px]">info</span>
                        <p className="text-xs text-amber-700 font-medium">
                            {t('learn.guestModeInfo')}
                        </p>
                    </div>
                )}
                <div className="lg:hidden border-b border-gray-200 bg-white px-3 py-2 flex items-center justify-between gap-2">
                    <button
                        onClick={() => setIsCurriculumOpen(true)}
                        className="inline-flex h-10 items-center gap-2 rounded-lg border border-gray-200 px-3 text-sm font-medium text-gray-700"
                    >
                        <span className="material-symbols-outlined text-[18px]">menu_book</span>
                        {t('learn.curriculum')}
                    </button>

                    <div className="min-w-0 text-right">
                        <p className="text-xs text-gray-500 truncate">{currentPart.lessonTitle}</p>
                        <p className="text-sm font-semibold text-gray-900 truncate">{currentPart.title}</p>
                    </div>
                </div>

                {/* Video/PDF Player */}
                <div className="flex-1 bg-black flex items-center justify-center">
                    {currentPart.type === 'Video' ? (
                        currentPart.videoId ? (
                            <SecureVideoPlayer
                                videoId={currentPart.videoId}
                                ref={videoRef}
                                className="w-full h-full"
                            />
                        ) : (
                            <div className="text-center">
                                <span className="material-symbols-outlined text-6xl text-gray-600 mb-4">play_disabled</span>
                                <p className="text-gray-400">{t('learn.noVideo')}</p>
                            </div>
                        )
                    ) : (
                        currentPart.documentUrl ? (
                            <PdfViewer documentUrl={currentPart.documentUrl} className="w-full h-full" />
                        ) : (
                            <div className="text-center">
                                <span className="material-symbols-outlined text-6xl text-gray-600 mb-4">description</span>
                                <p className="text-gray-400">{t('learn.noPdf')}</p>
                            </div>
                        )
                    )}
                </div>

            </main>
        </div>
    );
};

export default LearningPage;
