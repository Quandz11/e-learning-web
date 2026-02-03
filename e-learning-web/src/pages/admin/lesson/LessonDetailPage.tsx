import React, { useEffect, useState } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { useTranslation } from 'react-i18next';
import AdminLayout from '../../../components/admin/AdminLayout';
import { lessonApi, type LessonDto, type LessonPartDto } from '../../../services/lessonApi';
import LessonFormModal from './components/LessonFormModal'; // To edit lesson info
import SecureVideoPlayer from '../../../components/SecureVideoPlayer';

const LessonDetailPage: React.FC = () => {
    const { t } = useTranslation();
    const { id } = useParams<{ id: string }>();
    const navigate = useNavigate();
    const [lesson, setLesson] = useState<LessonDto | null>(null);
    const [loading, setLoading] = useState(true);
    const [_error, setError] = useState<string | null>(null);



    // Lesson Edit Modal
    const [showEditLesson, setShowEditLesson] = useState(false);

    useEffect(() => {
        if (id) {
            load(id);
        }
    }, [id]);

    const load = async (lessonId: string) => {
        try {
            setLoading(true);
            const data = await lessonApi.getById(lessonId);
            setLesson(data);
        } catch (err: any) {
            setError(err.message || t('admin.lessons.loadLessonError'));
        } finally {
            setLoading(false);
        }
    };

    const handleEditLessonSuccess = async () => {
        if (id) await load(id);
        setShowEditLesson(false);
    };



    const openAddPart = () => {
        navigate(`/admin/lessons/${id}/parts/new`);
    };

    const openEditPart = (part: LessonPartDto) => {
        navigate(`/admin/lessons/${id}/parts/${part.id}`);
    };

    const handleDeletePart = async (partId: string) => {
        if (!id || !confirm(t('admin.lessons.deletePartConfirm'))) return;
        try {
            await lessonApi.deletePart(id, partId);
            await load(id);
        } catch (err: any) {
            alert(err.message);
        }
    };

    if (loading) {
        return (
            <AdminLayout>
                <div className="flex h-96 items-center justify-center">
                    <div className="h-8 w-8 animate-spin rounded-full border-b-2 border-dashboard-primary"></div>
                </div>
            </AdminLayout>
        );
    }

    if (!lesson) {
        return (
            <AdminLayout>
                <div className="text-center">{t('admin.lessons.notFound')}</div>
            </AdminLayout>
        );
    }

    return (
        <AdminLayout>
            <div className="mb-6">
                <button
                    onClick={() => navigate('/admin/lessons')}
                    className="mb-4 inline-flex items-center gap-1 text-sm text-slate-500 hover:text-dashboard-primary dark:text-slate-400"
                >
                    <span className="material-symbols-outlined text-[20px]">arrow_back</span>
                    {t('admin.lessons.backToLessons')}
                </button>

                <div className="flex items-start justify-between">
                    <div>
                        <h1 className="text-2xl font-bold text-slate-900 dark:text-white">{lesson.title}</h1>
                        {lesson.description && <p className="mt-1 text-slate-500 dark:text-slate-400">{lesson.description}</p>}
                    </div>
                    <button
                        onClick={() => setShowEditLesson(true)}
                        className="rounded-lg border border-slate-200 px-3 py-1.5 text-sm font-medium text-slate-700 hover:bg-slate-100 dark:border-slate-700 dark:text-slate-200 dark:hover:bg-slate-800"
                    >
                        {t('admin.lessons.editDetails')}
                    </button>
                </div>
            </div>

            <div className="space-y-6">
                <div className="flex items-center justify-between">
                    <h2 className="text-lg font-semibold text-slate-900 dark:text-white">{t('admin.lessons.partsTitle')}</h2>
                    <button
                        onClick={openAddPart}
                        className="inline-flex items-center gap-2 rounded-lg bg-dashboard-primary px-4 py-2 text-white shadow-sm shadow-dashboard-primary/30 transition hover:bg-dashboard-primary-dark"
                    >
                        <span className="material-symbols-outlined text-[18px]">add</span>
                        {t('admin.lessons.addPart')}
                    </button>
                </div>

                {(!lesson.parts || lesson.parts.length === 0) ? (
                    <div className="rounded-xl border border-dashed border-slate-300 bg-slate-50 p-8 text-center text-slate-500 dark:border-slate-700 dark:bg-slate-800/50">
                        {t('admin.lessons.emptyParts')}
                    </div>
                ) : (
                    <div className="grid gap-4">
                        {lesson.parts.sort((a, b) => a.orderIndex - b.orderIndex).map((part) => (
                            <div key={part.id} className="flex flex-col gap-4 rounded-xl border border-slate-200 bg-white p-4 shadow-sm dark:border-slate-700 dark:bg-dashboard-surface-dark md:flex-row md:items-start">
                                {/* Preview Thumbnail or Icon */}
                                <div
                                    className="h-32 w-full flex-shrink-0 overflow-hidden rounded-lg bg-slate-100 md:w-48 dark:bg-slate-900 cursor-pointer"
                                    onClick={() => openEditPart(part)}
                                >
                                    {part.type === 'Video' && part.videoId ? (
                                        <SecureVideoPlayer
                                            videoId={part.videoId}
                                            className="h-full w-full object-cover pointer-events-none" // Disable interaction in preview list
                                        />
                                    ) : part.type === 'Document' ? (
                                        <div className="flex h-full w-full flex-col items-center justify-center text-slate-400">
                                            <span className="material-symbols-outlined text-4xl">description</span>
                                            <span className="text-xs mt-1">{t('admin.lessons.pdfDocument')}</span>
                                        </div>
                                    ) : (
                                        <div className="flex h-full w-full items-center justify-center text-slate-400">
                                            <span className="material-symbols-outlined text-4xl">extension</span>
                                        </div>
                                    )}
                                </div>

                                <div className="flex flex-1 flex-col gap-2">
                                    <div className="flex items-start justify-between">
                                        <div>
                                            <div className="flex items-center gap-2">
                                                <span className={`inline-flex items-center rounded-md px-2 py-0.5 text-xs font-medium ${part.type === 'Video' ? 'bg-purple-100 text-purple-700 dark:bg-purple-900/30 dark:text-purple-300' : 'bg-blue-100 text-blue-700 dark:bg-blue-900/30 dark:text-blue-300'
                                                    }`}>
                                                    {part.type}
                                                </span>
                                                {part.isPreview && (
                                                    <span className="inline-flex items-center rounded-md bg-green-100 px-2 py-0.5 text-xs font-medium text-green-700 dark:bg-green-900/30 dark:text-green-300">
                                                        {t('admin.lessons.preview')}
                                                    </span>
                                                )}
                                                <span className="text-xs text-slate-500">{t('admin.lessons.orderLabel', { order: part.orderIndex })}</span>
                                            </div>
                                            <h3
                                                className="mt-1 text-base font-semibold text-slate-900 dark:text-white cursor-pointer hover:text-primary transition-colors"
                                                onClick={() => openEditPart(part)}
                                            >
                                                {part.title}
                                            </h3>
                                        </div>
                                        <div className="flex items-center gap-1">
                                            <button
                                                onClick={() => openEditPart(part)}
                                                className="rounded p-1.5 text-slate-500 hover:bg-slate-100 hover:text-dashboard-primary dark:text-slate-400 dark:hover:bg-slate-800"
                                            >
                                                <span className="material-symbols-outlined text-[20px]">edit</span>
                                            </button>
                                            <button
                                                onClick={() => handleDeletePart(part.id)}
                                                className="rounded p-1.5 text-slate-500 hover:bg-red-50 hover:text-red-600 dark:text-slate-400 dark:hover:bg-red-900/20 dark:hover:text-red-300"
                                            >
                                                <span className="material-symbols-outlined text-[20px]">delete</span>
                                            </button>
                                        </div>
                                    </div>

                                    {part.type === 'Document' && part.documentFileName && (
                                        <div className="text-sm text-slate-600 dark:text-slate-400 flex items-center gap-1">
                                            <span className="material-symbols-outlined text-[16px]">attach_file</span>
                                            {part.documentFileName}
                                        </div>
                                    )}
                                </div>
                            </div>
                        ))}
                    </div>
                )}
            </div>



            <LessonFormModal
                isOpen={showEditLesson}
                onClose={() => setShowEditLesson(false)}
                onSuccess={handleEditLessonSuccess}
                lessonId={lesson.id}
                initialData={lesson}
            />
        </AdminLayout>
    );
};

export default LessonDetailPage;
