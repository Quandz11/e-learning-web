import React, { useState, useEffect } from 'react';
import { useParams, Link } from 'react-router-dom';
import { useTranslation } from 'react-i18next';
import { articleApi, type Article } from '../services/articleApi';

const ArticleDetailPage: React.FC = () => {
    const { slug } = useParams<{ slug: string }>();
    const { t } = useTranslation();
    const [article, setArticle] = useState<Article | null>(null);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState<string | null>(null);

    useEffect(() => {
        if (slug) {
            fetchArticle(slug);
        }
    }, [slug]);

    const fetchArticle = async (articleSlug: string) => {
        try {
            setLoading(true);
            const data = await articleApi.getBySlug(articleSlug);
            setArticle(data);
        } catch (err: any) {
            setError(err.message || 'Failed to load article');
        } finally {
            setLoading(false);
        }
    };

    const formatDate = (dateString: string) => {
        return new Date(dateString).toLocaleDateString('vi-VN', {
            year: 'numeric',
            month: 'long',
            day: 'numeric',
            hour: '2-digit',
            minute: '2-digit'
        });
    };

    if (loading) {
        return (
            <div className="min-h-screen bg-background-light dark:bg-background-dark">
                <div className="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 py-12">
                    <div className="animate-pulse space-y-6">
                        <div className="h-8 bg-gray-200 dark:bg-gray-700 rounded w-3/4" />
                        <div className="h-4 bg-gray-200 dark:bg-gray-700 rounded w-1/4" />
                        <div className="aspect-video bg-gray-200 dark:bg-gray-700 rounded" />
                        <div className="space-y-3">
                            <div className="h-4 bg-gray-200 dark:bg-gray-700 rounded" />
                            <div className="h-4 bg-gray-200 dark:bg-gray-700 rounded" />
                            <div className="h-4 bg-gray-200 dark:bg-gray-700 rounded w-5/6" />
                        </div>
                    </div>
                </div>
            </div>
        );
    }

    if (error || !article) {
        return (
            <div className="min-h-screen bg-background-light dark:bg-background-dark flex items-center justify-center">
                <div className="text-center">
                    <h1 className="text-4xl font-bold text-gray-900 dark:text-white mb-4">
                        {t('articles.notFound', { defaultValue: 'Bài viết không tồn tại' })}
                    </h1>
                    <p className="text-gray-600 dark:text-gray-400 mb-6">{error}</p>
                    <Link
                        to="/articles"
                        className="inline-block px-6 py-3 bg-primary text-white rounded-lg hover:bg-primary/90 transition-colors"
                    >
                        {t('articles.backToList', { defaultValue: 'Quay lại danh sách' })}
                    </Link>
                </div>
            </div>
        );
    }

    return (
        <div className="min-h-screen">
            {/* Article Content */}
            <article className="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 py-12">
                {/* Header */}
                <header className="mb-8">
                    {article.categoryName && (
                        <span className="inline-block px-3 py-1 text-sm font-semibold text-primary bg-primary/10 rounded-full mb-4">
                            {article.categoryName}
                        </span>
                    )}
                    <h1 className="text-4xl md:text-5xl font-bold text-gray-900 dark:text-white mb-6">
                        {article.title}
                    </h1>

                    {/* Meta info */}
                    <div className="flex flex-wrap items-center gap-4 text-gray-600 dark:text-gray-400 text-sm">
                        <div className="flex items-center gap-2">
                            <span className="material-symbols-outlined text-lg">person</span>
                            <span>{article.authorName}</span>
                        </div>
                        <div className="flex items-center gap-2">
                            <span className="material-symbols-outlined text-lg">schedule</span>
                            <span>{formatDate(article.publishedAt || article.createdAt)}</span>
                        </div>
                        <div className="flex items-center gap-2">
                            <span className="material-symbols-outlined text-lg">visibility</span>
                            <span>{article.viewCount} {t('articles.views', { defaultValue: 'lượt xem' })}</span>
                        </div>
                    </div>
                </header>

                {/* Featured Image */}
                {article.featuredImageUrl && (
                    <div className="mb-8 rounded-xl overflow-hidden">
                        <img
                            src={article.featuredImageUrl}
                            alt={article.title}
                            className="w-full h-auto"
                        />
                    </div>
                )}

                {/* Excerpt */}
                {article.excerpt && (
                    <div className="mb-8 p-6 bg-gray-50 dark:bg-gray-800 border-l-4 border-primary rounded-lg">
                        <p className="text-lg text-gray-700 dark:text-gray-300 italic">
                            {article.excerpt}
                        </p>
                    </div>
                )}

                {/* Content */}
                <div
                    className="prose prose-lg dark:prose-invert max-w-none
            prose-headings:text-gray-900 dark:prose-headings:text-white
            prose-p:text-gray-700 dark:prose-p:text-gray-300
            prose-a:text-primary hover:prose-a:text-primary/80
            prose-strong:text-gray-900 dark:prose-strong:text-white
            prose-code:text-primary prose-code:bg-gray-100 dark:prose-code:bg-gray-800
            prose-pre:bg-gray-900 prose-pre:text-gray-100
            prose-img:rounded-xl prose-img:shadow-lg"
                    dangerouslySetInnerHTML={{ __html: article.content }}
                />

                {/* Footer */}
                <footer className="mt-12 pt-8 border-t border-gray-200 dark:border-gray-700">
                    <div className="flex items-center justify-between">
                        <Link
                            to="/articles"
                            className="flex items-center gap-2 px-6 py-3 bg-gray-100 dark:bg-gray-800 text-gray-700 dark:text-gray-300 rounded-lg hover:bg-gray-200 dark:hover:bg-gray-700 transition-colors"
                        >
                            <span className="material-symbols-outlined">arrow_back</span>
                            <span>{t('articles.backToList', { defaultValue: 'Quay lại danh sách' })}</span>
                        </Link>

                        {/* Share buttons (optional) */}
                        <div className="flex items-center gap-2">
                            <span className="text-sm text-gray-600 dark:text-gray-400 mr-2">
                                {t('articles.share', { defaultValue: 'Chia sẻ:' })}
                            </span>
                            <button
                                onClick={() => {
                                    navigator.clipboard.writeText(window.location.href);
                                    alert(t('articles.linkCopied', { defaultValue: 'Đã sao chép link!' }));
                                }}
                                className="p-2 bg-gray-100 dark:bg-gray-800 text-gray-700 dark:text-gray-300 rounded-lg hover:bg-gray-200 dark:hover:bg-gray-700 transition-colors"
                                title={t('articles.copyLink', { defaultValue: 'Sao chép link' })}
                            >
                                <span className="material-symbols-outlined text-lg">link</span>
                            </button>
                        </div>
                    </div>
                </footer>
            </article>
        </div>
    );
};

export default ArticleDetailPage;
