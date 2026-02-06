import React from 'react';
import { useTranslation } from 'react-i18next';

interface ArticlePreviewModalProps {
    article: {
        title: string;
        slug: string;
        content: string;
        excerpt?: string;
        featuredImageUrl?: string;
        categoryName?: string;
        metaDescription?: string;
        metaKeywords?: string;
    };
    onClose: () => void;
    onPublish?: () => void;
}

const ArticlePreviewModal: React.FC<ArticlePreviewModalProps> = ({ article, onClose, onPublish }) => {
    const { t } = useTranslation();

    return (
        <div className="fixed inset-0 bg-black/70 backdrop-blur-sm flex items-center justify-center z-50 p-4">
            <div className="bg-white dark:bg-dashboard-surface-dark rounded-2xl shadow-dashboard-xl w-full max-w-5xl max-h-[90vh] overflow-hidden flex flex-col border border-slate-200 dark:border-slate-700">
                {/* Header */}
                <div className="px-6 py-4 border-b border-slate-200 dark:border-slate-700 flex items-center justify-between bg-slate-50 dark:bg-gray-900/50">
                    <div className="flex items-center gap-3">
                        <span className="material-symbols-outlined text-dashboard-primary">visibility</span>
                        <h2 className="text-2xl font-bold text-slate-900 dark:text-white">
                            {t('admin.articles.previewArticle', { defaultValue: 'Xem trước bài viết' })}
                        </h2>
                    </div>
                    <button
                        onClick={onClose}
                        className="p-2 hover:bg-slate-200 dark:hover:bg-gray-800 rounded-lg transition-colors"
                    >
                        <span className="material-symbols-outlined">close</span>
                    </button>
                </div>

                {/* Preview Content */}
                <div className="flex-1 overflow-y-auto p-8 bg-slate-50 dark:bg-gray-900/30">
                    <article className="max-w-4xl mx-auto bg-white dark:bg-dashboard-surface-dark rounded-xl shadow-lg p-8">
                        {/* Category Badge */}
                        {article.categoryName && (
                            <div className="mb-4">
                                <span className="inline-block px-3 py-1 bg-dashboard-primary/10 text-dashboard-primary text-sm font-medium rounded-full">
                                    {article.categoryName}
                                </span>
                            </div>
                        )}

                        {/* Title */}
                        <h1 className="text-4xl font-bold text-slate-900 dark:text-white mb-4">
                            {article.title}
                        </h1>

                        {/* Excerpt */}
                        {article.excerpt && (
                            <p className="text-lg text-slate-600 dark:text-slate-400 mb-6 italic">
                                {article.excerpt}
                            </p>
                        )}

                        {/* Featured Image */}
                        {article.featuredImageUrl && (
                            <div className="mb-8 rounded-xl overflow-hidden">
                                <img
                                    src={article.featuredImageUrl}
                                    alt={article.title}
                                    className="w-full h-auto object-cover"
                                />
                            </div>
                        )}

                        {/* Meta Info */}
                        <div className="flex items-center gap-4 text-sm text-slate-500 dark:text-slate-400 mb-8 pb-8 border-b border-slate-200 dark:border-slate-700">
                            <div className="flex items-center gap-1">
                                <span className="material-symbols-outlined text-[18px]">schedule</span>
                                <span>{new Date().toLocaleDateString('vi-VN')}</span>
                            </div>
                            <div className="flex items-center gap-1">
                                <span className="material-symbols-outlined text-[18px]">link</span>
                                <span className="font-mono text-xs">{article.slug}</span>
                            </div>
                        </div>

                        {/* Content */}
                        <div
                            className="prose prose-slate dark:prose-invert max-w-none
                                prose-headings:text-slate-900 dark:prose-headings:text-white
                                prose-p:text-slate-700 dark:prose-p:text-slate-300
                                prose-a:text-dashboard-primary hover:prose-a:text-dashboard-primary-dark
                                prose-strong:text-slate-900 dark:prose-strong:text-white
                                prose-code:text-dashboard-primary prose-code:bg-slate-100 dark:prose-code:bg-slate-800
                                prose-pre:bg-slate-900 dark:prose-pre:bg-slate-950
                                prose-img:rounded-xl prose-img:shadow-lg"
                            dangerouslySetInnerHTML={{ __html: article.content }}
                        />

                        {/* SEO Preview */}
                        {(article.metaDescription || article.metaKeywords) && (
                            <div className="mt-12 pt-8 border-t border-slate-200 dark:border-slate-700">
                                <h3 className="text-sm font-semibold text-slate-500 dark:text-slate-400 uppercase tracking-wider mb-4">
                                    {t('admin.articles.seoPreview', { defaultValue: 'SEO Preview' })}
                                </h3>
                                <div className="bg-slate-50 dark:bg-gray-900/50 rounded-lg p-4 space-y-2">
                                    {article.metaDescription && (
                                        <div>
                                            <span className="text-xs font-medium text-slate-500 dark:text-slate-400">Meta Description:</span>
                                            <p className="text-sm text-slate-700 dark:text-slate-300">{article.metaDescription}</p>
                                        </div>
                                    )}
                                    {article.metaKeywords && (
                                        <div>
                                            <span className="text-xs font-medium text-slate-500 dark:text-slate-400">Keywords:</span>
                                            <p className="text-sm text-slate-700 dark:text-slate-300">{article.metaKeywords}</p>
                                        </div>
                                    )}
                                </div>
                            </div>
                        )}
                    </article>
                </div>

                {/* Footer */}
                <div className="px-6 py-4 border-t border-slate-200 dark:border-slate-700 flex items-center justify-end gap-3 bg-slate-50 dark:bg-gray-900/50">
                    <button
                        type="button"
                        onClick={onClose}
                        className="px-6 py-2.5 border border-slate-300 dark:border-gray-600 text-slate-700 dark:text-slate-300 font-medium rounded-lg hover:bg-slate-100 dark:hover:bg-gray-800 transition-colors"
                    >
                        {t('admin.articles.closePreview', { defaultValue: 'Đóng' })}
                    </button>
                    {onPublish && (
                        <button
                            type="button"
                            onClick={onPublish}
                            className="px-6 py-2.5 bg-dashboard-primary text-white font-medium rounded-lg hover:bg-dashboard-primary-dark transition-colors flex items-center gap-2 shadow-dashboard-sm"
                        >
                            <span className="material-symbols-outlined text-[20px]">publish</span>
                            <span>{t('admin.articles.publishArticle', { defaultValue: 'Xuất bản' })}</span>
                        </button>
                    )}
                </div>
            </div>
        </div>
    );
};

export default ArticlePreviewModal;
