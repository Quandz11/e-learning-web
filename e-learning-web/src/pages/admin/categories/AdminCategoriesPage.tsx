import React, { useEffect, useState } from 'react';
import { useTranslation } from 'react-i18next';
import { Link } from 'react-router-dom';
import AdminLayout from '../../../components/admin/AdminLayout';
import { categoryApi, type CategoryDto } from '../../../services/categoryApi';
import { toast } from 'react-hot-toast';

const AdminCategoriesPage: React.FC = () => {
    const { t } = useTranslation();
    const [categories, setCategories] = useState<CategoryDto[]>([]);
    const [loading, setLoading] = useState(true);

    useEffect(() => {
        fetchCategories();
    }, []);

    const fetchCategories = async () => {
        try {
            setLoading(true);
            const data = await categoryApi.getAll();
            setCategories(data);
        } catch (error) {
            console.error(error);
            toast.error(t('admin.lessonCategories.loadError', { defaultValue: 'Failed to load categories' }));
        } finally {
            setLoading(false);
        }
    };

    const handleDelete = async (id: string) => {
        if (!window.confirm(t('common.confirmDelete', { defaultValue: 'Are you sure?' }))) return;
        try {
            await categoryApi.delete(id);
            setCategories(categories.filter(c => c.id !== id));
            toast.success(t('common.deleteSuccess', { defaultValue: 'Deleted successfully' }));
        } catch (error) {
            console.error(error);
            toast.error(t('common.deleteError', { defaultValue: 'Failed to delete' }));
        }
    };

    return (
        <AdminLayout>
            <div className="mb-6 flex items-center justify-between">
                <div>
                    <h1 className="text-2xl font-bold text-slate-900 dark:text-white">
                        {t('admin.lessonCategories.title', { defaultValue: 'Lesson Categories' })}
                    </h1>
                    <p className="mt-1 text-sm text-slate-500 dark:text-slate-400">
                        {t('admin.lessonCategories.subtitle', { defaultValue: 'Manage lesson categories' })}
                    </p>
                </div>
                <Link
                    to="/admin/lesson-categories/new"
                    className="flex items-center gap-2 rounded-lg bg-dashboard-primary px-4 py-2 text-sm font-medium text-white transition-colors hover:bg-dashboard-primary-dark"
                >
                    <span className="material-symbols-outlined text-[20px]">add</span>
                    {t('admin.lessonCategories.create', { defaultValue: 'Create Category' })}
                </Link>
            </div>

            <div className="rounded-xl border border-slate-200 bg-white shadow-sm dark:border-slate-700 dark:bg-dashboard-surface-dark">
                <div className="overflow-x-auto">
                    <table className="w-full text-left text-sm">
                        <thead className="bg-slate-50 text-xs uppercase text-slate-500 dark:bg-slate-800/50 dark:text-slate-400">
                            <tr>
                                <th className="px-6 py-4 font-semibold">{t('admin.lessonCategories.table.name', { defaultValue: 'Name' })}</th>
                                <th className="px-6 py-4 font-semibold">{t('admin.lessonCategories.table.description', { defaultValue: 'Description' })}</th>
                                <th className="px-6 py-4 font-semibold">{t('admin.lessonCategories.table.order', { defaultValue: 'Order' })}</th>
                                <th className="px-6 py-4 font-semibold">{t('admin.lessonCategories.table.status', { defaultValue: 'Status' })}</th>
                                <th className="px-6 py-4 text-right font-semibold">{t('common.actions', { defaultValue: 'Actions' })}</th>
                            </tr>
                        </thead>
                        <tbody className="divide-y divide-slate-200 dark:divide-slate-700">
                            {loading ? (
                                <tr><td colSpan={5} className="p-8 text-center text-slate-500">{t('common.loading', { defaultValue: 'Loading...' })}</td></tr>
                            ) : categories.length === 0 ? (
                                <tr><td colSpan={5} className="p-8 text-center text-slate-500">{t('admin.lessonCategories.table.empty', { defaultValue: 'No categories found.' })}</td></tr>
                            ) : (
                                categories.map((category) => (
                                    <tr key={category.id} className="hover:bg-slate-50 dark:hover:bg-slate-800/50">
                                        <td className="px-6 py-4 font-medium text-slate-900 dark:text-white">
                                            {category.name}
                                        </td>
                                        <td className="px-6 py-4 text-slate-500 dark:text-slate-400">
                                            <div className="max-w-md truncate">{category.description || '-'}</div>
                                        </td>
                                        <td className="px-6 py-4 text-slate-500 dark:text-slate-400">
                                            {category.order}
                                        </td>
                                        <td className="px-6 py-4">
                                            <span className={`inline-flex rounded-full px-2 py-1 text-xs font-semibold ${category.isActive
                                                    ? 'bg-green-100 text-green-700 dark:bg-green-900/30 dark:text-green-400'
                                                    : 'bg-slate-100 text-slate-700 dark:bg-slate-800 dark:text-slate-400'
                                                }`}>
                                                {category.isActive ? t('admin.lessonCategories.status.active', { defaultValue: 'Active' }) : t('admin.lessonCategories.status.inactive', { defaultValue: 'Inactive' })}
                                            </span>
                                        </td>
                                        <td className="px-6 py-4 text-right">
                                            <div className="flex justify-end gap-2">
                                                <Link
                                                    to={`/admin/categories/${category.id}`}
                                                    className="rounded-lg p-2 text-slate-500 hover:bg-slate-100 hover:text-dashboard-primary dark:text-slate-400 dark:hover:bg-slate-800"
                                                    title={t('common.edit', { defaultValue: 'Edit' })}
                                                >
                                                    <span className="material-symbols-outlined text-[20px]">edit</span>
                                                </Link>
                                                <button
                                                    onClick={() => handleDelete(category.id)}
                                                    className="rounded-lg p-2 text-slate-500 hover:bg-red-50 hover:text-red-600 dark:text-slate-400 dark:hover:bg-red-900/20 dark:hover:text-red-400"
                                                    title={t('common.delete', { defaultValue: 'Delete' })}
                                                >
                                                    <span className="material-symbols-outlined text-[20px]">delete</span>
                                                </button>
                                            </div>
                                        </td>
                                    </tr>
                                ))
                            )}
                        </tbody>
                    </table>
                </div>
            </div>
        </AdminLayout>
    );
};

export default AdminCategoriesPage;
