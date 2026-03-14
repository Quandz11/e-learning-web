import React, { useEffect, useState } from 'react';
import { useTranslation } from 'react-i18next';
import { useNavigate, useParams, Link } from 'react-router-dom';
import AdminLayout from '../../../components/admin/AdminLayout';
import { whyChooseUsApi, type CreateWhyChooseUsItemRequest } from '../../../services/whyChooseUsApi';
import { toast } from 'react-hot-toast';

const ICON_SUGGESTIONS = [
    'school', 'schedule', 'workspace_premium', 'groups', 'star', 'verified',
    'trending_up', 'support_agent', 'emoji_events', 'bolt', 'security', 'devices',
];

const AdminWhyChooseUsEditorPage: React.FC = () => {
    const { t } = useTranslation();
    const navigate = useNavigate();
    const { id } = useParams<{ id: string }>();
    const isEditMode = !!id && id !== 'new';

    const [loading, setLoading] = useState(false);
    const [submitting, setSubmitting] = useState(false);

    const [formData, setFormData] = useState<CreateWhyChooseUsItemRequest>({
        icon: 'school',
        title: '',
        description: '',
        order: 0,
        isActive: true,
    });

    useEffect(() => {
        if (isEditMode && id) {
            fetchItem(id);
        }
    }, [isEditMode, id]);

    const fetchItem = async (itemId: string) => {
        try {
            setLoading(true);
            const data = await whyChooseUsApi.getById(itemId);
            setFormData({
                icon: data.icon,
                title: data.title,
                description: data.description,
                order: data.order,
                isActive: data.isActive,
            });
        } catch (error) {
            console.error(error);
            toast.error(t('admin.whyChooseUs.loadError'));
            navigate('/admin/why-choose-us');
        } finally {
            setLoading(false);
        }
    };

    const handleSubmit = async (e: React.FormEvent) => {
        e.preventDefault();
        setSubmitting(true);
        try {
            if (isEditMode && id) {
                await whyChooseUsApi.update(id, formData);
                toast.success(t('common.updateSuccess', { defaultValue: 'Updated successfully' }));
            } else {
                await whyChooseUsApi.create(formData);
                toast.success(t('common.createSuccess', { defaultValue: 'Created successfully' }));
            }
            navigate('/admin/why-choose-us');
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
                    <h1 className="text-2xl font-bold text-slate-900 dark:text-white">
                        {isEditMode ? t('admin.whyChooseUs.editItem') : t('admin.whyChooseUs.addItem')} — {t('admin.whyChooseUs.title')}
                    </h1>
                    <Link
                        to="/admin/why-choose-us"
                        className="rounded-lg px-4 py-2 text-sm font-medium text-slate-600 hover:bg-slate-100 dark:text-slate-400 dark:hover:bg-slate-800"
                    >
                        {t('common.cancel', { defaultValue: 'Cancel' })}
                    </Link>
                </div>

                <form onSubmit={handleSubmit} className="space-y-6">
                    <div className="rounded-xl border border-slate-200 bg-white p-6 shadow-sm dark:border-slate-700 dark:bg-dashboard-surface-dark">
                        <div className="grid gap-6">
                            {/* Icon */}
                            <div>
                                <label className="mb-2 block text-sm font-medium text-slate-700 dark:text-slate-300">
                                    {t('admin.whyChooseUs.form.icon')} <span className="text-red-500">*</span>
                                </label>
                                <div className="flex items-center gap-3">
                                    <div className="flex h-12 w-12 items-center justify-center rounded-lg bg-primary/10">
                                        <span className="material-symbols-outlined text-2xl text-primary">
                                            {formData.icon || 'help_outline'}
                                        </span>
                                    </div>
                                    <input
                                        type="text"
                                        required
                                        className="flex-1 rounded-lg border border-slate-300 px-4 py-2 dark:border-slate-600 dark:bg-slate-800 dark:text-white"
                                        value={formData.icon}
                                        onChange={e => setFormData({ ...formData, icon: e.target.value })}
                                        placeholder={t('admin.whyChooseUs.form.iconPlaceholder')}
                                    />
                                </div>
                                <div className="mt-3 flex flex-wrap gap-2">
                                    {ICON_SUGGESTIONS.map(iconName => (
                                        <button
                                            key={iconName}
                                            type="button"
                                            onClick={() => setFormData({ ...formData, icon: iconName })}
                                            className={`flex items-center gap-1.5 rounded-lg border px-3 py-1.5 text-xs transition-colors ${
                                                formData.icon === iconName
                                                    ? 'border-primary bg-primary/10 text-primary'
                                                    : 'border-slate-200 text-slate-600 hover:border-slate-300 dark:border-slate-700 dark:text-slate-400'
                                            }`}
                                            title={iconName}
                                        >
                                            <span className="material-symbols-outlined text-[16px]">{iconName}</span>
                                            {iconName}
                                        </button>
                                    ))}
                                </div>
                                <p className="mt-1.5 text-xs text-slate-400">
                                    {t('admin.whyChooseUs.form.iconHint')}
                                </p>
                            </div>

                            {/* Title */}
                            <div>
                                <label className="mb-2 block text-sm font-medium text-slate-700 dark:text-slate-300">
                                    {t('admin.whyChooseUs.form.title')} <span className="text-red-500">*</span>
                                </label>
                                <input
                                    type="text"
                                    required
                                    className="w-full rounded-lg border border-slate-300 px-4 py-2 dark:border-slate-600 dark:bg-slate-800 dark:text-white"
                                    value={formData.title}
                                    onChange={e => setFormData({ ...formData, title: e.target.value })}
                                    placeholder={t('admin.whyChooseUs.form.titlePlaceholder')}
                                />
                            </div>

                            {/* Description */}
                            <div>
                                <label className="mb-2 block text-sm font-medium text-slate-700 dark:text-slate-300">
                                    {t('admin.whyChooseUs.form.description')} <span className="text-red-500">*</span>
                                </label>
                                <textarea
                                    required
                                    rows={3}
                                    className="w-full rounded-lg border border-slate-300 px-4 py-2 dark:border-slate-600 dark:bg-slate-800 dark:text-white"
                                    value={formData.description}
                                    onChange={e => setFormData({ ...formData, description: e.target.value })}
                                    placeholder={t('admin.whyChooseUs.form.descriptionPlaceholder')}
                                />
                            </div>

                            {/* Order */}
                            <div>
                                <label className="mb-2 block text-sm font-medium text-slate-700 dark:text-slate-300">
                                    {t('admin.whyChooseUs.form.order')}
                                </label>
                                <input
                                    type="number"
                                    min={0}
                                    className="w-full rounded-lg border border-slate-300 px-4 py-2 dark:border-slate-600 dark:bg-slate-800 dark:text-white"
                                    value={formData.order}
                                    onChange={e => setFormData({ ...formData, order: Number(e.target.value) })}
                                />
                                <p className="mt-1 text-xs text-slate-400">{t('admin.whyChooseUs.form.orderHint')}</p>
                            </div>

                            {/* IsActive */}
                            <div className="flex items-center justify-between rounded-lg border border-slate-200 p-4 dark:border-slate-700">
                                <div>
                                    <p className="text-sm font-medium text-slate-700 dark:text-slate-300">{t('admin.whyChooseUs.form.isActive')}</p>
                                    <p className="text-xs text-slate-400">{t('admin.whyChooseUs.form.isActiveHint')}</p>
                                </div>
                                <button
                                    type="button"
                                    onClick={() => setFormData({ ...formData, isActive: !formData.isActive })}
                                    className={`relative inline-flex h-6 w-11 items-center rounded-full transition-colors ${
                                        formData.isActive ? 'bg-primary' : 'bg-slate-300 dark:bg-slate-600'
                                    }`}
                                >
                                    <span
                                        className={`inline-block h-4 w-4 transform rounded-full bg-white transition-transform ${
                                            formData.isActive ? 'translate-x-6' : 'translate-x-1'
                                        }`}
                                    />
                                </button>
                            </div>
                        </div>
                    </div>

                    {/* Submit */}
                    <div className="flex justify-end gap-3">
                        <Link
                            to="/admin/why-choose-us"
                            className="rounded-lg border border-slate-200 px-6 py-2 text-sm font-medium text-slate-600 hover:bg-slate-50 dark:border-slate-700 dark:text-slate-400 dark:hover:bg-slate-800"
                        >
                            {t('common.cancel', { defaultValue: 'Cancel' })}
                        </Link>
                        <button
                            type="submit"
                            disabled={submitting}
                            className="flex items-center gap-2 rounded-lg bg-dashboard-primary px-6 py-2 text-sm font-medium text-white transition-colors hover:bg-dashboard-primary-dark disabled:opacity-60"
                        >
                            {submitting && <span className="material-symbols-outlined animate-spin text-[18px]">progress_activity</span>}
                            {isEditMode ? t('admin.whyChooseUs.saveChanges') : t('admin.whyChooseUs.createItem')}
                        </button>
                    </div>
                </form>
            </div>
        </AdminLayout>
    );
};

export default AdminWhyChooseUsEditorPage;
