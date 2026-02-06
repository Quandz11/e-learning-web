import React, { useEffect, useState } from 'react';
import { useTranslation } from 'react-i18next';
import { Link } from 'react-router-dom';
import AdminLayout from '../../../components/admin/AdminLayout';
import { testimonialApi, type TestimonialDto } from '../../../services/testimonialApi';
import { toast } from 'react-hot-toast';

const AdminTestimonialsPage: React.FC = () => {
    const { t } = useTranslation();
    const [testimonials, setTestimonials] = useState<TestimonialDto[]>([]);
    const [loading, setLoading] = useState(true);

    useEffect(() => {
        fetchTestimonials();
    }, []);

    const fetchTestimonials = async () => {
        try {
            setLoading(true);
            const data = await testimonialApi.getAll();
            setTestimonials(data);
        } catch (error) {
            console.error(error);
            toast.error(t('admin.testimonials.loadError', { defaultValue: 'Failed to load testimonials' }));
        } finally {
            setLoading(false);
        }
    };

    const handleDelete = async (id: string) => {
        if (!window.confirm(t('common.confirmDelete', { defaultValue: 'Are you sure?' }))) return;
        try {
            await testimonialApi.delete(id);
            setTestimonials(testimonials.filter(t => t.id !== id));
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
                        {t('admin.testimonials.title', { defaultValue: 'Testimonials' })}
                    </h1>
                    <p className="mt-1 text-sm text-slate-500 dark:text-slate-400">
                        {t('admin.testimonials.subtitle', { defaultValue: 'Manage student testimonials' })}
                    </p>
                </div>
                <Link
                    to="/admin/testimonials/new"
                    className="flex items-center gap-2 rounded-lg bg-dashboard-primary px-4 py-2 text-sm font-medium text-white transition-colors hover:bg-dashboard-primary-dark"
                >
                    <span className="material-symbols-outlined text-[20px]">add</span>
                    {t('admin.testimonials.create', { defaultValue: 'Create Testimonial' })}
                </Link>
            </div>

            <div className="rounded-xl border border-slate-200 bg-white shadow-sm dark:border-slate-700 dark:bg-dashboard-surface-dark">
                <div className="overflow-x-auto">
                    <table className="w-full text-left text-sm">
                        <thead className="bg-slate-50 text-xs uppercase text-slate-500 dark:bg-slate-800/50 dark:text-slate-400">
                            <tr>
                                <th className="px-6 py-4 font-semibold">{t('admin.testimonials.table.name', { defaultValue: 'Name' })}</th>
                                <th className="px-6 py-4 font-semibold">{t('admin.testimonials.table.position', { defaultValue: 'Position' })}</th>
                                <th className="px-6 py-4 font-semibold">{t('admin.testimonials.table.content', { defaultValue: 'Content' })}</th>
                                <th className="px-6 py-4 font-semibold">{t('admin.testimonials.table.order', { defaultValue: 'Order' })}</th>
                                <th className="px-6 py-4 font-semibold">{t('admin.testimonials.table.status', { defaultValue: 'Status' })}</th>
                                <th className="px-6 py-4 text-right font-semibold">{t('common.actions', { defaultValue: 'Actions' })}</th>
                            </tr>
                        </thead>
                        <tbody className="divide-y divide-slate-200 dark:divide-slate-700">
                            {loading ? (
                                <tr><td colSpan={6} className="p-8 text-center text-slate-500">{t('common.loading', { defaultValue: 'Loading...' })}</td></tr>
                            ) : testimonials.length === 0 ? (
                                <tr><td colSpan={6} className="p-8 text-center text-slate-500">{t('admin.testimonials.table.empty', { defaultValue: 'No testimonials found.' })}</td></tr>
                            ) : (
                                testimonials.map((testimonial) => (
                                    <tr key={testimonial.id} className="hover:bg-slate-50 dark:hover:bg-slate-800/50">
                                        <td className="px-6 py-4">
                                            <div className="flex items-center gap-3">
                                                {testimonial.avatarUrl ? (
                                                    <img src={testimonial.avatarUrl} alt={testimonial.name} className="w-10 h-10 rounded-full object-cover" />
                                                ) : (
                                                    <div className="w-10 h-10 rounded-full bg-slate-200 dark:bg-slate-700 flex items-center justify-center">
                                                        <span className="material-symbols-outlined text-slate-500">person</span>
                                                    </div>
                                                )}
                                                <span className="font-medium text-slate-900 dark:text-white">{testimonial.name}</span>
                                            </div>
                                        </td>
                                        <td className="px-6 py-4 text-slate-500 dark:text-slate-400">
                                            {testimonial.position || '-'}
                                        </td>
                                        <td className="px-6 py-4 text-slate-500 dark:text-slate-400">
                                            <div className="max-w-md truncate">{testimonial.content}</div>
                                        </td>
                                        <td className="px-6 py-4 text-slate-500 dark:text-slate-400">
                                            {testimonial.order}
                                        </td>
                                        <td className="px-6 py-4">
                                            <span className={`inline-flex rounded-full px-2 py-1 text-xs font-semibold ${testimonial.isActive
                                                    ? 'bg-green-100 text-green-700 dark:bg-green-900/30 dark:text-green-400'
                                                    : 'bg-slate-100 text-slate-700 dark:bg-slate-800 dark:text-slate-400'
                                                }`}>
                                                {testimonial.isActive ? t('admin.testimonials.status.active', { defaultValue: 'Active' }) : t('admin.testimonials.status.inactive', { defaultValue: 'Inactive' })}
                                            </span>
                                        </td>
                                        <td className="px-6 py-4 text-right">
                                            <div className="flex justify-end gap-2">
                                                <Link
                                                    to={`/admin/testimonials/${testimonial.id}`}
                                                    className="rounded-lg p-2 text-slate-500 hover:bg-slate-100 hover:text-dashboard-primary dark:text-slate-400 dark:hover:bg-slate-800"
                                                    title={t('common.edit', { defaultValue: 'Edit' })}
                                                >
                                                    <span className="material-symbols-outlined text-[20px]">edit</span>
                                                </Link>
                                                <button
                                                    onClick={() => handleDelete(testimonial.id)}
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

export default AdminTestimonialsPage;
