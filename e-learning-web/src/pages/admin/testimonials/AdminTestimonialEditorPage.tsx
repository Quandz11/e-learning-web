import React, { useEffect, useState } from 'react';
import { useTranslation } from 'react-i18next';
import { useNavigate, useParams, Link } from 'react-router-dom';
import AdminLayout from '../../../components/admin/AdminLayout';
import { testimonialApi, type CreateTestimonialRequest, TestimonialType } from '../../../services/testimonialApi';
import { toast } from 'react-hot-toast';

const AdminTestimonialEditorPage: React.FC = () => {
    const { t } = useTranslation();
    const navigate = useNavigate();
    const { id } = useParams<{ id: string }>();
    const isEditMode = !!id && id !== 'new';

    const [loading, setLoading] = useState(false);
    const [submitting, setSubmitting] = useState(false);

    const [formData, setFormData] = useState<CreateTestimonialRequest>({
        name: '',
        position: '',
        content: '',
        avatarUrl: '',
        videoUrl: '',
        type: TestimonialType.Text,
        order: 0,
        isActive: true,
    });

    useEffect(() => {
        if (isEditMode && id) {
            fetchTestimonial(id);
        }
    }, [isEditMode, id]);

    const fetchTestimonial = async (testimonialId: string) => {
        try {
            setLoading(true);
            const data = await testimonialApi.getById(testimonialId);
            setFormData({
                name: data.name,
                position: data.position || '',
                content: data.content,
                avatarUrl: data.avatarUrl || '',
                videoUrl: data.videoUrl || '',
                type: data.type,
                order: data.order,
                isActive: data.isActive,
            });
        } catch (error) {
            console.error(error);
            toast.error(t('admin.testimonials.loadError', { defaultValue: 'Failed to load testimonial' }));
            navigate('/admin/testimonials');
        } finally {
            setLoading(false);
        }
    };

    const handleSubmit = async (e: React.FormEvent) => {
        e.preventDefault();
        setSubmitting(true);
        try {
            if (isEditMode && id) {
                await testimonialApi.update(id, formData);
                toast.success(t('common.updateSuccess', { defaultValue: 'Updated successfully' }));
            } else {
                await testimonialApi.create(formData);
                toast.success(t('common.createSuccess', { defaultValue: 'Created successfully' }));
            }
            navigate('/admin/testimonials');
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
                            {isEditMode ? t('admin.testimonials.edit', { defaultValue: 'Edit Testimonial' }) : t('admin.testimonials.create', { defaultValue: 'Create Testimonial' })}
                        </h1>
                    </div>
                    <Link
                        to="/admin/testimonials"
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
                                    {t('admin.testimonials.form.name', { defaultValue: 'Name' })} <span className="text-red-500">*</span>
                                </label>
                                <input
                                    type="text"
                                    required
                                    className="w-full rounded-lg border border-slate-300 px-4 py-2 dark:border-slate-600 dark:bg-slate-800 dark:text-white"
                                    value={formData.name}
                                    onChange={e => setFormData({ ...formData, name: e.target.value })}
                                    placeholder={t('admin.testimonials.form.namePlaceholder', { defaultValue: 'Enter name' })}
                                />
                            </div>

                            {/* Position */}
                            <div>
                                <label className="mb-2 block text-sm font-medium text-slate-700 dark:text-slate-300">
                                    {t('admin.testimonials.form.position', { defaultValue: 'Position' })}
                                </label>
                                <input
                                    type="text"
                                    className="w-full rounded-lg border border-slate-300 px-4 py-2 dark:border-slate-600 dark:bg-slate-800 dark:text-white"
                                    value={formData.position}
                                    onChange={e => setFormData({ ...formData, position: e.target.value })}
                                    placeholder={t('admin.testimonials.form.positionPlaceholder', { defaultValue: 'e.g. Software Engineer' })}
                                />
                            </div>

                            {/* Content */}
                            <div>
                                <label className="mb-2 block text-sm font-medium text-slate-700 dark:text-slate-300">
                                    {t('admin.testimonials.form.content', { defaultValue: 'Content' })} <span className="text-red-500">*</span>
                                </label>
                                <textarea
                                    required
                                    rows={5}
                                    className="w-full rounded-lg border border-slate-300 px-4 py-2 dark:border-slate-600 dark:bg-slate-800 dark:text-white"
                                    value={formData.content}
                                    onChange={e => setFormData({ ...formData, content: e.target.value })}
                                    placeholder={t('admin.testimonials.form.contentPlaceholder', { defaultValue: 'Enter testimonial content...' })}
                                />
                            </div>

                            {/* Avatar URL */}
                            <div>
                                <label className="mb-2 block text-sm font-medium text-slate-700 dark:text-slate-300">
                                    {t('admin.testimonials.form.avatarUrl', { defaultValue: 'Avatar URL' })}
                                </label>
                                <input
                                    type="url"
                                    className="w-full rounded-lg border border-slate-300 px-4 py-2 dark:border-slate-600 dark:bg-slate-800 dark:text-white"
                                    value={formData.avatarUrl}
                                    onChange={e => setFormData({ ...formData, avatarUrl: e.target.value })}
                                    placeholder="https://example.com/avatar.jpg"
                                />
                                {formData.avatarUrl && (
                                    <div className="mt-2">
                                        <img src={formData.avatarUrl} alt="Preview" className="w-16 h-16 rounded-full object-cover" />
                                    </div>
                                )}
                            </div>

                            {/* Testimonial Type */}
                            <div>
                                <label className="mb-2 block text-sm font-medium text-slate-700 dark:text-slate-300">
                                    {t('admin.testimonials.form.type', { defaultValue: 'Type' })} <span className="text-red-500">*</span>
                                </label>
                                <select
                                    className="w-full rounded-lg border border-slate-300 px-4 py-2 dark:border-slate-600 dark:bg-slate-800 dark:text-white"
                                    value={formData.type}
                                    onChange={e => setFormData({ ...formData, type: Number(e.target.value) as TestimonialType })}
                                >
                                    <option value={TestimonialType.Text}>{t('admin.testimonials.form.typeText', { defaultValue: 'Text' })}</option>
                                    <option value={TestimonialType.Video}>{t('admin.testimonials.form.typeVideo', { defaultValue: 'Video' })}</option>
                                </select>
                            </div>

                            {/* Video URL - Only show for video type */}
                            {formData.type === TestimonialType.Video && (
                                <div>
                                    <label className="mb-2 block text-sm font-medium text-slate-700 dark:text-slate-300">
                                        {t('admin.testimonials.form.videoUrl', { defaultValue: 'Video URL' })} <span className="text-red-500">*</span>
                                    </label>
                                    <input
                                        type="url"
                                        required={formData.type === TestimonialType.Video}
                                        className="w-full rounded-lg border border-slate-300 px-4 py-2 dark:border-slate-600 dark:bg-slate-800 dark:text-white"
                                        value={formData.videoUrl}
                                        onChange={e => setFormData({ ...formData, videoUrl: e.target.value })}
                                        placeholder="https://example.com/video.mp4"
                                    />
                                    {formData.videoUrl && (
                                        <div className="mt-2">
                                            <video controls className="w-full max-w-md rounded-lg">
                                                <source src={formData.videoUrl} type="video/mp4" />
                                                Your browser does not support the video tag.
                                            </video>
                                        </div>
                                    )}
                                    <p className="mt-1 text-xs text-slate-500 dark:text-slate-400">
                                        {t('admin.testimonials.form.videoUrlHint', { defaultValue: 'Direct link to MP4 video file' })}
                                    </p>
                                </div>
                            )}

                            {/* Order */}
                            <div>
                                <label className="mb-2 block text-sm font-medium text-slate-700 dark:text-slate-300">
                                    {t('admin.testimonials.form.order', { defaultValue: 'Display Order' })}
                                </label>
                                <input
                                    type="number"
                                    className="w-full rounded-lg border border-slate-300 px-4 py-2 dark:border-slate-600 dark:bg-slate-800 dark:text-white"
                                    value={formData.order}
                                    onChange={e => setFormData({ ...formData, order: Number(e.target.value) })}
                                />
                            </div>

                            {/* Active Status */}
                            <div className="flex items-center gap-2">
                                <input
                                    type="checkbox"
                                    id="isActive"
                                    className="h-4 w-4 rounded border-slate-300 text-dashboard-primary focus:ring-dashboard-primary"
                                    checked={formData.isActive}
                                    onChange={e => setFormData({ ...formData, isActive: e.target.checked })}
                                />
                                <label htmlFor="isActive" className="text-sm font-medium text-slate-700 dark:text-slate-300">
                                    {t('admin.testimonials.form.isActive', { defaultValue: 'Active (Visible to users)' })}
                                </label>
                            </div>
                        </div>

                        <div className="mt-6 flex justify-end gap-3">
                            <Link
                                to="/admin/testimonials"
                                className="rounded-lg px-6 py-2 text-sm font-medium text-slate-600 hover:bg-slate-100 dark:text-slate-400 dark:hover:bg-slate-800"
                            >
                                {t('common.cancel', { defaultValue: 'Cancel' })}
                            </Link>
                            <button
                                type="submit"
                                disabled={submitting}
                                className="rounded-lg bg-dashboard-primary px-6 py-2 text-sm font-bold text-white shadow-dashboard-primary/20 hover:bg-dashboard-primary-dark disabled:opacity-50"
                            >
                                {submitting ? t('common.saving', { defaultValue: 'Saving...' }) : t('common.save', { defaultValue: 'Save' })}
                            </button>
                        </div>
                    </div>
                </form>
            </div>
        </AdminLayout>
    );
};

export default AdminTestimonialEditorPage;
