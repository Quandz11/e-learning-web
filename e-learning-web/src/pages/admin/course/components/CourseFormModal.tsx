import React, { useEffect, useState, useMemo } from 'react';
import ReactQuill from 'react-quill-new';
import 'react-quill-new/dist/quill.snow.css';
import { useTranslation } from 'react-i18next';
import { courseApi, type CourseInput, type CourseResponse } from '../../../../services/courseApi';
import { userApi, type UserDto } from '../../../../services/userApi';
import { type LessonDto } from '../../../../services/lessonApi';
import { useSelector } from 'react-redux';
import type { RootState } from '../../../../store/store';
import SelectLessonModal from './SelectLessonModal';

interface CourseFormModalProps {
    isOpen: boolean;
    onClose: () => void;
    onSuccess: () => void;
    courseId?: string | null;
    initialData?: CourseResponse | null;
}

const CourseFormModal: React.FC<CourseFormModalProps> = ({ isOpen, onClose, onSuccess, courseId, initialData }) => {
    const { t } = useTranslation();
    const { user } = useSelector((state: RootState) => state.auth);

    const [loading, setLoading] = useState(false);
    const [error, setError] = useState<string | null>(null);
    const quillRef = React.useRef<any>(null);

    // Form State
    const [title, setTitle] = useState('');
    const [description, setDescription] = useState('');
    const [price, setPrice] = useState(0);
    const [isFree, setIsFree] = useState(false);
    const [lecturerId, setLecturerId] = useState('');
    const [thumbnailUrl, setThumbnailUrl] = useState('');
    const [isPublished, setIsPublished] = useState(false);
    const [learningOutcomes, setLearningOutcomes] = useState<string[]>([]);

    // Lessons State
    const [selectedLessons, setSelectedLessons] = useState<LessonDto[]>([]);
    const [showSelectLessonModal, setShowSelectLessonModal] = useState(false);

    // Data Loading State
    const [lecturers, setLecturers] = useState<UserDto[]>([]);
    const [lecturerSearch, setLecturerSearch] = useState('');
    const [_lecturerLoading, setLecturerLoading] = useState(false);
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
            setThumbnailUrl(url);
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
                setTitle(initialData.title);
                setDescription(initialData.description || '');
                setPrice(initialData.price);
                setIsFree(initialData.isFree);
                setLecturerId((initialData.lecturerId as any)?.id || initialData.lecturerId as unknown as string || '');
                setThumbnailUrl(initialData.thumbnailUrl || '');
                setIsPublished(initialData.isPublished);
                setLearningOutcomes(initialData.learningOutcomes || []);
                setSelectedLessons(initialData.lessons || []);
            } else {
                // Reset form
                setTitle('');
                setDescription('');
                setPrice(0);
                setIsFree(false);
                setLecturerId(currentUserLecturerId);
                setThumbnailUrl('');
                setIsPublished(false);
                setLearningOutcomes([]);
                setSelectedLessons([]);
            }
            setLecturerSearch('');
        }
    }, [isOpen, initialData, courseId, currentUserLecturerId]);

    // Set Quill content imperatively after mount (avoids controlled value timing issues)
    useEffect(() => {
        if (!isOpen) return;
        const timer = setTimeout(() => {
            if (quillRef.current) {
                const editor = quillRef.current.getEditor();
                editor.clipboard.dangerouslyPasteHTML(initialData?.description || '');
            }
        }, 50);
        return () => clearTimeout(timer);
    }, [isOpen, initialData]);

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
                } finally {
                    setLecturerLoading(false);
                }
            };
            void fetchLecturers();
        }, 300);
        return () => clearTimeout(handle);
    }, [lecturerSearch, isOpen]);

    const handleSave = async () => {
        if (!title.trim()) {
            setError(t('admin.courses.form.errors.title'));
            return;
        }
        if (!lecturerId) {
            // If lecturerId prop from initialData was an object (LecturerInfo), we need to extract ID. 
            // In init, we tried to handle it.
            setError(t('admin.courses.form.errors.lecturer'));
            return;
        }

        const payload: CourseInput = {
            title,
            description,
            price: isFree ? 0 : price,
            isFree,
            lecturerId,
            thumbnailUrl,
            isPublished,
            learningOutcomes,
            lessonIds: selectedLessons.map(l => l.id)
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

    const handleAddLessons = (newLessons: LessonDto[]) => {
        // Add only ones that aren't already there? The modal filters them out, but safe to check
        const currentIds = new Set(selectedLessons.map(l => l.id));
        const toAdd = newLessons.filter(l => !currentIds.has(l.id));
        setSelectedLessons([...selectedLessons, ...toAdd]);
    };

    const removeLesson = (index: number) => {
        const newLessons = [...selectedLessons];
        newLessons.splice(index, 1);
        setSelectedLessons(newLessons);
    };

    const moveLesson = (index: number, direction: 'up' | 'down') => {
        if (direction === 'up' && index === 0) return;
        if (direction === 'down' && index === selectedLessons.length - 1) return;

        const newLessons = [...selectedLessons];
        const swapIndex = direction === 'up' ? index - 1 : index + 1;
        [newLessons[index], newLessons[swapIndex]] = [newLessons[swapIndex], newLessons[index]];
        setSelectedLessons(newLessons);
    };

    if (!isOpen) return null;

    return (
        <div className="fixed inset-0 z-[100] flex items-start justify-center overflow-y-auto bg-black/50 p-4">
            <div className="w-full max-w-5xl rounded-2xl border border-slate-200 bg-white shadow-2xl dark:border-slate-700 dark:bg-dashboard-surface-dark">
                <div className="flex items-center justify-between border-b border-slate-200 px-6 py-4 dark:border-slate-700 h-[70px]">
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

                <div className="max-h-[calc(100vh-160px)] overflow-y-auto px-6 py-5 space-y-6">
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
                                value={title}
                                onChange={(e) => setTitle(e.target.value)}
                            />
                        </div>
                        <div className="space-y-2">
                            <label className="text-sm font-medium text-slate-700 dark:text-slate-200">{t('admin.courses.form.price')}</label>
                            <input
                                type="number"
                                min={0}
                                className="w-full rounded-lg border border-slate-200 bg-slate-50 px-3 py-2 text-sm focus:border-dashboard-primary focus:bg-white focus:outline-none dark:border-slate-700 dark:bg-slate-900"
                                value={price}
                                onChange={(e) => setPrice(Number(e.target.value))}
                                disabled={isFree}
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
                                    value={lecturerId}
                                    onChange={(e) => setLecturerId(e.target.value)}
                                >
                                    <option value="">{t('admin.courses.form.lecturerSelectPlaceholder')}</option>
                                    {lecturerId && !lecturers.find((l) => l.id === lecturerId) && (
                                        <option value={lecturerId}>{t('admin.courses.form.selectedLecturerId', { id: lecturerId })}</option>
                                    )}
                                    {lecturers.map((l) => (
                                        <option key={l.id} value={l.id}>
                                            {l.fullName || l.email} ({l.email})
                                        </option>
                                    ))}
                                </select>
                            </div>
                        </div>
                    </div>

                    <div className="space-y-2">
                        <label className="text-sm font-medium text-slate-700 dark:text-slate-200">{t('admin.courses.form.thumbnail')}</label>
                        <div className="flex items-start gap-4">
                            <div className="relative h-32 w-48 flex-shrink-0 overflow-hidden rounded-lg border border-slate-200 bg-slate-50 dark:border-slate-700 dark:bg-slate-900">
                                {thumbnailUrl ? (
                                    <img src={thumbnailUrl} alt="Thumbnail Preview" className="h-full w-full object-cover" />
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
                            </div>
                        </div>
                    </div>

                    <div className="space-y-2">
                        <label className="text-sm font-medium text-slate-700 dark:text-slate-200">{t('admin.courses.form.description')}</label>
                        <div className="quill-wrapper rounded-lg border border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-900 overflow-hidden">
                            <ReactQuill
                                ref={quillRef}
                                theme="snow"
                                value={description}
                                onChange={setDescription}
                                modules={{
                                    toolbar: [
                                        [{ header: [1, 2, 3, false] }],
                                        ['bold', 'italic', 'underline', 'strike'],
                                        [{ color: [] }, { background: [] }],
                                        [{ list: 'ordered' }, { list: 'bullet' }],
                                        [{ indent: '-1' }, { indent: '+1' }],
                                        ['link', 'clean'],
                                    ],
                                }}
                                formats={['header', 'bold', 'italic', 'underline', 'strike', 'color', 'background', 'list', 'indent', 'link']}
                                style={{ minHeight: '160px' }}
                            />
                        </div>
                    </div>

                    <div className="space-y-2">
                        <label className="text-sm font-medium text-slate-700 dark:text-slate-200">{t('admin.courses.form.learningOutcomes')}</label>
                        <div className="space-y-2">
                            {learningOutcomes.map((outcome, idx) => (
                                <div key={idx} className="flex gap-2">
                                    <input
                                        className="flex-1 rounded-lg border border-slate-200 bg-slate-50 px-3 py-2 text-sm focus:border-dashboard-primary focus:bg-white focus:outline-none dark:border-slate-700 dark:bg-slate-900"
                                        value={outcome}
                                        onChange={(e) => {
                                            const newOutcomes = [...learningOutcomes];
                                            newOutcomes[idx] = e.target.value;
                                            setLearningOutcomes(newOutcomes);
                                        }}
                                        placeholder={t('admin.courses.form.learningOutcomePlaceholder')}
                                    />
                                    <button
                                        onClick={() => {
                                            const newOutcomes = [...learningOutcomes];
                                            newOutcomes.splice(idx, 1);
                                            setLearningOutcomes(newOutcomes);
                                        }}
                                        className="rounded-lg p-2 text-red-500 hover:bg-red-50 dark:hover:bg-red-900/20"
                                    >
                                        <span className="material-symbols-outlined">delete</span>
                                    </button>
                                </div>
                            ))}
                            <button
                                onClick={() => setLearningOutcomes([...learningOutcomes, ''])}
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
                                checked={isFree}
                                onChange={(e) => {
                                    setIsFree(e.target.checked);
                                    if (e.target.checked) setPrice(0);
                                }}
                                className="h-4 w-4 rounded border-slate-300 text-dashboard-primary focus:ring-dashboard-primary"
                            />
                            {t('admin.courses.form.free')}
                        </label>
                        <label className="inline-flex items-center gap-2 text-sm text-slate-700 dark:text-slate-200">
                            <input
                                type="checkbox"
                                checked={isPublished}
                                onChange={(e) => setIsPublished(e.target.checked)}
                                className="h-4 w-4 rounded border-slate-300 text-dashboard-primary focus:ring-dashboard-primary"
                            />
                            {t('admin.courses.form.published')}
                        </label>
                    </div>

                    {/* Lesson Management */}
                    <div className="space-y-4 pt-4 border-t border-slate-100 dark:border-slate-800">
                        <div className="flex items-center justify-between">
                            <h4 className="text-base font-semibold text-slate-900 dark:text-white">{t('admin.courses.form.lessonsTitle')}</h4>
                            <button
                                onClick={() => setShowSelectLessonModal(true)}
                                className="inline-flex items-center gap-1 rounded-md border border-slate-200 px-3 py-1.5 text-sm text-slate-700 hover:bg-slate-100 dark:border-slate-700 dark:text-slate-200 dark:hover:bg-slate-800"
                            >
                                <span className="material-symbols-outlined text-[18px]">add_circle</span>
                                {t('admin.courses.form.addLessons')}
                            </button>
                        </div>

                        {selectedLessons.length === 0 ? (
                            <div className="text-center p-8 bg-slate-50 border border-dashed border-slate-200 rounded-lg dark:bg-slate-900/50 dark:border-slate-700">
                                <p className="text-sm text-slate-500">{t('admin.courses.form.noLessons')}</p>
                            </div>
                        ) : (
                            <div className="space-y-2">
                                {selectedLessons.map((lesson, idx) => (
                                    <div key={idx} className="flex items-center gap-3 bg-white p-3 rounded-lg border border-slate-200 shadow-sm dark:bg-slate-900 dark:border-slate-700">
                                        <div className="flex flex-col gap-1 text-slate-400">
                                            <button onClick={() => moveLesson(idx, 'up')} disabled={idx === 0} className="hover:text-dashboard-primary disabled:opacity-30">
                                                <span className="material-symbols-outlined text-[18px]">keyboard_arrow_up</span>
                                            </button>
                                            <button onClick={() => moveLesson(idx, 'down')} disabled={idx === selectedLessons.length - 1} className="hover:text-dashboard-primary disabled:opacity-30">
                                                <span className="material-symbols-outlined text-[18px]">keyboard_arrow_down</span>
                                            </button>
                                        </div>
                                        <div className="h-12 w-20 rounded bg-slate-100 overflow-hidden flex-shrink-0">
                                            {lesson.thumbnailUrl && <img src={lesson.thumbnailUrl} className="h-full w-full object-cover" />}
                                        </div>
                                        <div className="flex-1">
                                            <div className="text-sm font-medium text-slate-900 dark:text-white line-clamp-1">{lesson.title}</div>
                                            <div className="text-xs text-slate-500">{lesson.parts?.length || 0} parts</div>
                                        </div>
                                        <button
                                            onClick={() => removeLesson(idx)}
                                            className="p-2 text-slate-400 hover:text-red-500 hover:bg-red-50 rounded-full dark:hover:bg-red-900/20"
                                        >
                                            <span className="material-symbols-outlined">close</span>
                                        </button>
                                    </div>
                                ))}
                            </div>
                        )}
                    </div>

                </div>

                <div className="flex items-center justify-end gap-3 border-t border-slate-200 px-6 py-4 dark:border-slate-700 h-[70px]">
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

            <SelectLessonModal
                isOpen={showSelectLessonModal}
                onClose={() => setShowSelectLessonModal(false)}
                onSelect={handleAddLessons}
                alreadySelectedIds={selectedLessons.map(l => l.id)}
            />
        </div>
    );
};

export default CourseFormModal;
