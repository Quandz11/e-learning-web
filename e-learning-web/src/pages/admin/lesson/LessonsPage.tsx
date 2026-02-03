import React, { useEffect, useState } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { useTranslation } from 'react-i18next';
import AdminLayout from '../../../components/admin/AdminLayout';
import { lessonApi, type LessonDto } from '../../../services/lessonApi';
import { format } from 'date-fns';
import LessonFormModal from './components/LessonFormModal';

const LessonsPage: React.FC = () => {
    const { t } = useTranslation();
    const navigate = useNavigate();
    const [lessons, setLessons] = useState<LessonDto[]>([]);
    const [loading, setLoading] = useState(false);
    const [error, setError] = useState<string | null>(null);

    // Modal State
    const [showForm, setShowForm] = useState(false);
    const [editingId, setEditingId] = useState<string | null>(null);
    const [selectedLesson, setSelectedLesson] = useState<LessonDto | null>(null);

    useEffect(() => {
        load();
    }, []);

    const load = async () => {
        try {
            setLoading(true);
            const data = await lessonApi.getAll();
            setLessons(data);
        } catch (err: any) {
            setError(err.message || t('admin.lessons.loadError'));
        } finally {
            setLoading(false);
        }
    };

    const openCreate = () => {
        setEditingId(null);
        setSelectedLesson(null);
        setShowForm(true);
    };

    const openEdit = (lesson: LessonDto) => {
        setEditingId(lesson.id);
        setSelectedLesson(lesson);
        setShowForm(true);
    };

    const handleManageContent = (id: string) => {
        navigate(`/admin/lessons/${id}`);
    };

    const handleDelete = async (id: string) => {
        if (!confirm(t('admin.lessons.deleteConfirm'))) return;
        try {
            await lessonApi.delete(id);
            await load();
        } catch (err: any) {
            setError(err.message || t('admin.lessons.deleteError'));
        }
    };

    const handleSuccess = async (lessonId: string) => {
        await load();
        if (!editingId) {
            // If creating new, optionally redirect to manage content immediately
            // For now, just close modal and let user choose
            navigate(`/admin/lessons/${lessonId}`);
        } else {
            setShowForm(false);
        }
    };

    return (
        <AdminLayout>
            <div className="mb-6 flex items-center justify-between">
                <div>
                    <h1 className="text-2xl font-bold text-slate-900 dark:text-white">{t('admin.lessons.title')}</h1>
                    <p className="text-sm text-slate-500 dark:text-slate-400">{t('admin.lessons.subtitle')}</p>
                </div>
                <button
                    onClick={openCreate}
                    className="inline-flex items-center gap-2 rounded-lg bg-dashboard-primary px-4 py-2 text-white shadow-sm shadow-dashboard-primary/30 transition hover:bg-dashboard-primary-dark"
                >
                    <span className="material-symbols-outlined text-[18px]">add</span>
                    {t('admin.lessons.new')}
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
                ) : lessons.length === 0 ? (
                    <div className="rounded-2xl border border-dashed border-slate-300 bg-white/80 p-10 text-center text-slate-600 dark:border-slate-700 dark:bg-slate-900/70 dark:text-slate-300">
                        <p className="text-base font-semibold">{t('admin.lessons.emptyTitle')}</p>
                        <p className="mt-1 text-sm text-slate-500 dark:text-slate-400">{t('admin.lessons.emptyDesc')}</p>
                    </div>
                ) : (
                    <div className="grid gap-5 md:grid-cols-2 xl:grid-cols-3 2xl:grid-cols-4">
                        {lessons.map((lesson) => (
                            <div
                                key={lesson.id}
                                className="group flex h-full flex-col overflow-hidden rounded-2xl border border-white/60 bg-white/90 shadow-sm shadow-slate-200 backdrop-blur transition hover:-translate-y-1 hover:shadow-xl dark:border-slate-800 dark:bg-dashboard-surface-dark"
                            >
                                <div onClick={() => handleManageContent(lesson.id)} className="relative h-44 overflow-hidden block cursor-pointer">
                                    {lesson.thumbnailUrl ? (
                                        <img
                                            src={lesson.thumbnailUrl}
                                            alt={lesson.title}
                                            className="h-full w-full object-cover transition duration-500 group-hover:scale-105"
                                        />
                                    ) : (
                                        <div className="h-full w-full bg-gradient-to-br from-indigo-500 via-purple-500 to-pink-500 flex items-center justify-between px-4 text-white">
                                            <div className="flex flex-col gap-2">
                                                <span className="text-xs uppercase tracking-[0.25em] text-white/80">{t('admin.lessons.badge')}</span>
                                                <p className="text-lg font-bold text-slate-900 line-clamp-2 transition group-hover:text-indigo-200 dark:text-white">{lesson.title}</p>
                                            </div>
                                            <span className="material-symbols-outlined text-4xl text-white/70">play_lesson</span>
                                        </div>
                                    )}
                                    <div className="absolute right-4 top-4 flex items-center gap-2">
                                        <button
                                            onClick={(e) => {
                                                e.stopPropagation();
                                                openEdit(lesson);
                                            }}
                                            className="rounded-full bg-white/90 p-2 text-slate-500 shadow-sm backdrop-blur transition hover:bg-white hover:text-indigo-600 dark:bg-slate-900/80 dark:text-slate-400 dark:hover:bg-slate-900 dark:hover:text-indigo-400"
                                            title={t('admin.lessons.editInfo')}
                                        >
                                            <span className="material-symbols-outlined text-[18px]">edit</span>
                                        </button>
                                        <button
                                            onClick={(e) => {
                                                e.stopPropagation();
                                                handleDelete(lesson.id);
                                            }}
                                            className="rounded-full bg-white/90 p-2 text-red-500 shadow-sm backdrop-blur transition hover:bg-white hover:text-red-600 dark:bg-slate-900/80 dark:text-red-400 dark:hover:bg-slate-900 dark:hover:text-red-300"
                                            title={t('common.delete', { defaultValue: 'Delete' })}
                                        >
                                            <span className="material-symbols-outlined text-[18px]">delete</span>
                                        </button>
                                    </div>
                                    <div className="absolute left-4 top-4 flex items-center gap-2 rounded-full bg-white/90 px-3 py-1 text-xs font-semibold text-slate-700 shadow-sm backdrop-blur dark:bg-slate-900/80 dark:text-slate-200">
                                        <span className="material-symbols-outlined text-sm">segment</span>
                                        <span>{t('admin.lessons.partsCount', { count: lesson.parts?.length || 0 })}</span>
                                    </div>
                                </div>

                                <div className="flex flex-1 flex-col gap-3 p-5">
                                    <div className="space-y-1">
                                        <h4
                                            className="text-lg font-bold text-slate-900 line-clamp-2 transition group-hover:text-indigo-600 dark:text-white dark:group-hover:text-indigo-400 cursor-pointer"
                                            onClick={() => handleManageContent(lesson.id)}
                                        >
                                            {lesson.title}
                                        </h4>
                                    </div>

                                    <p className="line-clamp-2 text-sm text-slate-600 dark:text-slate-300">{lesson.description || t('admin.lessons.form.descriptionPlaceholder')}</p>

                                    <div className="mt-auto flex items-center justify-between border-t border-slate-100 pt-4 dark:border-slate-800">
                                        <div className="flex flex-col">
                                            <span className="text-xs text-slate-500 dark:text-slate-400">{t('admin.lessons.created')}</span>
                                            <span className="text-sm font-semibold text-slate-800 dark:text-slate-200">{format(new Date(lesson.createdAt), 'MMM d, yyyy')}</span>
                                        </div>
                                        <button
                                            className="inline-flex items-center gap-1 rounded-lg bg-indigo-50 px-3 py-1.5 text-sm font-medium text-indigo-700 transition hover:bg-indigo-100 dark:bg-indigo-900/30 dark:text-indigo-300 dark:hover:bg-indigo-900/50"
                                            onClick={() => handleManageContent(lesson.id)}
                                        >
                                            {t('admin.lessons.manageContent')}
                                            <span className="material-symbols-outlined text-[18px]">arrow_forward</span>
                                        </button>
                                    </div>
                                </div>
                            </div>
                        ))}
                    </div>
                )}
            </div>

            <LessonFormModal
                isOpen={showForm}
                onClose={() => setShowForm(false)}
                onSuccess={handleSuccess}
                lessonId={editingId}
                initialData={selectedLesson}
            />
        </AdminLayout>
    );
};

export default LessonsPage;
