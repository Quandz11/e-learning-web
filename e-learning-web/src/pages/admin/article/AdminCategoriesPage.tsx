import React, { useState, useEffect } from 'react';
import { useTranslation } from 'react-i18next';
import { articleApi, type ArticleCategory } from '../../../services/articleApi';
import CategoryFormModal from './components/CategoryFormModal';
import AdminLayout from '../../../components/admin/AdminLayout';

const AdminCategoriesPage: React.FC = () => {
    const { t } = useTranslation();
    const [categories, setCategories] = useState<ArticleCategory[]>([]);
    const [loading, setLoading] = useState(true);
    const [isModalOpen, setIsModalOpen] = useState(false);
    const [editingCategory, setEditingCategory] = useState<string | null>(null);

    useEffect(() => {
        fetchCategories();
    }, []);

    const fetchCategories = async () => {
        try {
            setLoading(true);
            const data = await articleApi.getCategories();
            setCategories(data.sort((a, b) => a.displayOrder - b.displayOrder));
        } catch (err) {
            console.error('Failed to load categories', err);
        } finally {
            setLoading(false);
        }
    };

    const handleDelete = async (id: string) => {
        const category = categories.find(c => c.id === id);
        if (!confirm(t('admin.categories.confirmDelete', {
            defaultValue: `Bạn có chắc muốn xóa danh mục "${category?.name}"?`
        }))) {
            return;
        }

        try {
            await articleApi.deleteCategory(id);
            await fetchCategories();
        } catch (err) {
            console.error('Failed to delete category', err);
            alert(t('admin.categories.deleteFailed', { defaultValue: 'Xóa danh mục thất bại' }));
        }
    };

    const handleEdit = (id: string) => {
        setEditingCategory(id);
        setIsModalOpen(true);
    };

    const handleCreate = () => {
        setEditingCategory(null);
        setIsModalOpen(true);
    };

    const handleModalClose = () => {
        setIsModalOpen(false);
        setEditingCategory(null);
        fetchCategories();
    };

    return (
        <AdminLayout>
            {/* Header */}
            <div className="mb-6 flex items-center justify-between">
                <div>
                    <h1 className="text-2xl font-bold text-slate-900 dark:text-white">
                        {t('admin.categories.title', { defaultValue: 'Quản lý Danh mục' })}
                    </h1>
                    <p className="text-sm text-slate-500 dark:text-slate-400">
                        {t('admin.categories.subtitle', { defaultValue: 'Quản lý danh mục bài viết' })}
                    </p>
                </div>
                <button
                    onClick={handleCreate}
                    className="flex items-center gap-2 px-6 py-2.5 bg-dashboard-primary text-white font-medium rounded-lg hover:bg-dashboard-primary-dark transition-colors shadow-dashboard-sm"
                >
                    <span className="material-symbols-outlined text-[20px]">add</span>
                    <span>{t('admin.categories.createNew', { defaultValue: 'Tạo danh mục mới' })}</span>
                </button>
            </div>

            {/* Table */}
            <div className="rounded-2xl border border-white/60 bg-white/90 shadow-sm shadow-slate-200 backdrop-blur dark:border-slate-800 dark:bg-dashboard-surface-dark overflow-hidden">
                {loading ? (
                    <div className="p-8 text-center text-slate-500 dark:text-slate-400">
                        {t('common.loading', { defaultValue: 'Đang tải...' })}
                    </div>
                ) : categories.length === 0 ? (
                    <div className="p-8 text-center text-slate-500 dark:text-slate-400">
                        {t('admin.categories.noCategories', { defaultValue: 'Chưa có danh mục nào' })}
                    </div>
                ) : (
                    <div className="overflow-x-auto">
                        <table className="w-full">
                            <thead className="bg-slate-50 dark:bg-gray-900/50 border-b border-slate-200 dark:border-gray-700">
                                <tr>
                                    <th className="px-6 py-3 text-left text-xs font-medium text-slate-500 dark:text-slate-400 uppercase tracking-wider">
                                        {t('admin.categories.table.name', { defaultValue: 'Tên danh mục' })}
                                    </th>
                                    <th className="px-6 py-3 text-left text-xs font-medium text-slate-500 dark:text-slate-400 uppercase tracking-wider">
                                        {t('admin.categories.table.slug', { defaultValue: 'Slug' })}
                                    </th>
                                    <th className="px-6 py-3 text-left text-xs font-medium text-slate-500 dark:text-slate-400 uppercase tracking-wider">
                                        {t('admin.categories.table.articles', { defaultValue: 'Số bài viết' })}
                                    </th>
                                    <th className="px-6 py-3 text-left text-xs font-medium text-slate-500 dark:text-slate-400 uppercase tracking-wider">
                                        {t('admin.categories.table.order', { defaultValue: 'Thứ tự' })}
                                    </th>
                                    <th className="px-6 py-3 text-left text-xs font-medium text-slate-500 dark:text-slate-400 uppercase tracking-wider">
                                        {t('admin.categories.table.status', { defaultValue: 'Trạng thái' })}
                                    </th>
                                    <th className="px-6 py-3 text-right text-xs font-medium text-slate-500 dark:text-slate-400 uppercase tracking-wider">
                                        {t('admin.categories.table.actions', { defaultValue: 'Thao tác' })}
                                    </th>
                                </tr>
                            </thead>
                            <tbody className="divide-y divide-slate-200 dark:divide-gray-700">
                                {categories.map((category) => (
                                    <tr key={category.id} className="hover:bg-slate-50 dark:hover:bg-gray-800/50 transition-colors">
                                        <td className="px-6 py-4">
                                            <div className="font-medium text-slate-900 dark:text-white">
                                                {category.name}
                                            </div>
                                            {category.description && (
                                                <div className="text-sm text-slate-500 dark:text-slate-400 line-clamp-1">
                                                    {category.description}
                                                </div>
                                            )}
                                        </td>
                                        <td className="px-6 py-4 text-sm text-slate-600 dark:text-slate-300 font-mono">
                                            {category.slug}
                                        </td>
                                        <td className="px-6 py-4 text-sm text-slate-900 dark:text-white">
                                            {category.articleCount}
                                        </td>
                                        <td className="px-6 py-4 text-sm text-slate-900 dark:text-white">
                                            {category.displayOrder}
                                        </td>
                                        <td className="px-6 py-4">
                                            <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${category.isActive
                                                ? 'bg-green-100 text-green-800 dark:bg-green-900/30 dark:text-green-400'
                                                : 'bg-gray-100 text-gray-800 dark:bg-gray-900/30 dark:text-gray-400'
                                                }`}>
                                                {category.isActive
                                                    ? t('admin.categories.active', { defaultValue: 'Kích hoạt' })
                                                    : t('admin.categories.inactive', { defaultValue: 'Tắt' })
                                                }
                                            </span>
                                        </td>
                                        <td className="px-6 py-4 text-right">
                                            <div className="flex items-center justify-end gap-2">
                                                <button
                                                    onClick={() => handleEdit(category.id)}
                                                    className="p-2 text-dashboard-primary hover:bg-dashboard-primary/10 rounded-lg transition-colors"
                                                    title={t('common.edit', { defaultValue: 'Sửa' })}
                                                >
                                                    <span className="material-symbols-outlined text-lg">edit</span>
                                                </button>
                                                <button
                                                    onClick={() => handleDelete(category.id)}
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
                <CategoryFormModal
                    categoryId={editingCategory}
                    onClose={handleModalClose}
                />
            )}
        </AdminLayout>
    );
};

export default AdminCategoriesPage;
