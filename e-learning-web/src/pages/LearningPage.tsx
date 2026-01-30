import React, { useState, useEffect, useRef } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { useSelector } from 'react-redux';
import type { RootState } from '../store/store';
import { courseApi, type CourseResponse } from '../services/courseApi';
import { enrollmentApi, type CourseProgressResponse } from '../services/enrollmentApi';
import SecureVideoPlayer from '../components/SecureVideoPlayer';
import PdfViewer from '../components/PdfViewer';
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
    const [contentType, setContentType] = useState<'video' | 'document'>('video');
    const [expandedSections, setExpandedSections] = useState<Set<string>>(new Set());

    const progressSaveInterval = useRef<number | null>(null);
    const videoRef = useRef<HTMLVideoElement | null>(null);

    // Get all lessons flat list
    const allLessons = course?.sections.flatMap(s => s.lessons.map(l => ({
        ...l,
        sectionId: s.id,
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

                // Expand all sections by default
                const sectionIds = new Set(courseData.sections.map(s => s.id || ''));
                setExpandedSections(sectionIds);

                // Find last watched lesson or start from beginning
                const lastWatchedIndex = progressData.lessonProgress
                    .map((lp, idx) => ({ ...lp, idx }))
                    .filter(lp => !lp.isCompleted && lp.watchedDuration > 0)
                    .sort((a, b) => new Date(b.lastWatchedAt).getTime() - new Date(a.lastWatchedAt).getTime())[0]?.idx || 0;

                setCurrentLessonIndex(lastWatchedIndex);
            } catch (err: any) {
                setError(err.message || 'Failed to load course');
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
        }, 10000);

        return () => {
            if (progressSaveInterval.current) {
                clearInterval(progressSaveInterval.current);
            }
        };
    }, [id, currentLesson]);

    // Auto-select content type
    useEffect(() => {
        if (!currentLesson) return;

        if (currentLesson.videoId && currentLesson.documentId) {
            setContentType('video');
        } else if (currentLesson.videoId) {
            setContentType('video');
        } else if (currentLesson.documentId) {
            setContentType('document');
        }
    }, [currentLessonIndex]);

    // Update last accessed
    useEffect(() => {
        if (!id) return;
        enrollmentApi.updateLastAccessed(id);
        return () => {
            if (id) enrollmentApi.updateLastAccessed(id);
        };
    }, [id]);

    const handleMarkComplete = async () => {
        if (!id || !currentLesson?.id || isMarkingComplete) return;

        try {
            setIsMarkingComplete(true);
            await enrollmentApi.markLessonComplete(id, currentLesson.id);

            const newProgress = await enrollmentApi.getCourseProgress(id);
            setProgress(newProgress);

            if (currentLessonIndex < allLessons.length - 1) {
                setTimeout(() => setCurrentLessonIndex(prev => prev + 1), 500);
            }
        } catch (err) {
            console.error('Failed to mark lesson complete:', err);
            alert('Failed to mark lesson as complete. Please try again.');
        } finally {
            setIsMarkingComplete(false);
        }
    };

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

    if (error || !course || !currentLesson) {
        return (
            <div className="min-h-screen bg-white flex items-center justify-center">
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
    const completedCount = progress?.lessonProgress.filter(lp => lp.isCompleted).length || 0;
    const progressPercentage = Math.round((completedCount / allLessons.length) * 100);

    return (
        <div className="min-h-screen bg-white flex">
            {/* Sidebar */}
            <aside className="w-96 bg-gray-50 border-r border-gray-200 flex flex-col overflow-hidden">
                {/* Course Header */}
                <div className="p-6 bg-white border-b border-gray-200">
                    <button
                        onClick={() => navigate(`/courses/${id}`)}
                        className="mb-4 text-gray-600 hover:text-gray-900 flex items-center gap-2 text-sm"
                    >
                        <span className="material-symbols-outlined text-lg">arrow_back</span>
                        {t('learn.backToCourse')}
                    </button>
                    <h1 className="text-xl font-bold text-gray-900 mb-2">{course.title}</h1>
                    <p className="text-sm text-gray-600">{course.lecturer?.fullName}</p>
                </div>

                {/* Progress */}
                <div className="p-6 bg-white border-b border-gray-200">
                    <div className="space-y-2">
                        <div className="flex justify-between text-sm">
                            <span className="text-gray-600">{t('learn.progress')}</span>
                            <span className="text-primary font-medium">{completedCount}/{allLessons.length}</span>
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

                {/* Current Lesson Info */}
                <div className="p-6 bg-white border-b border-gray-200">
                    <div className="mb-3">
                        <p className="text-xs text-gray-500 mb-1">{currentLesson.sectionTitle}</p>
                        <h2 className="text-base font-bold text-gray-900">{currentLesson.title}</h2>
                        <p className="text-xs text-gray-500 mt-1">
                            {t('learn.lesson')} {currentLessonIndex + 1} / {allLessons.length}
                        </p>
                    </div>

                    {/* Navigation Buttons */}
                    <div className="flex gap-2 mb-3">
                        <button
                            onClick={() => setCurrentLessonIndex(prev => Math.max(0, prev - 1))}
                            disabled={currentLessonIndex === 0}
                            className="flex-1 px-3 py-2 bg-gray-100 text-gray-900 rounded-lg hover:bg-gray-200 disabled:opacity-50 disabled:cursor-not-allowed transition-colors flex items-center justify-center gap-1 text-sm"
                        >
                            <span className="material-symbols-outlined text-lg">arrow_back</span>
                            {t('learn.previous')}
                        </button>
                        <button
                            onClick={() => setCurrentLessonIndex(prev => Math.min(allLessons.length - 1, prev + 1))}
                            disabled={currentLessonIndex === allLessons.length - 1}
                            className="flex-1 px-3 py-2 bg-gray-100 text-gray-900 rounded-lg hover:bg-gray-200 disabled:opacity-50 disabled:cursor-not-allowed transition-colors flex items-center justify-center gap-1 text-sm"
                        >
                            {t('learn.next')}
                            <span className="material-symbols-outlined text-lg">arrow_forward</span>
                        </button>
                    </div>

                    {/* Mark Complete Button */}
                    <button
                        onClick={handleMarkComplete}
                        disabled={isCurrentLessonCompleted || isMarkingComplete}
                        className="w-full px-4 py-2.5 bg-primary text-white rounded-lg hover:bg-primary/90 disabled:opacity-50 disabled:cursor-not-allowed transition-colors flex items-center justify-center gap-2 text-sm font-medium"
                    >
                        {isCurrentLessonCompleted ? (
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

                {/* Curriculum */}
                <div className="flex-1 overflow-y-auto">
                    <div className="p-4">
                        <h3 className="text-sm font-semibold text-gray-900 mb-3 px-2">{t('learn.curriculum')}</h3>

                        <div className="space-y-2">
                            {course.sections.map((section, sectionIdx) => {
                                const sectionId = section.id || `section-${sectionIdx}`;
                                const isExpanded = expandedSections.has(sectionId);

                                return (
                                    <div key={sectionId} className="border border-gray-200 rounded-lg overflow-hidden bg-white">
                                        {/* Section Header */}
                                        <button
                                            onClick={() => toggleSection(sectionId)}
                                            className="w-full px-3 py-2 bg-gray-50 hover:bg-gray-100 transition-colors flex items-center justify-between text-left"
                                        >
                                            <span className="font-medium text-sm text-gray-900">{section.title}</span>
                                            <span className="material-symbols-outlined text-gray-500 text-lg">
                                                {isExpanded ? 'expand_less' : 'expand_more'}
                                            </span>
                                        </button>

                                        {/* Lessons */}
                                        {isExpanded && (
                                            <div className="bg-white">
                                                {section.lessons.map((lesson) => {
                                                    const globalIdx = allLessons.findIndex(l => l.id === lesson.id);
                                                    const lessonProg = progress?.lessonProgress.find(lp => lp.lessonId === lesson.id);
                                                    const isCompleted = lessonProg?.isCompleted || false;
                                                    const isCurrent = globalIdx === currentLessonIndex;

                                                    return (
                                                        <button
                                                            key={lesson.id}
                                                            onClick={() => setCurrentLessonIndex(globalIdx)}
                                                            className={`w-full px-3 py-2 flex items-center gap-2 hover:bg-gray-50 transition-colors border-t border-gray-100 ${isCurrent ? 'bg-blue-50 border-l-4 border-l-primary' : ''
                                                                }`}
                                                        >
                                                            {/* Completion Icon */}
                                                            <span className={`material-symbols-outlined text-base flex-shrink-0 ${isCompleted ? 'text-green-500' : 'text-gray-400'
                                                                }`}>
                                                                {isCompleted ? 'check_circle' : 'radio_button_unchecked'}
                                                            </span>

                                                            {/* Lesson Info */}
                                                            <div className="flex-1 text-left min-w-0">
                                                                <p className={`text-xs font-medium truncate ${isCurrent ? 'text-primary' : 'text-gray-900'
                                                                    }`}>
                                                                    {lesson.title}
                                                                </p>
                                                                <p className="text-xs text-gray-500">
                                                                    {Math.floor(lesson.duration / 60)}:{String(lesson.duration % 60).padStart(2, '0')}
                                                                </p>
                                                            </div>

                                                            {/* Content Type Icons */}
                                                            <div className="flex gap-1 flex-shrink-0">
                                                                {lesson.videoId && (
                                                                    <span className="material-symbols-outlined text-sm text-gray-400">play_circle</span>
                                                                )}
                                                                {lesson.documentUrl && (
                                                                    <span className="material-symbols-outlined text-sm text-gray-400">description</span>
                                                                )}
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
            <main className="flex-1 flex flex-col bg-white overflow-hidden">
                {/* Content Type Tabs */}
                {currentLesson.videoId && currentLesson.documentUrl && (
                    <div className="flex gap-2 border-b border-gray-200 bg-white px-6">
                        <button
                            onClick={() => setContentType('video')}
                            className={`px-6 py-3 font-medium text-sm transition-colors border-b-2 ${contentType === 'video'
                                ? 'border-primary text-primary'
                                : 'border-transparent text-gray-600 hover:text-gray-900'
                                }`}
                        >
                            <span className="flex items-center gap-2">
                                <span className="material-symbols-outlined text-lg">play_circle</span>
                                {t('learn.contentType.video')}
                            </span>
                        </button>
                        <button
                            onClick={() => setContentType('document')}
                            className={`px-6 py-3 font-medium text-sm transition-colors border-b-2 ${contentType === 'document'
                                ? 'border-primary text-primary'
                                : 'border-transparent text-gray-600 hover:text-gray-900'
                                }`}
                        >
                            <span className="flex items-center gap-2">
                                <span className="material-symbols-outlined text-lg">description</span>
                                {t('learn.contentType.document')}
                            </span>
                        </button>
                    </div>
                )}

                {/* Video/PDF Player */}
                <div className="flex-1 bg-black flex items-center justify-center">
                    {contentType === 'video' ? (
                        currentLesson.videoId ? (
                            <SecureVideoPlayer
                                videoId={currentLesson.videoId}
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
                        currentLesson.documentUrl ? (
                            <PdfViewer documentUrl={currentLesson.documentUrl} className="w-full h-full" />
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
