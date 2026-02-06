import React, { useState, useEffect } from 'react';
import { useTranslation } from 'react-i18next';
import { articleApi, type CreateArticleCategoryDto } from '../../../../services/articleApi';

interface CategoryFormModalProps {
    categoryId: string | null;
    onClose: () => void;
}

const CategoryFormModal: React.FC<CategoryFormModalProps> = ({ categoryId, onClose }) => {
    const { t } = useTranslation();
    const [loading, setLoading] = useState(false);
    const [formData, setFormData] = useState({
        name: '',
        slug: '',
        description: '',
        displayOrder: 0
    });

    useEffect(() => {
        if (categoryId) {
            fetchCategory();
        }
    }, [categoryId]);

    const fetchCategory = async () => {
        try {
            setLoading(true);
            const categories = await articleApi.getCategories();
            const category = categories.find(c => c.id === categoryId);
            if (category) {
                setFormData({
                    name: category.name,
                    slug: category.slug,
                    description: category.description || '',
                    displayOrder: category.displayOrder
                });
            }
        } catch (err) {
            console.error('Failed to load category', err);
        } finally {
            setLoading(false);
        }
    };

    const generateSlug = (name: string) => {
        return name
            .toLowerCase()
            .normalize('NFD')
            .replace(/[\u0300-\u036f]/g, '')
            .replace(/đ/g, 'd')
            .replace(/[^a-z0-9\s-]/g, '')
            .replace(/\s+/g, '-')
            .replace(/-+/g, '-')
            .trim();
    };

    const handleNameChange = (name: string) => {
        setFormData(prev => ({
            ...prev,
            name,
            slug: generateSlug(name)
        }));
    };

    const handleSubmit = async (e: React.FormEvent) => {
        e.preventDefault();

        try {
            setLoading(true);

            const dto: CreateArticleCategoryDto = {
                name: formData.name,
                slug: formData.slug,
                description: formData.description || undefined,
                displayOrder: formData.displayOrder
            };

            if (categoryId) {
                await articleApi.updateCategory(categoryId, dto);
            } else {
                await articleApi.createCategory(dto);
            }

            onClose();
        } catch (err) {
            console.error('Failed to save category', err);
            alert(t('admin.categories.saveFailed', { defaultValue: 'Lưu danh mục thất bại' }));
        } finally {
            setLoading(false);
        }
    };

    return (
        <div className="fixed inset-0 bg-black/50 backdrop-blur-sm flex items-center justify-center z-50 p-4">
            <div className="bg-white dark:bg-dashboard-surface-dark rounded-2xl shadow-dashboard-xl w-full max-w-2xl overflow-hidden flex flex-col border border-slate-200 dark:border-slate-700">
                {/* Header */}
                <div className="px-6 py-4 border-b border-slate-200 dark:border-slate-700 flex items-center justify-between bg-slate-50 dark:bg-gray-900/50">
                    <h2 className="text-2xl font-bold text-slate-900 dark:text-white">
                        {categoryId
                            ? t('admin.categories.editCategory', { defaultValue: 'Sửa danh mục' })
                            : t('admin.categories.createCategory', { defaultValue: 'Tạo danh mục mới' })
                        }
                    </h2>
                    <button
                        onClick={onClose}
                        className="p-2 hover:bg-slate-200 dark:hover:bg-gray-800 rounded-lg transition-colors"
                    >
                        <span className="material-symbols-outlined">close</span>
                    </button>
                </div>

                {/* Form */}
                <form onSubmit={handleSubmit} className="p-6">
                    <div className="space-y-6">
                        {/* Name */}
                        <div>
                            <label className="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-2">
                                {t('admin.categories.form.name', { defaultValue: 'Tên danh mục' })} <span className="text-red-500">*</span>
                            </label>
                            <input
                                type="text"
                                value={formData.name}
                                onChange={(e) => handleNameChange(e.target.value)}
                                required
                                className="w-full px-4 py-2.5 border border-slate-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-700 text-slate-900 dark:text-white placeholder-slate-400 focus:ring-2 focus:ring-dashboard-primary focus:border-dashboard-primary transition-colors"
                            />
                        </div>

                        {/* Slug */}
                        <div>
                            <label className="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-2">
                                {t('admin.categories.form.slug', { defaultValue: 'Slug (URL)' })} <span className="text-red-500">*</span>
                            </label>
                            <input
                                type="text"
                                value={formData.slug}
                                onChange={(e) => setFormData(prev => ({ ...prev, slug: e.target.value }))}
                                required
                                className="w-full px-4 py-2.5 border border-slate-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-700 text-slate-900 dark:text-white placeholder-slate-400 focus:ring-2 focus:ring-dashboard-primary focus:border-dashboard-primary transition-colors"
                            />
                            <p className="mt-1 text-sm text-slate-500 dark:text-slate-400">
                                {t('admin.categories.form.slugHint', { defaultValue: 'Tự động tạo từ tên danh mục' })}
                            </p>
                        </div>

                        {/* Description */}
                        <div>
                            <label className="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-2">
                                {t('admin.categories.form.description', { defaultValue: 'Mô tả' })}
                            </label>
                            <textarea
                                value={formData.description}
                                onChange={(e) => setFormData(prev => ({ ...prev, description: e.target.value }))}
                                rows={3}
                                className="w-full px-4 py-2.5 border border-slate-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-700 text-slate-900 dark:text-white placeholder-slate-400 focus:ring-2 focus:ring-dashboard-primary focus:border-dashboard-primary transition-colors resize-none"
                            />
                        </div>

                        {/* Display Order */}
                        <div>
                            <label className="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-2">
                                {t('admin.categories.form.displayOrder', { defaultValue: 'Thứ tự hiển thị' })}
                            </label>
                            <input
                                type="number"
                                value={formData.displayOrder}
                                onChange={(e) => setFormData(prev => ({ ...prev, displayOrder: parseInt(e.target.value) || 0 }))}
                                min="0"
                                className="w-full px-4 py-2.5 border border-slate-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-700 text-slate-900 dark:text-white placeholder-slate-400 focus:ring-2 focus:ring-dashboard-primary focus:border-dashboard-primary transition-colors"
                            />
                            <p className="mt-1 text-sm text-slate-500 dark:text-slate-400">
                                {t('admin.categories.form.displayOrderHint', { defaultValue: 'Số nhỏ hơn sẽ hiển thị trước' })}
                            </p>
                        </div>
                    </div>
                </form>

                {/* Footer */}
                <div className="px-6 py-4 border-t border-slate-200 dark:border-slate-700 flex items-center justify-end gap-3 bg-slate-50 dark:bg-gray-900/50">
                    <button
                        type="button"
                        onClick={onClose}
                        disabled={loading}
                        className="px-6 py-2.5 border border-slate-300 dark:border-gray-600 text-slate-700 dark:text-slate-300 font-medium rounded-lg hover:bg-slate-100 dark:hover:bg-gray-800 transition-colors disabled:opacity-50"
                    >
                        {t('common.cancel', { defaultValue: 'Hủy' })}
                    </button>
                    <button
                        type="submit"
                        onClick={handleSubmit}
                        disabled={loading}
                        className="px-6 py-2.5 bg-dashboard-primary text-white font-medium rounded-lg hover:bg-dashboard-primary-dark transition-colors disabled:opacity-50 flex items-center gap-2 shadow-dashboard-sm"
                    >
                        {loading && (
                            <div className="w-4 h-4 border-2 border-white/30 border-t-white rounded-full animate-spin"></div>
                        )}
                        <span>{t('common.save', { defaultValue: 'Lưu' })}</span>
                    </button>
                </div>
            </div>
        </div>
    );
};

export default CategoryFormModal;
