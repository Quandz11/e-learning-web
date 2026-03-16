import React, { useState, useEffect } from 'react';
import { useNavigate, useParams, Link } from 'react-router-dom';
import { toast } from 'react-hot-toast';
import AdminLayout from '../../../components/admin/AdminLayout';
import ImageUploadButton from '../../../components/common/ImageUploadButton';
import ArticleRichEditor from './components/ArticleRichEditor';
import ArticlePreviewModal from './components/ArticlePreviewModal';
import { articleApi, type ArticleCategory } from '../../../services/articleApi';

const ArticleEditorPage: React.FC = () => {
    const navigate = useNavigate();
    const { id } = useParams<{ id: string }>();
    const isEditMode = !!id && id !== 'new';

    const [loading, setLoading] = useState(false);
    const [saving, setSaving] = useState(false);
    const [categories, setCategories] = useState<ArticleCategory[]>([]);
    const [showPreview, setShowPreview] = useState(false);
    const [titleFocused, setTitleFocused] = useState(false);

    const [formData, setFormData] = useState({
        title: '',
        slug: '',
        content: '',
        excerpt: '',
        featuredImageUrl: '',
        categoryId: '',
        isPublished: false,
        metaDescription: '',
        metaKeywords: '',
    });

    useEffect(() => {
        fetchCategories();
        if (isEditMode && id) {
            fetchArticle(id);
        }
    }, [isEditMode, id]);

    const fetchCategories = async () => {
        try {
            const data = await articleApi.getCategories();
            setCategories(data);
        } catch {
            console.error('Failed to load categories');
        }
    };

    const fetchArticle = async (articleId: string) => {
        try {
            setLoading(true);
            const article = await articleApi.getById(articleId);
            setFormData({
                title: article.title,
                slug: article.slug,
                content: article.content,
                excerpt: article.excerpt || '',
                featuredImageUrl: article.featuredImageUrl || '',
                categoryId: article.categoryId || '',
                isPublished: article.isPublished,
                metaDescription: article.metaDescription || '',
                metaKeywords: article.metaKeywords || '',
            });
        } catch {
            toast.error('Không thể tải bài viết');
            navigate('/admin/articles');
        } finally {
            setLoading(false);
        }
    };

    const generateSlug = (title: string) =>
        title
            .toLowerCase()
            .normalize('NFD')
            .replace(/[\u0300-\u036f]/g, '')
            .replace(/đ/g, 'd')
            .replace(/[^a-z0-9\s-]/g, '')
            .replace(/\s+/g, '-')
            .replace(/-+/g, '-')
            .trim();

    const handleTitleChange = (title: string) => {
        setFormData(prev => ({
            ...prev,
            title,
            // Only auto-generate slug if not in edit mode (or slug hasn't been manually changed)
            slug: !isEditMode ? generateSlug(title) : prev.slug,
        }));
    };

    const handleSave = async (publish?: boolean) => {
        if (!formData.title.trim()) {
            toast.error('Vui lòng nhập tiêu đề');
            return;
        }
        if (!formData.content.trim() || formData.content === '<p><br></p>') {
            toast.error('Vui lòng nhập nội dung');
            return;
        }

        const dto = {
            title: formData.title,
            slug: formData.slug || generateSlug(formData.title),
            content: formData.content,
            excerpt: formData.excerpt || undefined,
            featuredImageUrl: formData.featuredImageUrl || undefined,
            categoryId: formData.categoryId || undefined,   // must be undefined, not ""
            isPublished: publish !== undefined ? publish : formData.isPublished,
            metaDescription: formData.metaDescription || undefined,
            metaKeywords: formData.metaKeywords || undefined,
        };

        try {
            setSaving(true);
            if (isEditMode && id) {
                await articleApi.update(id, dto);
                toast.success('Đã cập nhật bài viết thành công');
            } else {
                await articleApi.create(dto);
                toast.success('Đã tạo bài viết thành công');
            }
            navigate('/admin/articles');
        } catch (err: any) {
            const msg = err?.message || 'Lưu bài viết thất bại';
            toast.error(msg);
        } finally {
            setSaving(false);
        }
    };

    const selectedCategory = categories.find(c => c.id === formData.categoryId);

    if (loading) {
        return (
            <AdminLayout>
                <div className="flex items-center justify-center h-64">
                    <div className="flex flex-col items-center gap-3 text-slate-500 dark:text-slate-400">
                        <div className="w-8 h-8 border-4 border-slate-200 border-t-dashboard-primary rounded-full animate-spin" />
                        <span>Đang tải bài viết...</span>
                    </div>
                </div>
            </AdminLayout>
        );
    }

    return (
        <AdminLayout>
            {/* Top Toolbar */}
            <div className="mb-5 flex flex-wrap items-center justify-between gap-3">
                <div className="flex items-center gap-3 min-w-0">
                    <Link
                        to="/admin/articles"
                        className="flex items-center gap-1.5 text-sm text-slate-500 dark:text-slate-400 hover:text-slate-800 dark:hover:text-white transition-colors whitespace-nowrap"
                    >
                        <span className="material-symbols-outlined text-[18px]">arrow_back</span>
                        <span className="hidden sm:inline">Danh sách bài viết</span>
                    </Link>
                    <span className="text-slate-300 dark:text-slate-600">|</span>
                    <h1 className="text-base sm:text-lg font-bold text-slate-900 dark:text-white truncate">
                        {isEditMode ? 'Sửa bài viết' : 'Tạo bài viết mới'}
                    </h1>
                </div>

                <div className="flex items-center gap-2 flex-shrink-0">
                    {/* Preview */}
                    <button
                        type="button"
                        onClick={() => setShowPreview(true)}
                        className="flex items-center gap-1.5 px-3 py-2 text-sm font-medium text-slate-600 dark:text-slate-300 border border-slate-300 dark:border-slate-600 rounded-lg hover:bg-slate-100 dark:hover:bg-gray-800 transition-colors"
                    >
                        <span className="material-symbols-outlined text-[18px]">visibility</span>
                        <span className="hidden sm:inline">Xem trước</span>
                    </button>

                    {/* Save Draft */}
                    <button
                        type="button"
                        onClick={() => handleSave(false)}
                        disabled={saving}
                        className="flex items-center gap-1.5 px-3 py-2 text-sm font-medium text-slate-600 dark:text-slate-300 border border-slate-300 dark:border-slate-600 rounded-lg hover:bg-slate-100 dark:hover:bg-gray-800 transition-colors disabled:opacity-50"
                    >
                        {saving ? (
                            <div className="w-4 h-4 border-2 border-slate-300 border-t-slate-600 rounded-full animate-spin" />
                        ) : (
                            <span className="material-symbols-outlined text-[18px]">save</span>
                        )}
                        <span className="hidden sm:inline">Lưu nháp</span>
                    </button>

                    {/* Publish */}
                    <button
                        type="button"
                        onClick={() => handleSave(true)}
                        disabled={saving}
                        className="flex items-center gap-1.5 px-4 py-2 text-sm font-semibold bg-dashboard-primary text-white rounded-lg hover:bg-dashboard-primary-dark transition-colors shadow-sm disabled:opacity-50"
                    >
                        {saving ? (
                            <div className="w-4 h-4 border-2 border-white/30 border-t-white rounded-full animate-spin" />
                        ) : (
                            <span className="material-symbols-outlined text-[18px]">publish</span>
                        )}
                        {formData.isPublished ? 'Cập nhật' : 'Xuất bản'}
                    </button>
                </div>
            </div>

            {/* Main 2-Column Layout — stacks on mobile, side-by-side on lg+ */}
            <div className="flex flex-col lg:flex-row gap-6 items-start">
                {/* ===== Left: Editor ===== */}
                <div className="flex-1 min-w-0 w-full space-y-4">
                    {/* Title */}
                    <div
                        className={`rounded-xl border bg-white dark:bg-gray-900 transition-shadow ${
                            titleFocused
                                ? 'border-dashboard-primary shadow-md shadow-dashboard-primary/10'
                                : 'border-slate-200 dark:border-slate-700 shadow-sm'
                        }`}
                    >
                        <input
                            type="text"
                            value={formData.title}
                            onChange={e => handleTitleChange(e.target.value)}
                            onFocus={() => setTitleFocused(true)}
                            onBlur={() => setTitleFocused(false)}
                            placeholder="Nhập tiêu đề bài viết..."
                            className="w-full px-6 py-4 text-2xl font-bold text-slate-900 dark:text-white bg-transparent placeholder-slate-300 dark:placeholder-slate-600 focus:outline-none rounded-xl"
                        />
                        {/* Slug */}
                        {formData.slug && (
                            <div className="px-6 pb-3 flex items-center gap-2">
                                <span className="text-xs text-slate-400">URL:</span>
                                <input
                                    type="text"
                                    value={formData.slug}
                                    onChange={e => setFormData(prev => ({ ...prev, slug: e.target.value }))}
                                    className="text-xs text-dashboard-primary bg-transparent border-b border-dashed border-dashboard-primary/30 focus:outline-none focus:border-dashboard-primary flex-1 min-w-0"
                                />
                                <span className="material-symbols-outlined text-[14px] text-slate-400">edit</span>
                            </div>
                        )}
                    </div>

                    {/* Rich Editor */}
                    <div>
                        <ArticleRichEditor
                            value={formData.content}
                            onChange={content => setFormData(prev => ({ ...prev, content }))}
                        />
                    </div>

                    {/* Excerpt */}
                    <div className="rounded-xl border border-slate-200 dark:border-slate-700 bg-white dark:bg-gray-900 p-5 shadow-sm">
                        <h3 className="text-sm font-semibold text-slate-700 dark:text-slate-300 mb-3 flex items-center gap-2">
                            <span className="material-symbols-outlined text-[18px]">short_text</span>
                            Tóm tắt (Excerpt)
                        </h3>
                        <textarea
                            value={formData.excerpt}
                            onChange={e => setFormData(prev => ({ ...prev, excerpt: e.target.value }))}
                            rows={3}
                            placeholder="Nhập tóm tắt ngắn về bài viết... (tùy chọn)"
                            className="w-full px-4 py-3 border border-slate-200 dark:border-slate-600 rounded-lg bg-slate-50 dark:bg-gray-800 text-slate-800 dark:text-slate-200 placeholder-slate-400 focus:outline-none focus:ring-2 focus:ring-dashboard-primary/40 transition-all resize-none text-sm"
                        />
                    </div>

                    {/* SEO Panel */}
                    <div className="rounded-xl border border-slate-200 dark:border-slate-700 bg-white dark:bg-gray-900 p-5 shadow-sm">
                        <h3 className="text-sm font-semibold text-slate-700 dark:text-slate-300 mb-4 flex items-center gap-2">
                            <span className="material-symbols-outlined text-[18px]">search</span>
                            SEO
                        </h3>
                        <div className="space-y-4">
                            <div>
                                <label className="block text-xs font-medium text-slate-600 dark:text-slate-400 mb-1.5">
                                    Meta Description
                                </label>
                                <textarea
                                    value={formData.metaDescription}
                                    onChange={e => setFormData(prev => ({ ...prev, metaDescription: e.target.value }))}
                                    rows={2}
                                    maxLength={160}
                                    placeholder="Mô tả ngắn hiển thị trên Google..."
                                    className="w-full px-4 py-3 border border-slate-200 dark:border-slate-600 rounded-lg bg-slate-50 dark:bg-gray-800 text-slate-800 dark:text-slate-200 placeholder-slate-400 focus:outline-none focus:ring-2 focus:ring-dashboard-primary/40 transition-all resize-none text-sm"
                                />
                                <p className="mt-1 text-xs text-slate-400">{formData.metaDescription.length}/160</p>
                            </div>
                            <div>
                                <label className="block text-xs font-medium text-slate-600 dark:text-slate-400 mb-1.5">
                                    Meta Keywords
                                </label>
                                <input
                                    type="text"
                                    value={formData.metaKeywords}
                                    onChange={e => setFormData(prev => ({ ...prev, metaKeywords: e.target.value }))}
                                    placeholder="từ khóa 1, từ khóa 2, ..."
                                    className="w-full px-4 py-2.5 border border-slate-200 dark:border-slate-600 rounded-lg bg-slate-50 dark:bg-gray-800 text-slate-800 dark:text-slate-200 placeholder-slate-400 focus:outline-none focus:ring-2 focus:ring-dashboard-primary/40 transition-all text-sm"
                                />
                            </div>
                        </div>
                    </div>
                </div>

                {/* ===== Right: Sidebar ===== */}
                <div className="w-full lg:w-72 flex-shrink-0 space-y-4">
                    {/* Publish Box */}
                    <div className="rounded-xl border border-slate-200 dark:border-slate-700 bg-white dark:bg-gray-900 shadow-sm overflow-hidden">
                        <div className="px-4 py-3 bg-slate-50 dark:bg-gray-800/60 border-b border-slate-200 dark:border-slate-700">
                            <h3 className="text-sm font-semibold text-slate-700 dark:text-slate-300 flex items-center gap-2">
                                <span className="material-symbols-outlined text-[18px]">publish</span>
                                Xuất bản
                            </h3>
                        </div>
                        <div className="p-4 space-y-3">
                            {/* Status badge */}
                            <div className="flex items-center justify-between">
                                <span className="text-xs text-slate-500 dark:text-slate-400">Trạng thái</span>
                                <span className={`inline-flex items-center gap-1 px-2.5 py-1 rounded-full text-xs font-semibold ${
                                    formData.isPublished
                                        ? 'bg-green-100 text-green-700 dark:bg-green-900/30 dark:text-green-400'
                                        : 'bg-amber-100 text-amber-700 dark:bg-amber-900/30 dark:text-amber-400'
                                }`}>
                                    <span className={`w-1.5 h-1.5 rounded-full ${formData.isPublished ? 'bg-green-500' : 'bg-amber-500'}`} />
                                    {formData.isPublished ? 'Đã xuất bản' : 'Nháp'}
                                </span>
                            </div>

                            <div className="border-t border-slate-100 dark:border-slate-700 pt-3 flex flex-col gap-2">
                                <button
                                    type="button"
                                    onClick={() => handleSave(true)}
                                    disabled={saving}
                                    className="w-full flex items-center justify-center gap-2 px-4 py-2.5 bg-dashboard-primary text-white text-sm font-semibold rounded-lg hover:bg-dashboard-primary-dark transition-colors disabled:opacity-50"
                                >
                                    <span className="material-symbols-outlined text-[16px]">publish</span>
                                    {formData.isPublished ? 'Cập nhật bài viết' : 'Xuất bản ngay'}
                                </button>
                                <button
                                    type="button"
                                    onClick={() => handleSave(false)}
                                    disabled={saving}
                                    className="w-full flex items-center justify-center gap-2 px-4 py-2.5 border border-slate-200 dark:border-slate-600 text-slate-600 dark:text-slate-300 text-sm font-medium rounded-lg hover:bg-slate-50 dark:hover:bg-gray-800 transition-colors disabled:opacity-50"
                                >
                                    <span className="material-symbols-outlined text-[16px]">save</span>
                                    Lưu nháp
                                </button>
                                <button
                                    type="button"
                                    onClick={() => setShowPreview(true)}
                                    className="w-full flex items-center justify-center gap-2 px-4 py-2.5 border border-slate-200 dark:border-slate-600 text-slate-600 dark:text-slate-300 text-sm font-medium rounded-lg hover:bg-slate-50 dark:hover:bg-gray-800 transition-colors"
                                >
                                    <span className="material-symbols-outlined text-[16px]">visibility</span>
                                    Xem trước
                                </button>
                            </div>
                        </div>
                    </div>

                    {/* Category */}
                    <div className="rounded-xl border border-slate-200 dark:border-slate-700 bg-white dark:bg-gray-900 shadow-sm overflow-hidden">
                        <div className="px-4 py-3 bg-slate-50 dark:bg-gray-800/60 border-b border-slate-200 dark:border-slate-700">
                            <h3 className="text-sm font-semibold text-slate-700 dark:text-slate-300 flex items-center gap-2">
                                <span className="material-symbols-outlined text-[18px]">folder</span>
                                Danh mục
                            </h3>
                        </div>
                        <div className="p-4">
                            <select
                                value={formData.categoryId}
                                onChange={e => setFormData(prev => ({ ...prev, categoryId: e.target.value }))}
                                className="w-full px-3 py-2 border border-slate-200 dark:border-slate-600 rounded-lg bg-slate-50 dark:bg-gray-800 text-slate-800 dark:text-slate-200 text-sm focus:outline-none focus:ring-2 focus:ring-dashboard-primary/40 transition-all"
                            >
                                <option value="">— Không có danh mục —</option>
                                {categories.map(cat => (
                                    <option key={cat.id} value={cat.id}>{cat.name}</option>
                                ))}
                            </select>
                            {selectedCategory && (
                                <p className="mt-2 text-xs text-slate-400">{selectedCategory.description}</p>
                            )}
                        </div>
                    </div>

                    {/* Featured Image */}
                    <div className="rounded-xl border border-slate-200 dark:border-slate-700 bg-white dark:bg-gray-900 shadow-sm overflow-hidden">
                        <div className="px-4 py-3 bg-slate-50 dark:bg-gray-800/60 border-b border-slate-200 dark:border-slate-700">
                            <h3 className="text-sm font-semibold text-slate-700 dark:text-slate-300 flex items-center gap-2">
                                <span className="material-symbols-outlined text-[18px]">image</span>
                                Ảnh đại diện
                            </h3>
                        </div>
                        <div className="p-4">
                            <ImageUploadButton
                                currentImageUrl={formData.featuredImageUrl}
                                onImageChange={url => setFormData(prev => ({ ...prev, featuredImageUrl: url }))}
                                onUpload={async file => {
                                    const result = await articleApi.uploadArticleContentImage(file);
                                    return result.url;
                                }}
                            />
                        </div>
                    </div>
                </div>
            </div>

            {/* Preview Modal */}
            {showPreview && (
                <ArticlePreviewModal
                    article={{
                        title: formData.title,
                        slug: formData.slug,
                        content: formData.content,
                        excerpt: formData.excerpt,
                        featuredImageUrl: formData.featuredImageUrl,
                        categoryName: selectedCategory?.name,
                        metaDescription: formData.metaDescription,
                        metaKeywords: formData.metaKeywords,
                    }}
                    onClose={() => setShowPreview(false)}
                    onPublish={() => {
                        setShowPreview(false);
                        handleSave(true);
                    }}
                />
            )}
        </AdminLayout>
    );
};

export default ArticleEditorPage;
