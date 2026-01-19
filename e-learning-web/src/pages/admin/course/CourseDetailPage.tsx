import React, { useEffect, useMemo, useState } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { useTranslation } from 'react-i18next';
import { courseApi, type CourseResponse, type CourseLessonInput } from '../../../services/courseApi';

const CourseDetailPage: React.FC = () => {
  const { id } = useParams<{ id: string }>();
  const navigate = useNavigate();
  const { t } = useTranslation();
  const [course, setCourse] = useState<CourseResponse | null>(null);
  const [selectedLesson, setSelectedLesson] = useState<CourseLessonInput | null>(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (!id) return;
    const fetchCourse = async () => {
      try {
        setLoading(true);
        setError(null);
        const data = await courseApi.getById(id);
        setCourse(data);
        const firstWithVideo = data.sections
          .flatMap((s) => s.lessons)
          .find((l) => l.playbackUrl);
        setSelectedLesson(firstWithVideo || null);
      } catch (err: any) {
        setError(err.message || t('courseDetail.loadError'));
      } finally {
        setLoading(false);
      }
    };

    void fetchCourse();
  }, [id]);

  const lessons = useMemo(() => course?.sections.flatMap((s) => s.lessons) ?? [], [course]);
  const totalLessons = lessons.length;
  const totalDuration = lessons.reduce((sum, l) => sum + (l.duration || 0), 0);
  const statusLabel = course?.isPublished ? t('courseDetail.meta.statusPublished') : t('courseDetail.meta.statusDraft');
  const priceLabel = course?.isFree ? t('courseDetail.free') : `$${course?.price ?? 0}`;

  return (
    <div className="min-h-screen bg-slate-50 dark:bg-slate-900">
      <div className="mx-auto max-w-6xl px-4 py-8 space-y-6">
        <button
          onClick={() => navigate(-1)}
          className="inline-flex items-center gap-2 text-sm text-dashboard-primary hover:underline"
        >
          <span className="material-symbols-outlined text-[18px]">arrow_back</span>
          {t('courseDetail.back')}
        </button>

        {loading && <div className="text-slate-600 dark:text-slate-300">{t('courseDetail.loading')}</div>}
        {error && (
          <div className="mb-4 rounded-lg border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-700 dark:border-red-900/50 dark:bg-red-900/20 dark:text-red-200">
            {error}
          </div>
        )}

        {course && (
          <div className="space-y-6">
            <div className="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm dark:border-slate-800 dark:bg-slate-800">
              <div className="flex flex-wrap items-start gap-4">
                <div className="flex-1 space-y-3">
                  <div className="flex flex-wrap items-center gap-2 text-xs font-semibold uppercase tracking-wide text-slate-500 dark:text-slate-400">
                    <span className="rounded-full bg-slate-100 px-3 py-1 dark:bg-slate-700">#{course.id.slice(0, 8)}</span>
                    <span className="rounded-full bg-indigo-100 px-3 py-1 text-indigo-700 dark:bg-indigo-900/50 dark:text-indigo-200">{statusLabel}</span>
                  </div>
                  <h1 className="text-3xl font-bold text-slate-900 dark:text-white leading-tight">{course.title}</h1>
                  <div className="flex flex-wrap items-center gap-3 text-sm text-slate-600 dark:text-slate-300">
                    <span className="inline-flex items-center gap-1 rounded-full bg-blue-50 px-3 py-1 text-blue-700 dark:bg-blue-900/40 dark:text-blue-200">
                      <span className="material-symbols-outlined text-[16px]">sell</span>
                      {priceLabel}
                    </span>
                    <span className="inline-flex items-center gap-1 rounded-full bg-slate-100 px-3 py-1 dark:bg-slate-700">
                      <span className="material-symbols-outlined text-[16px]">list_alt</span>
                      {course.sections.length} {t('courseDetail.sections')}
                    </span>
                    <span className="inline-flex items-center gap-1 rounded-full bg-slate-100 px-3 py-1 dark:bg-slate-700">
                      <span className="material-symbols-outlined text-[16px]">play_circle</span>
                      {totalLessons} {t('courseDetail.lessons')}
                    </span>
                  </div>
                  <p className="text-slate-600 dark:text-slate-300">{course.description}</p>
                  <div className="flex flex-wrap gap-3 text-sm text-slate-600 dark:text-slate-300">
                    <span className="inline-flex items-center gap-1 rounded-full bg-slate-100 px-3 py-1 dark:bg-slate-700">
                      <span className="material-symbols-outlined text-[16px]">translate</span>
                      {t('courseDetail.language')}: {t('courseDetail.defaultLanguage')}
                    </span>
                  </div>
                </div>
                <div className="w-full max-w-xs rounded-xl border border-slate-200 bg-slate-50 p-4 shadow-sm dark:border-slate-700 dark:bg-slate-900">
                  <div className="flex items-center gap-3">
                    <div className="h-12 w-12 rounded-full bg-gradient-to-br from-slate-200 to-slate-100 dark:from-slate-700 dark:to-slate-600" />
                    <div>
                      <div className="text-sm font-semibold text-slate-900 dark:text-white">{t('courseDetail.instructor')}</div>
                      <div className="text-xs text-slate-500 dark:text-slate-400">{t('courseDetail.unknownInstructor')}</div>
                    </div>
                  </div>
                  <div className="mt-3 space-y-2 text-sm text-slate-600 dark:text-slate-300">
                    <div className="flex items-center gap-2">
                      <span className="material-symbols-outlined text-[18px] text-slate-400">event</span>
                      <span>{t('courseDetail.submittedAt')}: {new Date(course.createdAt).toLocaleDateString()}</span>
                    </div>
                    <div className="flex items-center gap-2">
                      <span className="material-symbols-outlined text-[18px] text-slate-400">schedule</span>
                      <span>{t('courseDetail.totalDuration')}: {t('courseDetail.durationMinutes', { minutes: totalDuration })}</span>
                    </div>
                  </div>
                </div>
              </div>
            </div>

            <div className="grid gap-6 lg:grid-cols-3">
              <div className="lg:col-span-2 space-y-4">
                <div className="overflow-hidden rounded-2xl border border-slate-200 bg-black shadow-sm dark:border-slate-800">
                  {selectedLesson?.playbackUrl ? (
                    <video
                      key={selectedLesson.playbackUrl}
                      src={selectedLesson.playbackUrl}
                      controls
                      className="aspect-video w-full"
                    />
                  ) : (
                    <div className="flex aspect-video items-center justify-center text-slate-400">{t('courseDetail.selectLesson')}</div>
                  )}
                </div>

                <div className="rounded-xl border border-slate-200 bg-white p-4 shadow-sm dark:border-slate-800 dark:bg-slate-800">
                  <div className="flex gap-6 border-b border-slate-200 pb-3 text-sm font-semibold text-slate-600 dark:border-slate-700 dark:text-slate-300">
                    <div className="border-b-2 border-dashboard-primary pb-2 text-dashboard-primary">{t('courseDetail.overviewTab')}</div>
                    <div className="pb-2 text-slate-400">{t('courseDetail.curriculumTab')}</div>
                  </div>
                  <div className="mt-4 space-y-2 text-sm text-slate-600 dark:text-slate-300">
                    <p>{course.description}</p>
                  </div>
                </div>
              </div>

              <div className="rounded-2xl border border-slate-200 bg-white p-4 shadow-sm dark:border-slate-800 dark:bg-slate-800">
                <h3 className="mb-3 text-lg font-semibold text-slate-900 dark:text-white">{t('courseDetail.curriculumTab')}</h3>
                <div className="space-y-3">
                  {course.sections.map((section, sIdx) => (
                    <div key={section.id || sIdx} className="rounded-lg border border-slate-200 bg-slate-50 p-3 dark:border-slate-700 dark:bg-slate-900">
                      <div className="text-sm font-semibold text-slate-800 dark:text-white">{section.title}</div>
                      <div className="mt-2 space-y-2">
                        {section.lessons.map((lesson, lIdx) => (
                          <button
                            key={lesson.id || `${sIdx}-${lIdx}`}
                            onClick={() => setSelectedLesson(lesson)}
                            className={`w-full rounded-md px-3 py-2 text-left text-sm transition ${
                              selectedLesson?.id === lesson.id || selectedLesson === lesson
                                ? 'bg-dashboard-primary text-white'
                                : 'bg-white text-slate-800 hover:bg-slate-100 dark:bg-slate-800 dark:text-slate-200 dark:hover:bg-slate-700'
                            }`}
                          >
                            <div className="flex items-center justify-between">
                              <span className="flex items-center gap-2">
                                <span className="material-symbols-outlined text-[18px]">play_circle</span>
                                {lesson.title}
                              </span>
                              {lesson.duration ? (
                                <span className="text-xs opacity-80">{t('courseDetail.durationMinutes', { minutes: lesson.duration })}</span>
                              ) : null}
                            </div>
                          </button>
                        ))}
                      </div>
                    </div>
                  ))}
                </div>
              </div>
            </div>
          </div>
        )}
      </div>
    </div>
  );
};

export default CourseDetailPage;
