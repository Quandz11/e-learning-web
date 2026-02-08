import React, { useEffect, useState } from 'react';
import { useParams, useNavigate, Link } from 'react-router-dom';
import { useTranslation } from 'react-i18next';
import { useSelector } from 'react-redux';
import type { RootState } from '../store/store';
import { forumApi, type ForumCategoryDto, type CreateForumThreadRequest } from '../services/forumApi';
import { ArrowLeft } from 'lucide-react';
import { toast } from 'react-hot-toast';

const NewThreadPage: React.FC = () => {
    const { categoryId } = useParams<{ categoryId: string }>();
    const { t } = useTranslation();
    const navigate = useNavigate();
    const { user } = useSelector((state: RootState) => state.auth);
    const [category, setCategory] = useState<ForumCategoryDto | null>(null);
    const [title, setTitle] = useState('');
    const [content, setContent] = useState('');
    const [submitting, setSubmitting] = useState(false);

    useEffect(() => {
        if (!user) {
            navigate('/login');
            return;
        }

        if (categoryId) {
            fetchCategory();
        }
    }, [categoryId, user, navigate]);

    const fetchCategory = async () => {
        if (!categoryId) return;

        try {
            const data = await forumApi.categories.getById(categoryId);
            setCategory(data);
        } catch (error) {
            console.error('Failed to fetch category:', error);
            toast.error(t('forum.categoryNotFound', { defaultValue: 'Category not found' }));
            navigate('/forum');
        }
    };

    const handleSubmit = async (e: React.FormEvent) => {
        e.preventDefault();
        if (!categoryId || !title.trim() || !content.trim()) return;

        try {
            setSubmitting(true);
            const request: CreateForumThreadRequest = {
                categoryId,
                title: title.trim(),
                content: content.trim()
            };
            const newThread = await forumApi.threads.create(request);
            toast.success(t('forum.threadCreated', { defaultValue: 'Thread created successfully' }));
            navigate(`/forum/thread/${newThread.id}`);
        } catch (error) {
            console.error('Failed to create thread:', error);
            toast.error(t('forum.threadFailed', { defaultValue: 'Failed to create thread' }));
        } finally {
            setSubmitting(false);
        }
    };

    if (!category) {
        return (
            <div className="container mx-auto px-4 py-8">
                <div className="animate-pulse">
                    <div className="h-8 bg-gray-200 dark:bg-gray-700 rounded w-1/3 mb-4" />
                    <div className="h-64 bg-gray-200 dark:bg-gray-700 rounded" />
                </div>
            </div>
        );
    }

    return (
        <div className="container mx-auto px-4 py-8 max-w-4xl">
            {/* Back Link */}
            <Link
                to={`/forum/category/${categoryId}`}
                className="inline-flex items-center gap-2 text-primary hover:text-primary/80 mb-6"
            >
                <ArrowLeft className="w-4 h-4" />
                {t('forum.backToCategory', { defaultValue: 'Back to' })} {category.name}
            </Link>

            {/* Form */}
            <div className="bg-white dark:bg-gray-800 rounded-xl shadow-sm border border-gray-100 dark:border-gray-700 p-6">
                <h1 className="text-2xl font-bold text-gray-900 dark:text-white mb-6">
                    {t('forum.createNewThread', { defaultValue: 'Create New Thread' })}
                </h1>

                <form onSubmit={handleSubmit} className="space-y-6">
                    {/* Title */}
                    <div>
                        <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                            {t('forum.threadTitle', { defaultValue: 'Title' })} <span className="text-red-500">*</span>
                        </label>
                        <input
                            type="text"
                            value={title}
                            onChange={e => setTitle(e.target.value)}
                            placeholder={t('forum.titlePlaceholder', { defaultValue: 'Enter a descriptive title for your thread' })}
                            className="w-full px-4 py-3 border border-gray-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-700 text-gray-900 dark:text-white focus:ring-2 focus:ring-primary"
                            required
                            maxLength={200}
                        />
                        <p className="mt-1 text-sm text-gray-500 dark:text-gray-400">
                            {title.length}/200
                        </p>
                    </div>

                    {/* Content */}
                    <div>
                        <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                            {t('forum.threadContent', { defaultValue: 'Content' })} <span className="text-red-500">*</span>
                        </label>
                        <textarea
                            value={content}
                            onChange={e => setContent(e.target.value)}
                            placeholder={t('forum.contentPlaceholder', { defaultValue: 'Write your question or discussion topic...' })}
                            className="w-full px-4 py-3 border border-gray-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-700 text-gray-900 dark:text-white focus:ring-2 focus:ring-primary resize-none"
                            rows={10}
                            required
                        />
                    </div>

                    {/* Actions */}
                    <div className="flex items-center justify-end gap-4">
                        <Link
                            to={`/forum/category/${categoryId}`}
                            className="px-6 py-2 border border-gray-300 dark:border-gray-600 text-gray-700 dark:text-gray-300 rounded-lg hover:bg-gray-50 dark:hover:bg-gray-700 transition-colors"
                        >
                            {t('common.cancel', { defaultValue: 'Cancel' })}
                        </Link>
                        <button
                            type="submit"
                            disabled={submitting || !title.trim() || !content.trim()}
                            className="px-6 py-2 bg-primary text-white rounded-lg hover:bg-primary/90 transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
                        >
                            {submitting ? t('forum.creating', { defaultValue: 'Creating...' }) : t('forum.createThread', { defaultValue: 'Create Thread' })}
                        </button>
                    </div>
                </form>
            </div>
        </div>
    );
};

export default NewThreadPage;
