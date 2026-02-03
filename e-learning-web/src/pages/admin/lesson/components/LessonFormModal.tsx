import React, { useEffect, useState, useRef } from 'react';
import { useTranslation } from 'react-i18next';
import { lessonApi, type CreateLessonRequest, type LessonDto } from '../../../../services/lessonApi';
import { courseApi } from '../../../../services/courseApi'; // Reusing for thumbnail

interface LessonFormModalProps {
    isOpen: boolean;
    onClose: () => void;
    onSuccess: (lessonId: string) => void;
    lessonId?: string | null;
    initialData?: LessonDto | null;
}

const LessonFormModal: React.FC<LessonFormModalProps> = ({ isOpen, onClose, onSuccess, lessonId, initialData }) => {
    const { t } = useTranslation();
    const [loading, setLoading] = useState(false);
    const [error, setError] = useState<string | null>(null);
    const [title, setTitle] = useState('');
    const [description, setDescription] = useState('');
    const [thumbnailUrl, setThumbnailUrl] = useState('');
    const [uploadingThumbnail, setUploadingThumbnail] = useState(false);
    const thumbnailInputRef = useRef<HTMLInputElement>(null);

    useEffect(() => {
        if (isOpen) {
            setError(null);
            if (initialData) {
                setTitle(initialData.title);
                setDescription(initialData.description || '');
                setThumbnailUrl(initialData.thumbnailUrl || '');
            } else {
                setTitle('');
                setDescription('');
                setThumbnailUrl('');
            }
        }
    }, [isOpen, initialData]);

    const handleThumbnailUpload = async (e: React.ChangeEvent<HTMLInputElement>) => {
        const file = e.target.files?.[0];
        if (!file) return;

        if (file.size > 5 * 1024 * 1024) {
            setError(t('admin.lessons.form.fileSizeError'));
            return;
        }

        try {
            setUploadingThumbnail(true);
            setError(null);
            const { url } = await courseApi.uploadThumbnail(file); // Reusing course thumbnail upload
            setThumbnailUrl(url);
        } catch (err: any) {
            setError(err.message || t('admin.lessons.form.uploadError'));
        } finally {
            setUploadingThumbnail(false);
            if (thumbnailInputRef.current) {
                thumbnailInputRef.current.value = '';
            }
        }
    };

    const handleSave = async () => {
        if (!title.trim()) {
            setError(t('admin.lessons.form.titleRequired'));
            return;
        }

        const payload: CreateLessonRequest = {
            title,
            description,
            thumbnailUrl
        };

        try {
            setLoading(true);
            setError(null);
            let resultId = lessonId;
            if (lessonId) {
                await lessonApi.update(lessonId, payload);
            } else {
                const created = await lessonApi.create(payload);
                resultId = created.id;
            }
            onSuccess(resultId!);
            onClose();
        } catch (err: any) {
            setError(err.message || t('admin.lessons.form.saveError'));
        } finally {
            setLoading(false);
        }
    };

    if (!isOpen) return null;

    return (
        <div className="fixed inset-0 z-[100] flex items-center justify-center bg-black/50 p-4">
            <div className="w-full max-w-2xl rounded-2xl border border-slate-200 bg-white shadow-2xl dark:border-slate-700 dark:bg-dashboard-surface-dark">
                <div className="flex items-center justify-between border-b border-slate-200 px-6 py-4 dark:border-slate-700">
                    <h3 className="text-lg font-semibold text-slate-900 dark:text-white">
                        {lessonId ? t('admin.lessons.form.editTitle') : t('admin.lessons.form.newTitle')}
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
                        <label className="text-sm font-medium text-slate-700 dark:text-slate-200">{t('admin.lessons.form.title')}</label>
                        <input
                            className="w-full rounded-lg border border-slate-200 bg-slate-50 px-3 py-2 text-sm focus:border-dashboard-primary focus:bg-white focus:outline-none dark:border-slate-700 dark:bg-slate-900"
                            value={title}
                            onChange={(e) => setTitle(e.target.value)}
                            placeholder={t('admin.lessons.form.titlePlaceholder')}
                        />
                    </div>

                    <div className="space-y-2">
                        <label className="text-sm font-medium text-slate-700 dark:text-slate-200">{t('admin.lessons.form.description')}</label>
                        <textarea
                            className="w-full rounded-lg border border-slate-200 bg-slate-50 px-3 py-2 text-sm focus:border-dashboard-primary focus:bg-white focus:outline-none dark:border-slate-700 dark:bg-slate-900"
                            rows={3}
                            value={description}
                            onChange={(e) => setDescription(e.target.value)}
                            placeholder={t('admin.lessons.form.descriptionPlaceholder')}
                        />
                    </div>

                    <div className="space-y-2">
                        <label className="text-sm font-medium text-slate-700 dark:text-slate-200">{t('admin.lessons.form.thumbnail')}</label>
                        <div className="flex items-start gap-4">
                            <div className="relative h-24 w-40 flex-shrink-0 overflow-hidden rounded-lg border border-slate-200 bg-slate-50 dark:border-slate-700 dark:bg-slate-900">
                                {thumbnailUrl ? (
                                    <img src={thumbnailUrl} alt="Thumbnail Preview" className="h-full w-full object-cover" />
                                ) : (
                                    <div className="flex h-full w-full items-center justify-center text-slate-400">
                                        <span className="material-symbols-outlined text-3xl">image</span>
                                    </div>
                                )}
                                {uploadingThumbnail && (
                                    <div className="absolute inset-0 flex items-center justify-center bg-black/50">
                                        <div className="h-6 w-6 animate-spin rounded-full border-2 border-white border-t-transparent"></div>
                                    </div>
                                )}
                            </div>
                            <div className="flex-1">
                                <input
                                    type="file"
                                    ref={thumbnailInputRef}
                                    onChange={handleThumbnailUpload}
                                    accept="image/*"
                                    className="hidden"
                                />
                                <button
                                    type="button"
                                    onClick={() => thumbnailInputRef.current?.click()}
                                    disabled={uploadingThumbnail || loading}
                                    className="inline-flex items-center gap-2 rounded-lg border border-slate-200 bg-white px-3 py-2 text-sm font-medium text-slate-700 hover:bg-slate-50 disabled:opacity-50 dark:border-slate-700 dark:bg-slate-800 dark:text-slate-200 dark:hover:bg-slate-700"
                                >
                                    <span className="material-symbols-outlined text-[18px]">upload</span>
                                    {t('admin.lessons.form.uploadThumbnail')}
                                </button>
                            </div>
                        </div>
                    </div>
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
                        disabled={loading}
                        className="inline-flex items-center gap-2 rounded-lg bg-dashboard-primary px-4 py-2 text-sm font-semibold text-white shadow-sm shadow-dashboard-primary/30 transition hover:bg-dashboard-primary-dark disabled:opacity-60"
                    >
                        {loading ? t('admin.lessons.form.saving') : t('admin.lessons.form.save')}
                    </button>
                </div>
            </div>
        </div>
    );
};

export default LessonFormModal;
