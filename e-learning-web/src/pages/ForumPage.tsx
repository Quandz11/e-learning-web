import React, { useEffect, useState } from 'react';
import { Link } from 'react-router-dom';
import { useTranslation } from 'react-i18next';
import { forumApi, type ForumCategoryDto } from '../services/forumApi';
import { MessageSquare, Users, TrendingUp } from 'lucide-react';

const ForumPage: React.FC = () => {
    const { t } = useTranslation();
    const [categories, setCategories] = useState<ForumCategoryDto[]>([]);
    const [loading, setLoading] = useState(true);

    useEffect(() => {
        const fetchCategories = async () => {
            try {
                const data = await forumApi.categories.getAll();
                setCategories(data);
            } catch (error) {
                console.error('Failed to fetch forum categories:', error);
            } finally {
                setLoading(false);
            }
        };

        fetchCategories();
    }, []);

    if (loading) {
        return (
            <div className="container mx-auto px-4 py-8">
                <div className="animate-pulse space-y-4">
                    {[1, 2, 3].map(i => (
                        <div key={i} className="h-32 bg-gray-200 dark:bg-gray-700 rounded-xl" />
                    ))}
                </div>
            </div>
        );
    }

    return (
        <div className="container mx-auto px-4 py-8">
            {/* Header */}
            <div className="mb-8">
                <h1 className="text-3xl font-bold text-gray-900 dark:text-white mb-2">
                    {t('forum.title', { defaultValue: 'Community Forum' })}
                </h1>
                <p className="text-gray-600 dark:text-gray-400">
                    {t('forum.subtitle', { defaultValue: 'Connect with fellow learners, ask questions, and share knowledge' })}
                </p>
            </div>

            {/* Categories List */}
            <div className="space-y-4">
                {categories.length === 0 ? (
                    <div className="text-center py-12">
                        <MessageSquare className="mx-auto h-12 w-12 text-gray-400 mb-4" />
                        <p className="text-gray-600 dark:text-gray-400">
                            {t('forum.noCategories', { defaultValue: 'No forum categories available yet' })}
                        </p>
                    </div>
                ) : (
                    categories.map(category => (
                        <Link
                            key={category.id}
                            to={`/forum/category/${category.id}`}
                            className="block bg-white dark:bg-gray-800 rounded-xl shadow-sm hover:shadow-md transition-all duration-300 border border-gray-100 dark:border-gray-700 p-6 group"
                        >
                            <div className="flex items-start gap-4">
                                {/* Icon */}
                                <div className="flex-shrink-0">
                                    <div className="w-12 h-12 bg-primary/10 rounded-lg flex items-center justify-center group-hover:bg-primary/20 transition-colors">
                                        {category.icon ? (
                                            <span className="text-2xl">{category.icon}</span>
                                        ) : (
                                            <MessageSquare className="w-6 h-6 text-primary" />
                                        )}
                                    </div>
                                </div>

                                {/* Content */}
                                <div className="flex-1 min-w-0">
                                    <h3 className="text-lg font-semibold text-gray-900 dark:text-white mb-1 group-hover:text-primary transition-colors">
                                        {category.name}
                                    </h3>
                                    {category.description && (
                                        <p className="text-sm text-gray-600 dark:text-gray-400 line-clamp-2">
                                            {category.description}
                                        </p>
                                    )}
                                </div>

                                {/* Stats */}
                                <div className="flex-shrink-0 text-right">
                                    <div className="flex items-center gap-2 text-sm text-gray-600 dark:text-gray-400">
                                        <MessageSquare className="w-4 h-4" />
                                        <span>{category.threadCount}</span>
                                        <span className="hidden sm:inline">
                                            {t('forum.threads', { defaultValue: 'threads' })}
                                        </span>
                                    </div>
                                </div>
                            </div>
                        </Link>
                    ))
                )}
            </div>

            {/* Stats Section */}
            {categories.length > 0 && (
                <div className="mt-8 grid grid-cols-1 md:grid-cols-3 gap-4">
                    <div className="bg-gradient-to-br from-blue-50 to-blue-100 dark:from-blue-900/20 dark:to-blue-800/20 rounded-xl p-6">
                        <div className="flex items-center gap-3">
                            <div className="w-10 h-10 bg-blue-500 rounded-lg flex items-center justify-center">
                                <MessageSquare className="w-5 h-5 text-white" />
                            </div>
                            <div>
                                <p className="text-2xl font-bold text-gray-900 dark:text-white">
                                    {categories.reduce((sum, cat) => sum + cat.threadCount, 0)}
                                </p>
                                <p className="text-sm text-gray-600 dark:text-gray-400">
                                    {t('forum.totalThreads', { defaultValue: 'Total Discussions' })}
                                </p>
                            </div>
                        </div>
                    </div>

                    <div className="bg-gradient-to-br from-green-50 to-green-100 dark:from-green-900/20 dark:to-green-800/20 rounded-xl p-6">
                        <div className="flex items-center gap-3">
                            <div className="w-10 h-10 bg-green-500 rounded-lg flex items-center justify-center">
                                <Users className="w-5 h-5 text-white" />
                            </div>
                            <div>
                                <p className="text-2xl font-bold text-gray-900 dark:text-white">
                                    {categories.length}
                                </p>
                                <p className="text-sm text-gray-600 dark:text-gray-400">
                                    {t('forum.categories', { defaultValue: 'Categories' })}
                                </p>
                            </div>
                        </div>
                    </div>

                    <div className="bg-gradient-to-br from-purple-50 to-purple-100 dark:from-purple-900/20 dark:to-purple-800/20 rounded-xl p-6">
                        <div className="flex items-center gap-3">
                            <div className="w-10 h-10 bg-purple-500 rounded-lg flex items-center justify-center">
                                <TrendingUp className="w-5 h-5 text-white" />
                            </div>
                            <div>
                                <p className="text-2xl font-bold text-gray-900 dark:text-white">
                                    {t('forum.active', { defaultValue: 'Active' })}
                                </p>
                                <p className="text-sm text-gray-600 dark:text-gray-400">
                                    {t('forum.community', { defaultValue: 'Community' })}
                                </p>
                            </div>
                        </div>
                    </div>
                </div>
            )}
        </div>
    );
};

export default ForumPage;
