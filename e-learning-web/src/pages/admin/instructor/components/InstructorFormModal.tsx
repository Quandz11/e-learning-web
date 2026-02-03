import React, { useState, useEffect } from 'react';
import { useTranslation } from 'react-i18next';
import { instructorApi, type InstructorDto, type InstructorStatus, type CreateInstructorRequest, type UpdateInstructorRequest } from '../../../../services/instructorApi';

interface InstructorFormModalProps {
    isOpen: boolean;
    onClose: () => void;
    onSuccess: () => void;
    editingId: string | null;
    initialData: InstructorDto | null;
}

const statuses: InstructorStatus[] = ['ACTIVE', 'INACTIVE', 'SUSPENDED'];

const InstructorFormModal: React.FC<InstructorFormModalProps> = ({
    isOpen,
    onClose,
    onSuccess,
    editingId,
    initialData,
}) => {
    const { t } = useTranslation();
    const [email, setEmail] = useState('');
    const [password, setPassword] = useState('');
    const [fullName, setFullName] = useState('');
    const [phone, setPhone] = useState('');
    const [avatarUrl, setAvatarUrl] = useState('');
    const [status, setStatus] = useState<InstructorStatus>('ACTIVE');
    const [showPassword, setShowPassword] = useState(false);
    const [saving, setSaving] = useState(false);
    const [error, setError] = useState<string | null>(null);

    const isEditing = !!editingId;

    useEffect(() => {
        if (isOpen) {
            if (initialData) {
                setEmail(initialData.email);
                setFullName(initialData.fullName || '');
                setPhone(initialData.phone || '');
                setAvatarUrl(initialData.avatarUrl || '');
                setStatus(initialData.status);
            } else {
                resetForm();
            }
            setError(null);
        }
    }, [isOpen, initialData]);

    const resetForm = () => {
        setEmail('');
        setPassword('');
        setFullName('');
        setPhone('');
        setAvatarUrl('');
        setStatus('ACTIVE');
        setShowPassword(false);
    };

    const handleSubmit = async (e: React.FormEvent) => {
        e.preventDefault();
        setError(null);

        // Validation
        if (!email.trim()) {
            setError(t('admin.instructors.errors.emailRequired'));
            return;
        }
        if (!isEditing && !password) {
            setError(t('admin.instructors.errors.passwordRequired'));
            return;
        }
        if (!isEditing && password.length < 8) {
            setError(t('admin.instructors.errors.passwordLength'));
            return;
        }

        setSaving(true);
        try {
            if (isEditing && editingId) {
                const payload: UpdateInstructorRequest = {
                    fullName: fullName.trim() || undefined,
                    phone: phone.trim() || undefined,
                    status,
                    avatarUrl: avatarUrl.trim() || undefined,
                };
                await instructorApi.update(editingId, payload);
            } else {
                const payload: CreateInstructorRequest = {
                    email: email.trim(),
                    password,
                    fullName: fullName.trim() || undefined,
                    phone: phone.trim() || undefined,
                    status,
                    avatarUrl: avatarUrl.trim() || undefined,
                };
                await instructorApi.create(payload);
            }
            onSuccess();
            onClose();
        } catch (err: any) {
            setError(err.message || t('admin.instructors.errors.saveFailed'));
        } finally {
            setSaving(false);
        }
    };

    if (!isOpen) return null;

    const statusLabel = (value: InstructorStatus) => t(`admin.instructors.statuses.${value}`);

    return (
        <div className="fixed inset-0 z-[100] flex items-center justify-center bg-black/50 p-4">
            <div className="w-full max-w-lg rounded-xl bg-white shadow-xl dark:bg-slate-900">
                <div className="border-b border-slate-200 px-6 py-4 dark:border-slate-800">
                    <h2 className="text-xl font-bold text-slate-900 dark:text-white">
                        {isEditing ? t('admin.instructors.form.editTitle') : t('admin.instructors.form.newTitle')}
                    </h2>
                </div>

                <form onSubmit={handleSubmit} className="p-6 space-y-4">
                    {error && (
                        <div className="rounded-lg border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-700 dark:border-red-900/50 dark:bg-red-900/20 dark:text-red-200">
                            {error}
                        </div>
                    )}

                    <div>
                        <label className="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-1">
                            {t('admin.instructors.form.email')} <span className="text-red-500">*</span>
                        </label>
                        <input
                            type="email"
                            className="w-full rounded-lg border border-slate-200 bg-white px-3 py-2 text-sm focus:border-dashboard-primary focus:outline-none dark:border-slate-700 dark:bg-slate-800"
                            value={email}
                            onChange={(e) => setEmail(e.target.value)}
                            disabled={isEditing}
                            required
                        />
                    </div>

                    {!isEditing && (
                        <div>
                            <label className="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-1">
                                {t('admin.instructors.form.password')} <span className="text-red-500">*</span>
                            </label>
                            <div className="relative">
                                <input
                                    type={showPassword ? 'text' : 'password'}
                                    className="w-full rounded-lg border border-slate-200 bg-white px-3 py-2 text-sm focus:border-dashboard-primary focus:outline-none dark:border-slate-700 dark:bg-slate-800"
                                    value={password}
                                    onChange={(e) => setPassword(e.target.value)}
                                    required
                                    minLength={8}
                                />
                                <button
                                    type="button"
                                    onClick={() => setShowPassword(!showPassword)}
                                    className="absolute right-2 top-1/2 -translate-y-1/2 text-slate-400 hover:text-slate-600"
                                >
                                    <span className="material-symbols-outlined text-[20px]">
                                        {showPassword ? 'visibility_off' : 'visibility'}
                                    </span>
                                </button>
                            </div>
                            <p className="mt-1 text-xs text-slate-500">{t('admin.instructors.form.passwordHint')}</p>
                        </div>
                    )}

                    <div>
                        <label className="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-1">
                            {t('admin.instructors.form.fullName')}
                        </label>
                        <input
                            type="text"
                            className="w-full rounded-lg border border-slate-200 bg-white px-3 py-2 text-sm focus:border-dashboard-primary focus:outline-none dark:border-slate-700 dark:bg-slate-800"
                            value={fullName}
                            onChange={(e) => setFullName(e.target.value)}
                        />
                    </div>

                    <div>
                        <label className="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-1">
                            {t('admin.instructors.form.phone')}
                        </label>
                        <input
                            type="tel"
                            className="w-full rounded-lg border border-slate-200 bg-white px-3 py-2 text-sm focus:border-dashboard-primary focus:outline-none dark:border-slate-700 dark:bg-slate-800"
                            value={phone}
                            onChange={(e) => setPhone(e.target.value)}
                        />
                    </div>

                    <div>
                        <label className="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-1">
                            {t('admin.instructors.form.avatar')}
                        </label>
                        <input
                            type="url"
                            className="w-full rounded-lg border border-slate-200 bg-white px-3 py-2 text-sm focus:border-dashboard-primary focus:outline-none dark:border-slate-700 dark:bg-slate-800"
                            value={avatarUrl}
                            onChange={(e) => setAvatarUrl(e.target.value)}
                            placeholder="https://..."
                        />
                    </div>

                    <div>
                        <label className="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-1">
                            {t('admin.instructors.form.status')} <span className="text-red-500">*</span>
                        </label>
                        <select
                            className="w-full rounded-lg border border-slate-200 bg-white px-3 py-2 text-sm focus:border-dashboard-primary focus:outline-none dark:border-slate-700 dark:bg-slate-800"
                            value={status}
                            onChange={(e) => setStatus(e.target.value as InstructorStatus)}
                            required
                        >
                            {statuses.map((s) => (
                                <option key={s} value={s}>{statusLabel(s)}</option>
                            ))}
                        </select>
                    </div>

                    <div className="flex gap-3 pt-4">
                        <button
                            type="button"
                            onClick={onClose}
                            className="flex-1 rounded-lg border border-slate-200 px-4 py-2 text-sm font-medium text-slate-700 transition hover:bg-slate-100 dark:border-slate-700 dark:text-slate-200 dark:hover:bg-slate-800"
                            disabled={saving}
                        >
                            {t('admin.instructors.form.cancel')}
                        </button>
                        <button
                            type="submit"
                            className="flex-1 rounded-lg bg-dashboard-primary px-4 py-2 text-sm font-medium text-white shadow-sm transition hover:bg-dashboard-primary-dark disabled:opacity-50"
                            disabled={saving}
                        >
                            {saving ? t('common.saving') : t('admin.instructors.form.save')}
                        </button>
                    </div>
                </form>
            </div>
        </div>
    );
};

export default InstructorFormModal;
