import React, { useState, useEffect } from 'react';
import { useTranslation } from 'react-i18next';
import { articleApi, type ArticleCategory, type CreateArticleDto, type UpdateArticleDto } from '../../../../services/articleApi';
import ImageUploadButton from '../../../../components/common/ImageUploadButton';

interface ArticleFormModalProps {
    articleId: string | null;
    categories: ArticleCategory[];
    onClose: () => void;
}

const ArticleFormModal: React.FC<ArticleFormModalProps> = ({ articleId, categories, onClose }) => {
    const { t } = useTranslation();
    const [loading, setLoading] = useState(false);
    const [formData, setFormData] = useState({
        title: '',
        slug: '',
        content: '',
        excerpt: '',
        featuredImageUrl: '',
        categoryId: '',
        isPublished: false,
        metaDescription: '',
        metaKeywords: ''
    });

    useEffect(() => {
        if (articleId) {
            fetchArticle();
        }
    }, [articleId]);

    const fetchArticle = async () => {
        try {
            setLoading(true);
            const article = await articleApi.getById(articleId!);
            setFormData({
                title: article.title,
                slug: article.slug,
                content: article.content,
                excerpt: article.excerpt || '',
                featuredImageUrl: article.featuredImageUrl || '',
                categoryId: article.categoryId || '',
                isPublished: article.isPublished,
                metaDescription: article.metaDescription || '',
                metaKeywords: article.metaKeywords || ''
            });
        } catch (err) {
            console.error('Failed to load article', err);
        } finally {
            setLoading(false);
        }
    };

    const generateSlug = (title: string) => {
        return title
            .toLowerCase()
            .normalize('NFD')
            .replace(/[\u0300-\u036f]/g, '')
            .replace(/đ/g, 'd')
            .replace(/[^a-z0-9\s-]/g, '')
            .replace(/\s+/g, '-')
            .replace(/-+/g, '-')
            .trim();
    };

    const handleTitleChange = (title: string) => {
        setFormData(prev => ({
            ...prev,
            title,
            slug: generateSlug(title)
        }));
    };

    const handleSubmit = async (e: React.FormEvent) => {
        e.preventDefault();

        try {
            setLoading(true);

            const dto: CreateArticleDto | UpdateArticleDto = {
                title: formData.title,
                slug: formData.slug,
                content: formData.content,
                excerpt: formData.excerpt || undefined,
                featuredImageUrl: formData.featuredImageUrl || undefined,
                categoryId: formData.categoryId || undefined,
                isPublished: formData.isPublished,
                metaDescription: formData.metaDescription || undefined,
                metaKeywords: formData.metaKeywords || undefined
            };

            if (articleId) {
                await articleApi.update(articleId, dto);
            } else {
                await articleApi.create(dto);
            }

            onClose();
        } catch (err) {
            console.error('Failed to save article', err);
            alert(t('admin.articles.saveFailed', { defaultValue: 'Lưu bài viết thất bại' }));
        } finally {
            setLoading(false);
        }
    };

    return (
        <div className="fixed inset-0 bg-black/50 backdrop-blur-sm flex items-center justify-center z-50 p-4">
            <div className="bg-white dark:bg-dashboard-surface-dark rounded-2xl shadow-dashboard-xl w-full max-w-4xl max-h-[90vh] overflow-hidden flex flex-col border border-slate-200 dark:border-slate-700">
                {/* Header */}
                <div className="px-6 py-4 border-b border-slate-200 dark:border-slate-700 flex items-center justify-between bg-slate-50 dark:bg-gray-900/50">
                    <h2 className="text-2xl font-bold text-slate-900 dark:text-white">
                        {articleId
                            ? t('admin.articles.editArticle', { defaultValue: 'Sửa bài viết' })
                            : t('admin.articles.createArticle', { defaultValue: 'Tạo bài viết mới' })
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
                <form onSubmit={handleSubmit} className="flex-1 overflow-y-auto p-6">
                    <div className="space-y-6">
                        {/* Title */}
                        <div>
                            <label className="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-2">
                                {t('admin.articles.form.title', { defaultValue: 'Tiêu đề' })} <span className="text-red-500">*</span>
                            </label>
                            <input
                                type="text"
                                value={formData.title}
                                onChange={(e) => handleTitleChange(e.target.value)}
                                required
                                className="w-full px-4 py-2.5 border border-slate-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-700 text-slate-900 dark:text-white placeholder-slate-400 focus:ring-2 focus:ring-dashboard-primary focus:border-dashboard-primary transition-colors"
                            />
                        </div>

                        {/* Slug */}
                        <div>
                            <label className="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-2">
                                {t('admin.articles.form.slug', { defaultValue: 'Slug (URL)' })} <span className="text-red-500">*</span>
                            </label>
                            <input
                                type="text"
                                value={formData.slug}
                                onChange={(e) => setFormData(prev => ({ ...prev, slug: e.target.value }))}
                                required
                                className="w-full px-4 py-2.5 border border-slate-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-700 text-slate-900 dark:text-white placeholder-slate-400 focus:ring-2 focus:ring-dashboard-primary focus:border-dashboard-primary transition-colors"
                            />
                            <p className="mt-1 text-sm text-slate-500 dark:text-slate-400">
                                {t('admin.articles.form.slugHint', { defaultValue: 'Tự động tạo từ tiêu đề' })}
                            </p>
                        </div>

                        {/* Category */}
                        <div>
                            <label className="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-2">
                                {t('admin.articles.form.category', { defaultValue: 'Danh mục' })}
                            </label>
                            <select
                                value={formData.categoryId}
                                onChange={(e) => setFormData(prev => ({ ...prev, categoryId: e.target.value }))}
                                className="w-full px-4 py-2.5 border border-slate-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-700 text-slate-900 dark:text-white focus:ring-2 focus:ring-dashboard-primary focus:border-dashboard-primary transition-colors"
                            >
                                <option value="">{t('admin.articles.form.selectCategory', { defaultValue: 'Chọn danh mục' })}</option>
                                {categories.map(cat => (
                                    <option key={cat.id} value={cat.id}>{cat.name}</option>
                                ))}
                            </select>
                        </div>

                        {/* Featured Image Upload */}
                        <div>
                            <ImageUploadButton
                                label={t('admin.articles.form.featuredImage', { defaultValue: 'Ảnh đại diện' })}
                                currentImageUrl={formData.featuredImageUrl}
                                onImageChange={(url) => setFormData(prev => ({ ...prev, featuredImageUrl: url }))}
                                onUpload={async (file) => {
                                    const result = await articleApi.uploadArticleContentImage(file);
                                    return result.url;
                                }}
                            />
                        </div>

                        {/* Excerpt */}
                        <div>
                            <label className="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-2">
                                {t('admin.articles.form.excerpt', { defaultValue: 'Tóm tắt' })}
                            </label>
                            <textarea
                                value={formData.excerpt}
                                onChange={(e) => setFormData(prev => ({ ...prev, excerpt: e.target.value }))}
                                rows={3}
                                className="w-full px-4 py-2.5 border border-slate-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-700 text-slate-900 dark:text-white placeholder-slate-400 focus:ring-2 focus:ring-dashboard-primary focus:border-dashboard-primary transition-colors resize-none"
                            />
                        </div>

                        {/* Content */}
                        <div>
                            <label className="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-2">
                                {t('admin.articles.form.content', { defaultValue: 'Nội dung' })} <span className="text-red-500">*</span>
                            </label>
                            <textarea
                                value={formData.content}
                                onChange={(e) => setFormData(prev => ({ ...prev, content: e.target.value }))}
                                required
                                rows={12}
                                placeholder={t('admin.articles.form.contentPlaceholder', { defaultValue: 'Nhập nội dung bài viết (hỗ trợ HTML)...' })}
                                className="w-full px-4 py-2.5 border border-slate-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-700 text-slate-900 dark:text-white placeholder-slate-400 focus:ring-2 focus:ring-dashboard-primary focus:border-dashboard-primary transition-colors font-mono text-sm resize-none"
                            />
                            <p className="mt-1 text-sm text-slate-500 dark:text-slate-400">
                                {t('admin.articles.form.contentHint', { defaultValue: 'Hỗ trợ HTML. Sử dụng thẻ <p>, <h2>, <h3>, <strong>, <em>, <ul>, <ol>, <li>, v.v.' })}
                            </p>
                        </div>

                        {/* SEO Fields */}
                        <div className="border-t border-slate-200 dark:border-slate-700 pt-6">
                            <h3 className="text-lg font-semibold text-slate-900 dark:text-white mb-4">
                                {t('admin.articles.form.seoSection', { defaultValue: 'SEO' })}
                            </h3>

                            <div className="space-y-4">
                                <div>
                                    <label className="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-2">
                                        {t('admin.articles.form.metaDescription', { defaultValue: 'Meta Description' })}
                                    </label>
                                    <textarea
                                        value={formData.metaDescription}
                                        onChange={(e) => setFormData(prev => ({ ...prev, metaDescription: e.target.value }))}
                                        rows={2}
                                        maxLength={160}
                                        className="w-full px-4 py-2.5 border border-slate-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-700 text-slate-900 dark:text-white placeholder-slate-400 focus:ring-2 focus:ring-dashboard-primary focus:border-dashboard-primary transition-colors resize-none"
                                    />
                                    <p className="mt-1 text-sm text-slate-500 dark:text-slate-400">
                                        {formData.metaDescription.length}/160
                                    </p>
                                </div>

                                <div>
                                    <label className="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-2">
                                        {t('admin.articles.form.metaKeywords', { defaultValue: 'Meta Keywords' })}
                                    </label>
                                    <input
                                        type="text"
                                        value={formData.metaKeywords}
                                        onChange={(e) => setFormData(prev => ({ ...prev, metaKeywords: e.target.value }))}
                                        placeholder={t('admin.articles.form.keywordsPlaceholder', { defaultValue: 'từ khóa 1, từ khóa 2, ...' })}
                                        className="w-full px-4 py-2.5 border border-slate-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-700 text-slate-900 dark:text-white placeholder-slate-400 focus:ring-2 focus:ring-dashboard-primary focus:border-dashboard-primary transition-colors"
                                    />
                                </div>
                            </div>
                        </div>

                        {/* Publish Status */}
                        <div className="flex items-center gap-3 p-4 bg-slate-50 dark:bg-gray-900/50 rounded-lg border border-slate-200 dark:border-slate-700">
                            <input
                                type="checkbox"
                                id="isPublished"
                                checked={formData.isPublished}
                                onChange={(e) => setFormData(prev => ({ ...prev, isPublished: e.target.checked }))}
                                className="w-5 h-5 text-dashboard-primary border-slate-300 dark:border-gray-600 rounded focus:ring-dashboard-primary"
                            />
                            <label htmlFor="isPublished" className="text-sm font-medium text-slate-900 dark:text-white cursor-pointer">
                                {t('admin.articles.form.publishNow', { defaultValue: 'Xuất bản ngay' })}
                            </label>
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

export default ArticleFormModal;
