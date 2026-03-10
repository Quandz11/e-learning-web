import React, { useEffect, useMemo, useState } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { useTranslation } from 'react-i18next';
import { courseApi, type CourseResponse, type StudentResponse } from '../../../services/courseApi';
import { type LessonPartDto } from '../../../services/lessonApi';
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
  const [enrolledStudents, setEnrolledStudents] = useState<StudentResponse[]>([]);
  const [selectedPart, setSelectedPart] = useState<LessonPartDto | null>(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [activeTab, setActiveTab] = useState<'overview' | 'curriculum' | 'students' | 'financials'>('overview');
  const [expandedLessons, setExpandedLessons] = useState<Set<string>>(new Set());
  const [showEditModal, setShowEditModal] = useState(false);

  // Fetch course data
  const fetchCourse = async () => {
    if (!id) return;
    try {
      setLoading(true);
      setError(null);
      const data = await courseApi.getById(id);
      setCourse(data);

      // Auto-select first part of first lesson
      if (!selectedPart) {
        if (data.lessons && data.lessons.length > 0) {
          const firstLesson = data.lessons[0];
          if (firstLesson.parts && firstLesson.parts.length > 0) {
            setSelectedPart(firstLesson.parts[0]);
          }
        }
      }

      // Expand first lesson by default
      if (expandedLessons.size === 0 && data.lessons && data.lessons.length > 0) {
        setExpandedLessons(new Set([data.lessons[0].id || '0']));
      }

      // Fetch enrolled students
      const students = await courseApi.getEnrolledStudents(id);
      setEnrolledStudents(students);
    } catch (err: any) {
      setError(err.message || t('courseDetail.loadError'));
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    void fetchCourse();
  }, [id, t]);

  // Computed values
  const totalParts = useMemo(() => course?.lessons?.reduce((acc, l) => acc + (l.parts?.length || 0), 0) ?? 0, [course]);
  const statusLabel = course?.isPublished ? t('courseDetail.meta.statusPublished') : t('courseDetail.meta.statusDraft');
  const priceLabel = course?.isFree ? t('courseDetail.free') : `${(course?.price ?? 0).toLocaleString('vi-VN')} VND`;

  // Handlers
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

  // Mock data (will be replaced with real data from backend later)
  const mockStats = {
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
                {/* 1. Video/Document Player */}
                <div className={`w-full rounded-xl bg-slate-900 relative overflow-hidden shadow-lg border border-slate-800 ${selectedPart?.type === 'Video' ? 'aspect-video' : 'min-h-[800px]'
                  }`}>
                  {selectedPart?.type === 'Video' ? (
                    selectedPart?.videoId ? (
                      <SecureVideoPlayer
                        videoId={selectedPart.videoId}
                        className="absolute inset-0 w-full h-full object-cover"
                        controls
                      />
                    ) : (
                      <div className="flex aspect-video items-center justify-center text-slate-400">
                        {t('learn.noVideo')}
                      </div>
                    )
                  ) : (
                    selectedPart?.documentUrl ? (
                      <PdfViewer documentUrl={selectedPart.documentUrl} />
                    ) : (
                      <div className="flex aspect-video items-center justify-center text-slate-400">
                        {t('learn.noPdf')}
                      </div>
                    )
                  )}
                </div>

                {/* 2. Tabs & Content */}
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
                          {tab === 'curriculum' && ` (${totalParts})`}
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
                          <div
                            className="rich-text text-slate-600 dark:text-slate-300 leading-relaxed text-base"
                            dangerouslySetInnerHTML={{ __html: course.description || '' }}
                          />
                        </div>

                        {/* Learning Outcomes */}
                        <div>
                          <h3 className="text-lg font-bold text-slate-900 dark:text-white mb-3">
                            {t('courseDetail.sections.whatLearn')}
                          </h3>
                          <ul className="grid grid-cols-1 md:grid-cols-2 gap-3">
                            {(course.learningOutcomes && course.learningOutcomes.length > 0 ? course.learningOutcomes : mockLearningOutcomes).map((outcome, idx) => (
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
                      <div className="space-y-4">
                        {course.lessons?.map((lesson, lIdx) => (
                          <div key={lesson.id || lIdx} className="rounded-lg border border-slate-200 bg-white p-4 dark:border-slate-800 dark:bg-slate-900">
                            <h4 className="flex items-center gap-2 font-semibold text-slate-800 dark:text-slate-200 mb-2">
                              {lesson.thumbnailUrl && <img src={lesson.thumbnailUrl} className="w-8 h-8 rounded object-cover" />}
                              <span className="material-symbols-outlined text-primary">feed</span>
                              {lesson.title}
                              <span className="text-xs font-normal text-slate-500 ml-auto">{lesson.parts?.length || 0} {t('learn.parts')}</span>
                            </h4>
                            <div className="space-y-2 pl-4 border-l-2 border-slate-100 dark:border-slate-800 ml-2">
                              {lesson.parts?.map((part, pIdx) => (
                                <div key={part.id || pIdx} className="flex items-center gap-2 text-sm text-slate-600 dark:text-slate-400">
                                  <span className="material-symbols-outlined text-[18px]">
                                    {part.type === 'Video' ? 'play_circle' : 'description'}
                                  </span>
                                  <span>{part.title}</span>
                                  {part.type === 'Video' && part.videoDuration && (
                                    <span className="text-xs text-slate-400 ml-auto">{Math.round(part.videoDuration / 60)}{t('learn.minutes')}</span>
                                  )}
                                </div>
                              ))}
                            </div>
                          </div>
                        ))}
                      </div>
                    )}

                    {activeTab === 'students' && (
                      <div className="space-y-4">
                        <div className="flex items-center justify-between mb-2">
                          <h3 className="font-semibold text-slate-900 dark:text-white">{t('courseDetail.tabs.studentsCount', { count: enrolledStudents.length })}</h3>
                        </div>
                        <div className="overflow-hidden rounded-lg border border-slate-200 dark:border-slate-700">
                          <table className="w-full text-left text-sm text-slate-600 dark:text-slate-300">
                            <thead className="bg-slate-50 dark:bg-slate-800 text-xs uppercase text-slate-500">
                              <tr>
                                <th className="px-4 py-3">{t('courseDetail.studentsTable.student')}</th>
                                <th className="px-4 py-3">{t('courseDetail.studentsTable.email')}</th>
                                <th className="px-4 py-3">{t('courseDetail.studentsTable.enrolledDate')}</th>
                              </tr>
                            </thead>
                            <tbody className="divide-y divide-slate-200 dark:divide-slate-700 bg-white dark:bg-slate-900">
                              {enrolledStudents.map((student) => (
                                <tr key={student.id}>
                                  <td className="px-4 py-3">
                                    <div className="flex items-center gap-2">
                                      <div className="h-8 w-8 rounded-full bg-slate-200 bg-cover bg-center flex-shrink-0" style={{ backgroundImage: student.avatarUrl ? `url(${student.avatarUrl})` : undefined }}>
                                        {!student.avatarUrl && <span className="flex h-full w-full items-center justify-center text-xs font-bold text-slate-500">{student.fullName.charAt(0)}</span>}
                                      </div>
                                      <span className="font-medium text-slate-900 dark:text-white">{student.fullName}</span>
                                    </div>
                                  </td>
                                  <td className="px-4 py-3">{student.email}</td>
                                  <td className="px-4 py-3">{new Date(student.enrolledAt).toLocaleDateString()}</td>
                                </tr>
                              ))}
                              {enrolledStudents.length === 0 && (
                                <tr>
                                  <td colSpan={3} className="px-4 py-8 text-center text-slate-500">{t('courseDetail.studentsTable.empty')}</td>
                                </tr>
                              )}
                            </tbody>
                          </table>
                        </div>
                      </div>
                    )}

                    {activeTab === 'financials' && (
                      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                        <div className="p-4 rounded-xl bg-slate-50 dark:bg-slate-800 border border-slate-200 dark:border-slate-700">
                          <h4 className="text-sm font-medium text-slate-500 mb-1">{t('courseDetail.financials.totalRevenue')}</h4>
                          <div className="text-2xl font-bold text-slate-900 dark:text-white">
                            {((course.price || 0) * enrolledStudents.length).toLocaleString('vi-VN')} VND
                          </div>
                          <p className="text-xs text-slate-400 mt-1">{t('courseDetail.financials.basedOnPrice', { price: course.price.toLocaleString(), count: enrolledStudents.length })}</p>
                        </div>
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
                    {course.lessons?.map((lesson, lIdx) => {
                      const lessonId = lesson.id || `${lIdx}`;
                      const isExpanded = expandedLessons.has(lessonId);
                      const lessonDuration = lesson.parts?.reduce((sum, p) => sum + (p.videoDuration || 0), 0) || 0;

                      return (
                        <div key={lessonId}>
                          <div
                            onClick={() => toggleLesson(lessonId)}
                            className="p-4 flex justify-between items-center hover:bg-slate-50 dark:hover:bg-slate-800 cursor-pointer group"
                          >
                            <div className="flex items-center gap-3">
                              <span className={`material-symbols-outlined text-slate-400 transition-transform ${isExpanded ? 'rotate-180' : ''}`}>
                                expand_more
                              </span>
                              <span className="font-medium text-slate-800 dark:text-slate-200 line-clamp-1">{lesson.title}</span>
                            </div>
                            <span className="text-xs text-slate-500 whitespace-nowrap ml-2">
                              {lesson.parts?.length || 0} • {Math.round(lessonDuration / 60)}{t('learn.minutes')}
                            </span>
                          </div>

                          {isExpanded && (
                            <div className="px-4 pb-4 space-y-2 bg-slate-50 dark:bg-slate-900/50">
                              {lesson.parts?.map((part, pIdx) => (
                                <button
                                  key={part.id || `${lIdx}-${pIdx}`}
                                  onClick={() => setSelectedPart(part)}
                                  className={`w-full rounded-md px-3 py-2 text-left text-sm transition flex items-center justify-between ${selectedPart?.id === part.id || selectedPart === part
                                    ? 'bg-primary text-white'
                                    : 'bg-white text-slate-800 hover:bg-slate-100 dark:bg-slate-800 dark:text-slate-200 dark:hover:bg-slate-700'
                                    }`}
                                >
                                  <span className="flex items-center gap-2 overflow-hidden">
                                    <span className="material-symbols-outlined text-[18px] shrink-0">
                                      {part.type === 'Video' ? 'play_circle' : 'description'}
                                    </span>
                                    <span className="truncate">{part.title}</span>
                                  </span>
                                  {part.type === 'Video' && part.videoDuration && (
                                    <span className="text-xs opacity-80 shrink-0 ml-2">{Math.round(part.videoDuration / 60)}{t('learn.minutes')}</span>
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
                        {enrolledStudents.length.toLocaleString()}
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
                      <span className="text-xs text-slate-500 block mb-1">{t('courseDetail.stats.coursePrice')}</span>
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
