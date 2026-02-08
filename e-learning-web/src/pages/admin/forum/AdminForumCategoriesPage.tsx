import React, { useEffect, useState } from 'react';
import { useTranslation } from 'react-i18next';
import AdminLayout from '../../../components/admin/AdminLayout';
import { forumApi, type ForumCategoryDto, type CreateForumCategoryRequest, type UpdateForumCategoryRequest } from '../../../services/forumApi';
import { toast } from 'react-hot-toast';

const AdminForumCategoriesPage: React.FC = () => {
    const { t } = useTranslation();
    const [categories, setCategories] = useState<ForumCategoryDto[]>([]);
    const [loading, setLoading] = useState(true);
    const [showModal, setShowModal] = useState(false);
    const [editingCategory, setEditingCategory] = useState<ForumCategoryDto | null>(null);
    const [formData, setFormData] = useState({
        name: '',
        description: '',
        icon: '',
        order: 0,
        isActive: true
    });

    useEffect(() => {
        fetchCategories();
    }, []);

    const fetchCategories = async () => {
        try {
            setLoading(true);
            const data = await forumApi.categories.getAll();
            setCategories(data);
        } catch (error) {
            console.error(error);
            toast.error(t('admin.forum.loadError', { defaultValue: 'Failed to load categories' }));
        } finally {
            setLoading(false);
        }
    };

    const handleOpenModal = (category?: ForumCategoryDto) => {
        if (category) {
            setEditingCategory(category);
            setFormData({
                name: category.name,
                description: category.description || '',
                icon: category.icon || '',
                order: category.order,
                isActive: category.isActive
            });
        } else {
            setEditingCategory(null);
            setFormData({
                name: '',
                description: '',
                icon: '',
                order: categories.length,
                isActive: true
            });
        }
        setShowModal(true);
    };

    const handleCloseModal = () => {
        setShowModal(false);
        setEditingCategory(null);
        setFormData({
            name: '',
            description: '',
            icon: '',
            order: 0,
            isActive: true
        });
    };

    const handleSubmit = async (e: React.FormEvent) => {
        e.preventDefault();
        try {
            if (editingCategory) {
                const request: UpdateForumCategoryRequest = {
                    name: formData.name,
                    description: formData.description || undefined,
                    icon: formData.icon || undefined,
                    order: formData.order,
                    isActive: formData.isActive
                };
                await forumApi.categories.update(editingCategory.id, request);
                toast.success(t('common.updateSuccess', { defaultValue: 'Updated successfully' }));
            } else {
                const request: CreateForumCategoryRequest = {
                    name: formData.name,
                    description: formData.description || undefined,
                    icon: formData.icon || undefined,
                    order: formData.order,
                    isActive: formData.isActive
                };
                await forumApi.categories.create(request);
                toast.success(t('common.createSuccess', { defaultValue: 'Created successfully' }));
            }
            handleCloseModal();
            fetchCategories();
        } catch (error) {
            console.error(error);
            toast.error(t('common.saveError', { defaultValue: 'Failed to save' }));
        }
    };

    const handleDelete = async (id: string) => {
        if (!window.confirm(t('common.confirmDelete', { defaultValue: 'Are you sure?' }))) return;
        try {
            await forumApi.categories.delete(id);
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
                        {t('admin.forum.title', { defaultValue: 'Forum Categories' })}
                    </h1>
                    <p className="mt-1 text-sm text-slate-500 dark:text-slate-400">
                        {t('admin.forum.subtitle', { defaultValue: 'Manage forum categories and discussions' })}
                    </p>
                </div>
                <button
                    onClick={() => handleOpenModal()}
                    className="flex items-center gap-2 rounded-lg bg-dashboard-primary px-4 py-2 text-sm font-medium text-white transition-colors hover:bg-dashboard-primary-dark"
                >
                    <span className="material-symbols-outlined text-[20px]">add</span>
                    {t('admin.forum.create', { defaultValue: 'Create Category' })}
                </button>
            </div>

            <div className="rounded-xl border border-slate-200 bg-white shadow-sm dark:border-slate-700 dark:bg-dashboard-surface-dark">
                <div className="overflow-x-auto">
                    <table className="w-full text-left text-sm">
                        <thead className="bg-slate-50 text-xs uppercase text-slate-500 dark:bg-slate-800/50 dark:text-slate-400">
                            <tr>
                                <th className="px-6 py-4 font-semibold">{t('admin.forum.table.icon', { defaultValue: 'Icon' })}</th>
                                <th className="px-6 py-4 font-semibold">{t('admin.forum.table.name', { defaultValue: 'Name' })}</th>
                                <th className="px-6 py-4 font-semibold">{t('admin.forum.table.description', { defaultValue: 'Description' })}</th>
                                <th className="px-6 py-4 font-semibold">{t('admin.forum.table.threads', { defaultValue: 'Threads' })}</th>
                                <th className="px-6 py-4 font-semibold">{t('admin.forum.table.order', { defaultValue: 'Order' })}</th>
                                <th className="px-6 py-4 font-semibold">{t('admin.forum.table.status', { defaultValue: 'Status' })}</th>
                                <th className="px-6 py-4 text-right font-semibold">{t('common.actions', { defaultValue: 'Actions' })}</th>
                            </tr>
                        </thead>
                        <tbody className="divide-y divide-slate-200 dark:divide-slate-700">
                            {loading ? (
                                <tr><td colSpan={7} className="p-8 text-center text-slate-500">{t('common.loading', { defaultValue: 'Loading...' })}</td></tr>
                            ) : categories.length === 0 ? (
                                <tr><td colSpan={7} className="p-8 text-center text-slate-500">{t('admin.forum.table.empty', { defaultValue: 'No categories found.' })}</td></tr>
                            ) : (
                                categories.map((category) => (
                                    <tr key={category.id} className="hover:bg-slate-50 dark:hover:bg-slate-800/50">
                                        <td className="px-6 py-4">
                                            {category.icon ? (
                                                <span className="text-2xl">{category.icon}</span>
                                            ) : (
                                                <span className="material-symbols-outlined text-slate-400">forum</span>
                                            )}
                                        </td>
                                        <td className="px-6 py-4">
                                            <span className="font-medium text-slate-900 dark:text-white">{category.name}</span>
                                        </td>
                                        <td className="px-6 py-4 text-slate-500 dark:text-slate-400">
                                            <div className="max-w-md truncate">{category.description || '-'}</div>
                                        </td>
                                        <td className="px-6 py-4 text-slate-500 dark:text-slate-400">
                                            {category.threadCount}
                                        </td>
                                        <td className="px-6 py-4 text-slate-500 dark:text-slate-400">
                                            {category.order}
                                        </td>
                                        <td className="px-6 py-4">
                                            <span className={`inline-flex rounded-full px-2 py-1 text-xs font-semibold ${category.isActive
                                                ? 'bg-green-100 text-green-700 dark:bg-green-900/30 dark:text-green-400'
                                                : 'bg-slate-100 text-slate-700 dark:bg-slate-800 dark:text-slate-400'
                                                }`}>
                                                {category.isActive ? t('admin.forum.status.active', { defaultValue: 'Active' }) : t('admin.forum.status.inactive', { defaultValue: 'Inactive' })}
                                            </span>
                                        </td>
                                        <td className="px-6 py-4 text-right">
                                            <div className="flex justify-end gap-2">
                                                <button
                                                    onClick={() => handleOpenModal(category)}
                                                    className="rounded-lg p-2 text-slate-500 hover:bg-slate-100 hover:text-dashboard-primary dark:text-slate-400 dark:hover:bg-slate-800"
                                                    title={t('common.edit', { defaultValue: 'Edit' })}
                                                >
                                                    <span className="material-symbols-outlined text-[20px]">edit</span>
                                                </button>
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

            {/* Modal */}
            {showModal && (
                <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50">
                    <div className="w-full max-w-md rounded-xl bg-white p-6 shadow-xl dark:bg-slate-800">
                        <h2 className="mb-4 text-xl font-bold text-slate-900 dark:text-white">
                            {editingCategory ? t('admin.forum.edit', { defaultValue: 'Edit Category' }) : t('admin.forum.create', { defaultValue: 'Create Category' })}
                        </h2>
                        <form onSubmit={handleSubmit} className="space-y-4">
                            <div>
                                <label className="mb-2 block text-sm font-medium text-slate-700 dark:text-slate-300">
                                    {t('admin.forum.form.name', { defaultValue: 'Name' })} <span className="text-red-500">*</span>
                                </label>
                                <input
                                    type="text"
                                    required
                                    className="w-full rounded-lg border border-slate-300 px-4 py-2 dark:border-slate-600 dark:bg-slate-700 dark:text-white"
                                    value={formData.name}
                                    onChange={e => setFormData({ ...formData, name: e.target.value })}
                                />
                            </div>
                            <div>
                                <label className="mb-2 block text-sm font-medium text-slate-700 dark:text-slate-300">
                                    {t('admin.forum.form.description', { defaultValue: 'Description' })}
                                </label>
                                <textarea
                                    className="w-full rounded-lg border border-slate-300 px-4 py-2 dark:border-slate-600 dark:bg-slate-700 dark:text-white"
                                    rows={3}
                                    value={formData.description}
                                    onChange={e => setFormData({ ...formData, description: e.target.value })}
                                />
                            </div>
                            <div>
                                <label className="mb-2 block text-sm font-medium text-slate-700 dark:text-slate-300">
                                    {t('admin.forum.form.icon', { defaultValue: 'Icon (Emoji)' })}
                                </label>
                                <input
                                    type="text"
                                    className="w-full rounded-lg border border-slate-300 px-4 py-2 dark:border-slate-600 dark:bg-slate-700 dark:text-white"
                                    value={formData.icon}
                                    onChange={e => setFormData({ ...formData, icon: e.target.value })}
                                    placeholder="📚"
                                />
                            </div>
                            <div>
                                <label className="mb-2 block text-sm font-medium text-slate-700 dark:text-slate-300">
                                    {t('admin.forum.form.order', { defaultValue: 'Order' })}
                                </label>
                                <input
                                    type="number"
                                    className="w-full rounded-lg border border-slate-300 px-4 py-2 dark:border-slate-600 dark:bg-slate-700 dark:text-white"
                                    value={formData.order}
                                    onChange={e => setFormData({ ...formData, order: parseInt(e.target.value) })}
                                />
                            </div>
                            <div className="flex items-center gap-2">
                                <input
                                    type="checkbox"
                                    id="isActive"
                                    checked={formData.isActive}
                                    onChange={e => setFormData({ ...formData, isActive: e.target.checked })}
                                    className="h-4 w-4 rounded border-slate-300 text-dashboard-primary focus:ring-dashboard-primary"
                                />
                                <label htmlFor="isActive" className="text-sm font-medium text-slate-700 dark:text-slate-300">
                                    {t('admin.forum.form.active', { defaultValue: 'Active' })}
                                </label>
                            </div>
                            <div className="flex justify-end gap-3 pt-4">
                                <button
                                    type="button"
                                    onClick={handleCloseModal}
                                    className="rounded-lg border border-slate-300 px-4 py-2 text-sm font-medium text-slate-700 hover:bg-slate-50 dark:border-slate-600 dark:text-slate-300 dark:hover:bg-slate-700"
                                >
                                    {t('common.cancel', { defaultValue: 'Cancel' })}
                                </button>
                                <button
                                    type="submit"
                                    className="rounded-lg bg-dashboard-primary px-4 py-2 text-sm font-medium text-white hover:bg-dashboard-primary-dark"
                                >
                                    {t('common.save', { defaultValue: 'Save' })}
                                </button>
                            </div>
                        </form>
                    </div>
                </div>
            )}
        </AdminLayout>
    );
};

export default AdminForumCategoriesPage;
