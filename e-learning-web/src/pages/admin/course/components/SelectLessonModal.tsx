import React, { useState, useEffect } from 'react';
import { lessonApi, type LessonDto } from '../../../../services/lessonApi';
import { useTranslation } from 'react-i18next';

interface SelectLessonModalProps {
    isOpen: boolean;
    onClose: () => void;
    onSelect: (selectedLessons: LessonDto[]) => void;
    alreadySelectedIds: string[];
}

const SelectLessonModal: React.FC<SelectLessonModalProps> = ({ isOpen, onClose, onSelect, alreadySelectedIds }) => {
    const { t } = useTranslation();
    const [loading, setLoading] = useState(false);
    const [lessons, setLessons] = useState<LessonDto[]>([]);
    const [search, setSearch] = useState('');
    const [selectedIds, setSelectedIds] = useState<Set<string>>(new Set());

    useEffect(() => {
        if (isOpen) {
            loadLessons();
            setSelectedIds(new Set());
            setSearch('');
        }
    }, [isOpen]);

    const loadLessons = async () => {
        try {
            setLoading(true);
            const data = await lessonApi.getAll();
            setLessons(data);
        } catch (err) {
            console.error("Failed to load lessons", err);
        } finally {
            setLoading(false);
        }
    };

    const toggleSelect = (id: string) => {
        const newSet = new Set(selectedIds);
        if (newSet.has(id)) {
            newSet.delete(id);
        } else {
            newSet.add(id);
        }
        setSelectedIds(newSet);
    };

    const handleConfirm = () => {
        const selected = lessons.filter(l => selectedIds.has(l.id));
        onSelect(selected);
        onClose();
    };

    const filteredLessons = lessons.filter(l =>
        !alreadySelectedIds.includes(l.id) &&
        l.title.toLowerCase().includes(search.toLowerCase())
    );

    if (!isOpen) return null;

    return (
        <div className="fixed inset-0 z-[110] flex items-center justify-center bg-black/50 p-4">
            <div className="w-full max-w-3xl rounded-2xl border border-slate-200 bg-white shadow-2xl dark:border-slate-700 dark:bg-dashboard-surface-dark flex flex-col max-h-[80vh]">
                <div className="flex items-center justify-between border-b border-slate-200 px-6 py-4 dark:border-slate-700 shrink-0">
                    <h3 className="text-lg font-semibold text-slate-900 dark:text-white">
                        {t('admin.lessons.select.title')}
                    </h3>
                    <button onClick={onClose} className="rounded-full p-2 text-slate-500 hover:bg-slate-100 dark:text-slate-300 dark:hover:bg-slate-800">
                        <span className="material-symbols-outlined">close</span>
                    </button>
                </div>

                <div className="p-4 border-b border-slate-100 dark:border-slate-800 shrink-0">
                    <input
                        className="w-full rounded-lg border border-slate-200 bg-slate-50 px-3 py-2 text-sm focus:border-dashboard-primary focus:outline-none dark:border-slate-700 dark:bg-slate-900"
                        placeholder={t('admin.lessons.select.searchPlaceholder')}
                        value={search}
                        onChange={(e) => setSearch(e.target.value)}
                    />
                </div>

                <div className="flex-1 overflow-y-auto p-4 space-y-2">
                    {loading ? (
                        <div className="text-center py-8">{t('common.loading')}</div>
                    ) : filteredLessons.length === 0 ? (
                        <div className="text-center py-8 text-slate-500">{t('admin.lessons.select.empty')}</div>
                    ) : (
                        filteredLessons.map(lesson => (
                            <div
                                key={lesson.id}
                                onClick={() => toggleSelect(lesson.id)}
                                className={`flex items-center gap-3 p-3 rounded-lg border cursor-pointer transition-colors ${selectedIds.has(lesson.id)
                                    ? 'border-dashboard-primary bg-dashboard-primary/5 dark:bg-dashboard-primary/10'
                                    : 'border-slate-200 hover:bg-slate-50 dark:border-slate-700 dark:hover:bg-slate-800'
                                    }`}
                            >
                                <div className={`h-5 w-5 rounded border flex items-center justify-center ${selectedIds.has(lesson.id) ? 'bg-dashboard-primary border-dashboard-primary' : 'border-slate-300 dark:border-slate-600'
                                    }`}>
                                    {selectedIds.has(lesson.id) && <span className="material-symbols-outlined text-white text-sm">check</span>}
                                </div>
                                <div className="h-10 w-16 bg-slate-200 rounded overflow-hidden">
                                    {lesson.thumbnailUrl && <img src={lesson.thumbnailUrl} className="h-full w-full object-cover" />}
                                </div>
                                <div className="flex-1">
                                    <div className="font-medium text-slate-900 dark:text-white">{lesson.title}</div>
                                    <div className="text-xs text-slate-500">{t('admin.lessons.partsCount', { count: lesson.parts?.length || 0 })}</div>
                                </div>
                            </div>
                        ))
                    )}
                </div>

                <div className="flex items-center justify-end gap-3 border-t border-slate-200 px-6 py-4 dark:border-slate-700 shrink-0">
                    <button
                        onClick={onClose}
                        className="rounded-lg border border-slate-200 px-4 py-2 text-sm font-medium text-slate-700 hover:bg-slate-100 dark:border-slate-700 dark:text-slate-200 dark:hover:bg-slate-800"
                    >
                        {t('common.cancel')}
                    </button>
                    <button
                        onClick={handleConfirm}
                        disabled={selectedIds.size === 0}
                        className="inline-flex items-center gap-2 rounded-lg bg-dashboard-primary px-4 py-2 text-sm font-semibold text-white shadow-sm shadow-dashboard-primary/30 transition hover:bg-dashboard-primary-dark disabled:opacity-60"
                    >
                        {t('admin.lessons.select.addButton', { count: selectedIds.size })}
                    </button>
                </div>
            </div>
        </div>
    );
};

export default SelectLessonModal;
