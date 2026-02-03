import React, { useEffect, useState } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { useTranslation } from 'react-i18next';
import AdminLayout from '../../../components/admin/AdminLayout';
import { lessonApi, type LessonDto, type LessonPartDto, type CreateLessonPartRequest } from '../../../services/lessonApi';
import { courseApi } from '../../../services/courseApi';
import { documentApi } from '../../../services/documentApi';
import SecureVideoPlayer from '../../../components/SecureVideoPlayer';
import PdfViewer from '../../../components/PdfViewer';

const LessonPartDetailPage: React.FC = () => {
    const { t } = useTranslation();
    const { lessonId, partId } = useParams<{ lessonId: string; partId: string }>();
    const navigate = useNavigate();

    const [lesson, setLesson] = useState<LessonDto | null>(null);
    const [part, setPart] = useState<LessonPartDto | null>(null);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState<string | null>(null);
    const [saving, setSaving] = useState(false);
    const [uploading, setUploading] = useState(false);

    // Form State
    const [title, setTitle] = useState('');
    const [type, setType] = useState('Video');
    const [isPreview, setIsPreview] = useState(false);
    const [videoId, setVideoId] = useState<string | null>(null);
    const [documentId, setDocumentId] = useState<string | null>(null);
    const [documentUrl, setDocumentUrl] = useState<string | null>(null);
    const [documentFileName, setDocumentFileName] = useState<string | null>(null);
    const [orderIndex, setOrderIndex] = useState(0);
    const [content, setContent] = useState('');

    useEffect(() => {
        if (lessonId) {
            loadData(lessonId);
        }
    }, [lessonId, partId]);

    const loadData = async (lId: string) => {
        try {
            setLoading(true);
            const lessonData = await lessonApi.getById(lId);
            setLesson(lessonData);

            if (partId && lessonData.parts) {
                const foundPart = lessonData.parts.find(p => p.id === partId);
                if (foundPart) {
                    setPart(foundPart);
                    setTitle(foundPart.title);
                    setType(foundPart.type);
                    setIsPreview(foundPart.isPreview);
                    setVideoId(foundPart.videoId || null);
                    setDocumentId(foundPart.documentId || null);
                    // documentUrl might be needed if we want to preview it, but the DTO might not have it populated for Admin unless I fixed CourseService? 
                    // Actually LessonService was fixed, but this is Admin Lesson Detail. Admin usually uses LessonService for lessons.
                    // Wait, LessonDetailPage uses lessonApi.getById. Use 'LessonService' on backend.
                    // If LessonService.GetByIdAsync was fixed (it was), then `documentUrl` should be there.
                    setDocumentUrl(foundPart.documentUrl || null);
                    setDocumentFileName(foundPart.documentFileName || null);
                    setOrderIndex(foundPart.orderIndex);
                    setContent(foundPart.content || '');
                } else {
                    setError(t('admin.lessons.notFound'));
                }
            } else {
                // Determine next order index
                const maxOrder = lessonData.parts?.reduce((max, p) => Math.max(max, p.orderIndex), -1) ?? -1;
                setOrderIndex(maxOrder + 1);
            }
        } catch (err: any) {
            setError(err.message || t('admin.lessons.loadError'));
        } finally {
            setLoading(false);
        }
    };

    const handleVideoUpload = async (e: React.ChangeEvent<HTMLInputElement>) => {
        const file = e.target.files?.[0];
        if (!file) return;

        try {
            setUploading(true);
            const res = await courseApi.uploadVideo(file, title || 'New Lesson Video');
            setVideoId(res.videoId);
        } catch (err: any) {
            alert(err.message || t('admin.lessons.part.videoUploadError'));
        } finally {
            setUploading(false);
        }
    };

    const handleDocUpload = async (e: React.ChangeEvent<HTMLInputElement>) => {
        const file = e.target.files?.[0];
        if (!file) return;

        try {
            setUploading(true);
            const res = await documentApi.uploadPdf(file);
            setDocumentId(res.documentId);
            setDocumentFileName(file.name);
            // We won't have the URL immediately unless we refetch or the upload response returns it (it usually returns ID).
            // But we can assume it will be available after save. For now, maybe we can't preview immediately without URL.
        } catch (err: any) {
            alert(err.message || t('admin.lessons.part.docUploadError'));
        } finally {
            setUploading(false);
        }
    };

    const handleSave = async () => {
        if (!lessonId) return;
        if (!title.trim()) {
            alert(t('admin.lessons.part.titleRequired'));
            return;
        }

        const payload: CreateLessonPartRequest = {
            title,
            type,
            orderIndex,
            isPreview,
            videoId: videoId || undefined,
            documentId: documentId || undefined,
            content
        };

        try {
            setSaving(true);
            if (partId) {
                await lessonApi.updatePart(lessonId, partId, payload);
            } else {
                await lessonApi.addPart(lessonId, payload);
            }
            navigate(`/admin/lessons/${lessonId}`);
        } catch (err: any) {
            alert(err.message || t('admin.lessons.part.saveError'));
        } finally {
            setSaving(false);
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
        return <AdminLayout><div>{t('admin.lessons.notFound')}</div></AdminLayout>;
    }

    return (
        <AdminLayout>
            <div className="mx-auto max-w-5xl">
                {/* Header */}
                <div className="mb-6">
                    <button
                        onClick={() => navigate(`/admin/lessons/${lessonId}`)}
                        className="mb-4 inline-flex items-center gap-1 text-sm text-slate-500 hover:text-dashboard-primary dark:text-slate-400"
                    >
                        <span className="material-symbols-outlined text-[20px]">arrow_back</span>
                        {t('admin.lessons.part.backToLesson', { title: lesson.title })}
                    </button>

                    <div className="flex items-center justify-between">
                        <h1 className="text-2xl font-bold text-slate-900 dark:text-white">
                            {partId ? `${t('admin.lessons.part.editTitle')}: ${part?.title}` : t('admin.lessons.part.addTitle')}
                        </h1>
                        <button
                            onClick={handleSave}
                            disabled={saving || uploading}
                            className="inline-flex items-center gap-2 rounded-lg bg-dashboard-primary px-6 py-2.5 text-sm font-semibold text-white shadow-sm shadow-dashboard-primary/30 transition hover:bg-dashboard-primary-dark disabled:opacity-60"
                        >

                            {saving ? t('common.saving') : t('admin.lessons.part.saveChanges')}
                        </button>
                    </div>
                </div>

                <div className="grid grid-cols-1 gap-8 lg:grid-cols-3">
                    {/* Left Column: Form */}
                    <div className="lg:col-span-1 space-y-6">
                        <div className="rounded-xl border border-slate-200 bg-white p-6 shadow-sm dark:border-slate-700 dark:bg-dashboard-surface-dark space-y-4">
                            <h3 className="font-semibold text-slate-900 dark:text-white mb-4">{t('admin.lessons.part.detailsTitle')}</h3>

                            <div className="space-y-2">
                                <label className="text-sm font-medium text-slate-700 dark:text-slate-200">{t('admin.lessons.part.title')}</label>
                                <input
                                    className="w-full rounded-lg border border-slate-200 bg-slate-50 px-3 py-2 text-sm focus:border-dashboard-primary focus:bg-white focus:outline-none dark:border-slate-700 dark:bg-slate-900"
                                    value={title}
                                    onChange={(e) => setTitle(e.target.value)}
                                    placeholder={t('admin.lessons.part.titlePlaceholder')}
                                />
                            </div>

                            <div className="space-y-2">
                                <label className="text-sm font-medium text-slate-700 dark:text-slate-200">{t('admin.lessons.part.type')}</label>
                                <select
                                    className="w-full rounded-lg border border-slate-200 bg-slate-50 px-3 py-2 text-sm focus:border-dashboard-primary focus:bg-white focus:outline-none dark:border-slate-700 dark:bg-slate-900"
                                    value={type}
                                    onChange={(e) => setType(e.target.value)}
                                >
                                    <option value="Video">Video</option>
                                    <option value="Document">Document</option>
                                </select>
                            </div>

                            <div className="space-y-2">
                                <label className="text-sm font-medium text-slate-700 dark:text-slate-200">{t('admin.lessons.part.order')}</label>
                                <input
                                    type="number"
                                    className="w-full rounded-lg border border-slate-200 bg-slate-50 px-3 py-2 text-sm focus:border-dashboard-primary dark:border-slate-700 dark:bg-slate-900"
                                    value={orderIndex}
                                    onChange={(e) => setOrderIndex(Number(e.target.value))}
                                />
                            </div>

                            <div className="flex items-center gap-3 pt-2">
                                <input
                                    type="checkbox"
                                    id="isPreview"
                                    checked={isPreview}
                                    onChange={(e) => setIsPreview(e.target.checked)}
                                    className="h-4 w-4 rounded border-slate-300 text-dashboard-primary focus:ring-dashboard-primary"
                                />
                                <label htmlFor="isPreview" className="text-sm text-slate-700 dark:text-slate-200">{t('admin.lessons.part.allowPreview')}</label>
                            </div>
                        </div>

                        <div className="rounded-xl border border-slate-200 bg-white p-6 shadow-sm dark:border-slate-700 dark:bg-dashboard-surface-dark space-y-4">
                            <h3 className="font-semibold text-slate-900 dark:text-white mb-4">{t('admin.lessons.part.contentSourceTitle')}</h3>

                            {type === 'Video' && (
                                <div className="space-y-3">
                                    <label className="text-sm font-medium text-slate-700 dark:text-slate-200">{t('admin.lessons.part.uploadVideoLabel')}</label>
                                    <input
                                        type="file"
                                        accept="video/*"
                                        onChange={handleVideoUpload}
                                        disabled={uploading}
                                        className="w-full text-sm text-slate-600 file:mr-3 file:rounded-md file:border-0 file:bg-dashboard-primary file:px-3 file:py-2 file:text-white file:cursor-pointer disabled:opacity-50"
                                    />
                                    {uploading && <p className="text-xs text-blue-500">{t('admin.lessons.part.uploadingVideo')}</p>}
                                    {videoId && <p className="text-xs text-green-600">Video ID: {videoId}</p>}
                                </div>
                            )}

                            {type === 'Document' && (
                                <div className="space-y-3">
                                    <label className="text-sm font-medium text-slate-700 dark:text-slate-200">{t('admin.lessons.part.uploadPdfLabel')}</label>
                                    <input
                                        type="file"
                                        accept=".pdf,application/pdf"
                                        onChange={handleDocUpload}
                                        disabled={uploading}
                                        className="w-full text-sm text-slate-600 file:mr-3 file:rounded-md file:border-0 file:bg-dashboard-primary file:px-3 file:py-2 file:text-white file:cursor-pointer disabled:opacity-50"
                                    />
                                    {uploading && <p className="text-xs text-blue-500">{t('admin.lessons.part.uploadingDoc')}</p>}
                                    {(documentId || documentFileName) && <p className="text-xs text-green-600">{t('admin.lessons.part.docUploaded', { name: documentFileName || documentId })}</p>}
                                </div>
                            )}
                        </div>
                    </div>

                    {/* Right Column: Preview */}
                    <div className="lg:col-span-2">
                        <div className="sticky top-6 rounded-xl border border-slate-200 bg-white p-6 shadow-sm dark:border-slate-700 dark:bg-dashboard-surface-dark h-fit">
                            <h3 className="font-semibold text-slate-900 dark:text-white mb-4">{t('admin.lessons.part.previewTitle')}</h3>
                            <div className="overflow-hidden rounded-lg bg-slate-900 border border-slate-800 relative w-full aspect-video flex items-center justify-center">
                                {type === 'Video' ? (
                                    videoId ? (
                                        <SecureVideoPlayer
                                            videoId={videoId}
                                            className="absolute inset-0 w-full h-full object-cover"
                                            controls
                                        />
                                    ) : (
                                        <div className="text-slate-500 flex flex-col items-center">
                                            <span className="material-symbols-outlined text-4xl mb-2">movie</span>
                                            <span>{t('admin.lessons.part.noVideoSelected')}</span>
                                        </div>
                                    )
                                ) : (
                                    documentUrl ? (
                                        <div className="absolute inset-0 w-full h-full bg-white">
                                            <PdfViewer documentUrl={documentUrl} />
                                        </div>
                                    ) : (
                                        <div className="text-slate-500 flex flex-col items-center">
                                            <span className="material-symbols-outlined text-4xl mb-2">description</span>
                                            <span>{t('admin.lessons.part.noDocumentAvailable')}</span>
                                            {documentId && <span className="text-xs mt-2 text-slate-400">ID: {documentId} (Save to generate URL)</span>}
                                        </div>
                                    )
                                )}
                            </div>
                            <p className="mt-4 text-sm text-slate-500">
                                {t('admin.lessons.part.previewNote')}
                                {type === 'Document' && !documentUrl && documentId && ` (${t('admin.lessons.part.previewNoteDoc')})`}
                            </p>
                        </div>
                    </div>
                </div>
            </div>
        </AdminLayout>
    );
};

export default LessonPartDetailPage;
