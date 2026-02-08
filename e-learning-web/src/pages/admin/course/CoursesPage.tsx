import React, { useEffect, useState } from 'react';
import { Link } from 'react-router-dom';
import { useTranslation } from 'react-i18next';
import AdminLayout from '../../../components/admin/AdminLayout';
import { courseApi } from '../../../services/courseApi';
import type { CourseResponse } from '../../../services/courseApi';
import { format } from 'date-fns';
import CourseFormModal from './components/CourseFormModal';
import ConfirmModal from '../../../components/ui/Modal/ConfirmModal';
import { useToast } from '../../../contexts/ToastContext';

const CoursesPage: React.FC = () => {
  const { t } = useTranslation();
  const { showToast } = useToast();
  // const navigate = useNavigate(); // Hook is unused if we link directly, but checking usage
  const [courses, setCourses] = useState<CourseResponse[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  // Modal State
  const [showForm, setShowForm] = useState(false);
  const [editingId, setEditingId] = useState<string | null>(null);
  const [selectedCourse, setSelectedCourse] = useState<CourseResponse | null>(null);

  // Delete Modal State
  const [showDeleteModal, setShowDeleteModal] = useState(false);
  const [deletingId, setDeletingId] = useState<string | null>(null);
  const [isDeleting, setIsDeleting] = useState(false);

  useEffect(() => {
    load();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

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

  const openCreate = () => {
    setEditingId(null);
    setSelectedCourse(null);
    setShowForm(true);
  };

  const openEdit = (course: CourseResponse) => {
    setEditingId(course.id);
    setSelectedCourse(course);
    setShowForm(true);
  };

  const handleDeleteClick = (id: string) => {
    setDeletingId(id);
    setShowDeleteModal(true);
  };

  const handleConfirmDelete = async () => {
    if (!deletingId) return;

    setIsDeleting(true);
    try {
      await courseApi.remove(deletingId);
      showToast(t('notifications.success.deleteSuccess'), 'success');
      setShowDeleteModal(false);
      await load();
    } catch (err: any) {
      showToast(err.message || t('admin.courses.form.errors.deleteFailed'), 'error');
    } finally {
      setIsDeleting(false);
    }
  };

  const handleSuccess = async () => {
    await load();
    setShowForm(false);
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
                <Link to={`/admin/courses/${course.id}`} className="relative aspect-square overflow-hidden block">
                  {course.thumbnailUrl ? (
                    <img
                      src={course.thumbnailUrl}
                      alt={course.title}
                      className="h-full w-full object-cover transition duration-500 group-hover:scale-105"
                    />
                  ) : (
                    <div className="h-full w-full bg-gradient-to-br from-sky-500 via-emerald-500 to-cyan-500 flex items-center justify-between px-4 text-white">
                      <div className="flex flex-col gap-2">
                        <span className="text-xs uppercase tracking-[0.25em] text-white/80">Khóa học</span>
                        <p className="text-lg font-bold text-slate-900 line-clamp-2 transition group-hover:text-sky-700 dark:text-white dark:group-hover:text-sky-300">{course.title}</p>
                      </div>
                      <span className="material-symbols-outlined text-4xl text-white/70">play_circle</span>
                    </div>
                  )}
                  <div className="absolute left-4 top-4 flex items-center gap-2 rounded-full bg-white/90 px-3 py-1 text-xs font-semibold text-slate-700 shadow-sm backdrop-blur dark:bg-slate-900/80 dark:text-slate-200">
                    <span className="material-symbols-outlined text-sm">category</span>
                    <span>{course.lessons?.length || 0} Lessons</span>
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
                      <span className="text-base font-bold text-slate-900 dark:text-white">{course.isFree ? t('admin.courses.status.free') : `${course.price.toLocaleString('vi-VN')} VND`}</span>
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
                      onClick={() => handleDeleteClick(course.id)}
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

      <CourseFormModal
        isOpen={showForm}
        onClose={() => setShowForm(false)}
        onSuccess={handleSuccess}
        courseId={editingId}
        initialData={selectedCourse}
      />

      <ConfirmModal
        isOpen={showDeleteModal}
        onClose={() => setShowDeleteModal(false)}
        onConfirm={handleConfirmDelete}
        title={t('modal.confirmDelete.title')}
        message={t('modal.confirmDelete.message', { item: t('modal.confirmDelete.course') })}
        confirmText={t('modal.delete')}
        cancelText={t('modal.cancel')}
        variant="danger"
        isLoading={isDeleting}
      />
    </AdminLayout>
  );
};

export default CoursesPage;


