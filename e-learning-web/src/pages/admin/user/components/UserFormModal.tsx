import React, { useEffect, useState } from 'react';
import { useTranslation } from 'react-i18next';
import { userApi, type CreateUserRequest, type UpdateUserRequest, type UserDto, type UserRole, type UserStatus } from '../../../../services/userApi';

import { profileApi } from '../../../../services/profileApi';

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

    // Avatar upload state
    const [uploadingAvatar, setUploadingAvatar] = useState(false);
    const fileInputRef = React.useRef<HTMLInputElement>(null);

    const roleLabel = (value: UserRole) => t(`admin.users.roles.${value}`);
    const statusLabel = (value: UserStatus) => t(`admin.users.statuses.${value}`);

    const handleFileChange = async (e: React.ChangeEvent<HTMLInputElement>) => {
        const file = e.target.files?.[0];
        if (!file) return;

        // Validate file size (5MB)
        if (file.size > 5 * 1024 * 1024) {
            setError('File size exceeds 5MB');
            return;
        }

        try {
            setUploadingAvatar(true);
            setError(null);
            const { url } = await profileApi.uploadAvatar(file);
            setForm(prev => ({ ...prev, avatarUrl: url }));
        } catch (err: any) {
            setError(err.message || 'Upload failed');
        } finally {
            setUploadingAvatar(false);
            if (fileInputRef.current) {
                fileInputRef.current.value = '';
            }
        }
    };

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
                        <div className="space-y-2 md:col-span-2">
                            <label className="text-sm font-medium text-slate-700 dark:text-slate-200">{t('admin.users.form.avatar')}</label>
                            <div className="flex items-center gap-4">
                                <div className="relative h-16 w-16 flex-shrink-0 overflow-hidden rounded-full border border-slate-200 bg-dashboard-primary/10 dark:border-slate-700">
                                    {form.avatarUrl ? (
                                        <img src={form.avatarUrl} alt="Avatar Preview" className="h-full w-full object-cover" />
                                    ) : (
                                        <div className="flex h-full w-full items-center justify-center text-2xl font-semibold text-dashboard-primary">
                                            {form.fullName ? form.fullName.charAt(0).toUpperCase() : '?'}
                                        </div>
                                    )}
                                    {uploadingAvatar && (
                                        <div className="absolute inset-0 flex items-center justify-center bg-black/50">
                                            <div className="h-4 w-4 animate-spin rounded-full border-2 border-white border-t-transparent"></div>
                                        </div>
                                    )}
                                </div>
                                <div>
                                    <input
                                        type="file"
                                        ref={fileInputRef}
                                        onChange={handleFileChange}
                                        accept="image/png, image/jpeg, image/jpg, image/webp, image/gif"
                                        className="hidden"
                                    />
                                    <button
                                        type="button"
                                        onClick={() => fileInputRef.current?.click()}
                                        disabled={uploadingAvatar || loading}
                                        className="inline-flex items-center gap-2 rounded-lg border border-slate-200 bg-white px-3 py-2 text-sm font-medium text-slate-700 hover:bg-slate-50 disabled:opacity-50 dark:border-slate-700 dark:bg-slate-800 dark:text-slate-200 dark:hover:bg-slate-700"
                                    >
                                        <span className="material-symbols-outlined text-[18px]">upload</span>
                                        {uploadingAvatar ? t('common.uploading', { defaultValue: 'Uploading...' }) : t('profile.form.changeAvatar', { defaultValue: 'Change Avatar' })}
                                    </button>
                                    <p className="mt-1 text-xs text-slate-500 dark:text-slate-400">
                                        JPG, PNG, WebP up to 5MB
                                    </p>
                                </div>
                            </div>
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
