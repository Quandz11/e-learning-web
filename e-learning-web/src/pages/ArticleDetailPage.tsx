import React, { useState, useEffect } from 'react';
import { useParams, Link } from 'react-router-dom';
import { useTranslation } from 'react-i18next';
import { articleApi, type Article, type ArticleListItem } from '../services/articleApi';
import { toast } from 'react-hot-toast';

const ArticleDetailPage: React.FC = () => {
    const { slug } = useParams<{ slug: string }>();
    const { t } = useTranslation();
    const [article, setArticle] = useState<Article | null>(null);
    const [relatedArticles, setRelatedArticles] = useState<ArticleListItem[]>([]);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState<string | null>(null);

    useEffect(() => {
        if (slug) {
            fetchArticle(slug);
        }
    }, [slug]);

    useEffect(() => {
        const handleMessage = (event: MessageEvent) => {
            if (event.data?.type === 'resize-iframe' && event.data?.id === slug) {
                const iframes = document.querySelectorAll('iframe[title="Article Content"]');
                iframes.forEach(iframe => {
                    (iframe as HTMLIFrameElement).style.height = `${event.data.height}px`;
                });
            }
        };
        window.addEventListener('message', handleMessage);
        return () => window.removeEventListener('message', handleMessage);
    }, [slug]);

    const fetchArticle = async (articleSlug: string) => {
        try {
            setLoading(true);
            const data = await articleApi.getBySlug(articleSlug);
            setArticle(data);

            // Fetch related articles (latest 3 excluding this one)
            try {
                // Determine if we should fetch by category or just all
                const allArticles = await articleApi.getAll();
                const filtered = allArticles
                    .filter(a => a.id !== data.id)
                    .slice(0, 3);
                setRelatedArticles(filtered);
            } catch (e) {
                console.error('Failed to fetch related articles', e);
            }

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

                {/* Content Sandboxed using iframe */}
                <div className="w-full relative min-h-[600px] border-none">
                    <iframe
                        title="Article Content"
                        className="w-full h-full min-h-[600px] border-none"
                        srcDoc={`
                            <!DOCTYPE html>
                            <html>
                            <head>
                                <meta charset="utf-8">
                                <meta name="viewport" content="width=device-width, initial-scale=1">
                                <script src="https://cdn.tailwindcss.com"></script>
                                <style>
                                    body { font-family: ui-sans-serif, system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif; padding: 0; line-height: 1.8; color: #374151; }
                                    @media (prefers-color-scheme: dark) {
                                        body { color: #d1d5db; background: transparent; }
                                    }
                                    /* Basic reset for raw html */
                                    img { max-width: 100%; height: auto; border-radius: 0.75rem; margin: 2rem 0; box-shadow: 0 10px 15px -3px rgba(0, 0, 0, 0.1); }
                                    a { color: #0284c7; text-decoration: none; }
                                    a:hover { color: #0369a1; text-decoration: underline; }
                                    h1, h2, h3, h4 { color: #111827; }
                                    @media (prefers-color-scheme: dark) {
                                        h1, h2, h3, h4 { color: #f9fafb; }
                                        a { color: #38bdf8; }
                                        a:hover { color: #7dd3fc; }
                                    }
                                </style>
                            </head>
                            <body>
                                <div class="prose prose-lg dark:prose-invert max-w-none">
                                    ${article.content}
                                </div>
                                <script>
                                    // Auto-resize iframe height based on content
                                    const resizeIframe = () => {
                                        const height = document.documentElement.scrollHeight || document.body.scrollHeight;
                                        window.parent.postMessage({ type: 'resize-iframe', id: '${article.slug}', height: height }, '*');
                                    };
                                    window.addEventListener('load', resizeIframe);
                                    new ResizeObserver(resizeIframe).observe(document.body);
                                </script>
                            </body>
                            </html>
                        `}
                    />
                </div>

                {/* Footer */}
                <footer className="mt-12 pt-8 border-t border-gray-200 dark:border-gray-700">
                    <div className="flex items-center justify-between gap-4">
                        {/* Left: Back */}
                        <div className="flex-1 flex justify-start">
                            <Link
                                to="/articles"
                                className="flex items-center gap-2 px-4 py-3 md:px-6 md:py-3 bg-gray-100 dark:bg-gray-800 text-gray-700 dark:text-gray-300 rounded-lg hover:bg-gray-200 dark:hover:bg-gray-700 transition-colors whitespace-nowrap"
                            >
                                <span className="material-symbols-outlined">arrow_back</span>
                                <span className="hidden sm:inline">{t('articles.backToList', { defaultValue: 'Quay lại danh sách' })}</span>
                            </Link>
                        </div>

                        {/* Center: Share */}
                        <div className="flex-1 flex justify-center items-center">
                            <button
                                onClick={() => {
                                    navigator.clipboard.writeText(window.location.href);
                                    toast.success(t('articles.linkCopied', { defaultValue: 'Đã sao chép link!' }));
                                }}
                                className="flex items-center gap-2 px-4 py-3 md:px-6 md:py-3 bg-gray-100 dark:bg-gray-800 text-gray-700 dark:text-gray-300 rounded-lg hover:bg-gray-200 dark:hover:bg-gray-700 transition-colors whitespace-nowrap"
                                title={t('articles.copyLink', { defaultValue: 'Sao chép link' })}
                            >
                                <span className="material-symbols-outlined text-lg">share</span>
                                <span className="font-medium text-sm hidden sm:inline">{t('articles.share', { defaultValue: 'Chia sẻ' })}</span>
                            </button>
                        </div>

                        {/* Right: Next */}
                        <div className="flex-1 flex justify-end">
                            {relatedArticles.length > 0 ? (
                                <Link
                                    to={`/articles/${relatedArticles[0].slug}`}
                                    className="flex items-center gap-2 px-4 py-3 md:px-6 md:py-3 bg-primary text-white rounded-lg hover:bg-primary-dark transition-colors whitespace-nowrap"
                                    title={relatedArticles[0].title}
                                >
                                    <span className="hidden sm:inline">{t('articles.nextArticle', { defaultValue: 'Bài viết tiếp theo' })}</span>
                                    <span className="material-symbols-outlined">arrow_forward</span>
                                </Link>
                            ) : (
                                <div className="w-full"></div>
                            )}
                        </div>
                    </div>
                </footer>

                {/* Related Articles Section */}
                {relatedArticles.length > 0 && (
                    <div className="mt-16 border-t border-gray-200 dark:border-gray-700 pt-12">
                        <h2 className="text-2xl font-bold text-gray-900 dark:text-white mb-8">
                            {t('articles.related', { defaultValue: 'Bài viết liên quan' })}
                        </h2>
                        <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
                            {relatedArticles.map((relArticle) => (
                                <Link
                                    key={relArticle.id}
                                    to={`/articles/${relArticle.slug}`}
                                    className="group bg-white dark:bg-gray-800 rounded-xl shadow-sm hover:shadow-xl transition-all duration-300 overflow-hidden flex flex-col h-full border border-gray-100 dark:border-gray-700"
                                >
                                    {relArticle.featuredImageUrl && (
                                        <div className="aspect-[16/10] overflow-hidden bg-gray-200 dark:bg-gray-700 shrink-0">
                                            <img
                                                src={relArticle.featuredImageUrl}
                                                alt={relArticle.title}
                                                className="w-full h-full object-cover group-hover:scale-105 transition-transform duration-300"
                                            />
                                        </div>
                                    )}
                                    <div className="p-5 flex flex-col flex-1">
                                        {relArticle.categoryName && (
                                            <span className="inline-block self-start px-2.5 py-1 text-[11px] font-semibold text-primary bg-primary/10 rounded-full mb-3">
                                                {relArticle.categoryName}
                                            </span>
                                        )}
                                        <h3 className="font-bold text-gray-900 dark:text-white mb-2 line-clamp-2 group-hover:text-primary transition-colors text-base">
                                            {relArticle.title}
                                        </h3>
                                        <div className="mt-auto pt-4 flex items-center justify-between text-[13px] text-gray-500 dark:text-gray-400">
                                            <span>{formatDate(relArticle.publishedAt || relArticle.createdAt)}</span>
                                            <div className="flex items-center gap-1">
                                                <span className="material-symbols-outlined text-[14px]">visibility</span>
                                                <span>{relArticle.viewCount}</span>
                                            </div>
                                        </div>
                                    </div>
                                </Link>
                            ))}
                        </div>
                    </div>
                )}
            </article>
        </div>
    );
};

export default ArticleDetailPage;
