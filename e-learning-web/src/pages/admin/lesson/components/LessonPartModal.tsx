import React, { useState, useEffect } from 'react';
import { useTranslation } from 'react-i18next';
import { courseApi } from '../../../../services/courseApi';
import { documentApi } from '../../../../services/documentApi';
import { lessonApi, type CreateLessonPartRequest, type LessonPartDto } from '../../../../services/lessonApi';
import SecureVideoPlayer from '../../../../components/SecureVideoPlayer';

interface LessonPartModalProps {
    isOpen: boolean;
    onClose: () => void;
    onSuccess: () => void;
    lessonId: string;
    partId?: string | null;
    initialData?: LessonPartDto | null;
    currentOrderIndex?: number;
}

const LessonPartModal: React.FC<LessonPartModalProps> = ({
    isOpen, onClose, onSuccess, lessonId, partId, initialData, currentOrderIndex = 0
}) => {
    const { t } = useTranslation(); // Reuse generic translations or add new ones
    const [loading, setLoading] = useState(false);
    const [uploading, setUploading] = useState(false);
    const [error, setError] = useState<string | null>(null);

    const [title, setTitle] = useState('');
    const [type, setType] = useState('Video'); // Video, Document
    const [isPreview, setIsPreview] = useState(false);
    const [videoId, setVideoId] = useState<string | null>(null);
    const [documentId, setDocumentId] = useState<string | null>(null);
    const [documentFileName, setDocumentFileName] = useState<string | null>(null);
    const [orderIndex, setOrderIndex] = useState(currentOrderIndex);
    const [content, setContent] = useState('');

    useEffect(() => {
        if (isOpen) {
            setError(null);
            if (initialData) {
                setTitle(initialData.title);
                setType(initialData.type);
                setIsPreview(initialData.isPreview);
                setVideoId(initialData.videoId || null);
                setDocumentId(initialData.documentId || null);
                setDocumentFileName(initialData.documentFileName || null);
                setOrderIndex(initialData.orderIndex);
                setContent(initialData.content || '');
            } else {
                setTitle('');
                setType('Video');
                setIsPreview(false);
                setVideoId(null);
                setDocumentId(null);
                setOrderIndex(currentOrderIndex);
                setContent('');
            }
        }
    }, [isOpen, initialData, currentOrderIndex]);

    const handleVideoUpload = async (e: React.ChangeEvent<HTMLInputElement>) => {
        const file = e.target.files?.[0];
        if (!file) return;

        try {
            setUploading(true);
            setError(null);
            // We use lesson title if available, or just "Lesson Part"
            const res = await courseApi.uploadVideo(file, title || 'New Lesson Video');
            setVideoId(res.videoId);
            // Optionally sync duration later
        } catch (err: any) {
            setError(err.message || t('admin.lessons.part.videoUploadError'));
        } finally {
            setUploading(false);
        }
    };

    const handleDocUpload = async (e: React.ChangeEvent<HTMLInputElement>) => {
        const file = e.target.files?.[0];
        if (!file) return;

        try {
            setUploading(true);
            setError(null);
            const res = await documentApi.uploadPdf(file);
            setDocumentId(res.documentId);
            setDocumentFileName(file.name);
        } catch (err: any) {
            setError(err.message || t('admin.lessons.part.docUploadError'));
        } finally {
            setUploading(false);
        }
    };

    const handleSave = async () => {
        if (!title.trim()) {
            setError(t('admin.lessons.part.titleRequired'));
            return;
        }

        if (type === 'Video' && !videoId && !initialData?.videoId) {
            // If editing and same video, we might not have changed it, but state should match
            // initialData sets state. So videoId should be set.
            setError(t('admin.lessons.part.videoRequired'));
            return;
        }
        if (type === 'Document' && !documentId) {
            setError(t('admin.lessons.part.docRequired'));
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
            setLoading(true);
            setError(null);
            if (partId) {
                await lessonApi.updatePart(lessonId, partId, payload);
            } else {
                await lessonApi.addPart(lessonId, payload);
            }
            onSuccess();
            onClose();
        } catch (err: any) {
            setError(err.message || t('admin.lessons.part.saveError'));
        } finally {
            setLoading(false);
        }
    };

    if (!isOpen) return null;

    return (
        <div className="fixed inset-0 z-[100] flex items-center justify-center bg-black/50 p-4">
            <div className="w-full max-w-2xl rounded-2xl border border-slate-200 bg-white shadow-2xl dark:border-slate-700 dark:bg-dashboard-surface-dark max-h-[90vh] overflow-y-auto">
                <div className="flex items-center justify-between border-b border-slate-200 px-6 py-4 dark:border-slate-700">
                    <h3 className="text-lg font-semibold text-slate-900 dark:text-white">
                        {partId ? t('admin.lessons.part.editTitle') : t('admin.lessons.part.addTitle')}
                    </h3>
                    <button onClick={onClose} className="rounded-full p-2 text-slate-500 hover:bg-slate-100 dark:text-slate-300 dark:hover:bg-slate-800">
                        <span className="material-symbols-outlined">close</span>
                    </button>
                </div>

                <div className="p-6 space-y-4">
                    {error && (
                        <div className="rounded-lg border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-700 dark:border-red-900/50 dark:bg-red-900/20 dark:text-red-200">
                            {error}
                        </div>
                    )}

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
                            {/* <option value="Quiz">Quiz</option> Future */}
                        </select>
                    </div>

                    <div className="flex items-center gap-4">
                        <label className="inline-flex items-center gap-2 text-sm text-slate-700 dark:text-slate-200">
                            <input
                                type="checkbox"
                                checked={isPreview}
                                onChange={(e) => setIsPreview(e.target.checked)}
                                className="h-4 w-4 rounded border-slate-300 text-dashboard-primary focus:ring-dashboard-primary"
                            />
                            {t('admin.lessons.part.allowPreview')}
                        </label>
                        <div className="flex items-center gap-2">
                            <label className="text-sm font-medium text-slate-700 dark:text-slate-200">{t('admin.lessons.part.order')}</label>
                            <input
                                type="number"
                                className="w-16 rounded-lg border border-slate-200 bg-slate-50 px-2 py-1 text-sm focus:border-dashboard-primary"
                                value={orderIndex}
                                onChange={(e) => setOrderIndex(Number(e.target.value))}
                            />
                        </div>
                    </div>

                    {type === 'Video' && (
                        <div className="space-y-2 rounded-lg border border-slate-100 bg-slate-50 p-4 dark:border-slate-700 dark:bg-slate-800/50">
                            <label className="text-sm font-medium text-slate-700 dark:text-slate-200">{t('admin.lessons.part.videoContent')}</label>
                            <div className="flex flex-col gap-3">
                                <input
                                    type="file"
                                    accept="video/*"
                                    onChange={handleVideoUpload}
                                    disabled={uploading}
                                    className="text-sm text-slate-600 file:mr-3 file:rounded-md file:border-0 file:bg-dashboard-primary file:px-3 file:py-2 file:text-white file:cursor-pointer disabled:opacity-50"
                                />
                                {uploading && <div className="text-xs text-blue-600">{t('admin.lessons.part.uploadingVideo')}</div>}


                                {videoId && (
                                    <div className="mt-2 w-full aspect-video rounded-lg overflow-hidden border border-slate-200 dark:border-slate-700 bg-black">
                                        <SecureVideoPlayer
                                            videoId={videoId}
                                            className="w-full h-full object-cover"
                                            controls
                                        />
                                    </div>
                                )}
                            </div>
                        </div>
                    )}

                    {type === 'Document' && (
                        <div className="space-y-2 rounded-lg border border-slate-100 bg-slate-50 p-4 dark:border-slate-700 dark:bg-slate-800/50">
                            <label className="text-sm font-medium text-slate-700 dark:text-slate-200">{t('admin.lessons.part.docContent')}</label>
                            <div className="flex flex-col gap-3">
                                <input
                                    type="file"
                                    accept=".pdf,application/pdf"
                                    onChange={handleDocUpload}
                                    disabled={uploading}
                                    className="text-sm text-slate-600 file:mr-3 file:rounded-md file:border-0 file:bg-dashboard-primary file:px-3 file:py-2 file:text-white file:cursor-pointer disabled:opacity-50"
                                />
                                {uploading && <div className="text-xs text-blue-600">{t('admin.lessons.part.uploadingDoc')}</div>}


                                {documentId && (
                                    <div className="text-sm text-green-600 flex items-center gap-1">
                                        <span className="material-symbols-outlined text-lg">check_circle</span>
                                        {t('admin.lessons.part.docUploaded', { name: documentFileName || 'PDF File' })}
                                    </div>
                                )}
                            </div>
                        </div>
                    )}
                </div>

                <div className="flex items-center justify-end gap-3 border-t border-slate-200 px-6 py-4 dark:border-slate-700">
                    <button
                        onClick={onClose}
                        className="rounded-lg border border-slate-200 px-4 py-2 text-sm font-medium text-slate-700 hover:bg-slate-100 dark:border-slate-700 dark:text-slate-200 dark:hover:bg-slate-800"
                    >
                        {t('common.cancel')}
                    </button>
                    <button
                        onClick={handleSave}
                        disabled={loading || uploading}
                        className="inline-flex items-center gap-2 rounded-lg bg-dashboard-primary px-4 py-2 text-sm font-semibold text-white shadow-sm shadow-dashboard-primary/30 transition hover:bg-dashboard-primary-dark disabled:opacity-60"
                    >
                        {loading ? t('admin.lessons.form.saving') : t('admin.lessons.part.save')}
                    </button>
                </div>
            </div>
        </div>
    );
};

export default LessonPartModal;
