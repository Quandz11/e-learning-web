import React, { useEffect, useState } from 'react';
import { useTranslation } from 'react-i18next';
import { Link } from 'react-router-dom';
import AdminLayout from '../../../components/admin/AdminLayout';
import { whyChooseUsApi, type WhyChooseUsItemDto } from '../../../services/whyChooseUsApi';
import { toast } from 'react-hot-toast';

const AdminWhyChooseUsPage: React.FC = () => {
    const { t } = useTranslation();
    const [items, setItems] = useState<WhyChooseUsItemDto[]>([]);
    const [loading, setLoading] = useState(true);

    useEffect(() => {
        fetchItems();
    }, []);

    const fetchItems = async () => {
        try {
            setLoading(true);
            const data = await whyChooseUsApi.getAll();
            setItems(data);
        } catch (error) {
            console.error(error);
            toast.error(t('admin.whyChooseUs.loadError'));
        } finally {
            setLoading(false);
        }
    };

    const handleDelete = async (id: string) => {
        if (!window.confirm(t('admin.whyChooseUs.deleteConfirm'))) return;
        try {
            await whyChooseUsApi.delete(id);
            setItems(prev => prev.filter(i => i.id !== id));
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
                        {t('admin.whyChooseUs.title')}
                    </h1>
                    <p className="mt-1 text-sm text-slate-500 dark:text-slate-400">
                        {t('admin.whyChooseUs.subtitle')}
                    </p>
                </div>
                <Link
                    to="/admin/why-choose-us/new"
                    className="flex items-center gap-2 rounded-lg bg-dashboard-primary px-4 py-2 text-sm font-medium text-white transition-colors hover:bg-dashboard-primary-dark"
                >
                    <span className="material-symbols-outlined text-[20px]">add</span>
                    {t('admin.whyChooseUs.addItem')}
                </Link>
            </div>

            <div className="rounded-xl border border-slate-200 bg-white shadow-sm dark:border-slate-700 dark:bg-dashboard-surface-dark">
                <div className="overflow-x-auto">
                    <table className="w-full text-left text-sm">
                        <thead className="bg-slate-50 text-xs uppercase text-slate-500 dark:bg-slate-800/50 dark:text-slate-400">
                            <tr>
                                <th className="px-6 py-4 font-semibold">{t('admin.whyChooseUs.table.icon')}</th>
                                <th className="px-6 py-4 font-semibold">{t('admin.whyChooseUs.table.title')}</th>
                                <th className="px-6 py-4 font-semibold">{t('admin.whyChooseUs.table.description')}</th>
                                <th className="px-6 py-4 font-semibold">{t('admin.whyChooseUs.table.order')}</th>
                                <th className="px-6 py-4 font-semibold">{t('admin.whyChooseUs.table.status')}</th>
                                <th className="px-6 py-4 text-right font-semibold">{t('common.actions', { defaultValue: 'Actions' })}</th>
                            </tr>
                        </thead>
                        <tbody className="divide-y divide-slate-200 dark:divide-slate-700">
                            {loading ? (
                                <tr>
                                    <td colSpan={6} className="p-8 text-center text-slate-500">{t('common.loading', { defaultValue: 'Loading...' })}</td>
                                </tr>
                            ) : items.length === 0 ? (
                                <tr>
                                    <td colSpan={6} className="p-8 text-center text-slate-500">{t('admin.whyChooseUs.noItems')}</td>
                                </tr>
                            ) : (
                                items.map((item) => (
                                    <tr key={item.id} className="hover:bg-slate-50 dark:hover:bg-slate-800/50">
                                        <td className="px-6 py-4">
                                            <div className="flex items-center justify-center w-10 h-10 rounded-lg bg-primary/10">
                                                <span className="material-symbols-outlined text-2xl text-primary">{item.icon}</span>
                                            </div>
                                        </td>
                                        <td className="px-6 py-4 font-medium text-slate-900 dark:text-white">
                                            {item.title}
                                        </td>
                                        <td className="px-6 py-4 text-slate-500 dark:text-slate-400">
                                            <div className="max-w-xs truncate">{item.description}</div>
                                        </td>
                                        <td className="px-6 py-4 text-slate-500 dark:text-slate-400">
                                            {item.order}
                                        </td>
                                        <td className="px-6 py-4">
                                            <span className={`inline-flex rounded-full px-2 py-1 text-xs font-semibold ${
                                                item.isActive
                                                    ? 'bg-green-100 text-green-700 dark:bg-green-900/30 dark:text-green-400'
                                                    : 'bg-slate-100 text-slate-700 dark:bg-slate-800 dark:text-slate-400'
                                            }`}>
                                                {item.isActive ? t('admin.whyChooseUs.status.active') : t('admin.whyChooseUs.status.inactive')}
                                            </span>
                                        </td>
                                        <td className="px-6 py-4 text-right">
                                            <div className="flex justify-end gap-2">
                                                <Link
                                                    to={`/admin/why-choose-us/${item.id}`}
                                                    className="rounded-lg p-2 text-slate-500 hover:bg-slate-100 hover:text-dashboard-primary dark:text-slate-400 dark:hover:bg-slate-800"
                                                    title={t('common.edit', { defaultValue: 'Edit' })}
                                                >
                                                    <span className="material-symbols-outlined text-[20px]">edit</span>
                                                </Link>
                                                <button
                                                    onClick={() => handleDelete(item.id)}
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

export default AdminWhyChooseUsPage;
