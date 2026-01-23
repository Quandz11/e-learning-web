import React, { useState, useEffect, useRef } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { useSelector } from 'react-redux';
import type { RootState } from '../store/store';
import { courseApi, type CourseResponse } from '../services/courseApi';
import { enrollmentApi, type CourseProgressResponse } from '../services/enrollmentApi';
import SecureVideoPlayer from '../components/SecureVideoPlayer';
import { useTranslation } from 'react-i18next';

const LearningPage: React.FC = () => {
    const { t } = useTranslation();
    const { id } = useParams<{ id: string }>();
    const navigate = useNavigate();
    const { isAuthenticated } = useSelector((state: RootState) => state.auth);

    const [course, setCourse] = useState<CourseResponse | null>(null);
    const [progress, setProgress] = useState<CourseProgressResponse | null>(null);
    const [currentLessonIndex, setCurrentLessonIndex] = useState(0);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState<string | null>(null);
    const [isMarkingComplete, setIsMarkingComplete] = useState(false);

    const progressSaveInterval = useRef<number | null>(null);
    const videoRef = useRef<HTMLVideoElement | null>(null);

    // Get all lessons flat list
    const allLessons = course?.sections.flatMap(s => s.lessons.map(l => ({
        ...l,
        sectionTitle: s.title
    }))) || [];

    const currentLesson = allLessons[currentLessonIndex];

    useEffect(() => {
        if (!isAuthenticated) {
            navigate('/login');
            return;
        }

        const fetchData = async () => {
            if (!id) return;

            try {
                setLoading(true);
                const [courseData, progressData] = await Promise.all([
                    courseApi.getById(id),
                    enrollmentApi.getCourseProgress(id)
                ]);

                setCourse(courseData);
                setProgress(progressData);

                // Find last watched lesson or start from beginning
                const lastWatchedIndex = progressData.lessonProgress
                    .map((lp, idx) => ({ ...lp, idx }))
                    .filter(lp => !lp.isCompleted && lp.watchedDuration > 0)
                    .sort((a, b) => new Date(b.lastWatchedAt).getTime() - new Date(a.lastWatchedAt).getTime())[0]?.idx || 0;

                setCurrentLessonIndex(lastWatchedIndex);
            } catch (err: any) {
                setError(err.message || 'Failed to load course');
                // Check if not enrolled
                if (err.message.includes('Enrollment not found') || err.message.includes('Not Found')) {
                    setTimeout(() => navigate(`/courses/${id}`), 2000);
                }
            } finally {
                setLoading(false);
            }
        };

        fetchData();
    }, [id, isAuthenticated, navigate]);

    // Auto-save progress every 10 seconds
    useEffect(() => {
        if (!id || !currentLesson || !videoRef.current) return;

        progressSaveInterval.current = window.setInterval(async () => {
            const video = videoRef.current;
            if (video && !video.paused && id && currentLesson?.id) {
                try {
                    await enrollmentApi.updateLessonProgress(id, currentLesson.id, Math.floor(video.currentTime));
                } catch (err) {
                    console.error('Failed to save progress:', err);
                }
            }
        }, 10000); // Save every 10 seconds

        return () => {
            if (progressSaveInterval.current) {
                clearInterval(progressSaveInterval.current);
            }
        };
    }, [id, currentLesson]);

    // Update last accessed on mount and unmount
    useEffect(() => {
        if (!id) return;

        enrollmentApi.updateLastAccessed(id);

        return () => {
            if (id) {
                enrollmentApi.updateLastAccessed(id);
            }
        };
    }, [id]);

    const handleMarkComplete = async () => {
        if (!id || !currentLesson?.id || isMarkingComplete) return;

        try {
            setIsMarkingComplete(true);
            await enrollmentApi.markLessonComplete(id, currentLesson.id);

            // Refresh progress
            const newProgress = await enrollmentApi.getCourseProgress(id);
            setProgress(newProgress);

            // Auto-advance to next lesson
            if (currentLessonIndex < allLessons.length - 1) {
                setTimeout(() => {
                    setCurrentLessonIndex(prev => prev + 1);
                }, 500);
            }
        } catch (err) {
            console.error('Failed to mark lesson complete:', err);
            alert('Failed to mark lesson as complete. Please try again.');
        } finally {
            setIsMarkingComplete(false);
        }
    };

    const handleLessonSelect = (index: number) => {
        setCurrentLessonIndex(index);
    };

    const goToNextLesson = () => {
        if (currentLessonIndex < allLessons.length - 1) {
            setCurrentLessonIndex(prev => prev + 1);
        }
    };

    const goToPreviousLesson = () => {
        if (currentLessonIndex > 0) {
            setCurrentLessonIndex(prev => prev - 1);
        }
    };

    if (loading) {
        return (
            <div className="min-h-screen bg-background-dark flex items-center justify-center">
                <div className="text-center">
                    <div className="inline-block h-12 w-12 animate-spin rounded-full border-4 border-solid border-primary border-r-transparent" />
                    <p className="mt-4 text-gray-300">{t('learn.loading')}</p>
                </div>
            </div>
        );
    }

    if (error || !course || !currentLesson) {
        return (
            <div className="min-h-screen bg-background-dark flex items-center justify-center">
                <div className="text-center">
                    <span className="material-symbols-outlined text-6xl text-red-500 mb-4">error</span>
                    <p className="text-red-500 mb-4">{error || 'Course not found'}</p>
                    <button
                        onClick={() => navigate(`/courses/${id}`)}
                        className="px-6 py-3 bg-primary text-white rounded-lg hover:bg-primary/90"
                    >
                        {t('learn.backToCourse')}
                    </button>
                </div>
            </div>
        );
    }

    const lessonProgress = progress?.lessonProgress.find(lp => lp.lessonId === currentLesson.id);
    const isCurrentLessonCompleted = lessonProgress?.isCompleted || false;

    return (
        <div className="min-h-screen bg-background-dark text-white flex flex-col">
            {/* Header */}
            <header className="bg-gray-900 border-b border-gray-800">
                <div className="max-w-screen-2xl mx-auto px-4 sm:px-6 lg:px-8">
                    <div className="flex items-center justify-between h-16">
                        <div className="flex items-center gap-4">
                            <button
                                onClick={() => navigate(`/courses/${id}`)}
                                className="flex items-center gap-2 text-gray-300 hover:text-white transition-colors"
                            >
                                <span className="material-symbols-outlined">arrow_back</span>
                                <span className="hidden sm:inline">{t('learn.backToCourse')}</span>
                            </button>
                            <div className="h-8 w-px bg-gray-700" />
                            <h1 className="text-lg font-bold truncate max-w-md">{course.title}</h1>
                        </div>
                        <div className="flex items-center gap-4">
                            <div className="text-sm text-gray-400">
                                {t('learn.progress')}: <span className="text-primary font-bold">{progress?.progressPercentage}%</span>
                            </div>
                            <div className="hidden sm:block text-sm text-gray-400">
                                {progress?.completedLessons} / {progress?.totalLessons} {t('learn.lessons')}
                            </div>
                        </div>
                    </div>
                </div>
            </header>

            {/* Main Content */}
            <div className="flex-1 flex overflow-hidden">
                {/* Left Sidebar - Lesson List */}
                <div className="w-80 bg-gray-900 border-r border-gray-800 overflow-y-auto flex-shrink-0">
                    <div className="p-4 border-b border-gray-800 sticky top-0 bg-gray-900 z-10">
                        <h3 className="font-bold text-white">{t('learn.courseContent')}</h3>
                        <p className="text-sm text-gray-400 mt-1">
                            {progress?.completedLessons} / {progress?.totalLessons} {t('learn.completed')}
                        </p>
                        <div className="mt-2 w-full bg-gray-800 rounded-full h-2">
                            <div
                                className="bg-primary h-2 rounded-full transition-all"
                                style={{ width: `${progress?.progressPercentage}%` }}
                            />
                        </div>
                    </div>

                    <div className="divide-y divide-gray-800">
                        {course.sections.map((section, sIdx) => (
                            <div key={section.id || sIdx} className="p-4">
                                <h4 className="font-medium text-sm mb-3 text-gray-300 uppercase tracking-wide">{section.title}</h4>
                                <div className="space-y-1">
                                    {section.lessons.map((lesson, lIdx) => {
                                        const globalIndex = allLessons.findIndex(l => l.id === lesson.id);
                                        const lessonProg = progress?.lessonProgress.find(lp => lp.lessonId === lesson.id);
                                        const isCurrent = globalIndex === currentLessonIndex;
                                        const isCompleted = lessonProg?.isCompleted || false;

                                        return (
                                            <button
                                                key={lesson.id || lIdx}
                                                onClick={() => handleLessonSelect(globalIndex)}
                                                className={`w-full text-left p-3 rounded-lg transition-all ${isCurrent
                                                    ? 'bg-primary/20 border border-primary/50 shadow-lg'
                                                    : 'hover:bg-gray-800'
                                                    }`}
                                            >
                                                <div className="flex items-start gap-3">
                                                    <div className={`flex-shrink-0 w-6 h-6 rounded-full flex items-center justify-center mt-0.5 ${isCompleted
                                                        ? 'bg-success text-white'
                                                        : isCurrent
                                                            ? 'bg-primary text-white'
                                                            : 'bg-gray-700 text-gray-400'
                                                        }`}>
                                                        {isCompleted ? (
                                                            <span className="material-symbols-outlined text-sm">check</span>
                                                        ) : (
                                                            <span className="text-xs font-bold">{lIdx + 1}</span>
                                                        )}
                                                    </div>
                                                    <div className="flex-1 min-w-0">
                                                        <p className={`text-sm font-medium ${isCompleted
                                                            ? 'line-through text-gray-500'
                                                            : isCurrent
                                                                ? 'text-primary'
                                                                : 'text-white'
                                                            }`}>
                                                            {lesson.title}
                                                        </p>
                                                        {lesson.duration && (
                                                            <p className="text-xs text-gray-500 mt-0.5">
                                                                {lesson.duration} min
                                                            </p>
                                                        )}
                                                    </div>
                                                </div>
                                            </button>
                                        );
                                    })}
                                </div>
                            </div>
                        ))}
                    </div>
                </div>

                {/* Right Side - Video Player */}
                <div className="flex-1 flex flex-col bg-black">
                    {/* Video Container */}
                    <div className="flex-1 flex items-center justify-center bg-black">
                        {currentLesson.videoId ? (
                            <SecureVideoPlayer
                                videoId={currentLesson.videoId}
                                ref={videoRef}
                                className="w-full h-full"
                            />
                        ) : (
                            <div className="flex items-center justify-center h-full">
                                <div className="text-center">
                                    <span className="material-symbols-outlined text-6xl text-gray-600 mb-4">
                                        play_disabled
                                    </span>
                                    <p className="text-gray-400">{t('learn.noVideo')}</p>
                                </div>
                            </div>
                        )}
                    </div>

                    {/* Lesson Info & Controls */}
                    <div className="p-6 bg-gray-900 border-t border-gray-800">
                        <div className="max-w-7xl mx-auto">
                            {/* Lesson Title & Status */}
                            <div className="flex items-start justify-between gap-4 mb-4">
                                <div className="flex-1">
                                    <p className="text-sm text-gray-400 mb-1">{currentLesson.sectionTitle}</p>
                                    <h2 className="text-2xl font-bold text-white">{currentLesson.title}</h2>
                                </div>
                                {isCurrentLessonCompleted && (
                                    <span className="flex items-center gap-1 px-3 py-1 rounded-full bg-success/20 text-success text-sm font-medium">
                                        <span className="material-symbols-outlined text-sm">check_circle</span>
                                        {t('learn.completedStatus')}
                                    </span>
                                )}
                            </div>

                            {/* Navigation & Complete Button */}
                            <div className="flex items-center gap-3">
                                <button
                                    onClick={goToPreviousLesson}
                                    disabled={currentLessonIndex === 0}
                                    className="flex items-center gap-2 px-4 py-2.5 rounded-lg bg-gray-800 hover:bg-gray-700 disabled:opacity-50 disabled:cursor-not-allowed transition-colors text-white"
                                >
                                    <span className="material-symbols-outlined text-lg">chevron_left</span>
                                    <span className="hidden sm:inline">{t('learn.previous')}</span>
                                </button>

                                <button
                                    onClick={handleMarkComplete}
                                    disabled={isMarkingComplete || isCurrentLessonCompleted}
                                    className={`flex-1 flex items-center justify-center gap-2 px-6 py-2.5 rounded-lg font-medium transition-all ${isCurrentLessonCompleted
                                        ? 'bg-success/20 text-success cursor-default'
                                        : 'bg-success hover:bg-success/90 text-white shadow-lg hover:shadow-xl'
                                        } disabled:opacity-50 disabled:cursor-not-allowed`}
                                >
                                    {isMarkingComplete ? (
                                        <>
                                            <span className="material-symbols-outlined animate-spin">progress_activity</span>
                                            {t('learn.marking')}
                                        </>
                                    ) : isCurrentLessonCompleted ? (
                                        <>
                                            <span className="material-symbols-outlined">check_circle</span>
                                            Completed
                                        </>
                                    ) : (
                                        <>
                                            <span className="material-symbols-outlined">task_alt</span>
                                            {t('learn.markComplete')}
                                        </>
                                    )}
                                </button>

                                <button
                                    onClick={goToNextLesson}
                                    disabled={currentLessonIndex === allLessons.length - 1}
                                    className="flex items-center gap-2 px-4 py-2.5 rounded-lg bg-primary hover:bg-primary/90 disabled:opacity-50 disabled:cursor-not-allowed transition-colors text-white"
                                >
                                    <span className="hidden sm:inline">{t('learn.next')}</span>
                                    <span className="material-symbols-outlined text-lg">chevron_right</span>
                                </button>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    );
};

export default LearningPage;
