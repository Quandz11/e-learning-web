import React, { useEffect, useState } from 'react';
import { useTranslation } from 'react-i18next';
import { Link, useNavigate, useParams } from 'react-router-dom';
import AdminLayout from '../../../components/admin/AdminLayout';
import { quizApi, QuestionType, type CreateQuizInput, type CreateQuestionInput, type CreateOptionInput } from '../../../services/quizApi';
import { toast } from 'react-hot-toast';

const AdminQuizEditorPage: React.FC = () => {
    const { t } = useTranslation();
    const navigate = useNavigate();
    const { id } = useParams<{ id: string }>();
    const isEditMode = !!id;

    const [loading, setLoading] = useState(false);
    const [submitting, setSubmitting] = useState(false);

    const [formData, setFormData] = useState<CreateQuizInput>({
        title: '',
        description: '',
        isActive: true,
        questions: []
    });

    useEffect(() => {
        if (isEditMode && id) {
            fetchQuiz(id);
        }
    }, [isEditMode, id]);

    const fetchQuiz = async (quizId: string) => {
        try {
            setLoading(true);
            const data = await quizApi.getById(quizId);
            setFormData({
                title: data.title,
                description: data.description,
                isActive: data.isActive,
                questions: data.questions.map(q => ({
                    id: q.id,
                    text: q.text,
                    type: q.type,
                    order: q.order,
                    isRequired: q.isRequired,
                    options: q.options.map(o => ({
                        id: o.id,
                        text: o.text,
                        value: o.value,
                        order: o.order
                    }))
                }))
            });
        } catch (error) {
            console.error(error);
            toast.error(t('admin.quiz.loadError', { defaultValue: 'Failed to load quiz' }));
            navigate('/admin/quizzes');
        } finally {
            setLoading(false);
        }
    };

    const handleSubmit = async (e: React.FormEvent) => {
        e.preventDefault();
        setSubmitting(true);
        try {
            if (isEditMode && id) {
                await quizApi.update(id, formData);
                toast.success(t('common.updateSuccess', { defaultValue: 'Updated successfully' }));
            } else {
                await quizApi.create(formData);
                toast.success(t('common.createSuccess', { defaultValue: 'Created successfully' }));
            }
            navigate('/admin/quizzes');
        } catch (error) {
            console.error(error);
            toast.error(t('common.error', { defaultValue: 'An error occurred' }));
        } finally {
            setSubmitting(false);
        }
    };

    const addQuestion = () => {
        setFormData(prev => ({
            ...prev,
            questions: [
                ...prev.questions,
                {
                    text: '',
                    type: QuestionType.Text,
                    order: prev.questions.length + 1,
                    isRequired: false,
                    options: []
                }
            ]
        }));
    };

    const removeQuestion = (index: number) => {
        setFormData(prev => ({
            ...prev,
            questions: prev.questions.filter((_, i) => i !== index)
        }));
    };

    const updateQuestion = (index: number, field: keyof CreateQuestionInput, value: any) => {
        setFormData(prev => {
            const newQuestions = [...prev.questions];
            newQuestions[index] = { ...newQuestions[index], [field]: value };
            return { ...prev, questions: newQuestions };
        });
    };

    const addOption = (qIndex: number) => {
        setFormData(prev => {
            const newQuestions = [...prev.questions];
            const currentOptions = newQuestions[qIndex].options;
            newQuestions[qIndex].options = [
                ...currentOptions,
                { text: '', value: '', order: currentOptions.length + 1 }
            ];
            return { ...prev, questions: newQuestions };
        });
    };

    const removeOption = (qIndex: number, oIndex: number) => {
        setFormData(prev => {
            const newQuestions = [...prev.questions];
            newQuestions[qIndex].options = newQuestions[qIndex].options.filter((_, i) => i !== oIndex);
            return { ...prev, questions: newQuestions };
        });
    };

    const updateOption = (qIndex: number, oIndex: number, field: keyof CreateOptionInput, value: any) => {
        setFormData(prev => {
            const newQuestions = [...prev.questions];
            const newOptions = [...newQuestions[qIndex].options];
            newOptions[oIndex] = { ...newOptions[oIndex], [field]: value };
            newQuestions[qIndex].options = newOptions;
            return { ...prev, questions: newQuestions };
        });
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
            <div className="mx-auto max-w-4xl">
                <div className="mb-6 flex items-center justify-between">
                    <div>
                        <h1 className="text-2xl font-bold text-slate-900 dark:text-white">
                            {isEditMode ? t('admin.quiz.edit', { defaultValue: 'Edit Quiz' }) : t('admin.quiz.create', { defaultValue: 'Create Quiz' })}
                        </h1>
                    </div>
                    <div className="flex gap-2">
                        <Link
                            to="/admin/quizzes"
                            className="rounded-lg px-4 py-2 text-sm font-medium text-slate-600 hover:bg-slate-100 dark:text-slate-400 dark:hover:bg-slate-800"
                        >
                            {t('common.cancel', { defaultValue: 'Cancel' })}
                        </Link>
                        <button
                            onClick={handleSubmit}
                            disabled={submitting}
                            className="rounded-lg bg-dashboard-primary px-6 py-2 text-sm font-bold text-white shadow-dashboard-primary/20 hover:bg-dashboard-primary-dark disabled:opacity-50"
                        >
                            {submitting ? t('common.saving', { defaultValue: 'Saving...' }) : t('common.save', { defaultValue: 'Save Quiz' })}
                        </button>
                    </div>
                </div>

                <div className="space-y-6">
                    {/* Basic Info */}
                    <div className="rounded-xl border border-slate-200 bg-white p-6 shadow-sm dark:border-slate-700 dark:bg-dashboard-surface-dark">
                        <h2 className="mb-4 text-lg font-bold text-slate-900 dark:text-white">{t('admin.quiz.form.basicInfo', { defaultValue: 'Basic Information' })}</h2>
                        <div className="grid gap-4">
                            <div>
                                <label className="mb-1 block text-sm font-medium text-slate-700 dark:text-slate-300">
                                    {t('admin.quiz.form.title', { defaultValue: 'Title' })} <span className="text-red-500">*</span>
                                </label>
                                <input
                                    type="text"
                                    required
                                    className="w-full rounded-lg border border-slate-300 px-3 py-2 dark:border-slate-600 dark:bg-slate-800 dark:text-white"
                                    value={formData.title}
                                    onChange={e => setFormData({ ...formData, title: e.target.value })}
                                    placeholder={t('admin.quiz.form.titlePlaceholder', { defaultValue: 'Quiz Title' })}
                                />
                            </div>
                            <div>
                                <label className="mb-1 block text-sm font-medium text-slate-700 dark:text-slate-300">
                                    {t('admin.quiz.form.description', { defaultValue: 'Description' })}
                                </label>
                                <textarea
                                    className="w-full rounded-lg border border-slate-300 px-3 py-2 dark:border-slate-600 dark:bg-slate-800 dark:text-white"
                                    rows={3}
                                    value={formData.description || ''}
                                    onChange={e => setFormData({ ...formData, description: e.target.value })}
                                    placeholder={t('admin.quiz.form.descriptionPlaceholder', { defaultValue: 'Quiz Description' })}
                                />
                            </div>
                            <div className="flex items-center gap-2">
                                <input
                                    type="checkbox"
                                    id="isActive"
                                    className="h-4 w-4 rounded border-slate-300 text-dashboard-primary focus:ring-dashboard-primary"
                                    checked={formData.isActive}
                                    onChange={e => setFormData({ ...formData, isActive: e.target.checked })}
                                />
                                <label htmlFor="isActive" className="text-sm font-medium text-slate-700 dark:text-slate-300">
                                    {t('admin.quiz.form.isActive', { defaultValue: 'Active (Visible to users)' })}
                                </label>
                            </div>
                        </div>
                    </div>

                    {/* Questions */}
                    <div className="space-y-4">
                        <div className="flex items-center justify-between">
                            <h2 className="text-xl font-bold text-slate-900 dark:text-white">{t('admin.quiz.form.questions', { defaultValue: 'Questions' })}</h2>
                            <button
                                type="button"
                                onClick={addQuestion}
                                className="flex items-center gap-1 text-sm font-bold text-dashboard-primary hover:text-dashboard-primary-dark"
                            >
                                <span className="material-symbols-outlined text-[18px]">add_circle</span>
                                {t('admin.quiz.form.addQuestion', { defaultValue: 'Add Question' })}
                            </button>
                        </div>

                        {formData.questions.map((q, qIndex) => (
                            <div key={qIndex} className="rounded-xl border border-slate-200 bg-white p-6 shadow-sm dark:border-slate-700 dark:bg-dashboard-surface-dark relative group">
                                <button
                                    onClick={() => removeQuestion(qIndex)}
                                    className="absolute top-4 right-4 text-slate-400 hover:text-red-500 p-1"
                                    title="Remove Question"
                                >
                                    <span className="material-symbols-outlined">delete</span>
                                </button>

                                <div className="grid gap-4 md:grid-cols-12 mb-4">
                                    <div className="md:col-span-1 flex items-center justify-center">
                                        <span className="h-8 w-8 rounded-full bg-slate-100 flex items-center justify-center font-bold text-slate-500 text-sm">
                                            {qIndex + 1}
                                        </span>
                                    </div>
                                    <div className="md:col-span-11 grid gap-4">
                                        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                                            <div>
                                                <label className="mb-1 block text-xs font-bold uppercase text-slate-500">{t('admin.quiz.form.questionText', { defaultValue: 'Question Text' })}</label>
                                                <input
                                                    type="text"
                                                    required
                                                    className="w-full rounded-lg border border-slate-300 px-3 py-2 dark:border-slate-600 dark:bg-slate-800 dark:text-white"
                                                    value={q.text}
                                                    onChange={e => updateQuestion(qIndex, 'text', e.target.value)}
                                                />
                                            </div>
                                            <div>
                                                <label className="mb-1 block text-xs font-bold uppercase text-slate-500">{t('admin.quiz.form.type', { defaultValue: 'Type' })}</label>
                                                <select
                                                    className="w-full rounded-lg border border-slate-300 px-3 py-2 dark:border-slate-600 dark:bg-slate-800 dark:text-white"
                                                    value={q.type}
                                                    onChange={e => updateQuestion(qIndex, 'type', Number(e.target.value))}
                                                >
                                                    <option value={QuestionType.Text}>{t('admin.quiz.types.text', { defaultValue: 'Text Input' })}</option>
                                                    <option value={QuestionType.MultipleChoice}>{t('admin.quiz.types.multipleChoice', { defaultValue: 'Multiple Choice' })}</option>
                                                    <option value={QuestionType.SingleChoice}>{t('admin.quiz.types.singleChoice', { defaultValue: 'Single Choice' })}</option>
                                                    <option value={QuestionType.LongText}>{t('admin.quiz.types.longText', { defaultValue: 'Long Text' })}</option>
                                                </select>
                                            </div>
                                        </div>
                                        <div className="flex items-center gap-4">
                                            <div className="flex items-center gap-2">
                                                <input
                                                    type="checkbox"
                                                    id={`req-${qIndex}`}
                                                    checked={q.isRequired}
                                                    onChange={e => updateQuestion(qIndex, 'isRequired', e.target.checked)}
                                                    className="rounded border-slate-300 text-dashboard-primary focus:ring-dashboard-primary"
                                                />
                                                <label htmlFor={`req-${qIndex}`} className="text-sm text-slate-600 dark:text-slate-400">{t('admin.quiz.form.required', { defaultValue: 'Required' })}</label>
                                            </div>
                                            <div className="flex items-center gap-2">
                                                <label className="text-sm text-slate-600 dark:text-slate-400">{t('admin.quiz.form.order', { defaultValue: 'Order' })}:</label>
                                                <input
                                                    type="number"
                                                    className="w-20 rounded-lg border border-slate-300 px-2 py-1 text-sm dark:border-slate-600 dark:bg-slate-800 dark:text-white"
                                                    value={q.order}
                                                    onChange={e => updateQuestion(qIndex, 'order', Number(e.target.value))}
                                                />
                                            </div>
                                        </div>
                                    </div>
                                </div>

                                {/* Options Section for Choice Types */}
                                {(q.type === QuestionType.MultipleChoice || q.type === QuestionType.SingleChoice) && (
                                    <div className="mt-4 border-t border-slate-100 pt-4 dark:border-slate-700 pl-4 md:pl-12">
                                        <div className="mb-2 flex items-center justify-between">
                                            <span className="text-sm font-bold text-slate-500">{t('admin.quiz.form.options', { defaultValue: 'Options' })}</span>
                                            <button
                                                type="button"
                                                onClick={() => addOption(qIndex)}
                                                className="text-xs font-bold text-dashboard-primary hover:underline"
                                            >
                                                + {t('admin.quiz.form.addOption', { defaultValue: 'Add Option' })}
                                            </button>
                                        </div>
                                        <div className="space-y-2">
                                            {q.options.map((opt, oIndex) => (
                                                <div key={oIndex} className="flex items-center gap-2">
                                                    <span className="text-xs text-slate-400">{oIndex + 1}.</span>
                                                    <input
                                                        type="text"
                                                        placeholder={t('admin.quiz.form.optionPlaceholder', { defaultValue: 'Option Text' })}
                                                        className="flex-1 rounded-md border border-slate-300 px-3 py-1.5 text-sm dark:border-slate-600 dark:bg-slate-800 dark:text-white"
                                                        value={opt.text}
                                                        onChange={e => updateOption(qIndex, oIndex, 'text', e.target.value)}
                                                    />
                                                    <button
                                                        onClick={() => removeOption(qIndex, oIndex)}
                                                        className="text-slate-400 hover:text-red-500"
                                                    >
                                                        <span className="material-symbols-outlined text-[18px]">close</span>
                                                    </button>
                                                </div>
                                            ))}
                                            {q.options.length === 0 && (
                                                <p className="text-xs italic text-red-400">{t('admin.quiz.form.noOptions', { defaultValue: 'Add at least one option.' })}</p>
                                            )}
                                        </div>
                                    </div>
                                )}
                            </div>
                        ))}

                        {formData.questions.length === 0 && (
                            <div className="rounded-xl border border-dashed border-slate-300 p-8 text-center text-slate-500 dark:border-slate-700">
                                {t('admin.quiz.form.noQuestions', { defaultValue: 'No questions added yet. Click "Add Question" to begin.' })}
                            </div>
                        )}
                    </div>
                </div>
            </div>
        </AdminLayout>
    );
};

export default AdminQuizEditorPage;
