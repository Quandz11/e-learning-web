import React, { useEffect, useMemo, useState } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { useTranslation } from 'react-i18next';
import { courseApi, type CourseResponse, type CourseLessonInput } from '../../../services/courseApi';
import AdminLayout from '../../../components/admin/AdminLayout';
import CourseFormModal from './components/CourseFormModal';
import SecureVideoPlayer from '../../../components/SecureVideoPlayer';
import PdfViewer from '../../../components/PdfViewer';

const CourseDetailPage: React.FC = () => {
  const { id } = useParams<{ id: string }>();
  const navigate = useNavigate();
  const { t } = useTranslation();

  // State
  const [course, setCourse] = useState<CourseResponse | null>(null);
  const [selectedLesson, setSelectedLesson] = useState<CourseLessonInput | null>(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [activeTab, setActiveTab] = useState<'overview' | 'curriculum' | 'students' | 'financials'>('overview');
  const [expandedSections, setExpandedSections] = useState<Set<string>>(new Set());
  const [showEditModal, setShowEditModal] = useState(false);
  const [contentType, setContentType] = useState<'video' | 'document'>('video');

  // Fetch course data
  const fetchCourse = async () => {
    if (!id) return;
    try {
      setLoading(true);
      setError(null);
      const data = await courseApi.getById(id);
      setCourse(data);

      // Auto-select first lesson (regardless of playbackUrl)
      if (!selectedLesson) {
        const allLessons = data.sections.flatMap((s) => s.lessons);
        if (allLessons.length > 0) {
          setSelectedLesson(allLessons[0]);
        }
      }

      // Expand first section by default
      if (expandedSections.size === 0 && data.sections.length > 0) {
        setExpandedSections(new Set([data.sections[0].id || '0']));
      }
    } catch (err: any) {
      setError(err.message || t('courseDetail.loadError'));
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    void fetchCourse();
  }, [id, t]);

  // Auto-select content type when lesson changes
  useEffect(() => {
    if (selectedLesson) {
      // Prioritize video if available, otherwise show document
      if (selectedLesson.videoId) {
        setContentType('video');
      } else if (selectedLesson.documentUrl) {
        setContentType('document');
      }
    }
  }, [selectedLesson]);

  // Computed values
  const lessons = useMemo(() => course?.sections.flatMap((s) => s.lessons) ?? [], [course]);
  const totalLessons = lessons.length;
  const statusLabel = course?.isPublished ? t('courseDetail.meta.statusPublished') : t('courseDetail.meta.statusDraft');
  const priceLabel = course?.isFree ? t('courseDetail.free') : `${(course?.price ?? 0).toLocaleString('vi-VN')} VND`;

  // Handlers
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

  // Mock data (will be replaced with real data from backend later)
  const mockStats = {
    enrollments: 1240,
    rating: 4.8,
    reviews: 210
  };

  const mockLearningOutcomes = [
    'Master DataFrames and Series in Pandas',
    'Create interactive plots with Plotly',
    'NumPy array manipulation techniques',
    'Data cleaning best practices'
  ];

  return (
    <AdminLayout>
      <div className="max-w-7xl mx-auto pb-24">
        {/* Breadcrumb - Clickable */}
        <div className="flex items-center gap-2 text-xs font-medium text-slate-500 dark:text-slate-400 mb-6">
          <button
            onClick={() => navigate('/admin/courses')}
            className="hover:text-primary transition-colors"
          >
            {t('courseDetail.breadcrumb.courses')}
          </button>
          <span className="material-symbols-outlined text-xs">chevron_right</span>
          <span className="text-slate-800 dark:text-slate-200">#{course?.id.slice(0, 8)}</span>
        </div>

        {loading && <div className="text-slate-600 dark:text-slate-300">{t('courseDetail.loading')}</div>}
        {error && (
          <div className="mb-4 rounded-lg border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-700 dark:border-red-900/50 dark:bg-red-900/20 dark:text-red-200">
            {error}
          </div>
        )}

        {course && (
          <div className="space-y-8">
            {/* Course Header Info (Full Width) */}
            {/* Course Header Info (Full Width) */}
            <div className="flex flex-col md:flex-row md:items-start md:justify-between gap-4">
              <div>
                <h1 className="text-3xl font-bold font-dashboard text-slate-900 dark:text-white mb-3">
                  {course.title}
                </h1>
                <div className="flex flex-wrap items-center gap-3 text-sm text-slate-600 dark:text-slate-400">
                  <span className={`px-2.5 py-0.5 rounded-full font-medium text-xs border ${course.isPublished
                    ? 'bg-success/10 text-success border-success/20'
                    : 'bg-slate-100 text-slate-500 border-slate-200 dark:bg-slate-700 dark:text-slate-400'
                    }`}>
                    {statusLabel}
                  </span>
                </div>
              </div>

              <button
                onClick={() => setShowEditModal(true)}
                className="inline-flex items-center gap-2 rounded-lg bg-dashboard-primary px-4 py-2 text-sm font-semibold text-white shadow-sm shadow-dashboard-primary/30 transition hover:bg-dashboard-primary-dark whitespace-nowrap"
              >
                <span className="material-symbols-outlined text-[18px]">edit</span>
                {t('courseDetail.actions.edit')}
              </button>
            </div>

            {/* Main Layout Grid */}
            <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">

              {/* Left Column (2/3) - Video & Tabs & Content */}
              <div className="lg:col-span-2 space-y-8">
                {/* 1. Content Type Tabs (if lesson has both video and document) */}
                {selectedLesson && selectedLesson.videoId && selectedLesson.documentUrl && (
                  <div className="flex gap-2 border-b border-border-light dark:border-border-dark">
                    <button
                      onClick={() => setContentType('video')}
                      className={`px-4 py-2 font-medium text-sm transition-colors border-b-2 ${contentType === 'video'
                        ? 'border-primary text-primary'
                        : 'border-transparent text-slate-500 hover:text-slate-800 dark:hover:text-slate-200'
                        }`}
                    >
                      <span className="flex items-center gap-2">
                        <span className="material-symbols-outlined text-[18px]">play_circle</span>
                        {t('learn.contentType.video')}
                      </span>
                    </button>
                    <button
                      onClick={() => setContentType('document')}
                      className={`px-4 py-2 font-medium text-sm transition-colors border-b-2 ${contentType === 'document'
                        ? 'border-primary text-primary'
                        : 'border-transparent text-slate-500 hover:text-slate-800 dark:hover:text-slate-200'
                        }`}
                    >
                      <span className="flex items-center gap-2">
                        <span className="material-symbols-outlined text-[18px]">description</span>
                        {t('learn.contentType.document')}
                      </span>
                    </button>
                  </div>
                )}

                {/* 2. Video/Document Player */}
                <div className={`w-full rounded-xl bg-slate-900 relative overflow-hidden shadow-lg border border-slate-800 ${contentType === 'video' ? 'aspect-video' : 'min-h-[800px]'
                  }`}>
                  {contentType === 'video' ? (
                    selectedLesson?.videoId ? (
                      <SecureVideoPlayer
                        videoId={selectedLesson.videoId}
                        className="absolute inset-0 w-full h-full object-cover"
                        controls
                      />
                    ) : (
                      <div className="flex aspect-video items-center justify-center text-slate-400">
                        {t('learn.noVideo')}
                      </div>
                    )
                  ) : (
                    selectedLesson?.documentUrl ? (
                      <PdfViewer documentUrl={selectedLesson.documentUrl} />
                    ) : (
                      <div className="flex aspect-video items-center justify-center text-slate-400">
                        {t('learn.noPdf')}
                      </div>
                    )
                  )}
                </div>

                {/* 3. Tabs & Content */}
                <div className="space-y-6">
                  {/* Tab Navigation */}
                  <div className="border-b border-border-light dark:border-border-dark">
                    <nav className="flex gap-8 overflow-x-auto">
                      {(['overview', 'curriculum', 'students', 'financials'] as const).map((tab) => (
                        <button
                          key={tab}
                          onClick={() => setActiveTab(tab)}
                          className={`pb-3 border-b-2 transition-colors font-medium text-sm whitespace-nowrap ${activeTab === tab
                            ? 'border-primary text-primary font-bold'
                            : 'border-transparent text-slate-500 hover:text-slate-800 dark:hover:text-slate-200'
                            }`}
                        >
                          {t(`courseDetail.tabs.${tab}`)}
                          {tab === 'curriculum' && ` (${totalLessons})`}
                        </button>
                      ))}
                    </nav>
                  </div>

                  {/* Tab Content */}
                  <div>
                    {activeTab === 'overview' && (
                      <div className="space-y-8">
                        {/* Description */}
                        <div>
                          <h3 className="text-lg font-bold text-slate-900 dark:text-white mb-3">
                            {t('courseDetail.sections.description')}
                          </h3>
                          <p className="text-slate-600 dark:text-slate-300 leading-relaxed text-base">
                            {course.description}
                          </p>
                        </div>

                        {/* Learning Outcomes */}
                        <div>
                          <h3 className="text-lg font-bold text-slate-900 dark:text-white mb-3">
                            {t('courseDetail.sections.whatLearn')}
                          </h3>
                          <ul className="grid grid-cols-1 md:grid-cols-2 gap-3">
                            {mockLearningOutcomes.map((outcome, idx) => (
                              <li key={idx} className="flex items-start gap-2 text-slate-600 dark:text-slate-300 text-sm">
                                <span className="material-symbols-outlined text-success text-lg shrink-0">check_circle</span>
                                <span>{outcome}</span>
                              </li>
                            ))}
                          </ul>
                        </div>
                      </div>
                    )}

                    {activeTab === 'curriculum' && (
                      <div className="text-slate-600 dark:text-slate-300">
                        Curriculum tab content - Coming soon
                      </div>
                    )}

                    {activeTab === 'students' && (
                      <div className="text-slate-600 dark:text-slate-300">
                        Students enrolled tab content - Coming soon
                      </div>
                    )}

                    {activeTab === 'financials' && (
                      <div className="text-slate-600 dark:text-slate-300">
                        Financials/Earnings tab content - Coming soon
                      </div>
                    )}
                  </div>
                </div>
              </div>

              {/* Right Column (1/3) - Sidebar Info & Structure */}
              <div className="lg:col-span-1 space-y-6">

                {/* 1. Instructor Card */}
                {course.lecturer && (
                  <div className="flex items-center gap-3 bg-white dark:bg-slate-800 px-4 py-3 rounded-lg border border-border-light dark:border-border-dark shadow-sm">
                    {course.lecturer.avatarUrl ? (
                      <img
                        src={course.lecturer.avatarUrl}
                        alt={course.lecturer.fullName}
                        className="w-12 h-12 rounded-full object-cover"
                      />
                    ) : (
                      <div className="w-12 h-12 rounded-full bg-gradient-to-br from-primary to-blue-600 flex items-center justify-center text-white font-bold text-lg">
                        {course.lecturer.fullName.charAt(0).toUpperCase()}
                      </div>
                    )}
                    <div className="flex flex-col">
                      <span className="text-base font-bold text-slate-900 dark:text-white">{course.lecturer.fullName}</span>
                      <span className="text-xs text-slate-500">{t('courseDetail.instructorInfo.senior')}</span>
                    </div>
                  </div>
                )}

                {/* 2. Course Structure (Sticky or Scrollable area) */}
                <div className="flex flex-col max-h-[600px]">
                  <h3 className="flex-none text-lg font-bold text-slate-900 dark:text-white mb-3">
                    {t('courseDetail.sections.structure')}
                  </h3>
                  <div className="flex-1 border border-border-light dark:border-border-dark rounded-lg divide-y divide-border-light dark:divide-border-dark overflow-y-auto bg-white dark:bg-surface-dark custom-scrollbar">
                    {course.sections.map((section, sIdx) => {
                      const sectionId = section.id || `${sIdx}`;
                      const isExpanded = expandedSections.has(sectionId);
                      const sectionDuration = section.lessons.reduce((sum, l) => sum + (l.duration || 0), 0);

                      return (
                        <div key={sectionId}>
                          <div
                            onClick={() => toggleSection(sectionId)}
                            className="p-4 flex justify-between items-center hover:bg-slate-50 dark:hover:bg-slate-800 cursor-pointer group"
                          >
                            <div className="flex items-center gap-3">
                              <span className={`material-symbols-outlined text-slate-400 transition-transform ${isExpanded ? 'rotate-180' : ''}`}>
                                expand_more
                              </span>
                              <span className="font-medium text-slate-800 dark:text-slate-200 line-clamp-1">{section.title}</span>
                            </div>
                            <span className="text-xs text-slate-500 whitespace-nowrap ml-2">
                              {section.lessons.length} • {sectionDuration}m
                            </span>
                          </div>

                          {isExpanded && (
                            <div className="px-4 pb-4 space-y-2 bg-slate-50 dark:bg-slate-900/50">
                              {section.lessons.map((lesson, lIdx) => (
                                <button
                                  key={lesson.id || `${sIdx}-${lIdx}`}
                                  onClick={() => setSelectedLesson(lesson)}
                                  className={`w-full rounded-md px-3 py-2 text-left text-sm transition flex items-center justify-between ${selectedLesson?.id === lesson.id || selectedLesson === lesson
                                    ? 'bg-primary text-white'
                                    : 'bg-white text-slate-800 hover:bg-slate-100 dark:bg-slate-800 dark:text-slate-200 dark:hover:bg-slate-700'
                                    }`}
                                >
                                  <span className="flex items-center gap-2 overflow-hidden">
                                    <span className="material-symbols-outlined text-[18px] shrink-0">play_circle</span>
                                    <span className="truncate">{lesson.title}</span>
                                  </span>
                                  {lesson.duration && (
                                    <span className="text-xs opacity-80 shrink-0 ml-2">{lesson.duration}m</span>
                                  )}
                                </button>
                              ))}
                            </div>
                          )}
                        </div>
                      );
                    })}
                  </div>
                </div>

                {/* 3. Statistics */}
                <div className="p-5 bg-white dark:bg-surface-dark rounded-xl border border-border-light dark:border-border-dark shadow-sm">
                  <h4 className="font-bold text-sm text-slate-900 dark:text-white mb-4 uppercase tracking-wider">
                    {t('courseDetail.sections.statistics')}
                  </h4>
                  <div className="grid grid-cols-2 lg:grid-cols-1 gap-4">
                    <div className="col-span-1">
                      <span className="text-xs text-slate-500 block mb-1">{t('courseDetail.stats.enrollments')}</span>
                      <span className="text-sm font-medium text-slate-800 dark:text-slate-200 flex items-center gap-2">
                        <span className="material-symbols-outlined text-primary text-base">groups</span>
                        {mockStats.enrollments.toLocaleString()}
                      </span>
                    </div>
                    <div className="col-span-1">
                      <span className="text-xs text-slate-500 block mb-1">{t('courseDetail.stats.rating')}</span>
                      <span className="text-sm font-medium text-slate-800 dark:text-slate-200 flex items-center gap-2">
                        <span className="material-symbols-outlined text-yellow-500 text-base">star</span>
                        {mockStats.rating}
                      </span>
                    </div>
                    <div className="col-span-2 lg:col-span-1">
                      <span className="text-xs text-slate-500 block mb-1">{t('courseDetail.stats.lastUpdated')}</span>
                      <span className="text-sm font-medium text-slate-800 dark:text-slate-200">
                        {new Date(course.createdAt).toLocaleDateString('vi-VN')}
                      </span>
                    </div>
                    {/* Course Price */}
                    <div className="col-span-2 lg:col-span-1 pt-2 border-t border-border-light dark:border-border-dark mt-2">
                      <span className="text-xs text-slate-500 block mb-1">Chi phí khóa học</span>
                      <span className="text-lg font-bold text-slate-900 dark:text-white">
                        {priceLabel}
                      </span>
                    </div>
                  </div>
                </div>

              </div>
            </div>
            {/* End Main Layout Grid */}
          </div>
        )}
      </div>


      <CourseFormModal
        isOpen={showEditModal}
        onClose={() => setShowEditModal(false)}
        onSuccess={() => {
          void fetchCourse();
          setShowEditModal(false);
        }}
        courseId={id}
        initialData={course}
      />
    </AdminLayout>
  );
};

export default CourseDetailPage;
