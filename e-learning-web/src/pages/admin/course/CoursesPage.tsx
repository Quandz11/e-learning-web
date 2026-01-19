import React, { useEffect, useMemo, useState } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { useTranslation } from 'react-i18next';
import AdminLayout from '../../../components/admin/AdminLayout';
import { courseApi } from '../../../services/courseApi';
import type { CourseInput, CourseResponse, CourseSectionInput, CourseLessonInput } from '../../../services/courseApi';
import { userApi, type UserDto } from '../../../services/userApi';
import { useSelector } from 'react-redux';
import type { RootState } from '../../../store/store';
import { format } from 'date-fns';

const emptyLesson = (orderIndex: number): CourseLessonInput => ({
  title: 'New lesson',
  duration: 0,
  orderIndex,
  isPreview: false,
  videoId: '',
});

const emptySection = (orderIndex: number): CourseSectionInput => ({
  title: 'New section',
  orderIndex,
  lessons: [emptyLesson(1)],
});

const initialCourse = (lecturerId: string | undefined): CourseInput => ({
  title: '',
  description: '',
  price: 0,
  isFree: false,
  lecturerId: lecturerId || '',
  thumbnailUrl: '',
  isPublished: false,
  sections: [emptySection(1)],
});

const CoursesPage: React.FC = () => {
  const { t } = useTranslation();
  const { user } = useSelector((state: RootState) => state.auth);
  const navigate = useNavigate();
  const [courses, setCourses] = useState<CourseResponse[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [saving, setSaving] = useState(false);
  const [showForm, setShowForm] = useState(false);
  const [editingId, setEditingId] = useState<string | null>(null);
  const [form, setForm] = useState<CourseInput>(initialCourse(user?.id));
  const [lecturers, setLecturers] = useState<UserDto[]>([]);
  const [lecturerSearch, setLecturerSearch] = useState('');
  const [lecturerLoading, setLecturerLoading] = useState(false);
  const [videoThumbnailUploading, setVideoThumbnailUploading] = useState<Record<string, boolean>>({});
  const lecturerId = useMemo(() => user?.id || '', [user]);

  useEffect(() => {
    load();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  useEffect(() => {
    setForm((prev) => ({ ...prev, lecturerId }));
  }, [lecturerId]);

  useEffect(() => {
    if (!showForm) return;
    const handle = setTimeout(() => {
      void fetchLecturers();
    }, 300);
    return () => clearTimeout(handle);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [lecturerSearch, showForm]);

  const load = async () => {
    try {
      setLoading(true);
      const data = await courseApi.getAll();
      setCourses(data);
    } catch (err: any) {
      setError(err.message || t('admin.courses.form.errors.loadFailed'));
    } finally {
      setLoading(false);
    }
  };

  const fetchLecturers = async () => {
    try {
      setLecturerLoading(true);
      const res = await userApi.getPaged({ role: 'LECTURER', search: lecturerSearch, page: 1, pageSize: 20 });
      setLecturers(res.items);
    } catch (err: any) {
      setError(err.message || t('admin.courses.form.errors.loadLecturers'));
    } finally {
      setLecturerLoading(false);
    }
  };

  const openCreate = () => {
    setEditingId(null);
    setForm(initialCourse(lecturerId));
    setLecturerSearch('');
    setShowForm(true);
  };

  const openEdit = (course: CourseResponse) => {
    setEditingId(course.id);
    setForm({
      title: course.title,
      description: course.description,
      price: course.price,
      isFree: course.isFree,
      lecturerId: course.lecturerId,
      thumbnailUrl: course.thumbnailUrl,
      isPublished: course.isPublished,
      sections: course.sections.map((s) => ({
        id: s.id,
        title: s.title,
        orderIndex: s.orderIndex,
        lessons: s.lessons.map((l) => ({
          id: l.id,
          title: l.title,
          duration: l.duration,
          orderIndex: l.orderIndex,
          isPreview: l.isPreview,
          videoId: l.videoId,
          playbackUrl: l.playbackUrl,
        })),
      })),
    });
    setLecturerSearch('');
    setShowForm(true);
  };

  const closeForm = () => {
    setShowForm(false);
    setError(null);
  };

  const handleSave = async () => {
    if (!form.title.trim()) {
      setError(t('admin.courses.form.errors.title'));
      return;
    }
    if (!form.lecturerId) {
      setError(t('admin.courses.form.errors.lecturer'));
      return;
    }
    // Ensure price 0 when free
    const payload: CourseInput = {
      ...form,
      price: form.isFree ? 0 : form.price,
    };

    try {
      setSaving(true);
      setError(null);
      if (editingId) {
        await courseApi.update(editingId, payload);
      } else {
        await courseApi.create(payload);
      }
      await load();
      setShowForm(false);
    } catch (err: any) {
      setError(err.message || t('admin.courses.form.errors.saveFailed'));
    } finally {
      setSaving(false);
    }
  };

  const updateSection = (index: number, data: Partial<CourseSectionInput>) => {
    setForm((prev) => {
      const sections = [...prev.sections];
      sections[index] = { ...sections[index], ...data };
      return { ...prev, sections };
    });
  };

  const updateLesson = (sectionIndex: number, lessonIndex: number, data: Partial<CourseLessonInput>) => {
    setForm((prev) => {
      const sections = [...prev.sections];
      const lessons = [...sections[sectionIndex].lessons];
      lessons[lessonIndex] = { ...lessons[lessonIndex], ...data } as CourseLessonInput;
      sections[sectionIndex] = { ...sections[sectionIndex], lessons };
      return { ...prev, sections };
    });
  };

  const addSection = () => {
    setForm((prev) => ({
      ...prev,
      sections: [...prev.sections, emptySection(prev.sections.length + 1)],
    }));
  };

  const addLesson = (sectionIndex: number) => {
    setForm((prev) => {
      const sections = [...prev.sections];
      const lessons = [...sections[sectionIndex].lessons, emptyLesson(sections[sectionIndex].lessons.length + 1)];
      sections[sectionIndex] = { ...sections[sectionIndex], lessons };
      return { ...prev, sections };
    });
  };

  const handleDelete = async (id: string) => {
    if (!confirm(t('admin.courses.form.deleteConfirm'))) return;
    try {
      await courseApi.remove(id);
      await load();
    } catch (err: any) {
      setError(err.message || t('admin.courses.form.errors.deleteFailed'));
    }
  };

  const handleUpload = async (sectionIndex: number, lessonIndex: number, file?: File | null) => {
    if (!file) return;
    try {
      setSaving(true);
      const lesson = form.sections[sectionIndex].lessons[lessonIndex];
      const res = await courseApi.uploadVideo(file, lesson.title);
      updateLesson(sectionIndex, lessonIndex, { videoId: res.videoId, playbackUrl: res.playlistUrl, duration: res.duration });
    } catch (err: any) {
      setError(err.message || t('admin.courses.form.errors.uploadFailed'));
    } finally {
      setSaving(false);
    }
  };

  const handleVideoThumbnailUpload = async (sectionIndex: number, lessonIndex: number, file?: File | null) => {
    if (!file) return;
    const lesson = form.sections[sectionIndex].lessons[lessonIndex];
    if (!lesson.videoId) {
      setError(t('admin.courses.form.errors.videoRequiredBeforeThumbnail', { defaultValue: 'Upload video before setting a thumbnail.' }));
      return;
    }

    const key = `${sectionIndex}-${lessonIndex}`;
    try {
      setVideoThumbnailUploading((prev) => ({ ...prev, [key]: true }));
      setError(null);
      await courseApi.uploadVideoThumbnail(lesson.videoId, file);
    } catch (err: any) {
      setError(err.message || t('admin.courses.form.errors.uploadFailed'));
    } finally {
      setVideoThumbnailUploading((prev) => ({ ...prev, [key]: false }));
    }
  };

  return (
    <AdminLayout>
      <div className="mb-6 flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-slate-900 dark:text-white">{t('admin.courses.title')}</h1>
          <p className="text-sm text-slate-500 dark:text-slate-400">{t('admin.courses.subtitle')}</p>
        </div>
        <button
          onClick={openCreate}
          className="inline-flex items-center gap-2 rounded-lg bg-dashboard-primary px-4 py-2 text-white shadow-sm shadow-dashboard-primary/30 transition hover:bg-dashboard-primary-dark"
        >
          <span className="material-symbols-outlined text-[18px]">add</span>
          {t('admin.courses.new')}
        </button>
      </div>

      {error && (
        <div className="mb-4 rounded-lg border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-700 dark:border-red-900/50 dark:bg-red-900/20 dark:text-red-200">
          {error}
        </div>
      )}

      <div className="mb-10">

        {loading ? (
          <div className="grid gap-4 md:grid-cols-2 xl:grid-cols-3 2xl:grid-cols-4">
            {Array.from({ length: 6 }).map((_, index) => (
              <div
                key={index}
                className="h-72 rounded-2xl border border-white/60 bg-white/70 shadow-sm shadow-slate-200 backdrop-blur animate-pulse dark:border-slate-800 dark:bg-slate-900"
              />
            ))}
          </div>
        ) : courses.length === 0 ? (
          <div className="rounded-2xl border border-dashed border-slate-300 bg-white/80 p-10 text-center text-slate-600 dark:border-slate-700 dark:bg-slate-900/70 dark:text-slate-300">
            <p className="text-base font-semibold">{t('admin.courses.table.noData')}</p>
            <p className="mt-1 text-sm text-slate-500 dark:text-slate-400">{t('admin.courses.table.loading')}</p>
          </div>
        ) : (
          <div className="grid gap-5 md:grid-cols-2 xl:grid-cols-3 2xl:grid-cols-4">
            {courses.map((course) => (
              <div
                key={course.id}
                className="group flex h-full flex-col overflow-hidden rounded-2xl border border-white/60 bg-white/90 shadow-sm shadow-slate-200 backdrop-blur transition hover:-translate-y-1 hover:shadow-xl dark:border-slate-800 dark:bg-dashboard-surface-dark"
              >
                <Link to={`/courses/${course.id}`} className="relative h-44 overflow-hidden block">
                  {course.thumbnailUrl ? (
                    <img
                      src={course.thumbnailUrl}
                      alt={course.title}
                      className="h-full w-full object-cover transition duration-500 group-hover:scale-105"
                    />
                  ) : (
                    <div className="h-full w-full bg-gradient-to-br from-sky-500 via-emerald-500 to-cyan-500 flex items-center justify-between px-4 text-white">
                      <div className="flex flex-col gap-2">
                        <span className="text-xs uppercase tracking-[0.25em] text-white/80">Course</span>
                        <p className="text-lg font-black leading-tight line-clamp-2 drop-shadow-lg">{course.title}</p>
                      </div>
                      <span className="material-symbols-outlined text-4xl text-white/70">play_circle</span>
                    </div>
                  )}
                  <div className="absolute left-4 top-4 flex items-center gap-2 rounded-full bg-white/90 px-3 py-1 text-xs font-semibold text-slate-700 shadow-sm backdrop-blur dark:bg-slate-900/80 dark:text-slate-200">
                    <span className="material-symbols-outlined text-sm">category</span>
                    <span>{course.sections.length} {t('courseDetail.sections')}</span>
                  </div>
                </Link>

                <div className="flex flex-1 flex-col gap-3 p-5">
                  <div className="flex items-start justify-between gap-3">
                    <div className="space-y-1">
                      <p className="text-xs font-semibold uppercase tracking-[0.2em] text-slate-400 dark:text-slate-500">Course</p>
                      <h4 className="text-lg font-bold text-slate-900 line-clamp-2 transition group-hover:text-sky-700 dark:text-white dark:group-hover:text-sky-300">
                        {course.title}
                      </h4>
                    </div>
                    <span className={`inline-flex items-center gap-1 rounded-full px-3 py-1 text-xs font-semibold ${course.isPublished ? 'bg-emerald-100 text-emerald-700 dark:bg-emerald-900/30 dark:text-emerald-200' : 'bg-amber-100 text-amber-700 dark:bg-amber-900/30 dark:text-amber-200'}`}>
                      <span className="material-symbols-outlined text-sm">circle</span>
                      {course.isPublished ? t('admin.courses.status.published') : t('admin.courses.status.draft')}
                    </span>
                  </div>

                  <p className="line-clamp-2 text-sm text-slate-600 dark:text-slate-300">{course.description || t('admin.courses.table.noData')}</p>

                  <div className="mt-auto flex items-center justify-between border-t border-slate-100 pt-3 dark:border-slate-800">
                    <div className="flex flex-col">
                      <span className="text-xs text-slate-500 dark:text-slate-400">{t('admin.courses.table.price')}</span>
                      <span className="text-base font-bold text-slate-900 dark:text-white">{course.isFree ? t('admin.courses.status.free') : `$${course.price.toLocaleString('en-US')}`}</span>
                    </div>
                    <div className="flex flex-col items-end">
                      <span className="text-xs text-slate-500 dark:text-slate-400">{t('admin.courses.table.created')}</span>
                      <span className="text-sm font-semibold text-slate-800 dark:text-slate-200">{format(new Date(course.createdAt), 'MMM d, yyyy')}</span>
                    </div>
                  </div>

                  <div className="flex items-center justify-between gap-2">
                    <button
                      className="inline-flex items-center gap-1 rounded-lg border border-slate-200 px-3 py-1.5 text-sm text-slate-700 transition hover:bg-slate-100 dark:border-slate-700 dark:text-slate-200 dark:hover:bg-slate-800"
                      onClick={() => openEdit(course)}
                    >
                      <span className="material-symbols-outlined text-[16px]">edit</span>
                      {t('admin.courses.buttons.edit')}
                    </button>
                    <button
                      className="inline-flex items-center gap-1 rounded-lg border border-red-200 px-3 py-1.5 text-sm text-red-600 transition hover:bg-red-50 dark:border-red-700 dark:text-red-300 dark:hover:bg-red-900/20"
                      onClick={() => handleDelete(course.id)}
                    >
                      <span className="material-symbols-outlined text-[16px]">delete</span>
                      {t('admin.courses.buttons.delete')}
                    </button>
                  </div>
                </div>
              </div>
            ))}
          </div>
        )}
      </div>

      {showForm && (
        <div className="fixed inset-0 z-40 flex items-start justify-center overflow-y-auto bg-black/50 p-4">
          <div className="w-full max-w-5xl rounded-2xl border border-slate-200 bg-white shadow-2xl dark:border-slate-700 dark:bg-dashboard-surface-dark">
            <div className="flex items-center justify-between border-b border-slate-200 px-6 py-4 dark:border-slate-700">
              <div>
                <h3 className="text-lg font-semibold text-slate-900 dark:text-white">{editingId ? t('admin.courses.form.editTitle') : t('admin.courses.form.newTitle')}</h3>
                <p className="text-sm text-slate-500 dark:text-slate-400">{t('admin.courses.subtitle')}</p>
              </div>
              <button onClick={closeForm} className="rounded-full p-2 text-slate-500 hover:bg-slate-100 dark:text-slate-300 dark:hover:bg-slate-800">
                <span className="material-symbols-outlined">close</span>
              </button>
            </div>

            <div className="max-h-[80vh] overflow-y-auto px-6 py-5 space-y-6">
              <div className="grid grid-cols-1 gap-4 md:grid-cols-2">
                <div className="space-y-2">
                  <label className="text-sm font-medium text-slate-700 dark:text-slate-200">{t('admin.courses.form.title')}</label>
                  <input
                    className="w-full rounded-lg border border-slate-200 bg-slate-50 px-3 py-2 text-sm focus:border-dashboard-primary focus:bg-white focus:outline-none dark:border-slate-700 dark:bg-slate-900"
                    value={form.title}
                    onChange={(e) => setForm({ ...form, title: e.target.value })}
                  />
                </div>
                <div className="space-y-2">
                  <label className="text-sm font-medium text-slate-700 dark:text-slate-200">{t('admin.courses.form.price')}</label>
                  <input
                    type="number"
                    min={0}
                    className="w-full rounded-lg border border-slate-200 bg-slate-50 px-3 py-2 text-sm focus:border-dashboard-primary focus:bg-white focus:outline-none dark:border-slate-700 dark:bg-slate-900"
                    value={form.price}
                    onChange={(e) => setForm({ ...form, price: Number(e.target.value) })}
                    disabled={form.isFree}
                  />
                </div>
                <div className="space-y-2">
                  <label className="text-sm font-medium text-slate-700 dark:text-slate-200">{t('admin.courses.form.lecturer')}</label>
                  <div className="space-y-2">
                    <input
                      className="w-full rounded-lg border border-slate-200 bg-slate-50 px-3 py-2 text-sm focus:border-dashboard-primary focus:bg-white focus:outline-none dark:border-slate-700 dark:bg-slate-900"
                      placeholder={t('admin.courses.form.lecturerSearchPlaceholder')}
                      value={lecturerSearch}
                      onChange={(e) => setLecturerSearch(e.target.value)}
                    />
                    <select
                      className="w-full rounded-lg border border-slate-200 bg-white px-3 py-2 text-sm dark:border-slate-700 dark:bg-slate-900"
                      value={form.lecturerId}
                      onChange={(e) => setForm({ ...form, lecturerId: e.target.value })}
                    >
                      <option value="">{t('admin.courses.form.lecturerSelectPlaceholder')}</option>
                      {form.lecturerId && !lecturers.find((l) => l.id === form.lecturerId) && (
                        <option value={form.lecturerId}>{t('admin.courses.form.selectedLecturerId', { id: form.lecturerId })}</option>
                      )}
                      {lecturers.map((l) => (
                        <option key={l.id} value={l.id}>
                          {l.fullName || l.email} ({l.email})
                        </option>
                      ))}
                    </select>
                    <div className="text-xs text-slate-500 dark:text-slate-400">
                      {lecturerLoading
                        ? t('admin.courses.form.lecturerLoading')
                        : lecturers.length === 0
                          ? t('admin.courses.form.lecturerEmpty')
                          : t('admin.courses.form.lecturerHint')}
                    </div>
                  </div>
                </div>
              </div>

              <div className="space-y-2">
                <label className="text-sm font-medium text-slate-700 dark:text-slate-200">{t('admin.courses.form.description')}</label>
                <textarea
                  className="w-full rounded-lg border border-slate-200 bg-slate-50 px-3 py-2 text-sm focus:border-dashboard-primary focus:bg-white focus:outline-none dark:border-slate-700 dark:bg-slate-900"
                  rows={3}
                  value={form.description || ''}
                  onChange={(e) => setForm({ ...form, description: e.target.value })}
                />
              </div>

              <div className="flex flex-wrap gap-4">
                <label className="inline-flex items-center gap-2 text-sm text-slate-700 dark:text-slate-200">
                  <input
                    type="checkbox"
                    checked={form.isFree}
                    onChange={(e) => setForm({ ...form, isFree: e.target.checked, price: e.target.checked ? 0 : form.price })}
                    className="h-4 w-4 rounded border-slate-300 text-dashboard-primary focus:ring-dashboard-primary"
                  />
                  {t('admin.courses.form.free')}
                </label>
                <label className="inline-flex items-center gap-2 text-sm text-slate-700 dark:text-slate-200">
                  <input
                    type="checkbox"
                    checked={form.isPublished}
                    onChange={(e) => setForm({ ...form, isPublished: e.target.checked })}
                    className="h-4 w-4 rounded border-slate-300 text-dashboard-primary focus:ring-dashboard-primary"
                  />
                  {t('admin.courses.form.published')}
                </label>
              </div>

              <div className="flex items-center justify-between">
                <h4 className="text-base font-semibold text-slate-900 dark:text-white">{t('admin.courses.form.curriculum')}</h4>
                <button
                  onClick={addSection}
                  className="inline-flex items-center gap-1 rounded-md border border-slate-200 px-3 py-1.5 text-sm text-slate-700 hover:bg-slate-100 dark:border-slate-700 dark:text-slate-200 dark:hover:bg-slate-800"
                >
                  <span className="material-symbols-outlined text-[18px]">add</span>
                  {t('admin.courses.form.addSection')}
                </button>
              </div>

              <div className="space-y-4">
                {form.sections.map((section, sIdx) => (
                  <div key={sIdx} className="rounded-xl border border-slate-200 bg-slate-50 p-4 dark:border-slate-700 dark:bg-slate-900/40">
                    <div className="flex flex-wrap items-center gap-3">
                      <input
                        className="flex-1 rounded-lg border border-slate-200 bg-white px-3 py-2 text-sm focus:border-dashboard-primary focus:outline-none dark:border-slate-700 dark:bg-slate-900"
                        value={section.title}
                        onChange={(e) => updateSection(sIdx, { title: e.target.value })}
                      />
                      <input
                        type="number"
                        min={1}
                        className="w-24 rounded-lg border border-slate-200 bg-white px-3 py-2 text-sm focus:border-dashboard-primary focus:outline-none dark:border-slate-700 dark:bg-slate-900"
                        value={section.orderIndex}
                        onChange={(e) => updateSection(sIdx, { orderIndex: Number(e.target.value) })}
                      />
                      <button
                        onClick={() => addLesson(sIdx)}
                        className="inline-flex items-center gap-1 rounded-md border border-slate-200 px-3 py-1.5 text-sm text-slate-700 hover:bg-slate-100 dark:border-slate-700 dark:text-slate-200 dark:hover:bg-slate-800"
                      >
                        <span className="material-symbols-outlined text-[18px]">add</span>
                        {t('admin.courses.form.addLesson')}
                      </button>
                    </div>

                    <div className="mt-3 space-y-3">
                      {section.lessons.map((lesson, lIdx) => {
                        const thumbKey = `${sIdx}-${lIdx}`;
                        const isVideoThumbUploading = videoThumbnailUploading[thumbKey];

                        return (
                          <div key={lIdx} className="rounded-lg border border-slate-200 bg-white p-3 dark:border-slate-700 dark:bg-slate-900">
                            <div className="grid grid-cols-1 gap-3 md:grid-cols-12 md:items-center">
                              <input
                                className="md:col-span-4 rounded-lg border border-slate-200 bg-white px-3 py-2 text-sm focus:border-dashboard-primary focus:outline-none dark:border-slate-700 dark:bg-slate-900"
                                value={lesson.title}
                                onChange={(e) => updateLesson(sIdx, lIdx, { title: e.target.value })}
                              />
                              <input
                                type="number"
                                min={0}
                                className="md:col-span-2 rounded-lg border border-slate-200 bg-white px-3 py-2 text-sm focus:border-dashboard-primary focus:outline-none dark:border-slate-700 dark:bg-slate-900"
                                value={lesson.duration}
                                onChange={(e) => updateLesson(sIdx, lIdx, { duration: Number(e.target.value) })}
                              />
                              <input
                                type="number"
                                min={1}
                                className="md:col-span-2 rounded-lg border border-slate-200 bg-white px-3 py-2 text-sm focus:border-dashboard-primary focus:outline-none dark:border-slate-700 dark:bg-slate-900"
                                value={lesson.orderIndex}
                                onChange={(e) => updateLesson(sIdx, lIdx, { orderIndex: Number(e.target.value) })}
                              />
                              <label className="md:col-span-2 inline-flex items-center gap-2 text-sm text-slate-700 dark:text-slate-200">
                                <input
                                  type="checkbox"
                                  checked={lesson.isPreview}
                                  onChange={(e) => updateLesson(sIdx, lIdx, { isPreview: e.target.checked })}
                                  className="h-4 w-4 rounded border-slate-300 text-dashboard-primary focus:ring-dashboard-primary"
                                />
                                {t('admin.courses.form.preview')}
                              </label>
                              <div className="md:col-span-2 flex items-center gap-2 text-xs text-slate-500 dark:text-slate-400">
                                {lesson.videoId ? (
                                  <span className="inline-flex items-center gap-1 rounded-full bg-green-100 px-2 py-1 text-green-700 dark:bg-green-900/30 dark:text-green-300">
                                    <span className="material-symbols-outlined text-[16px]">check_circle</span>
                                    {t('admin.courses.form.videoLinked')}
                                  </span>
                                ) : (
                                  <span className="inline-flex items-center gap-1 rounded-full bg-amber-100 px-2 py-1 text-amber-700 dark:bg-amber-900/30 dark:text-amber-300">
                                    <span className="material-symbols-outlined text-[16px]">cloud_upload</span>
                                    {t('admin.courses.form.uploadRequired')}
                                  </span>
                                )}
                              </div>
                            </div>

                            <div className="mt-3 space-y-1">
                              <div className="text-sm font-medium text-slate-700 dark:text-slate-200">{t('admin.courses.form.uploadVideo', { defaultValue: 'Upload video file' })}</div>
                              <div className="flex flex-wrap items-center gap-3">
                                <input
                                  type="file"
                                  accept="video/*"
                                  onChange={(e) => handleUpload(sIdx, lIdx, e.target.files?.[0])}
                                  className="text-sm text-slate-600 file:mr-3 file:rounded-md file:border-0 file:bg-dashboard-primary file:px-3 file:py-2 file:text-white file:cursor-pointer"
                                />
                                {lesson.playbackUrl && (
                                  <a href={lesson.playbackUrl} target="_blank" rel="noreferrer" className="text-sm text-dashboard-primary underline">
                                    {t('admin.courses.form.previewPlaylist')}
                                  </a>
                                )}
                              </div>
                            </div>

                            <div className="mt-3 space-y-1">
                              <div className="text-sm font-medium text-slate-700 dark:text-slate-200">{t('admin.courses.form.uploadThumbnail', { defaultValue: 'Upload thumbnail (image)' })}</div>
                              <div className="flex flex-wrap items-center gap-3">
                                <input
                                  type="file"
                                  accept="image/*"
                                  onChange={(e) => handleVideoThumbnailUpload(sIdx, lIdx, e.target.files?.[0])}
                                  className="text-sm text-slate-600 file:mr-3 file:rounded-md file:border-0 file:bg-dashboard-primary file:px-3 file:py-2 file:text-white file:cursor-pointer"
                                />
                                {isVideoThumbUploading && (
                                  <span className="text-xs text-slate-500">
                                    {t('admin.courses.form.thumbnailUploading', { defaultValue: 'Uploading thumbnail...' })}
                                  </span>
                                )}
                              </div>
                            </div>
                          </div>
                        );
                      })}
                    </div>
                  </div>
                ))}
              </div>
            </div>

            <div className="flex items-center justify-end gap-3 border-t border-slate-200 px-6 py-4 dark:border-slate-700">
              <button
                onClick={closeForm}
                className="rounded-lg border border-slate-200 px-4 py-2 text-sm font-medium text-slate-700 hover:bg-slate-100 dark:border-slate-700 dark:text-slate-200 dark:hover:bg-slate-800"
              >
                {t('common.cancel', { defaultValue: t('admin.courses.form.cancel') })}
              </button>
              <button
                onClick={handleSave}
                disabled={saving}
                className="inline-flex items-center gap-2 rounded-lg bg-dashboard-primary px-4 py-2 text-sm font-semibold text-white shadow-sm shadow-dashboard-primary/30 transition hover:bg-dashboard-primary-dark disabled:opacity-60"
              >
                {saving ? t('common.saving', { defaultValue: 'Saving...' }) : t('admin.courses.form.save')}
              </button>
            </div>
          </div>
        </div>
      )}
    </AdminLayout>
    
  );
};

export default CoursesPage;
