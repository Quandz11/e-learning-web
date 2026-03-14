import React, { useEffect, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useTranslation } from 'react-i18next';
import AdminLayout from '../../../components/admin/AdminLayout';
import { lessonApi, type LessonDto } from '../../../services/lessonApi';
import { categoryApi, type CategoryDto } from '../../../services/categoryApi';
import { format } from 'date-fns';
import LessonFormModal from './components/LessonFormModal';
import ConfirmModal from '../../../components/ui/Modal/ConfirmModal';
import { useToast } from '../../../contexts/ToastContext';

const LessonsPage: React.FC = () => {
    const { t } = useTranslation();
    const navigate = useNavigate();
    const { showToast } = useToast();
    const [lessons, setLessons] = useState<LessonDto[]>([]);
    const [filteredLessons, setFilteredLessons] = useState<LessonDto[]>([]);
    const [categories, setCategories] = useState<CategoryDto[]>([]);
    const [loading, setLoading] = useState(false);
    const [error, setError] = useState<string | null>(null);

    // Search & Filter State
    const [searchQuery, setSearchQuery] = useState('');
    const [sortBy, setSortBy] = useState<'newest' | 'oldest'>('newest');
    const [partsFilter, setPartsFilter] = useState<'all' | 'with-parts' | 'no-parts'>('all');
    const [selectedCategoryId, setSelectedCategoryId] = useState<string>('');

    // Modal State
    const [showForm, setShowForm] = useState(false);
    const [editingId, setEditingId] = useState<string | null>(null);
    const [selectedLesson, setSelectedLesson] = useState<LessonDto | null>(null);

    // Delete Modal State
    const [showDeleteModal, setShowDeleteModal] = useState(false);
    const [deletingId, setDeletingId] = useState<string | null>(null);
    const [isDeleting, setIsDeleting] = useState(false);

    useEffect(() => {
        load();
    }, []);

    // Apply filters and search
    useEffect(() => {
        let result = [...lessons];

        // Search filter
        if (searchQuery.trim()) {
            const query = searchQuery.toLowerCase();
            result = result.filter(
                (lesson) =>
                    lesson.title.toLowerCase().includes(query) ||
                    lesson.description?.toLowerCase().includes(query)
            );
        }

        // Parts filter
        if (partsFilter === 'with-parts') {
            result = result.filter((lesson) => lesson.parts && lesson.parts.length > 0);
        } else if (partsFilter === 'no-parts') {
            result = result.filter((lesson) => !lesson.parts || lesson.parts.length === 0);
        }

        // Category filter
        if (selectedCategoryId) {
            result = result.filter((lesson) => lesson.categoryId === selectedCategoryId);
        }

        // Sort
        result.sort((a, b) => {
            const dateA = new Date(a.createdAt).getTime();
            const dateB = new Date(b.createdAt).getTime();
            return sortBy === 'newest' ? dateB - dateA : dateA - dateB;
        });

        setFilteredLessons(result);
    }, [lessons, searchQuery, sortBy, partsFilter, selectedCategoryId]);

    const load = async () => {
        try {
            setLoading(true);
            const [lessonsData, categoriesData] = await Promise.all([
                lessonApi.getAll(),
                categoryApi.getAll(),
            ]);
            setLessons(lessonsData);
            setCategories(categoriesData);
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

    const handleDeleteClick = (id: string) => {
        setDeletingId(id);
        setShowDeleteModal(true);
    };

    const handleConfirmDelete = async () => {
        if (!deletingId) return;

        setIsDeleting(true);
        try {
            await lessonApi.delete(deletingId);
            showToast(t('notifications.success.deleteSuccess'), 'success');
            setShowDeleteModal(false);
            await load();
        } catch (err: any) {
            showToast(err.message || t('admin.lessons.deleteError'), 'error');
        } finally {
            setIsDeleting(false);
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

            {/* Search & Filters */}
            <div className="mb-6 rounded-lg border border-slate-200 bg-white p-3 shadow-sm dark:border-slate-700 dark:bg-dashboard-surface-dark">
                <div className="grid gap-3 md:grid-cols-4">
                    {/* Search */}
                    <div>
                        <div className="relative">
                            <span className="material-symbols-outlined absolute left-3 top-1/2 -translate-y-1/2 text-slate-400 text-[18px]">search</span>
                            <input
                                type="text"
                                placeholder={t('admin.lessons.searchPlaceholder', { defaultValue: 'Search...' })}
                                value={searchQuery}
                                onChange={(e) => setSearchQuery(e.target.value)}
                                className="w-full rounded-lg border border-slate-300 bg-white py-2 pl-10 pr-3 text-sm placeholder-slate-500 focus:border-dashboard-primary focus:outline-none dark:border-slate-600 dark:bg-slate-900 dark:text-white"
                            />
                        </div>
                    </div>

                    {/* Sort */}
                    <div>
                        <select
                            value={sortBy}
                            onChange={(e) => setSortBy(e.target.value as 'newest' | 'oldest')}
                            className="w-full rounded-lg border border-slate-300 bg-white px-3 py-2 text-sm focus:border-dashboard-primary focus:outline-none dark:border-slate-600 dark:bg-slate-900 dark:text-white"
                            title={t('admin.lessons.sortBy', { defaultValue: 'Sort By' })}
                        >
                            <option value="newest">{t('admin.lessons.sortNewest', { defaultValue: 'Newest' })}</option>
                            <option value="oldest">{t('admin.lessons.sortOldest', { defaultValue: 'Oldest' })}</option>
                        </select>
                    </div>

                    {/* Filter by Parts */}
                    <div>
                        <select
                            value={partsFilter}
                            onChange={(e) => setPartsFilter(e.target.value as 'all' | 'with-parts' | 'no-parts')}
                            className="w-full rounded-lg border border-slate-300 bg-white px-3 py-2 text-sm focus:border-dashboard-primary focus:outline-none dark:border-slate-600 dark:bg-slate-900 dark:text-white"
                            title={t('admin.lessons.filterByParts', { defaultValue: 'Filter by Content' })}
                        >
                            <option value="all">{t('admin.lessons.filterAll', { defaultValue: 'All' })}</option>
                            <option value="with-parts">{t('admin.lessons.filterWithParts', { defaultValue: 'With Content' })}</option>
                            <option value="no-parts">{t('admin.lessons.filterNoParts', { defaultValue: 'No Content' })}</option>
                        </select>
                    </div>

                    {/* Filter by Category */}
                    <div>
                        <select
                            value={selectedCategoryId}
                            onChange={(e) => setSelectedCategoryId(e.target.value)}
                            className="w-full rounded-lg border border-slate-300 bg-white px-3 py-2 text-sm focus:border-dashboard-primary focus:outline-none dark:border-slate-600 dark:bg-slate-900 dark:text-white"
                            title={t('admin.lessons.filterByCategory', { defaultValue: 'Filter by Category' })}
                        >
                            <option value="">{t('admin.lessons.filterAllCategories', { defaultValue: 'All Categories' })}</option>
                            {categories.map((category) => (
                                <option key={category.id} value={category.id}>
                                    {category.name}
                                </option>
                            ))}
                        </select>
                    </div>
                </div>

                {/* Results count */}
                {(searchQuery || sortBy !== 'newest' || partsFilter !== 'all' || selectedCategoryId) && (
                    <div className="mt-2 text-xs text-slate-500 dark:text-slate-400">
                        {t('admin.lessons.resultsCount', { 
                            defaultValue: `Found {{count}} lesson(s)`, 
                            count: filteredLessons.length 
                        })}
                    </div>
                )}
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
                ) : filteredLessons.length === 0 ? (
                    <div className="rounded-2xl border border-dashed border-slate-300 bg-white/80 p-10 text-center text-slate-600 dark:border-slate-700 dark:bg-slate-900/70 dark:text-slate-300">
                        <p className="text-base font-semibold">
                            {searchQuery || sortBy !== 'newest' || partsFilter !== 'all'
                                ? t('admin.lessons.noResults', { defaultValue: 'No lessons match your filters' })
                                : t('admin.lessons.emptyTitle')}
                        </p>
                        <p className="mt-1 text-sm text-slate-500 dark:text-slate-400">
                            {searchQuery || sortBy !== 'newest' || partsFilter !== 'all'
                                ? t('admin.lessons.tryOtherFilters', { defaultValue: 'Try adjusting your search or filters' })
                                : t('admin.lessons.emptyDesc')}
                        </p>
                    </div>
                ) : (
                    <div className="grid gap-5 md:grid-cols-2 xl:grid-cols-3 2xl:grid-cols-4">
                        {filteredLessons.map((lesson) => (
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
                                                handleDeleteClick(lesson.id);
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

            <ConfirmModal
                isOpen={showDeleteModal}
                onClose={() => setShowDeleteModal(false)}
                onConfirm={handleConfirmDelete}
                title={t('modal.confirmDelete.title')}
                message={t('modal.confirmDelete.message', { item: t('modal.confirmDelete.lesson') })}
                confirmText={t('modal.delete')}
                cancelText={t('modal.cancel')}
                variant="danger"
                isLoading={isDeleting}
            />
        </AdminLayout>
    );
};

export default LessonsPage;
