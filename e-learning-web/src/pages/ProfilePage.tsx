import DeviceSessionsPanel from '../components/DeviceSessionsPanel';
import React, { useEffect, useState, useRef } from 'react';
import { useTranslation } from 'react-i18next';
import { useNavigate } from 'react-router-dom';
import AdminLayout from '../components/admin/AdminLayout';
import { profileApi, type UserProfileDto, type UpdateProfileRequest, type ChangePasswordRequest } from '../services/profileApi';
import { format } from 'date-fns';
import { useDispatch } from 'react-redux';
import { updateUser } from '../store/authSlice';

const ProfilePage: React.FC = () => {
    const { t } = useTranslation();
    const navigate = useNavigate();
    const dispatch = useDispatch();
    const [profile, setProfile] = useState<UserProfileDto | null>(null);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState<string | null>(null);
    const [success, setSuccess] = useState<string | null>(null);

    // Edit profile state
    const [isEditing, setIsEditing] = useState(false);
    const [fullName, setFullName] = useState('');
    const [phone, setPhone] = useState('');
    const [avatarUrl, setAvatarUrl] = useState('');
    const [saving, setSaving] = useState(false);
    const [uploadingAvatar, setUploadingAvatar] = useState(false);
    const fileInputRef = useRef<HTMLInputElement>(null);

    // Change password state
    const [showPasswordForm, setShowPasswordForm] = useState(false);
    const [currentPassword, setCurrentPassword] = useState('');
    const [newPassword, setNewPassword] = useState('');
    const [confirmPassword, setConfirmPassword] = useState('');
    const [changingPassword, setChangingPassword] = useState(false);

    useEffect(() => {
        void loadProfile();
    }, []);

    const loadProfile = async () => {
        try {
            setLoading(true);
            const data = await profileApi.getMyProfile();
            setProfile(data);
            setFullName(data.fullName || '');
            setPhone(data.phone || '');
            setAvatarUrl(data.avatarUrl || '');
        } catch (err: any) {
            setError(err.message || t('profile.errors.loadFailed'));
        } finally {
            setLoading(false);
        }
    };

    const handleUpdateProfile = async (e: React.FormEvent) => {
        e.preventDefault();
        setError(null);
        setSuccess(null);

        setSaving(true);
        try {
            const payload: UpdateProfileRequest = {
                fullName: fullName.trim() || undefined,
                phone: phone.trim() || undefined,
                avatarUrl: avatarUrl.trim() || undefined,
            };
            const updated = await profileApi.updateProfile(payload);
            setProfile(updated);

            // Update Redux state to reflect changes in header/sidebar
            dispatch(updateUser({
                fullName: updated.fullName || '',
                phone: updated.phone || '',
                avatarUrl: updated.avatarUrl,
            }));

            setIsEditing(false);
            setSuccess(t('profile.success.profileUpdated'));
        } catch (err: any) {
            setError(err.message || t('profile.errors.updateFailed'));
        } finally {
            setSaving(false);
        }
    };

    const handleChangePassword = async (e: React.FormEvent) => {
        e.preventDefault();
        setError(null);
        setSuccess(null);

        if (newPassword !== confirmPassword) {
            setError(t('profile.errors.passwordMismatch'));
            return;
        }

        if (newPassword.length < 8) {
            setError(t('profile.errors.passwordLength'));
            return;
        }

        setChangingPassword(true);
        try {
            const payload: ChangePasswordRequest = {
                currentPassword,
                newPassword,
            };
            await profileApi.changePassword(payload);
            setSuccess(t('profile.success.passwordChanged'));
            setShowPasswordForm(false);
            setCurrentPassword('');
            setNewPassword('');
            setConfirmPassword('');

            // Redirect to login after 2 seconds
            setTimeout(() => {
                navigate('/login');
            }, 2000);
        } catch (err: any) {
            setError(err.message || t('profile.errors.changeFailed'));
        } finally {
            setChangingPassword(false);
        }
    };

    const cancelEdit = () => {
        setIsEditing(false);
        if (profile) {
            setFullName(profile.fullName || '');
            setPhone(profile.phone || '');
            setAvatarUrl(profile.avatarUrl || '');
        }
        setError(null);
    };

    const handleFileChange = async (e: React.ChangeEvent<HTMLInputElement>) => {
        const file = e.target.files?.[0];
        if (!file) return;

        // Validate file size (5MB)
        if (file.size > 5 * 1024 * 1024) {
            setError(t('profile.errors.fileSize') || 'File size exceeds 5MB');
            return;
        }

        try {
            setUploadingAvatar(true);
            setError(null);
            const { url } = await profileApi.uploadAvatar(file);
            setAvatarUrl(url);
        } catch (err: any) {
            setError(err.message || 'Upload failed');
        } finally {
            setUploadingAvatar(false);
            if (fileInputRef.current) {
                fileInputRef.current.value = '';
            }
        }
    };

    if (loading) {
        return (
            <AdminLayout>
                <div className="flex items-center justify-center py-12">
                    <div className="text-slate-500">{t('profile.loading')}</div>
                </div>
            </AdminLayout>
        );
    }

    if (!profile) {
        return (
            <AdminLayout>
                <div className="rounded-lg border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-700">
                    {error || t('profile.errors.notFound')}
                </div>
            </AdminLayout>
        );
    }

    const roleLabel = t(`admin.users.roles.${profile.role}`);
    const statusLabel = t(`admin.users.statuses.${profile.status}`);

    return (
        <div className="container mx-auto max-w-5xl">
            <DeviceSessionsPanel />
            <div className="mb-6">
                <h1 className="text-2xl font-bold text-slate-900 dark:text-white">{t('profile.title')}</h1>
                <p className="text-sm text-slate-500 dark:text-slate-400">{t('profile.subtitle')}</p>
            </div>

            {error && (
                <div className="mb-4 rounded-lg border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-700 dark:border-red-900/50 dark:bg-red-900/20 dark:text-red-200">
                    {error}
                </div>
            )}

            {success && (
                <div className="mb-4 rounded-lg border border-green-200 bg-green-50 px-4 py-3 text-sm text-green-700 dark:border-green-900/50 dark:bg-green-900/20 dark:text-green-200">
                    {success}
                </div>
            )}

            {/* Profile Information Card */}
            <div className="mb-6 rounded-xl border border-slate-200 bg-white p-6 dark:border-slate-800 dark:bg-dashboard-surface-dark">
                <div className="mb-4 flex items-center justify-between">
                    <h2 className="text-lg font-bold text-slate-900 dark:text-white">{t('profile.profileInfo')}</h2>
                    {!isEditing && (
                        <button
                            onClick={() => setIsEditing(true)}
                            className="inline-flex items-center gap-2 rounded-lg border border-slate-200 px-3 py-1.5 text-sm text-slate-700 transition hover:bg-slate-100 dark:border-slate-700 dark:text-slate-200 dark:hover:bg-slate-800"
                        >
                            <span className="material-symbols-outlined text-[18px]">edit</span>
                            {t('profile.editProfile')}
                        </button>
                    )}
                </div>

                {!isEditing ? (
                    <div className="space-y-4">
                        <div className="flex items-start gap-4">
                            <div className="h-20 w-20 rounded-full border border-slate-200 bg-dashboard-primary/10 flex items-center justify-center overflow-hidden dark:border-slate-700">
                                {profile.avatarUrl ? (
                                    <img src={profile.avatarUrl} alt={profile.fullName} className="h-full w-full object-cover" />
                                ) : (
                                    <span className="text-3xl font-semibold text-dashboard-primary">
                                        {profile.fullName ? profile.fullName.charAt(0).toUpperCase() : profile.email.charAt(0).toUpperCase()}
                                    </span>
                                )}
                            </div>
                            <div className="flex-1">
                                <h3 className="text-xl font-bold text-slate-900 dark:text-white">{profile.fullName || t('common.unnamed')}</h3>
                                <p className="text-sm text-slate-500 dark:text-slate-400">{profile.email}</p>
                                <div className="mt-2 flex items-center gap-2">
                                    <span className="inline-flex items-center gap-1 rounded-full bg-slate-100 px-2 py-1 text-xs font-semibold text-slate-700 dark:bg-slate-800 dark:text-slate-200">
                                        {roleLabel}
                                    </span>
                                    <span className={`inline-flex items-center gap-1 rounded-full px-2 py-1 text-xs font-semibold ${profile.status === 'ACTIVE' ? 'bg-green-100 text-green-700 dark:bg-green-900/30 dark:text-green-300' : 'bg-amber-100 text-amber-700 dark:bg-amber-900/30 dark:text-amber-300'}`}>
                                        {statusLabel}
                                    </span>
                                    {profile.isEmailVerified && (
                                        <span className="inline-flex items-center gap-1 rounded-full bg-blue-100 px-2 py-1 text-xs font-semibold text-blue-700 dark:bg-blue-900/30 dark:text-blue-300">
                                            {t('admin.users.detail.verifiedEmail')}
                                        </span>
                                    )}
                                </div>
                            </div>
                        </div>

                        <div className="grid gap-4 md:grid-cols-2">
                            <div>
                                <div className="text-sm text-slate-500 dark:text-slate-400">{t('profile.form.phone')}</div>
                                <div className="mt-1 text-slate-900 dark:text-white">{profile.phone || '-'}</div>
                            </div>
                            <div>
                                <div className="text-sm text-slate-500 dark:text-slate-400">{t('profile.accountCreated')}</div>
                                <div className="mt-1 text-slate-900 dark:text-white">{format(new Date(profile.createdAt), 'dd/MM/yyyy HH:mm')}</div>
                            </div>
                            <div>
                                <div className="text-sm text-slate-500 dark:text-slate-400">{t('profile.lastUpdated')}</div>
                                <div className="mt-1 text-slate-900 dark:text-white">{format(new Date(profile.updatedAt), 'dd/MM/yyyy HH:mm')}</div>
                            </div>
                            <div>
                                <div className="text-sm text-slate-500 dark:text-slate-400">2FA</div>
                                <div className="mt-1 text-slate-900 dark:text-white">
                                    {profile.isTwoFactorEnabled ? t('admin.settings.security.statusEnabled') : t('profile.twoFactorDisabled')}
                                </div>
                            </div>
                        </div>
                    </div>
                ) : (
                    <form onSubmit={handleUpdateProfile} className="space-y-4">
                        <div>
                            <label className="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-1">
                                {t('profile.form.fullName')}
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
                                {t('profile.form.phone')}
                            </label>
                            <input
                                type="tel"
                                className="w-full rounded-lg border border-slate-200 bg-white px-3 py-2 text-sm focus:border-dashboard-primary focus:outline-none dark:border-slate-700 dark:bg-slate-800"
                                value={phone}
                                onChange={(e) => setPhone(e.target.value)}
                            />
                        </div>

                        <div>
                            <label className="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-2">
                                {t('profile.form.avatar')}
                            </label>

                            <div className="flex items-center gap-4">
                                <div className="relative h-20 w-20 flex-shrink-0 overflow-hidden rounded-full border border-slate-200 bg-dashboard-primary/10 dark:border-slate-700">
                                    {avatarUrl ? (
                                        <img src={avatarUrl} alt="Avatar Preview" className="h-full w-full object-cover" />
                                    ) : (
                                        <div className="flex h-full w-full items-center justify-center text-3xl font-semibold text-dashboard-primary">
                                            {fullName ? fullName.charAt(0).toUpperCase() : '?'}
                                        </div>
                                    )}
                                    {uploadingAvatar && (
                                        <div className="absolute inset-0 flex items-center justify-center bg-black/50">
                                            <div className="h-5 w-5 animate-spin rounded-full border-2 border-white border-t-transparent"></div>
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
                                        disabled={uploadingAvatar || saving}
                                        className="inline-flex items-center gap-2 rounded-lg border border-slate-200 bg-white px-3 py-2 text-sm font-medium text-slate-700 hover:bg-slate-50 disabled:opacity-50 dark:border-slate-700 dark:bg-slate-800 dark:text-slate-200 dark:hover:bg-slate-700"
                                    >
                                        <span className="material-symbols-outlined text-[18px]">upload</span>
                                        {uploadingAvatar ? t('common.uploading') : t('profile.form.changeAvatar')}
                                    </button>
                                    <p className="mt-1 text-xs text-slate-500 dark:text-slate-400">
                                        JPG, PNG, WebP up to 5MB
                                    </p>
                                </div>
                            </div>
                        </div>

                        <div className="flex gap-3">
                            <button
                                type="button"
                                onClick={cancelEdit}
                                className="flex-1 rounded-lg border border-slate-200 px-4 py-2 text-sm font-medium text-slate-700 transition hover:bg-slate-100 dark:border-slate-700 dark:text-slate-200 dark:hover:bg-slate-800"
                                disabled={saving}
                            >
                                {t('profile.form.cancel')}
                            </button>
                            <button
                                type="submit"
                                className="flex-1 rounded-lg bg-dashboard-primary px-4 py-2 text-sm font-medium text-white shadow-sm transition hover:bg-dashboard-primary-dark disabled:opacity-50"
                                disabled={saving}
                            >
                                {saving ? t('common.saving') : t('profile.form.save')}
                            </button>
                        </div>
                    </form>
                )}
            </div>

            {/* Change Password Section */}
            <div className="rounded-xl border border-slate-200 bg-white p-6 dark:border-slate-800 dark:bg-dashboard-surface-dark">
                <div className="mb-4 flex items-center justify-between">
                    <div>
                        <h2 className="text-lg font-bold text-slate-900 dark:text-white">{t('profile.changePassword')}</h2>
                        <p className="text-sm text-slate-500 dark:text-slate-400">{t('profile.changePasswordDesc')}</p>
                    </div>
                    {!showPasswordForm && (
                        <button
                            onClick={() => setShowPasswordForm(true)}
                            className="inline-flex items-center gap-2 rounded-lg border border-slate-200 px-3 py-1.5 text-sm text-slate-700 transition hover:bg-slate-100 dark:border-slate-700 dark:text-slate-200 dark:hover:bg-slate-800"
                        >
                            <span className="material-symbols-outlined text-[18px]">lock</span>
                            {t('profile.changePassword')}
                        </button>
                    )}
                </div>

                {showPasswordForm && (
                    <form onSubmit={handleChangePassword} className="space-y-4">
                        <div>
                            <label className="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-1">
                                {t('profile.form.currentPassword')} <span className="text-red-500">*</span>
                            </label>
                            <input
                                type="password"
                                className="w-full rounded-lg border border-slate-200 bg-white px-3 py-2 text-sm focus:border-dashboard-primary focus:outline-none dark:border-slate-700 dark:bg-slate-800"
                                value={currentPassword}
                                onChange={(e) => setCurrentPassword(e.target.value)}
                                required
                            />
                        </div>

                        <div>
                            <label className="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-1">
                                {t('profile.form.newPassword')} <span className="text-red-500">*</span>
                            </label>
                            <input
                                type="password"
                                className="w-full rounded-lg border border-slate-200 bg-white px-3 py-2 text-sm focus:border-dashboard-primary focus:outline-none dark:border-slate-700 dark:bg-slate-800"
                                value={newPassword}
                                onChange={(e) => setNewPassword(e.target.value)}
                                required
                                minLength={8}
                            />
                            <p className="mt-1 text-xs text-slate-500">{t('profile.form.passwordHint')}</p>
                        </div>

                        <div>
                            <label className="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-1">
                                {t('profile.form.confirmPassword')} <span className="text-red-500">*</span>
                            </label>
                            <input
                                type="password"
                                className="w-full rounded-lg border border-slate-200 bg-white px-3 py-2 text-sm focus:border-dashboard-primary focus:outline-none dark:border-slate-700 dark:bg-slate-800"
                                value={confirmPassword}
                                onChange={(e) => setConfirmPassword(e.target.value)}
                                required
                            />
                        </div>

                        <div className="flex gap-3">
                            <button
                                type="button"
                                onClick={() => {
                                    setShowPasswordForm(false);
                                    setCurrentPassword('');
                                    setNewPassword('');
                                    setConfirmPassword('');
                                    setError(null);
                                }}
                                className="flex-1 rounded-lg border border-slate-200 px-4 py-2 text-sm font-medium text-slate-700 transition hover:bg-slate-100 dark:border-slate-700 dark:text-slate-200 dark:hover:bg-slate-800"
                                disabled={changingPassword}
                            >
                                {t('profile.form.cancel')}
                            </button>
                            <button
                                type="submit"
                                className="flex-1 rounded-lg bg-dashboard-primary px-4 py-2 text-sm font-medium text-white shadow-sm transition hover:bg-dashboard-primary-dark disabled:opacity-50"
                                disabled={changingPassword}
                            >
                                {changingPassword ? t('profile.changing') : t('profile.form.changePassword')}
                            </button>
                        </div>
                    </form>
                )}
            </div>
        </div>
    );
};

export default ProfilePage;
