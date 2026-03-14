import React, { useEffect, useState } from 'react';
import { useTranslation } from 'react-i18next';
import { useNavigate, useParams, Link } from 'react-router-dom';
import AdminLayout from '../../../components/admin/AdminLayout';
import { categoryApi, type CreateCategoryRequest } from '../../../services/categoryApi';
import { toast } from 'react-hot-toast';

const AdminCategoryEditorPage: React.FC = () => {
    const { t } = useTranslation();
    const navigate = useNavigate();
    const { id } = useParams<{ id: string }>();
    const isEditMode = !!id && id !== 'new';

    const [loading, setLoading] = useState(false);
    const [submitting, setSubmitting] = useState(false);

    const [formData, setFormData] = useState<CreateCategoryRequest>({
        name: '',
        description: '',
        order: 0,
        isActive: true,
    });

    useEffect(() => {
        if (isEditMode && id) {
            fetchCategory(id);
        }
    }, [isEditMode, id]);

    const fetchCategory = async (categoryId: string) => {
        try {
            setLoading(true);
            const data = await categoryApi.getById(categoryId);
            setFormData({
                name: data.name,
                description: data.description || '',
                order: data.order,
                isActive: data.isActive,
            });
        } catch (error) {
            console.error(error);
            toast.error(t('admin.lessonCategories.loadError', { defaultValue: 'Failed to load category' }));
            navigate('/admin/lesson-categories');
        } finally {
            setLoading(false);
        }
    };

    const handleSubmit = async (e: React.FormEvent) => {
        e.preventDefault();
        setSubmitting(true);
        try {
            if (isEditMode && id) {
                await categoryApi.update(id, formData);
                toast.success(t('common.updateSuccess', { defaultValue: 'Updated successfully' }));
            } else {
                await categoryApi.create(formData);
                toast.success(t('common.createSuccess', { defaultValue: 'Created successfully' }));
            }
            navigate('/admin/lesson-categories');
        } catch (error) {
            console.error(error);
            toast.error(t('common.error', { defaultValue: 'An error occurred' }));
        } finally {
            setSubmitting(false);
        }
    };

    if (loading) {
        return (
            <AdminLayout>
                <div className="p-8 text-center text-gray-500">{t('common.loading', { defaultValue: 'Loading...' })}</div>
            </AdminLayout>
        );
    }

    return (
        <AdminLayout>
            <div className="mx-auto max-w-3xl">
                <div className="mb-6 flex items-center justify-between">
                    <div>
                        <h1 className="text-2xl font-bold text-slate-900 dark:text-white">
                            {isEditMode ? t('admin.lessonCategories.edit', { defaultValue: 'Edit Category' }) : t('admin.lessonCategories.create', { defaultValue: 'Create Category' })}
                        </h1>
                    </div>
                    <Link
                        to="/admin/lesson-categories"
                        className="rounded-lg px-4 py-2 text-sm font-medium text-slate-600 hover:bg-slate-100 dark:text-slate-400 dark:hover:bg-slate-800"
                    >
                        {t('common.cancel', { defaultValue: 'Cancel' })}
                    </Link>
                </div>

                <form onSubmit={handleSubmit} className="space-y-6">
                    <div className="rounded-xl border border-slate-200 bg-white p-6 shadow-sm dark:border-slate-700 dark:bg-dashboard-surface-dark">
                        <div className="grid gap-6">
                            {/* Name */}
                            <div>
                                <label className="mb-2 block text-sm font-medium text-slate-700 dark:text-slate-300">
                                    {t('admin.lessonCategories.form.name', { defaultValue: 'Category Name' })} <span className="text-red-500">*</span>
                                </label>
                                <input
                                    type="text"
                                    required
                                    className="w-full rounded-lg border border-slate-300 px-4 py-2 dark:border-slate-600 dark:bg-slate-800 dark:text-white"
                                    value={formData.name}
                                    onChange={e => setFormData({ ...formData, name: e.target.value })}
                                    placeholder={t('admin.lessonCategories.form.namePlaceholder', { defaultValue: 'e.g. Ập luyện, Dinh dưỡng, Thiền...' })}
                                />
                            </div>

                            {/* Description */}
                            <div>
                                <label className="mb-2 block text-sm font-medium text-slate-700 dark:text-slate-300">
                                    {t('admin.lessonCategories.form.description', { defaultValue: 'Description' })}
                                </label>
                                <textarea
                                    rows={4}
                                    className="w-full rounded-lg border border-slate-300 px-4 py-2 dark:border-slate-600 dark:bg-slate-800 dark:text-white"
                                    value={formData.description}
                                    onChange={e => setFormData({ ...formData, description: e.target.value })}
                                    placeholder={t('admin.lessonCategories.form.descriptionPlaceholder', { defaultValue: 'Enter category description...' })}
                                />
                            </div>

                            {/* Order */}
                            <div>
                                <label className="mb-2 block text-sm font-medium text-slate-700 dark:text-slate-300">
                                    {t('admin.lessonCategories.form.order', { defaultValue: 'Display Order' })} <span className="text-red-500">*</span>
                                </label>
                                <input
                                    type="number"
                                    required
                                    min="0"
                                    className="w-full rounded-lg border border-slate-300 px-4 py-2 dark:border-slate-600 dark:bg-slate-800 dark:text-white"
                                    value={formData.order}
                                    onChange={e => setFormData({ ...formData, order: parseInt(e.target.value) })}
                                    placeholder={t('admin.lessonCategories.form.orderPlaceholder', { defaultValue: 'e.g. 1, 2, 3...' })}
                                />
                            </div>

                            {/* Status */}
                            <div>
                                <label className="flex items-center gap-3">
                                    <input
                                        type="checkbox"
                                        checked={formData.isActive}
                                        onChange={e => setFormData({ ...formData, isActive: e.target.checked })}
                                        className="w-5 h-5 rounded border-slate-300 dark:border-slate-600"
                                    />
                                    <span className="text-sm font-medium text-slate-700 dark:text-slate-300">
                                        {t('admin.lessonCategories.form.isActive', { defaultValue: 'Active' })}
                                    </span>
                                </label>
                            </div>
                        </div>
                    </div>

                    {/* Form Actions */}
                    <div className="flex gap-3">
                        <button
                            type="submit"
                            disabled={submitting}
                            className="flex-1 rounded-lg bg-dashboard-primary px-4 py-2 text-sm font-medium text-white transition hover:bg-dashboard-primary-dark disabled:opacity-50"
                        >
                            {submitting ? t('common.saving', { defaultValue: 'Saving...' }) : (isEditMode ? t('common.update', { defaultValue: 'Update' }) : t('common.create', { defaultValue: 'Create' }))}
                        </button>
                        <Link
                            to="/admin/lesson-categories"
                            className="flex items-center justify-center rounded-lg border border-slate-300 px-4 py-2 text-sm font-medium text-slate-700 transition hover:bg-slate-50 dark:border-slate-600 dark:text-slate-300 dark:hover:bg-slate-800"
                        >
                            {t('common.cancel', { defaultValue: 'Cancel' })}
                        </Link>
                    </div>
                </form>
            </div>
        </AdminLayout>
    );
};

export default AdminCategoryEditorPage;
