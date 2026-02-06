import React, { useState, useEffect } from 'react';
import { useTranslation } from 'react-i18next';
import { Dialog } from '@headlessui/react';
import {
    quizApi,
    type QuizDto,

    type SubmitQuizInput
} from '../../services/quizApi';
import { toast } from 'react-hot-toast';

interface QuizModalProps {
    isOpen: boolean;
    onClose: () => void;
}

const QuizModal: React.FC<QuizModalProps> = ({ isOpen, onClose }) => {
    const { t } = useTranslation();
    const [step, setStep] = useState(0); // 0: Contact Info, 1...N: Questions
    const [quiz, setQuiz] = useState<QuizDto | null>(null);
    const [loading, setLoading] = useState(false);
    const [submitting, setSubmitting] = useState(false);
    const [isSuccess, setIsSuccess] = useState(false);

    // Form State
    const [contact, setContact] = useState({
        fullName: '',
        phone: '',
        email: '',
        // These can be special questions or part of contact form if hardcoded
        // But user asked for "Quiz managed by Admin". 
        // So Height/Weight etc should be questions? 
        // User prompt: "Noi dung quiz nhu sau: Ho ten, SDT, Chieu cao..."
        // This implies the form IS the quiz.
    });

    // Answers for dynamic questions
    const [answers, setAnswers] = useState<Record<string, { text?: string, optionId?: string }>>({});

    useEffect(() => {
        if (isOpen && !quiz) {
            fetchActiveQuiz();
        }
    }, [isOpen]);

    const fetchActiveQuiz = async () => {
        try {
            setLoading(true);
            const activeQuiz = await quizApi.getActive();
            if (activeQuiz) {
                setQuiz(activeQuiz);
            }
        } catch (error) {
            console.error(error);
            toast.error(t('quiz.loadError', { defaultValue: 'Failed to load quiz' }));
        } finally {
            setLoading(false);
        }
    };

    const handleNext = () => {
        // Validate current step
        if (step === 0) {
            if (!contact.fullName || !contact.phone) {
                toast.error(t('quiz.required'));
                return;
            }
        }

        // If dynamic quiz is loaded, navigate through questions
        // If no quiz, maybe we are just collecting contact info?
        // Assuming we rely on the Quiz from DB.

        if (quiz && step > 0 && step <= quiz.questions.length) {
            const currentQuestion = quiz.questions[step - 1];
            if (currentQuestion.isRequired) {
                const answer = answers[currentQuestion.id];
                if (!answer || (!answer.text && !answer.optionId)) {
                    toast.error(t('quiz.required'));
                    return;
                }
            }
        }

        if (quiz && step < quiz.questions.length) {
            setStep(prev => prev + 1);
        } else if (step === 0 && (!quiz || quiz.questions.length === 0)) {
            // No questions, just submit contact?
            handleSubmit();
        } else {
            handleSubmit();
        }
    };

    const handlePrev = () => {
        setStep(prev => Math.max(0, prev - 1));
    };

    const handleSubmit = async () => {
        if (!quiz) return;
        setSubmitting(true);
        try {
            const payload: SubmitQuizInput = {
                quizId: quiz.id,
                fullName: contact.fullName,
                phoneNumber: contact.phone,
                email: contact.email,
                answers: Object.entries(answers).map(([qId, val]) => ({
                    questionId: qId,
                    textValue: val.text,
                    selectedOptionId: val.optionId
                }))
            };

            await quizApi.submit(payload);
            setIsSuccess(true);
        } catch (error) {
            console.error(error);
            toast.error(t('quiz.submitError', { defaultValue: 'Failed to submit quiz' }));
        } finally {
            setSubmitting(false);
        }
    };

    // Fallback if no quiz found? 
    // Show "Survey currently unavailable" or a hardcoded fallback if desired.
    // Given the task, ideally Admin creates the quiz.

    if (!isOpen) return null;

    return (
        <Dialog open={isOpen} onClose={() => !submitting && onClose()} className="relative z-50">
            {/* Backdrop */}
            <div className="fixed inset-0 bg-black/30 backdrop-blur-sm" aria-hidden="true" />

            <div className="fixed inset-0 flex items-center justify-center p-4">
                <Dialog.Panel className="w-full max-w-2xl bg-white dark:bg-gray-800 rounded-2xl shadow-xl overflow-hidden flex flex-col max-h-[90vh]">
                    {/* Header */}
                    <div className="bg-primary px-6 py-4 flex items-center justify-between">
                        <Dialog.Title className="text-white font-bold text-lg">
                            {t('home.quiz.title')}
                        </Dialog.Title>
                        {!submitting && !isSuccess && (
                            <button onClick={onClose} className="text-white/80 hover:text-white">
                                <span className="material-symbols-outlined">close</span>
                            </button>
                        )}
                    </div>

                    {/* Content */}
                    <div className="p-6 overflow-y-auto flex-grow">
                        {loading ? (
                            <div className="flex flex-col items-center justify-center py-12">
                                <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-primary"></div>
                                <p className="mt-4 text-gray-500">{t('common.loading')}</p>
                            </div>
                        ) : isSuccess ? (
                            <div className="text-center py-12">
                                <div className="w-16 h-16 bg-green-100 text-green-600 rounded-full flex items-center justify-center mx-auto mb-4">
                                    <span className="material-symbols-outlined text-3xl">check</span>
                                </div>
                                <h3 className="text-xl font-bold mb-2 dark:text-white">{t('home.quiz.success')}</h3>
                                <p className="text-gray-500 dark:text-gray-400 mb-6">
                                    {t('home.quiz.successMessage', { defaultValue: 'We will contact you shortly.' })}
                                </p>
                                <button
                                    onClick={onClose}
                                    className="px-6 py-2 bg-primary text-white rounded-lg font-bold hover:bg-primary/90"
                                >
                                    {t('home.quiz.close')}
                                </button>
                            </div>
                        ) : !quiz ? (
                            <div className="text-center py-12">
                                <span className="material-symbols-outlined text-gray-300 text-6xl mb-4">assignment_late</span>
                                <p className="text-gray-500">{t('home.quiz.unavailable', { defaultValue: 'Survey is currently unavailable.' })}</p>
                            </div>
                        ) : (
                            <div className="max-w-xl mx-auto">
                                {/* Progress Bar */}
                                <div className="mb-8">
                                    <div className="flex justify-between text-xs text-gray-500 mb-1">
                                        <span>Step {step + 1} of {quiz.questions.length + 1}</span>
                                        <span>{Math.round(((step + 1) / (quiz.questions.length + 1)) * 100)}%</span>
                                    </div>
                                    <div className="h-2 bg-gray-100 dark:bg-gray-700 rounded-full overflow-hidden">
                                        <div
                                            className="h-full bg-primary transition-all duration-300 ease-out"
                                            style={{ width: `${((step + 1) / (quiz.questions.length + 1)) * 100}%` }}
                                        />
                                    </div>
                                </div>

                                {step === 0 && (
                                    <div className="space-y-4 animate-fadeIn">
                                        <h3 className="text-xl font-bold dark:text-white mb-2">{t('home.quiz.contactInfo')}</h3>

                                        <div>
                                            <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                                                {t('home.quiz.fields.fullName')} <span className="text-red-500">*</span>
                                            </label>
                                            <input
                                                type="text"
                                                className="w-full px-4 py-2 rounded-lg border border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-700 dark:text-white focus:ring-2 focus:ring-primary focus:border-transparent outline-none transition-all"
                                                value={contact.fullName}
                                                onChange={e => setContact({ ...contact, fullName: e.target.value })}
                                                placeholder={t('home.quiz.fields.fullNamePlaceholder')}
                                            />
                                        </div>

                                        <div>
                                            <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                                                {t('home.quiz.fields.phone')} <span className="text-red-500">*</span>
                                            </label>
                                            <input
                                                type="tel"
                                                className="w-full px-4 py-2 rounded-lg border border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-700 dark:text-white focus:ring-2 focus:ring-primary focus:border-transparent outline-none transition-all"
                                                value={contact.phone}
                                                onChange={e => setContact({ ...contact, phone: e.target.value })}
                                                placeholder={t('home.quiz.fields.phonePlaceholder')}
                                            />
                                        </div>

                                        <div>
                                            <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1">
                                                {t('home.quiz.fields.email')}
                                            </label>
                                            <input
                                                type="email"
                                                className="w-full px-4 py-2 rounded-lg border border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-700 dark:text-white focus:ring-2 focus:ring-primary focus:border-transparent outline-none transition-all"
                                                value={contact.email}
                                                onChange={e => setContact({ ...contact, email: e.target.value })}
                                                placeholder={t('home.quiz.fields.emailPlaceholder')}
                                            />
                                        </div>
                                    </div>
                                )}

                                {step > 0 && (
                                    <div className="space-y-6 animate-fadeIn">
                                        {/* Question Display */}
                                        {(() => {
                                            const q = quiz.questions[step - 1];
                                            const answer = answers[q.id] || {};

                                            return (
                                                <div>
                                                    <h3 className="text-xl font-bold dark:text-white mb-4">
                                                        {q.text} {q.isRequired && <span className="text-red-500">*</span>}
                                                    </h3>

                                                    {/* Render based on Type */}
                                                    {/* 0: Text, 1: MultiChoice, 2: SingleChoice, 3: LongText */}

                                                    {(q.type === 0 || q.type === 3) && (
                                                        <textarea
                                                            className="w-full px-4 py-3 rounded-xl border border-gray-300 dark:border-gray-600 bg-white dark:bg-gray-700 dark:text-white focus:ring-2 focus:ring-primary outline-none min-h-[120px]"
                                                            placeholder={t('home.quiz.fields.answerPlaceholder')}
                                                            value={answer.text || ''}
                                                            onChange={(e) => setAnswers({
                                                                ...answers,
                                                                [q.id]: { ...answer, text: e.target.value }
                                                            })}
                                                        />
                                                    )}

                                                    {(q.type === 1 || q.type === 2) && (
                                                        <div className="space-y-3">
                                                            {q.options.map(opt => (
                                                                <label
                                                                    key={opt.id}
                                                                    className={`flex items-center p-4 rounded-xl border-2 cursor-pointer transition-all ${answer.optionId === opt.id
                                                                        ? 'border-primary bg-primary/5 dark:bg-primary/20'
                                                                        : 'border-gray-200 dark:border-gray-700 hover:border-primary/50'
                                                                        }`}
                                                                >
                                                                    <div className={`w-5 h-5 rounded-full border-2 flex items-center justify-center mr-3 ${answer.optionId === opt.id ? 'border-primary' : 'border-gray-400'
                                                                        }`}>
                                                                        {answer.optionId === opt.id && (
                                                                            <div className="w-2.5 h-2.5 rounded-full bg-primary" />
                                                                        )}
                                                                    </div>
                                                                    <input
                                                                        type="radio"
                                                                        name={`q-${q.id}`}
                                                                        className="hidden"
                                                                        checked={answer.optionId === opt.id}
                                                                        onChange={() => setAnswers({
                                                                            ...answers,
                                                                            [q.id]: { ...answer, optionId: opt.id, text: opt.value } // Store value if needed
                                                                        })}
                                                                    />
                                                                    <span className="font-medium dark:text-white">{opt.text}</span>
                                                                </label>
                                                            ))}
                                                        </div>
                                                    )}
                                                </div>
                                            );
                                        })()}
                                    </div>
                                )}

                                {/* Navigation Buttons */}
                                <div className="flex justify-between mt-8 pt-6 border-t border-gray-100 dark:border-gray-700">
                                    <button
                                        onClick={handlePrev}
                                        disabled={step === 0}
                                        className={`px-6 py-2 rounded-lg font-medium transition-colors ${step === 0
                                            ? 'text-gray-400 cursor-not-allowed'
                                            : 'text-gray-600 dark:text-gray-300 hover:bg-gray-100 dark:hover:bg-gray-700'
                                            }`}
                                    >
                                        {t('home.quiz.back')}
                                    </button>
                                    <button
                                        onClick={handleNext}
                                        key={step}
                                        className="px-8 py-2 bg-primary text-white rounded-lg font-bold hover:bg-primary/90 shadow-lg shadow-primary/25 transition-all active:scale-95"
                                    >
                                        {step === (quiz?.questions.length || 0)
                                            ? (submitting ? t('common.sending') : t('home.quiz.submit'))
                                            : t('home.quiz.next')}
                                    </button>
                                </div>
                            </div>
                        )}
                    </div>
                </Dialog.Panel>
            </div>
        </Dialog>
    );
};

export default QuizModal;
