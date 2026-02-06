import React, { useEffect, useState } from 'react';
import { useTranslation } from 'react-i18next';
import { useParams, Link } from 'react-router-dom';
import AdminLayout from '../../../components/admin/AdminLayout';
import { quizApi, type QuizDto, type QuizSubmissionDto } from '../../../services/quizApi';
import { toast } from 'react-hot-toast';

const AdminQuizSubmissionsPage: React.FC = () => {
    const { t } = useTranslation();
    const { id } = useParams<{ id: string }>(); // Quiz ID
    const [quiz, setQuiz] = useState<QuizDto | null>(null);
    const [submissions, setSubmissions] = useState<QuizSubmissionDto[]>([]);
    const [loading, setLoading] = useState(true);

    useEffect(() => {
        if (id) {
            fetchData(id);
        }
    }, [id]);

    const fetchData = async (quizId: string) => {
        try {
            setLoading(true);
            const [quizData, submissionsData] = await Promise.all([
                quizApi.getById(quizId),
                quizApi.getSubmissions(quizId)
            ]);
            setQuiz(quizData);
            setSubmissions(submissionsData);
        } catch (error) {
            console.error(error);
            toast.error(t('admin.quiz.loadError', { defaultValue: 'Failed to load data' }));
        } finally {
            setLoading(false);
        }
    };

    if (loading) {
        return (
            <AdminLayout>
                <div className="p-8 text-center text-gray-500">{t('common.loading', { defaultValue: 'Loading...' })}</div>
            </AdminLayout>
        );
    }

    if (!quiz) {
        return (
            <AdminLayout>
                <div className="p-8 text-center text-red-500">{t('admin.quiz.notFound', { defaultValue: 'Quiz not found' })}</div>
            </AdminLayout>
        );
    }

    return (
        <AdminLayout>
            <div className="mx-auto max-w-7xl">
                <div className="mb-6 flex items-center justify-between">
                    <div>
                        <div className="mb-2 flex items-center gap-2 text-sm text-slate-500">
                            <Link to="/admin/quizzes" className="hover:text-dashboard-primary">{t('admin.quiz.title', { defaultValue: 'Quizzes' })}</Link>
                            <span>/</span>
                            <span>{quiz.title}</span>
                        </div>
                        <h1 className="text-2xl font-bold text-slate-900 dark:text-white">
                            {t('admin.quiz.submissions.title', { defaultValue: 'Submissions' })}
                        </h1>
                    </div>
                </div>

                <div className="rounded-xl border border-slate-200 bg-white shadow-sm dark:border-slate-700 dark:bg-dashboard-surface-dark overflow-hidden">
                    <div className="overflow-x-auto">
                        <table className="w-full text-left text-sm">
                            <thead className="bg-slate-50 text-xs uppercase text-slate-500 dark:bg-slate-800/50 dark:text-slate-400">
                                <tr>
                                    <th className="px-6 py-4 font-semibold">{t('admin.quiz.submissions.submittedAt', { defaultValue: 'Submitted At' })}</th>
                                    <th className="px-6 py-4 font-semibold">{t('admin.quiz.submissions.contactInfo', { defaultValue: 'Contact Info' })}</th>
                                    <th className="px-6 py-4 font-semibold">{t('admin.quiz.submissions.answers', { defaultValue: 'Answers' })}</th>
                                </tr>
                            </thead>
                            <tbody className="divide-y divide-slate-200 dark:divide-slate-700">
                                {submissions.length === 0 ? (
                                    <tr><td colSpan={3} className="p-8 text-center text-slate-500">{t('admin.quiz.submissions.noSubmissions', { defaultValue: 'No submissions yet.' })}</td></tr>
                                ) : (
                                    submissions.map((sub) => (
                                        <tr key={sub.id} className="hover:bg-slate-50 dark:hover:bg-slate-800/50 align-top">
                                            <td className="px-6 py-4 text-slate-500 dark:text-slate-400 whitespace-nowrap">
                                                {new Date(sub.submittedAt).toLocaleString()}
                                            </td>
                                            <td className="px-6 py-4">
                                                <div className="flex flex-col">
                                                    <span className="font-bold text-slate-900 dark:text-white">{sub.fullName}</span>
                                                    <span className="text-slate-500">{sub.phoneNumber}</span>
                                                    <span className="text-slate-400 text-xs">{sub.email}</span>
                                                </div>
                                            </td>
                                            <td className="px-6 py-4">
                                                <div className="space-y-3 max-h-60 overflow-y-auto pr-2">
                                                    {sub.answers.map((ans, idx) => (
                                                        <div key={idx} className="bg-slate-50 dark:bg-slate-800 p-2 rounded">
                                                            <p className="text-xs font-bold text-slate-500 uppercase mb-1">{ans.questionText}</p>
                                                            <p className="text-slate-800 dark:text-slate-200">
                                                                {ans.selectedOptionText || ans.textValue || <span className="italic text-slate-400">{t('admin.quiz.submissions.noAnswer', { defaultValue: 'No Answer' })}</span>}
                                                            </p>
                                                        </div>
                                                    ))}
                                                </div>
                                            </td>
                                        </tr>
                                    ))
                                )}
                            </tbody>
                        </table>
                    </div>
                </div>
            </div>
        </AdminLayout>
    );
};

export default AdminQuizSubmissionsPage;
