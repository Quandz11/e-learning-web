import React, { useEffect, useState } from 'react';
import { Link, useParams, useNavigate } from 'react-router-dom';
import { useTranslation } from 'react-i18next';
import { useSelector } from 'react-redux';
import type { RootState } from '../store/store';
import { forumApi, type ForumThreadDto, type ForumCategoryDto } from '../services/forumApi';
import { MessageSquare, Eye, Clock, Plus, ArrowLeft } from 'lucide-react';

const ForumCategoryPage: React.FC = () => {
    const { categoryId } = useParams<{ categoryId: string }>();
    const { t } = useTranslation();
    const navigate = useNavigate();
    const { user } = useSelector((state: RootState) => state.auth);
    const [category, setCategory] = useState<ForumCategoryDto | null>(null);
    const [threads, setThreads] = useState<ForumThreadDto[]>([]);
    const [loading, setLoading] = useState(true);

    useEffect(() => {
        if (categoryId) {
            fetchData();
        }
    }, [categoryId]);

    const fetchData = async () => {
        if (!categoryId) return;

        try {
            const [categoryData, threadsData] = await Promise.all([
                forumApi.categories.getById(categoryId),
                forumApi.threads.getByCategory(categoryId)
            ]);
            setCategory(categoryData);
            setThreads(threadsData);
        } catch (error) {
            console.error('Failed to fetch forum data:', error);
        } finally {
            setLoading(false);
        }
    };

    const formatDate = (dateString: string) => {
        return new Date(dateString).toLocaleDateString('vi-VN', {
            year: 'numeric',
            month: 'short',
            day: 'numeric',
            hour: '2-digit',
            minute: '2-digit'
        });
    };

    if (loading) {
        return (
            <div className="container mx-auto px-4 py-8">
                <div className="animate-pulse space-y-4">
                    <div className="h-20 bg-gray-200 dark:bg-gray-700 rounded-xl" />
                    {[1, 2, 3].map(i => (
                        <div key={i} className="h-24 bg-gray-200 dark:bg-gray-700 rounded-xl" />
                    ))}
                </div>
            </div>
        );
    }

    if (!category) {
        return (
            <div className="container mx-auto px-4 py-8 text-center">
                <p className="text-gray-600 dark:text-gray-400">
                    {t('forum.categoryNotFound', { defaultValue: 'Category not found' })}
                </p>
            </div>
        );
    }

    return (
        <div className="container mx-auto px-4 py-8">
            {/* Header */}
            <div className="mb-6">
                <Link
                    to="/forum"
                    className="inline-flex items-center gap-2 text-primary hover:text-primary/80 mb-4"
                >
                    <ArrowLeft className="w-4 h-4" />
                    {t('forum.backToForum', { defaultValue: 'Back to Forum' })}
                </Link>

                <div className="flex items-start justify-between gap-4">
                    <div className="flex items-start gap-4">
                        {category.icon && (
                            <div className="w-16 h-16 bg-primary/10 rounded-xl flex items-center justify-center flex-shrink-0">
                                <span className="text-3xl">{category.icon}</span>
                            </div>
                        )}
                        <div>
                            <h1 className="text-3xl font-bold text-gray-900 dark:text-white mb-2">
                                {category.name}
                            </h1>
                            {category.description && (
                                <p className="text-gray-600 dark:text-gray-400">
                                    {category.description}
                                </p>
                            )}
                        </div>
                    </div>

                    {user && (
                        <button
                            onClick={() => navigate(`/forum/category/${categoryId}/new-thread`)}
                            className="flex items-center gap-2 px-4 py-2 bg-primary text-white rounded-lg hover:bg-primary/90 transition-colors"
                        >
                            <Plus className="w-5 h-5" />
                            <span className="hidden sm:inline">
                                {t('forum.newThread', { defaultValue: 'New Thread' })}
                            </span>
                        </button>
                    )}
                </div>
            </div>

            {/* Threads List */}
            <div className="space-y-3">
                {threads.length === 0 ? (
                    <div className="text-center py-12 bg-white dark:bg-gray-800 rounded-xl">
                        <MessageSquare className="mx-auto h-12 w-12 text-gray-400 mb-4" />
                        <p className="text-gray-600 dark:text-gray-400 mb-4">
                            {t('forum.noThreads', { defaultValue: 'No discussions yet' })}
                        </p>
                        {user && (
                            <button
                                onClick={() => navigate(`/forum/category/${categoryId}/new-thread`)}
                                className="inline-flex items-center gap-2 px-4 py-2 bg-primary text-white rounded-lg hover:bg-primary/90 transition-colors"
                            >
                                <Plus className="w-5 h-5" />
                                {t('forum.startFirst', { defaultValue: 'Start the first discussion' })}
                            </button>
                        )}
                    </div>
                ) : (
                    threads.map(thread => (
                        <Link
                            key={thread.id}
                            to={`/forum/thread/${thread.id}`}
                            className="block bg-white dark:bg-gray-800 rounded-xl shadow-sm hover:shadow-md transition-all duration-300 border border-gray-100 dark:border-gray-700 p-4 group"
                        >
                            <div className="flex items-start gap-4">
                                {/* Avatar */}
                                <div className="flex-shrink-0">
                                    {thread.authorAvatarUrl ? (
                                        <img
                                            src={thread.authorAvatarUrl}
                                            alt={thread.authorName}
                                            className="w-10 h-10 rounded-full object-cover"
                                        />
                                    ) : (
                                        <div className="w-10 h-10 bg-primary/10 rounded-full flex items-center justify-center">
                                            <span className="text-primary font-semibold">
                                                {thread.authorName.charAt(0).toUpperCase()}
                                            </span>
                                        </div>
                                    )}
                                </div>

                                {/* Content */}
                                <div className="flex-1 min-w-0">
                                    <h3 className="text-lg font-semibold text-gray-900 dark:text-white mb-1 group-hover:text-primary transition-colors line-clamp-1">
                                        {thread.title}
                                    </h3>
                                    <p className="text-sm text-gray-600 dark:text-gray-400 line-clamp-2 mb-2">
                                        {thread.content}
                                    </p>
                                    <div className="flex items-center gap-4 text-xs text-gray-500 dark:text-gray-400">
                                        <span className="flex items-center gap-1">
                                            <span className="font-medium">{thread.authorName}</span>
                                        </span>
                                        <span className="flex items-center gap-1">
                                            <Clock className="w-3 h-3" />
                                            {formatDate(thread.lastPostAt || thread.createdAt)}
                                        </span>
                                    </div>
                                </div>

                                {/* Stats */}
                                <div className="flex-shrink-0 text-right space-y-1">
                                    <div className="flex items-center gap-2 text-sm text-gray-600 dark:text-gray-400">
                                        <MessageSquare className="w-4 h-4" />
                                        <span>{thread.postCount}</span>
                                    </div>
                                    <div className="flex items-center gap-2 text-sm text-gray-600 dark:text-gray-400">
                                        <Eye className="w-4 h-4" />
                                        <span>{thread.viewCount}</span>
                                    </div>
                                </div>
                            </div>
                        </Link>
                    ))
                )}
            </div>
        </div>
    );
};

export default ForumCategoryPage;
