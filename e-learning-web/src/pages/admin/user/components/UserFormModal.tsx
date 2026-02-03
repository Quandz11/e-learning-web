import React, { useEffect, useState } from 'react';
import { useTranslation } from 'react-i18next';
import { userApi, type CreateUserRequest, type UpdateUserRequest, type UserDto, type UserRole, type UserStatus } from '../../../../services/userApi';

const roles: UserRole[] = ['ADMIN', 'CARE', 'CABIN_OWNER', 'STUDENT', 'LECTURER'];
const statuses: UserStatus[] = ['ACTIVE', 'INACTIVE', 'SUSPENDED'];

const emptyCreate = (email?: string): CreateUserRequest => ({
    email: email || '',
    password: '',
    fullName: '',
    phone: '',
    role: 'STUDENT',
    status: 'ACTIVE',
    avatarUrl: '',
});

interface UserFormModalProps {
    isOpen: boolean;
    onClose: () => void;
    onSuccess: () => void;
    editingId?: string | null;
    initialData?: UserDto | null;
}

const UserFormModal: React.FC<UserFormModalProps> = ({ isOpen, onClose, onSuccess, editingId, initialData }) => {
    const { t } = useTranslation();
    const [loading, setLoading] = useState(false);
    const [error, setError] = useState<string | null>(null);
    const [showCreatePassword, setShowCreatePassword] = useState(false);
    const [form, setForm] = useState<CreateUserRequest>(emptyCreate());

    const roleLabel = (value: UserRole) => t(`admin.users.roles.${value}`);
    const statusLabel = (value: UserStatus) => t(`admin.users.statuses.${value}`);

    useEffect(() => {
        if (isOpen) {
            setError(null);
            if (initialData && editingId) {
                // Edit mode
                const update: UpdateUserRequest = {
                    fullName: initialData.fullName,
                    phone: initialData.phone,
                    role: initialData.role,
                    status: initialData.status,
                    avatarUrl: initialData.avatarUrl,
                };
                setForm({ ...emptyCreate(initialData.email), ...update, password: '' });
            } else {
                // Create mode
                setForm(emptyCreate());
            }
        }
    }, [isOpen, editingId, initialData]);

    const save = async () => {
        if (!form.email.trim()) {
            setError(t('admin.users.errors.emailRequired'));
            return;
        }
        if (!editingId && !form.password.trim()) {
            setError(t('admin.users.errors.passwordRequired'));
            return;
        }
        try {
            setLoading(true);
            setError(null);
            if (editingId) {
                const payload: UpdateUserRequest = {
                    fullName: form.fullName,
                    phone: form.phone,
                    role: form.role,
                    status: form.status,
                    avatarUrl: form.avatarUrl,
                };
                await userApi.update(editingId, payload);
            } else {
                await userApi.create(form);
            }
            onSuccess();
            onClose();
        } catch (err: any) {
            setError(err.message || t('admin.users.errors.saveFailed'));
        } finally {
            setLoading(false);
        }
    };

    if (!isOpen) return null;

    return (
        <div className="fixed inset-0 z-[100] flex items-start justify-center overflow-y-auto bg-black/50 p-4">
            <div className="w-full max-w-3xl rounded-2xl border border-slate-200 bg-white shadow-2xl dark:border-slate-700 dark:bg-dashboard-surface-dark">
                <div className="flex items-center justify-between border-b border-slate-200 px-6 py-4 dark:border-slate-700">
                    <div>
                        <h3 className="text-lg font-semibold text-slate-900 dark:text-white">
                            {editingId ? t('admin.users.form.editTitle') : t('admin.users.form.newTitle')}
                        </h3>
                        <p className="text-sm text-slate-500 dark:text-slate-400">{t('admin.users.subtitle')}</p>
                    </div>
                    <button onClick={onClose} className="rounded-full p-2 text-slate-500 hover:bg-slate-100 dark:text-slate-300 dark:hover:bg-slate-800">
                        <span className="material-symbols-outlined">close</span>
                    </button>
                </div>

                <div className="max-h-[70vh] overflow-y-auto px-6 py-5 space-y-4">
                    {error && (
                        <div className="mb-4 rounded-lg border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-700 dark:border-red-900/50 dark:bg-red-900/20 dark:text-red-200">
                            {error}
                        </div>
                    )}

                    <div className="grid grid-cols-1 gap-4 md:grid-cols-2">
                        <div className="space-y-2">
                            <label className="text-sm font-medium text-slate-700 dark:text-slate-200">{t('admin.users.form.email')}</label>
                            <input
                                className="w-full rounded-lg border border-slate-200 bg-slate-50 px-3 py-2 text-sm focus:border-dashboard-primary focus:bg-white focus:outline-none dark:border-slate-700 dark:bg-slate-900"
                                value={form.email}
                                onChange={(e) => setForm({ ...form, email: e.target.value })}
                                disabled={!!editingId}
                            />
                        </div>
                        <div className="space-y-2">
                            <label className="text-sm font-medium text-slate-700 dark:text-slate-200">{t('admin.users.form.fullName')}</label>
                            <input
                                className="w-full rounded-lg border border-slate-200 bg-slate-50 px-3 py-2 text-sm focus:border-dashboard-primary focus:bg-white focus:outline-none dark:border-slate-700 dark:bg-slate-900"
                                value={form.fullName || ''}
                                onChange={(e) => setForm({ ...form, fullName: e.target.value })}
                            />
                        </div>
                        <div className="space-y-2">
                            <label className="text-sm font-medium text-slate-700 dark:text-slate-200">{t('admin.users.form.phone')}</label>
                            <input
                                className="w-full rounded-lg border border-slate-200 bg-slate-50 px-3 py-2 text-sm focus:border-dashboard-primary focus:bg-white focus:outline-none dark:border-slate-700 dark:bg-slate-900"
                                value={form.phone || ''}
                                onChange={(e) => setForm({ ...form, phone: e.target.value })}
                            />
                        </div>
                        <div className="space-y-2">
                            <label className="text-sm font-medium text-slate-700 dark:text-slate-200">{t('admin.users.form.avatar')}</label>
                            <input
                                className="w-full rounded-lg border border-slate-200 bg-slate-50 px-3 py-2 text-sm focus:border-dashboard-primary focus:bg-white focus:outline-none dark:border-slate-700 dark:bg-slate-900"
                                value={form.avatarUrl || ''}
                                onChange={(e) => setForm({ ...form, avatarUrl: e.target.value })}
                            />
                        </div>
                        {!editingId && (
                            <div className="space-y-2">
                                <label className="text-sm font-medium text-slate-700 dark:text-slate-200">{t('admin.users.form.password')}</label>
                                <div className="relative">
                                    <input
                                        className="w-full rounded-lg border border-slate-200 bg-slate-50 px-3 py-2 text-sm focus:border-dashboard-primary focus:bg-white focus:outline-none dark:border-slate-700 dark:bg-slate-900"
                                        type={showCreatePassword ? 'text' : 'password'}
                                        value={form.password}
                                        onChange={(e) => setForm({ ...form, password: e.target.value })}
                                    />
                                    <button
                                        type="button"
                                        className="absolute right-3 top-1/2 -translate-y-1/2 text-xs font-medium text-dashboard-primary hover:text-dashboard-primary-dark"
                                        onClick={() => setShowCreatePassword((v) => !v)}
                                    >
                                        {showCreatePassword ? t('admin.users.passwordToggle.hide') : t('admin.users.passwordToggle.show')}
                                    </button>
                                </div>
                            </div>
                        )}
                        <div className="space-y-2">
                            <label className="text-sm font-medium text-slate-700 dark:text-slate-200">{t('admin.users.form.role')}</label>
                            <select
                                className="w-full rounded-lg border border-slate-200 bg-white px-3 py-2 text-sm dark:border-slate-700 dark:bg-slate-900"
                                value={form.role}
                                onChange={(e) => setForm({ ...form, role: e.target.value as UserRole })}
                            >
                                {roles.map((r) => <option key={r} value={r}>{roleLabel(r)}</option>)}
                            </select>
                        </div>
                        <div className="space-y-2">
                            <label className="text-sm font-medium text-slate-700 dark:text-slate-200">{t('admin.users.form.status')}</label>
                            <select
                                className="w-full rounded-lg border border-slate-200 bg-white px-3 py-2 text-sm dark:border-slate-700 dark:bg-slate-900"
                                value={form.status}
                                onChange={(e) => setForm({ ...form, status: e.target.value as UserStatus })}
                            >
                                {statuses.map((s) => <option key={s} value={s}>{statusLabel(s)}</option>)}
                            </select>
                        </div>
                    </div>
                </div>

                <div className="flex items-center justify-end gap-3 border-t border-slate-200 px-6 py-4 dark:border-slate-700">
                    <button
                        onClick={onClose}
                        className="rounded-lg border border-slate-200 px-4 py-2 text-sm font-medium text-slate-700 hover:bg-slate-100 dark:border-slate-700 dark:text-slate-200 dark:hover:bg-slate-800"
                    >
                        {t('admin.users.form.cancel')}
                    </button>
                    <button
                        onClick={save}
                        disabled={loading}
                        className="inline-flex items-center gap-2 rounded-lg bg-dashboard-primary px-4 py-2 text-sm font-semibold text-white shadow-sm shadow-dashboard-primary/30 transition hover:bg-dashboard-primary-dark disabled:opacity-60"
                    >
                        {loading ? t('common.saving', { defaultValue: 'Saving...' }) : t('admin.users.form.save')}
                    </button>
                </div>
            </div>
        </div>
    );
};

export default UserFormModal;
