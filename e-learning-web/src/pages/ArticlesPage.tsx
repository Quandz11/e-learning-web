import React, { useState, useEffect, useMemo } from 'react';
import { Link } from 'react-router-dom';
import { useTranslation } from 'react-i18next';
import { articleApi, type ArticleListItem, type ArticleCategory } from '../services/articleApi';

const ArticlesPage: React.FC = () => {
    const { t } = useTranslation();
    const [articles, setArticles] = useState<ArticleListItem[]>([]);
    const [categories, setCategories] = useState<ArticleCategory[]>([]);
    const [selectedCategory, setSelectedCategory] = useState<string | null>(null);
    const [searchQuery, setSearchQuery] = useState('');
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState<string | null>(null);
    const [page, setPage] = useState(1);
    const [pageSize, setPageSize] = useState(10);
    const [total, setTotal] = useState(0);

    const totalPages = useMemo(() => Math.max(1, Math.ceil(total / pageSize)), [total, pageSize]);

    useEffect(() => {
        fetchCategories();
        fetchArticles();
        // eslint-disable-next-line react-hooks/exhaustive-deps
    }, [page, pageSize, selectedCategory, searchQuery]);

    const fetchCategories = async () => {
        try {
            const data = await articleApi.getCategories();
            setCategories(data);
        } catch (err) {
            console.error('Failed to load categories', err);
        }
    };

    const fetchArticles = async () => {
        try {
            setLoading(true);
            let result;
            
            if (searchQuery.trim()) {
                result = await articleApi.searchPaged(searchQuery, { page, pageSize });
            } else if (selectedCategory) {
                result = await articleApi.getByPagingCategory(selectedCategory, { page, pageSize });
            } else {
                result = await articleApi.getPaged({ page, pageSize });
            }

            setArticles(result.items);
            setTotal(result.total);
        } catch (err: any) {
            setError(err.message || 'Failed to load articles');
        } finally {
            setLoading(false);
        }
    };

    const handleCategoryFilter = (categoryId: string | null) => {
        setSelectedCategory(categoryId);
        setPage(1);
        setSearchQuery('');
    };

    const handleSearch = async (e: React.FormEvent) => {
        e.preventDefault();
        setPage(1);
    };

    const formatDate = (dateString: string) => {
        return new Date(dateString).toLocaleDateString('vi-VN', {
            year: 'numeric',
            month: 'long',
            day: 'numeric'
        });
    };

    return (
        <div className="min-h-screen">
            <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
                <div className="grid grid-cols-1 lg:grid-cols-4 gap-8">
                    {/* Sidebar */}
                    <aside className="lg:col-span-1">
                        {/* Search */}
                        <div className="bg-white dark:bg-gray-800 rounded-xl shadow-sm p-6 mb-6">
                            <h3 className="font-bold text-gray-900 dark:text-white mb-4">
                                {t('articles.search', { defaultValue: 'Tìm kiếm' })}
                            </h3>
                            <form onSubmit={handleSearch}>
                                <div className="relative">
                                    <input
                                        type="text"
                                        value={searchQuery}
                                        onChange={(e) => setSearchQuery(e.target.value)}
                                        placeholder={t('articles.searchPlaceholder', { defaultValue: 'Tìm kiếm bài viết...' })}
                                        className="w-full px-4 py-2 pr-10 border border-gray-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-700 text-gray-900 dark:text-white focus:ring-2 focus:ring-primary"
                                    />
                                    <button
                                        type="submit"
                                        className="absolute right-2 top-1/2 -translate-y-1/2 text-gray-400 hover:text-primary"
                                    >
                                        <span className="material-symbols-outlined">search</span>
                                    </button>
                                </div>
                            </form>
                        </div>

                        {/* Categories */}
                        <div className="bg-white dark:bg-gray-800 rounded-xl shadow-sm p-6">
                            <h3 className="font-bold text-gray-900 dark:text-white mb-4">
                                {t('articles.categories', { defaultValue: 'Danh mục' })}
                            </h3>
                            <ul className="space-y-2">
                                <li>
                                    <button
                                        onClick={() => handleCategoryFilter(null)}
                                        className={`w-full text-left px-3 py-2 rounded-lg transition-colors ${selectedCategory === null
                                            ? 'bg-primary text-white'
                                            : 'text-gray-700 dark:text-gray-300 hover:bg-gray-100 dark:hover:bg-gray-700'
                                            }`}
                                    >
                                        {t('articles.allCategories', { defaultValue: 'Tất cả' })}
                                    </button>
                                </li>
                                {categories.map((category) => (
                                    <li key={category.id}>
                                        <button
                                            onClick={() => handleCategoryFilter(category.id)}
                                            className={`w-full text-left px-3 py-2 rounded-lg transition-colors ${selectedCategory === category.id
                                                ? 'bg-primary text-white'
                                                : 'text-gray-700 dark:text-gray-300 hover:bg-gray-100 dark:hover:bg-gray-700'
                                                }`}
                                        >
                                            {category.name} ({category.articleCount})
                                        </button>
                                    </li>
                                ))}
                            </ul>
                        </div>
                    </aside>

                    {/* Main Content */}
                    <main className="lg:col-span-3">
                        {loading ? (
                            <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                                {[1, 2, 3, 4].map((i) => (
                                    <div key={i} className="bg-white dark:bg-gray-800 rounded-xl shadow-sm overflow-hidden animate-pulse">
                                        <div className="aspect-video bg-gray-200 dark:bg-gray-700" />
                                        <div className="p-6 space-y-3">
                                            <div className="h-4 bg-gray-200 dark:bg-gray-700 rounded w-3/4" />
                                            <div className="h-3 bg-gray-200 dark:bg-gray-700 rounded" />
                                            <div className="h-3 bg-gray-200 dark:bg-gray-700 rounded w-5/6" />
                                        </div>
                                    </div>
                                ))}
                            </div>
                        ) : error ? (
                            <div className="text-center py-12 text-red-500">{error}</div>
                        ) : articles.length === 0 ? (
                            <div className="text-center py-12 text-gray-500 dark:text-gray-400">
                                {t('articles.noArticles', { defaultValue: 'Chưa có bài viết nào' })}
                            </div>
                        ) : (
                            <>
                                <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                                    {articles.map((article) => (
                                        <Link
                                            key={article.id}
                                            to={`/articles/${article.slug}`}
                                            className="group bg-white dark:bg-gray-800 rounded-xl shadow-sm hover:shadow-xl transition-all duration-300 overflow-hidden"
                                        >
                                            {article.featuredImageUrl && (
                                                <div className="aspect-video overflow-hidden bg-gray-200 dark:bg-gray-700">
                                                    <img
                                                        src={article.featuredImageUrl}
                                                        alt={article.title}
                                                        className="w-full h-full object-cover group-hover:scale-105 transition-transform duration-300"
                                                    />
                                                </div>
                                            )}
                                            <div className="p-6">
                                                {article.categoryName && (
                                                    <span className="inline-block px-3 py-1 text-xs font-semibold text-primary bg-primary/10 rounded-full mb-3">
                                                        {article.categoryName}
                                                    </span>
                                                )}
                                                <h2 className="text-xl font-bold text-gray-900 dark:text-white mb-2 line-clamp-2 group-hover:text-primary transition-colors">
                                                    {article.title}
                                                </h2>
                                                {article.excerpt && (
                                                    <p className="text-gray-600 dark:text-gray-400 text-sm mb-4 line-clamp-3">
                                                        {article.excerpt}
                                                    </p>
                                                )}
                                                <div className="flex items-center justify-between text-sm text-gray-500 dark:text-gray-400">
                                                    <div className="flex items-center gap-2">
                                                        <span className="material-symbols-outlined text-sm">person</span>
                                                        <span>{article.authorName}</span>
                                                    </div>
                                                    <div className="flex items-center gap-4">
                                                        <div className="flex items-center gap-1">
                                                            <span className="material-symbols-outlined text-sm">visibility</span>
                                                            <span>{article.viewCount}</span>
                                                        </div>
                                                        <span>{formatDate(article.publishedAt || article.createdAt)}</span>
                                                    </div>
                                                </div>
                                            </div>
                                        </Link>
                                    ))}
                                </div>

                                {/* Pagination */}
                                {totalPages > 1 && (
                                    <div className="mt-12 flex flex-wrap items-center justify-between gap-4 rounded-lg border border-gray-200 dark:border-gray-700 p-6 bg-white dark:bg-gray-800">
                                        <div className="text-sm text-gray-600 dark:text-gray-400">
                                            {t('articles.pagination.showing', { defaultValue: 'Hiển thị' })} <span className="font-semibold">{(page - 1) * pageSize + 1}</span> {t('articles.pagination.to', { defaultValue: 'đến' })} <span className="font-semibold">{Math.min(page * pageSize, total)}</span> {t('articles.pagination.of', { defaultValue: 'trong' })} <span className="font-semibold">{total}</span>
                                        </div>
                                        <div className="flex flex-wrap items-center gap-2">
                                            <button
                                                onClick={() => setPage(Math.max(1, page - 1))}
                                                disabled={page === 1}
                                                className="rounded-lg border border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-700 px-3 py-2 text-sm text-gray-700 dark:text-gray-300 disabled:opacity-50 disabled:cursor-not-allowed hover:bg-gray-50 dark:hover:bg-gray-600 transition-colors"
                                            >
                                                {'<'} {t('articles.pagination.prev', { defaultValue: 'Trước' })}
                                            </button>

                                            <div className="flex gap-1">
                                                {Array.from({ length: totalPages }, (_, i) => i + 1).map((pageNum) => {
                                                    // Show first page, last page, current page, and adjacent pages
                                                    const isVisible =
                                                        pageNum === 1 ||
                                                        pageNum === totalPages ||
                                                        (pageNum >= page - 1 && pageNum <= page + 1);

                                                    if (!isVisible) {
                                                        if (pageNum === 2 || pageNum === totalPages - 1) {
                                                            return <span key={pageNum} className="px-2 py-1">...</span>;
                                                        }
                                                        return null;
                                                    }

                                                    return (
                                                        <button
                                                            key={pageNum}
                                                            onClick={() => setPage(pageNum)}
                                                            className={`rounded-lg px-3 py-2 text-sm transition-colors ${
                                                                page === pageNum
                                                                    ? 'bg-primary text-white'
                                                                    : 'border border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-700 text-gray-700 dark:text-gray-300 hover:bg-gray-50 dark:hover:bg-gray-600'
                                                            }`}
                                                        >
                                                            {pageNum}
                                                        </button>
                                                    );
                                                })}
                                            </div>

                                            <button
                                                onClick={() => setPage(Math.min(totalPages, page + 1))}
                                                disabled={page === totalPages}
                                                className="rounded-lg border border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-700 px-3 py-2 text-sm text-gray-700 dark:text-gray-300 disabled:opacity-50 disabled:cursor-not-allowed hover:bg-gray-50 dark:hover:bg-gray-600 transition-colors"
                                            >
                                                {t('articles.pagination.next', { defaultValue: 'Tiếp' })} {'>'}
                                            </button>
                                        </div>
                                    </div>
                                )}
                            </>
                        )}
                    </main>
                </div>
            </div>
        </div>
    );
};

export default ArticlesPage;
