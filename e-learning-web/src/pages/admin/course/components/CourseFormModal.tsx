import React, { useEffect, useState, useMemo } from 'react';
import { useTranslation } from 'react-i18next';
import { courseApi, type CourseInput, type CourseResponse, type CourseSectionInput, type CourseLessonInput } from '../../../../services/courseApi';
import { documentApi } from '../../../../services/documentApi';
import { userApi, type UserDto } from '../../../../services/userApi';
import { useSelector } from 'react-redux';
import type { RootState } from '../../../../store/store';
import SecureVideoPlayer from '../../../../components/SecureVideoPlayer';

interface CourseFormModalProps {
    isOpen: boolean;
    onClose: () => void;
    onSuccess: () => void;
    courseId?: string | null;
    initialData?: CourseResponse | null;
}

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
    learningOutcomes: [],
    sections: [emptySection(1)],
});

const CourseFormModal: React.FC<CourseFormModalProps> = ({ isOpen, onClose, onSuccess, courseId, initialData }) => {
    const { t } = useTranslation();
    const { user } = useSelector((state: RootState) => state.auth);

    const [loading, setLoading] = useState(false);
    const [error, setError] = useState<string | null>(null);
    const [form, setForm] = useState<CourseInput>(initialCourse(user?.id));
    const [lecturers, setLecturers] = useState<UserDto[]>([]);
    const [lecturerSearch, setLecturerSearch] = useState('');
    const [lecturerLoading, setLecturerLoading] = useState(false);
    const [videoThumbnailUploading, setVideoThumbnailUploading] = useState<Record<string, boolean>>({});
    const [pdfUploading, setPdfUploading] = useState<Record<string, boolean>>({});
    const [uploadingThumbnail, setUploadingThumbnail] = useState(false);
    const thumbnailInputRef = React.useRef<HTMLInputElement>(null);

    const currentUserLecturerId = useMemo(() => user?.id || '', [user]);

    const handleThumbnailUpload = async (e: React.ChangeEvent<HTMLInputElement>) => {
        const file = e.target.files?.[0];
        if (!file) return;

        if (file.size > 5 * 1024 * 1024) {
            setError(t('admin.courses.form.errors.fileSize', { defaultValue: 'File size exceeds 5MB' }));
            return;
        }

        try {
            setUploadingThumbnail(true);
            setError(null);
            const { url } = await courseApi.uploadThumbnail(file);
            setForm((prev) => ({ ...prev, thumbnailUrl: url }));
        } catch (err: any) {
            setError(err.message || t('admin.courses.form.errors.uploadFailed'));
        } finally {
            setUploadingThumbnail(false);
            if (thumbnailInputRef.current) {
                thumbnailInputRef.current.value = '';
            }
        }
    };

    // Initialize form when opening
    useEffect(() => {
        if (isOpen) {
            setError(null);
            if (initialData) {
                // Map CourseResponse to CourseInput
                setForm({
                    title: initialData.title,
                    description: initialData.description,
                    price: initialData.price,
                    isFree: initialData.isFree,
                    lecturerId: initialData.lecturerId,
                    thumbnailUrl: initialData.thumbnailUrl,
                    isPublished: initialData.isPublished,
                    sections: initialData.sections.map((s) => ({
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
                            documentId: l.documentId,
                            documentUrl: l.documentUrl,
                            documentFileName: l.documentFileName,
                        })),
                    })),
                    learningOutcomes: initialData.learningOutcomes || [],
                });
            } else if (courseId) {
                // TODO: If only ID is passed, fetch data? 
                // For now we assume initialData is passed if editing, or we reset if not.
                // If courseId is present but no initialData, we might want to fetch. 
                // But current usage in CoursesPage passes data.
            } else {
                setForm(initialCourse(currentUserLecturerId));
            }
            setLecturerSearch('');
        }
    }, [isOpen, initialData, courseId, currentUserLecturerId]);

    // Fetch lecturers
    useEffect(() => {
        if (!isOpen) return;
        const handle = setTimeout(() => {
            const fetchLecturers = async () => {
                try {
                    setLecturerLoading(true);
                    const res = await userApi.getPaged({ role: 'LECTURER', search: lecturerSearch, page: 1, pageSize: 20 });
                    setLecturers(res.items);
                } catch (err: any) {
                    console.error(err);
                    // Silent error or small notification
                } finally {
                    setLecturerLoading(false);
                }
            };
            void fetchLecturers();
        }, 300);
        return () => clearTimeout(handle);
    }, [lecturerSearch, isOpen]);

    const handleSave = async () => {
        if (!form.title.trim()) {
            setError(t('admin.courses.form.errors.title'));
            return;
        }
        if (!form.lecturerId) {
            setError(t('admin.courses.form.errors.lecturer'));
            return;
        }

        const payload: CourseInput = {
            ...form,
            price: form.isFree ? 0 : form.price,
        };

        try {
            setLoading(true);
            setError(null);
            if (courseId) {
                await courseApi.update(courseId, payload);
            } else {
                await courseApi.create(payload);
            }
            onSuccess();
            onClose();
        } catch (err: any) {
            setError(err.message || t('admin.courses.form.errors.saveFailed'));
        } finally {
            setLoading(false);
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

    const handleUpload = async (sectionIndex: number, lessonIndex: number, file?: File | null) => {
        if (!file) return;
        try {
            setLoading(true);
            const lesson = form.sections[sectionIndex].lessons[lessonIndex];
            const res = await courseApi.uploadVideo(file, lesson.title);
            updateLesson(sectionIndex, lessonIndex, { videoId: res.videoId, playbackUrl: res.playlistUrl, duration: res.duration });
        } catch (err: any) {
            setError(err.message || t('admin.courses.form.errors.uploadFailed'));
        } finally {
            setLoading(false);
        }
    };

    const syncDuration = async (sectionIndex: number, lessonIndex: number, videoId: string) => {
        if (!videoId) return;
        try {
            setLoading(true); // Or use a specific loading state for sync
            const res = await courseApi.syncVideoDuration(videoId);
            updateLesson(sectionIndex, lessonIndex, { duration: res.duration });
        } catch (err: any) {
            console.error('Failed to sync duration:', err);
            // Optional: show toast/error
        } finally {
            setLoading(false);
        }
    };

    // Auto-sync duration for videos with 0 duration when modal opens or initial data loads
    useEffect(() => {
        if (!isOpen || !form.sections) return;

        const syncNeededLessons: { sIdx: number; lIdx: number; videoId: string }[] = [];
        form.sections.forEach((section, sIdx) => {
            section.lessons.forEach((lesson, lIdx) => {
                if (lesson.videoId && (lesson.duration === 0 || !lesson.duration)) {
                    syncNeededLessons.push({ sIdx, lIdx, videoId: lesson.videoId });
                }
            });
        });

        if (syncNeededLessons.length > 0) {
            // Processing sequentially to avoid race conditions or API flooding (though parallel is fine for few)
            // Using a small delay or just firing them
            syncNeededLessons.forEach(({ sIdx, lIdx, videoId }) => {
                void syncDuration(sIdx, lIdx, videoId);
            });
        }
        // eslint-disable-next-line react-hooks/exhaustive-deps
    }, [isOpen, initialData]); // Run once when opening/data loaded. 
    // Ideally we track if we already synced to avoid loops, but checking duration === 0 is safe enough unless it stays 0.

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
            // Optional: Update UI to show success or new thumbnail URL if API returned it (currently it just uploads to Bunny)
        } catch (err: any) {
            setError(err.message || t('admin.courses.form.errors.uploadFailed'));
        } finally {
            setVideoThumbnailUploading((prev) => ({ ...prev, [key]: false }));
        }
    };

    const handlePdfUpload = async (sectionIndex: number, lessonIndex: number, file?: File | null) => {
        if (!file) return;

        const key = `${sectionIndex}-${lessonIndex}`;
        try {
            setPdfUploading((prev) => ({ ...prev, [key]: true }));
            setError(null);
            const res = await documentApi.uploadPdf(file);

            // Update lesson with document info
            updateLesson(sectionIndex, lessonIndex, {
                documentId: res.documentId,
                documentUrl: res.fileUrl,
                documentFileName: file.name,
            });
        } catch (err: any) {
            setError(err.message || t('admin.courses.form.errors.uploadFailed'));
        } finally {
            setPdfUploading((prev) => ({ ...prev, [key]: false }));
        }
    };

    if (!isOpen) return null;

    return (
        <div className="fixed inset-0 z-[100] flex items-start justify-center overflow-y-auto bg-black/50 p-4">
            <div className="w-full max-w-5xl rounded-2xl border border-slate-200 bg-white shadow-2xl dark:border-slate-700 dark:bg-dashboard-surface-dark">
                <div className="flex items-center justify-between border-b border-slate-200 px-6 py-4 dark:border-slate-700">
                    <div>
                        <h3 className="text-lg font-semibold text-slate-900 dark:text-white">
                            {courseId ? t('admin.courses.form.editTitle') : t('admin.courses.form.newTitle')}
                        </h3>
                        <p className="text-sm text-slate-500 dark:text-slate-400">{t('admin.courses.subtitle')}</p>
                    </div>
                    <button onClick={onClose} className="rounded-full p-2 text-slate-500 hover:bg-slate-100 dark:text-slate-300 dark:hover:bg-slate-800">
                        <span className="material-symbols-outlined">close</span>
                    </button>
                </div>

                <div className="max-h-[80vh] overflow-y-auto px-6 py-5 space-y-6">
                    {error && (
                        <div className="rounded-lg border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-700 dark:border-red-900/50 dark:bg-red-900/20 dark:text-red-200">
                            {error}
                        </div>
                    )}

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
                        <label className="text-sm font-medium text-slate-700 dark:text-slate-200">{t('admin.courses.form.thumbnail')}</label>
                        <div className="flex items-start gap-4">
                            <div className="relative h-32 w-48 flex-shrink-0 overflow-hidden rounded-lg border border-slate-200 bg-slate-50 dark:border-slate-700 dark:bg-slate-900">
                                {form.thumbnailUrl ? (
                                    <img src={form.thumbnailUrl} alt="Thumbnail Preview" className="h-full w-full object-cover" />
                                ) : (
                                    <div className="flex h-full w-full items-center justify-center text-slate-400">
                                        <span className="material-symbols-outlined text-4xl">image</span>
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
                                    accept="image/png, image/jpeg, image/jpg, image/webp"
                                    className="hidden"
                                />
                                <button
                                    type="button"
                                    onClick={() => thumbnailInputRef.current?.click()}
                                    disabled={uploadingThumbnail || loading}
                                    className="inline-flex items-center gap-2 rounded-lg border border-slate-200 bg-white px-3 py-2 text-sm font-medium text-slate-700 hover:bg-slate-50 disabled:opacity-50 dark:border-slate-700 dark:bg-slate-800 dark:text-slate-200 dark:hover:bg-slate-700"
                                >
                                    <span className="material-symbols-outlined text-[18px]">upload</span>
                                    {uploadingThumbnail ? t('common.uploading', { defaultValue: 'Uploading...' }) : t('admin.courses.form.uploadThumbnail', { defaultValue: 'Upload Thumbnail' })}
                                </button>
                                <p className="mt-2 text-xs text-slate-500 dark:text-slate-400">
                                    JPG, PNG, WebP up to 5MB. Recommended ratio 16:9.
                                </p>
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

                    <div className="space-y-2">
                        <label className="text-sm font-medium text-slate-700 dark:text-slate-200">{t('admin.courses.form.learningOutcomes')}</label>
                        <div className="space-y-2">
                            {(form.learningOutcomes || []).map((outcome, idx) => (
                                <div key={idx} className="flex gap-2">
                                    <input
                                        className="flex-1 rounded-lg border border-slate-200 bg-slate-50 px-3 py-2 text-sm focus:border-dashboard-primary focus:bg-white focus:outline-none dark:border-slate-700 dark:bg-slate-900"
                                        value={outcome}
                                        onChange={(e) => {
                                            const newOutcomes = [...(form.learningOutcomes || [])];
                                            newOutcomes[idx] = e.target.value;
                                            setForm({ ...form, learningOutcomes: newOutcomes });
                                        }}
                                        placeholder={t('admin.courses.form.learningOutcomePlaceholder')}
                                    />
                                    <button
                                        onClick={() => {
                                            const newOutcomes = [...(form.learningOutcomes || [])];
                                            newOutcomes.splice(idx, 1);
                                            setForm({ ...form, learningOutcomes: newOutcomes });
                                        }}
                                        className="rounded-lg p-2 text-red-500 hover:bg-red-50 dark:hover:bg-red-900/20"
                                    >
                                        <span className="material-symbols-outlined">delete</span>
                                    </button>
                                </div>
                            ))}
                            <button
                                onClick={() => setForm({ ...form, learningOutcomes: [...(form.learningOutcomes || []), ''] })}
                                className="inline-flex items-center gap-1 text-sm font-medium text-dashboard-primary hover:text-dashboard-primary-dark"
                            >
                                <span className="material-symbols-outlined text-[18px]">add</span>
                                {t('admin.courses.form.addLearningOutcome')}
                            </button>
                        </div>
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
                                    <div className="flex-1 space-y-1">
                                        <label className="text-xs font-medium text-slate-500 dark:text-slate-400">{t('admin.courses.form.sectionTitle')}</label>
                                        <input
                                            className="w-full rounded-lg border border-slate-200 bg-white px-3 py-2 text-sm focus:border-dashboard-primary focus:outline-none dark:border-slate-700 dark:bg-slate-900"
                                            value={section.title}
                                            onChange={(e) => updateSection(sIdx, { title: e.target.value })}
                                        />
                                    </div>
                                    <div className="w-24 space-y-1">
                                        <label className="text-xs font-medium text-slate-500 dark:text-slate-400">{t('admin.courses.form.order')}</label>
                                        <input
                                            type="number"
                                            min={1}
                                            className="w-full rounded-lg border border-slate-200 bg-white px-3 py-2 text-sm focus:border-dashboard-primary focus:outline-none dark:border-slate-700 dark:bg-slate-900"
                                            value={section.orderIndex}
                                            onChange={(e) => updateSection(sIdx, { orderIndex: Number(e.target.value) })}
                                        />
                                    </div>
                                    <button
                                        onClick={() => addLesson(sIdx)}
                                        className="mt-6 inline-flex items-center gap-1 rounded-md border border-slate-200 px-3 py-1.5 text-sm text-slate-700 hover:bg-slate-100 dark:border-slate-700 dark:text-slate-200 dark:hover:bg-slate-800"
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
                                            <div key={lIdx} className="rounded-lg border border-slate-200 bg-white p-3 dark:border-slate-700 dark:bg-slate-900 border-l-4 border-l-transparent hover:border-l-dashboard-primary transition-colors">
                                                <div className="flex flex-wrap items-end gap-3">
                                                    <div className="flex-1 min-w-[200px] space-y-1">
                                                        <label className="text-xs font-medium text-slate-500 dark:text-slate-400">{t('admin.courses.form.lessonTitle')}</label>
                                                        <input
                                                            className="w-full rounded-lg border border-slate-200 bg-white px-3 py-2 text-sm focus:border-dashboard-primary focus:outline-none dark:border-slate-700 dark:bg-slate-900"
                                                            value={lesson.title}
                                                            onChange={(e) => updateLesson(sIdx, lIdx, { title: e.target.value })}
                                                        />
                                                    </div>
                                                    <div className="w-[140px] space-y-1">
                                                        <label className="text-xs font-medium text-slate-500 dark:text-slate-400">{t('admin.courses.form.duration')}</label>
                                                        <div className="flex items-center gap-1">
                                                            <input
                                                                type="number"
                                                                min={0}
                                                                className="w-full rounded-lg border border-slate-200 bg-white px-3 py-2 text-sm focus:border-dashboard-primary focus:outline-none dark:border-slate-700 dark:bg-slate-900"
                                                                value={lesson.duration}
                                                                onChange={(e) => updateLesson(sIdx, lIdx, { duration: Number(e.target.value) })}
                                                            />
                                                            {lesson.videoId && (
                                                                <button
                                                                    type="button"
                                                                    onClick={() => syncDuration(sIdx, lIdx, lesson.videoId)}
                                                                    className="h-[38px] w-[38px] flex items-center justify-center text-slate-500 hover:text-dashboard-primary hover:bg-slate-100 rounded-md dark:hover:bg-slate-800 border border-slate-200 dark:border-slate-700"
                                                                    title={t('admin.courses.form.syncDuration')}
                                                                >
                                                                    <span className="material-symbols-outlined text-[20px]">sync</span>
                                                                </button>
                                                            )}
                                                        </div>
                                                    </div>
                                                    <div className="w-20 space-y-1">
                                                        <label className="text-xs font-medium text-slate-500 dark:text-slate-400">{t('admin.courses.form.order')}</label>
                                                        <input
                                                            type="number"
                                                            min={1}
                                                            className="w-full rounded-lg border border-slate-200 bg-white px-3 py-2 text-sm focus:border-dashboard-primary focus:outline-none dark:border-slate-700 dark:bg-slate-900"
                                                            value={lesson.orderIndex}
                                                            onChange={(e) => updateLesson(sIdx, lIdx, { orderIndex: Number(e.target.value) })}
                                                        />
                                                    </div>
                                                    <div className="flex items-center h-[38px] pb-1">
                                                        <label className="inline-flex items-center gap-2 text-sm text-slate-700 dark:text-slate-200 cursor-pointer select-none">
                                                            <input
                                                                type="checkbox"
                                                                checked={lesson.isPreview}
                                                                onChange={(e) => updateLesson(sIdx, lIdx, { isPreview: e.target.checked })}
                                                                className="h-4 w-4 rounded border-slate-300 text-dashboard-primary focus:ring-dashboard-primary"
                                                            />
                                                            {t('admin.courses.form.preview')}
                                                        </label>
                                                    </div>
                                                    <div className="flex items-center h-[38px] pb-1">
                                                        {lesson.videoId ? (
                                                            <span className="inline-flex items-center gap-1 rounded-full bg-green-100 px-3 py-1 text-xs font-medium text-green-700 dark:bg-green-900/30 dark:text-green-300">
                                                                <span className="material-symbols-outlined text-[16px]">check_circle</span>
                                                                {t('admin.courses.form.videoLinked')}
                                                            </span>
                                                        ) : (
                                                            <span className="inline-flex items-center gap-1 rounded-full bg-amber-100 px-3 py-1 text-xs font-medium text-amber-700 dark:bg-amber-900/30 dark:text-amber-300">
                                                                <span className="material-symbols-outlined text-[16px]">cloud_upload</span>
                                                                {t('admin.courses.form.uploadRequired')}
                                                            </span>
                                                        )}
                                                    </div>
                                                </div>

                                                <div className="mt-3 space-y-1">
                                                    <div className="text-sm font-medium text-slate-700 dark:text-slate-200">{t('admin.courses.form.uploadVideo')}</div>
                                                    <div className="flex flex-wrap items-center gap-3">
                                                        <input
                                                            type="file"
                                                            accept="video/*"
                                                            onChange={(e) => handleUpload(sIdx, lIdx, e.target.files?.[0])}
                                                            className="text-sm text-slate-600 file:mr-3 file:rounded-md file:border-0 file:bg-dashboard-primary file:px-3 file:py-2 file:text-white file:cursor-pointer"
                                                        />
                                                        {/* Preview with SecureVideoPlayer */}
                                                        {lesson.videoId && (
                                                            <div className="mt-2 w-64 aspect-video rounded-lg overflow-hidden border border-slate-200 dark:border-slate-700 bg-black">
                                                                <SecureVideoPlayer
                                                                    videoId={lesson.videoId}
                                                                    className="w-full h-full object-cover"
                                                                    controls
                                                                />
                                                            </div>
                                                        )}
                                                    </div>
                                                </div>

                                                <div className="mt-3 space-y-1">
                                                    <div className="text-sm font-medium text-slate-700 dark:text-slate-200">{t('admin.courses.form.uploadThumbnail')}</div>
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

                                                <div className="mt-3 space-y-1">
                                                    <div className="text-sm font-medium text-slate-700 dark:text-slate-200">{t('admin.courses.form.uploadDocument', { defaultValue: 'Upload PDF Document' })}</div>
                                                    <div className="flex flex-wrap items-center gap-3">
                                                        <input
                                                            type="file"
                                                            accept=".pdf,application/pdf"
                                                            onChange={(e) => handlePdfUpload(sIdx, lIdx, e.target.files?.[0])}
                                                            className="text-sm text-slate-600 file:mr-3 file:rounded-md file:border-0 file:bg-dashboard-primary file:px-3 file:py-2 file:text-white file:cursor-pointer"
                                                        />
                                                        {pdfUploading[`${sIdx}-${lIdx}`] && (
                                                            <span className="text-xs text-slate-500">
                                                                {t('admin.courses.form.pdfUploading', { defaultValue: 'Uploading PDF...' })}
                                                            </span>
                                                        )}
                                                        {lesson.documentId && !pdfUploading[`${sIdx}-${lIdx}`] && (
                                                            <span className="inline-flex items-center gap-1 rounded-full bg-blue-100 px-3 py-1 text-xs font-medium text-blue-700 dark:bg-blue-900/30 dark:text-blue-300">
                                                                <span className="material-symbols-outlined text-[16px]">description</span>
                                                                {t('admin.courses.form.documentLinked', { defaultValue: 'PDF Linked' })}
                                                                {lesson.documentFileName && `: ${lesson.documentFileName.substring(0, 20)}...`}
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
                        onClick={onClose}
                        className="rounded-lg border border-slate-200 px-4 py-2 text-sm font-medium text-slate-700 hover:bg-slate-100 dark:border-slate-700 dark:text-slate-200 dark:hover:bg-slate-800"
                    >
                        {t('common.cancel', { defaultValue: t('admin.courses.form.cancel') })}
                    </button>
                    <button
                        onClick={handleSave}
                        disabled={loading}
                        className="inline-flex items-center gap-2 rounded-lg bg-dashboard-primary px-4 py-2 text-sm font-semibold text-white shadow-sm shadow-dashboard-primary/30 transition hover:bg-dashboard-primary-dark disabled:opacity-60"
                    >
                        {loading ? t('common.saving', { defaultValue: 'Saving...' }) : t('admin.courses.form.save')}
                    </button>
                </div>
            </div>
        </div>
    );
};

export default CourseFormModal;
