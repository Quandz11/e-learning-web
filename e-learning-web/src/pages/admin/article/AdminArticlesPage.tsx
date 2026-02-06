import React, { useState } from 'react';
import { useTranslation } from 'react-i18next';
import { articleApi, type ArticleListItem, type ArticleCategory } from '../../../services/articleApi';
import ArticleFormModal from './components/ArticleFormModal';
import AdminLayout from '../../../components/admin/AdminLayout';

const AdminArticlesPage: React.FC = () => {
    const { t } = useTranslation();
    const [articles, setArticles] = useState<ArticleListItem[]>([]);
    const [categories, setCategories] = useState<ArticleCategory[]>([]);
    const [loading, setLoading] = useState(true);
    const [searchQuery, setSearchQuery] = useState('');
    const [isModalOpen, setIsModalOpen] = useState(false);
    const [editingArticle, setEditingArticle] = useState<string | null>(null);

    React.useEffect(() => {
        fetchData();
    }, []);

    const fetchData = async () => {
        try {
            setLoading(true);
            const [articlesData, categoriesData] = await Promise.all([
                articleApi.getAllAdmin(),
                articleApi.getCategories()
            ]);
            setArticles(articlesData);
            setCategories(categoriesData);
        } catch (err) {
            console.error('Failed to load data', err);
        } finally {
            setLoading(false);
        }
    };

    const handleDelete = async (id: string) => {
        if (!confirm(t('admin.articles.confirmDelete', { defaultValue: 'Bạn có chắc muốn xóa bài viết này?' }))) {
            return;
        }

        try {
            await articleApi.delete(id);
            await fetchData();
        } catch (err) {
            console.error('Failed to delete article', err);
            alert(t('admin.articles.deleteFailed', { defaultValue: 'Xóa bài viết thất bại' }));
        }
    };

    const handleEdit = (id: string) => {
        setEditingArticle(id);
        setIsModalOpen(true);
    };

    const handleCreate = () => {
        setEditingArticle(null);
        setIsModalOpen(true);
    };

    const handleModalClose = () => {
        setIsModalOpen(false);
        setEditingArticle(null);
        fetchData();
    };

    const filteredArticles = articles.filter(article =>
        article.title.toLowerCase().includes(searchQuery.toLowerCase()) ||
        article.excerpt?.toLowerCase().includes(searchQuery.toLowerCase())
    );

    const formatDate = (dateString: string) => {
        return new Date(dateString).toLocaleDateString('vi-VN', {
            year: 'numeric',
            month: '2-digit',
            day: '2-digit',
            hour: '2-digit',
            minute: '2-digit'
        });
    };

    return (
        <AdminLayout>
            {/* Header */}
            <div className="mb-6 flex items-center justify-between">
                <div>
                    <h1 className="text-2xl font-bold text-slate-900 dark:text-white">
                        {t('admin.articles.title', { defaultValue: 'Quản lý Bài viết' })}
                    </h1>
                    <p className="text-sm text-slate-500 dark:text-slate-400">
                        {t('admin.articles.subtitle', { defaultValue: 'Quản lý tất cả bài viết trên hệ thống' })}
                    </p>
                </div>
            </div>

            {/* Actions Bar */}
            <div className="mb-6 flex flex-col sm:flex-row gap-4 justify-between">
                <div className="relative flex-1 max-w-md">
                    <span className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                        <span className="material-symbols-outlined text-slate-400">search</span>
                    </span>
                    <input
                        type="text"
                        value={searchQuery}
                        onChange={(e) => setSearchQuery(e.target.value)}
                        placeholder={t('admin.articles.searchPlaceholder', { defaultValue: 'Tìm kiếm bài viết...' })}
                        className="block w-full pl-10 pr-3 py-2.5 border border-slate-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-700 text-slate-900 dark:text-white placeholder-slate-400 focus:ring-2 focus:ring-dashboard-primary focus:border-dashboard-primary transition-colors sm:text-sm"
                    />
                </div>
                <button
                    onClick={handleCreate}
                    className="flex items-center gap-2 px-6 py-2.5 bg-dashboard-primary text-white font-medium rounded-lg hover:bg-dashboard-primary-dark transition-colors shadow-dashboard-sm"
                >
                    <span className="material-symbols-outlined text-[20px]">add</span>
                    <span>{t('admin.articles.createNew', { defaultValue: 'Tạo bài viết mới' })}</span>
                </button>
            </div>

            {/* Table */}
            <div className="rounded-2xl border border-white/60 bg-white/90 shadow-sm shadow-slate-200 backdrop-blur dark:border-slate-800 dark:bg-dashboard-surface-dark overflow-hidden">
                {loading ? (
                    <div className="p-8 text-center text-slate-500 dark:text-slate-400">
                        {t('common.loading', { defaultValue: 'Đang tải...' })}
                    </div>
                ) : filteredArticles.length === 0 ? (
                    <div className="p-8 text-center text-slate-500 dark:text-slate-400">
                        {t('admin.articles.noArticles', { defaultValue: 'Chưa có bài viết nào' })}
                    </div>
                ) : (
                    <div className="overflow-x-auto">
                        <table className="w-full">
                            <thead className="bg-slate-50 dark:bg-gray-900/50 border-b border-slate-200 dark:border-gray-700">
                                <tr>
                                    <th className="px-6 py-3 text-left text-xs font-medium text-slate-500 dark:text-slate-400 uppercase tracking-wider">
                                        {t('admin.articles.table.title', { defaultValue: 'Tiêu đề' })}
                                    </th>
                                    <th className="px-6 py-3 text-left text-xs font-medium text-slate-500 dark:text-slate-400 uppercase tracking-wider">
                                        {t('admin.articles.table.category', { defaultValue: 'Danh mục' })}
                                    </th>
                                    <th className="px-6 py-3 text-left text-xs font-medium text-slate-500 dark:text-slate-400 uppercase tracking-wider">
                                        {t('admin.articles.table.author', { defaultValue: 'Tác giả' })}
                                    </th>
                                    <th className="px-6 py-3 text-left text-xs font-medium text-slate-500 dark:text-slate-400 uppercase tracking-wider">
                                        {t('admin.articles.table.status', { defaultValue: 'Trạng thái' })}
                                    </th>
                                    <th className="px-6 py-3 text-left text-xs font-medium text-slate-500 dark:text-slate-400 uppercase tracking-wider">
                                        {t('admin.articles.table.views', { defaultValue: 'Lượt xem' })}
                                    </th>
                                    <th className="px-6 py-3 text-left text-xs font-medium text-slate-500 dark:text-slate-400 uppercase tracking-wider">
                                        {t('admin.articles.table.date', { defaultValue: 'Ngày tạo' })}
                                    </th>
                                    <th className="px-6 py-3 text-right text-xs font-medium text-slate-500 dark:text-slate-400 uppercase tracking-wider">
                                        {t('admin.articles.table.actions', { defaultValue: 'Thao tác' })}
                                    </th>
                                </tr>
                            </thead>
                            <tbody className="divide-y divide-slate-200 dark:divide-gray-700">
                                {filteredArticles.map((article) => (
                                    <tr key={article.id} className="hover:bg-slate-50 dark:hover:bg-gray-800/50 transition-colors">
                                        <td className="px-6 py-4">
                                            <div className="flex items-center gap-3">
                                                {article.featuredImageUrl && (
                                                    <img
                                                        src={article.featuredImageUrl}
                                                        alt={article.title}
                                                        className="w-12 h-12 rounded object-cover"
                                                    />
                                                )}
                                                <div>
                                                    <div className="font-medium text-slate-900 dark:text-white line-clamp-1">
                                                        {article.title}
                                                    </div>
                                                    {article.excerpt && (
                                                        <div className="text-sm text-slate-500 dark:text-slate-400 line-clamp-1">
                                                            {article.excerpt}
                                                        </div>
                                                    )}
                                                </div>
                                            </div>
                                        </td>
                                        <td className="px-6 py-4 text-sm text-slate-900 dark:text-white">
                                            {article.categoryName || '-'}
                                        </td>
                                        <td className="px-6 py-4 text-sm text-slate-900 dark:text-white">
                                            {article.authorName}
                                        </td>
                                        <td className="px-6 py-4">
                                            <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${article.isPublished
                                                    ? 'bg-green-100 text-green-800 dark:bg-green-900/30 dark:text-green-400'
                                                    : 'bg-yellow-100 text-yellow-800 dark:bg-yellow-900/30 dark:text-yellow-400'
                                                }`}>
                                                {article.isPublished
                                                    ? t('admin.articles.published', { defaultValue: 'Đã xuất bản' })
                                                    : t('admin.articles.draft', { defaultValue: 'Nháp' })
                                                }
                                            </span>
                                        </td>
                                        <td className="px-6 py-4 text-sm text-slate-900 dark:text-white">
                                            {article.viewCount}
                                        </td>
                                        <td className="px-6 py-4 text-sm text-slate-500 dark:text-slate-400">
                                            {formatDate(article.createdAt)}
                                        </td>
                                        <td className="px-6 py-4 text-right">
                                            <div className="flex items-center justify-end gap-2">
                                                <button
                                                    onClick={() => handleEdit(article.id)}
                                                    className="p-2 text-dashboard-primary hover:bg-dashboard-primary/10 rounded-lg transition-colors"
                                                    title={t('common.edit', { defaultValue: 'Sửa' })}
                                                >
                                                    <span className="material-symbols-outlined text-lg">edit</span>
                                                </button>
                                                <button
                                                    onClick={() => handleDelete(article.id)}
                                                    className="p-2 text-red-600 hover:bg-red-50 dark:hover:bg-red-900/20 rounded-lg transition-colors"
                                                    title={t('common.delete', { defaultValue: 'Xóa' })}
                                                >
                                                    <span className="material-symbols-outlined text-lg">delete</span>
                                                </button>
                                            </div>
                                        </td>
                                    </tr>
                                ))}
                            </tbody>
                        </table>
                    </div>
                )}
            </div>

            {/* Modal */}
            {isModalOpen && (
                <ArticleFormModal
                    articleId={editingArticle}
                    categories={categories}
                    onClose={handleModalClose}
                />
            )}
        </AdminLayout>
    );
};

export default AdminArticlesPage;
