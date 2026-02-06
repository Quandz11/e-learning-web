import React, { useEffect, useState } from 'react';
import { useTranslation } from 'react-i18next';
import { Link } from 'react-router-dom';
import AdminLayout from '../../../components/admin/AdminLayout';
import { quizApi, type QuizDto } from '../../../services/quizApi';
import { toast } from 'react-hot-toast';

const AdminQuizPage: React.FC = () => {
    const { t } = useTranslation();
    const [quizzes, setQuizzes] = useState<QuizDto[]>([]);
    const [loading, setLoading] = useState(true);

    useEffect(() => {
        fetchQuizzes();
    }, []);

    const fetchQuizzes = async () => {
        try {
            setLoading(true);
            const data = await quizApi.getAll();
            setQuizzes(data);
        } catch (error) {
            console.error(error);
            toast.error(t('admin.quiz.loadError', { defaultValue: 'Failed to load quizzes' }));
        } finally {
            setLoading(false);
        }
    };

    const handleDelete = async (id: string) => {
        if (!window.confirm(t('common.confirmDelete', { defaultValue: 'Are you sure?' }))) return;
        try {
            await quizApi.delete(id);
            setQuizzes(quizzes.filter(q => q.id !== id));
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
                        {t('admin.quiz.title', { defaultValue: 'Quizzes' })}
                    </h1>
                    <p className="mt-1 text-sm text-slate-500 dark:text-slate-400">
                        {t('admin.quiz.subtitle', { defaultValue: 'Manage your quizzes and surveys' })}
                    </p>
                </div>
                <Link
                    to="/admin/quizzes/new"
                    className="flex items-center gap-2 rounded-lg bg-dashboard-primary px-4 py-2 text-sm font-medium text-white transition-colors hover:bg-dashboard-primary-dark"
                >
                    <span className="material-symbols-outlined text-[20px]">add</span>
                    {t('admin.quiz.create', { defaultValue: 'Create Quiz' })}
                </Link>
            </div>

            <div className="rounded-xl border border-slate-200 bg-white shadow-sm dark:border-slate-700 dark:bg-dashboard-surface-dark">
                <div className="overflow-x-auto">
                    <table className="w-full text-left text-sm">
                        <thead className="bg-slate-50 text-xs uppercase text-slate-500 dark:bg-slate-800/50 dark:text-slate-400">
                            <tr>
                                <th className="px-6 py-4 font-semibold">{t('admin.quiz.table.title', { defaultValue: 'Title' })}</th>
                                <th className="px-6 py-4 font-semibold">{t('admin.quiz.table.status', { defaultValue: 'Status' })}</th>
                                <th className="px-6 py-4 font-semibold">{t('admin.quiz.table.created', { defaultValue: 'Created At' })}</th>
                                <th className="px-6 py-4 text-right font-semibold">{t('admin.quiz.table.actions', { defaultValue: 'Actions' })}</th>
                            </tr>
                        </thead>
                        <tbody className="divide-y divide-slate-200 dark:divide-slate-700">
                            {loading ? (
                                <tr><td colSpan={4} className="p-8 text-center text-slate-500">{t('common.loading', { defaultValue: 'Loading...' })}</td></tr>
                            ) : quizzes.length === 0 ? (
                                <tr><td colSpan={4} className="p-8 text-center text-slate-500">{t('admin.quiz.table.noQuizzes', { defaultValue: 'No quizzes found.' })}</td></tr>
                            ) : (
                                quizzes.map((quiz) => (
                                    <tr key={quiz.id} className="hover:bg-slate-50 dark:hover:bg-slate-800/50">
                                        <td className="px-6 py-4 font-medium text-slate-900 dark:text-white">
                                            {quiz.title}
                                        </td>
                                        <td className="px-6 py-4">
                                            <span className={`inline-flex rounded-full px-2 py-1 text-xs font-semibold ${quiz.isActive
                                                    ? 'bg-green-100 text-green-700 dark:bg-green-900/30 dark:text-green-400'
                                                    : 'bg-slate-100 text-slate-700 dark:bg-slate-800 dark:text-slate-400'
                                                }`}>
                                                {quiz.isActive ? t('admin.quiz.status.active', { defaultValue: 'Active' }) : t('admin.quiz.status.inactive', { defaultValue: 'Inactive' })}
                                            </span>
                                        </td>
                                        <td className="px-6 py-4 text-slate-500 dark:text-slate-400">
                                            {new Date(quiz.createdAt).toLocaleDateString()}
                                        </td>
                                        <td className="px-6 py-4 text-right">
                                            <div className="flex justify-end gap-2">
                                                <Link
                                                    to={`/admin/quizzes/${quiz.id}/submissions`}
                                                    className="rounded-lg p-2 text-slate-500 hover:bg-slate-100 hover:text-blue-600 dark:text-slate-400 dark:hover:bg-slate-800"
                                                    title={t('admin.quiz.table.viewSubmissions', { defaultValue: 'View Submissions' })}
                                                >
                                                    <span className="material-symbols-outlined text-[20px]">description</span>
                                                </Link>
                                                <Link
                                                    to={`/admin/quizzes/${quiz.id}`}
                                                    className="rounded-lg p-2 text-slate-500 hover:bg-slate-100 hover:text-dashboard-primary dark:text-slate-400 dark:hover:bg-slate-800"
                                                    title={t('common.edit', { defaultValue: 'Edit' })}
                                                >
                                                    <span className="material-symbols-outlined text-[20px]">edit</span>
                                                </Link>
                                                <button
                                                    onClick={() => handleDelete(quiz.id)}
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

export default AdminQuizPage;
