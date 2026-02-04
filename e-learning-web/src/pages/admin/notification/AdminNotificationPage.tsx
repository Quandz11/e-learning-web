import React, { useState } from 'react';
import { useTranslation } from 'react-i18next';
import { useNotification } from '../../../context/NotificationContext';
import { useToast } from '../../../contexts/ToastContext';
import { apiClient } from '../../../services/apiClient';
import AdminLayout from '../../../components/admin/AdminLayout';

// Simple user search interface
interface UserResult {
    id: string;
    email: string;
    fullName: string;
}

export default function AdminNotificationPage() {
    const { t } = useTranslation();
    const { sendNotification } = useNotification();
    const { showToast } = useToast();

    const [title, setTitle] = useState('');
    const [content, setContent] = useState('');
    const [targetType, setTargetType] = useState('USER'); // USER, ROLE, ALL
    const [targetRole, setTargetRole] = useState('STUDENT');

    // User search state
    const [searchQuery, setSearchQuery] = useState('');
    const [searchResults, setSearchResults] = useState<UserResult[]>([]);
    const [searching, setSearching] = useState(false);
    const [selectedUser, setSelectedUser] = useState<UserResult | null>(null);

    const [sending, setSending] = useState(false);

    const handleSearchUser = async () => {
        if (!searchQuery) return;
        setSearching(true);
        try {
            // Adjust endpoint to your actual user search API
            const response = await apiClient<{ items: UserResult[] }>(`/users?search=${searchQuery}`, {
                method: 'GET'
            });
            setSearchResults(response.items || []); // Adjust based on pagination
        } catch (error) {
            console.error('Search failed', error);
        } finally {
            setSearching(false);
        }
    };

    const handleSend = async (e: React.FormEvent) => {
        e.preventDefault();

        if (!title || !content) {
            showToast(t('admin.notifications.form.error'), 'error');
            return;
        }

        if (targetType === 'USER' && !selectedUser) {
            showToast(t('admin.notifications.form.error'), 'error');
            return;
        }

        setSending(true);
        try {
            await sendNotification({
                title,
                content,
                targetType,
                targetUserId: targetType === 'USER' ? selectedUser?.id : undefined,
                targetRole: targetType === 'ROLE' ? targetRole : undefined
            });
            showToast(t('admin.notifications.form.success'), 'success');
            // Reset form
            setTitle('');
            setContent('');
        } catch (error) {
            console.error('Send failed', error);
            showToast(t('admin.notifications.form.error'), 'error');
        } finally {
            setSending(false);
        }
    };

    return (
        <AdminLayout>
            <div className="mb-6 flex items-center justify-between">
                <div>
                    <h1 className="text-2xl font-bold text-slate-900 dark:text-white">
                        {t('admin.notifications.title')}
                    </h1>
                    <p className="text-sm text-slate-500 dark:text-slate-400">
                        {t('admin.notifications.subtitle')}
                    </p>
                </div>
            </div>

            <div className="rounded-2xl border border-white/60 bg-white/90 p-6 shadow-sm shadow-slate-200 backdrop-blur dark:border-slate-800 dark:bg-dashboard-surface-dark md:p-8">
                <form onSubmit={handleSend} className="space-y-8">
                    {/* Target Selection */}
                    <div className="space-y-4">
                        <label className="text-sm font-semibold text-slate-900 dark:text-white uppercase tracking-wider">
                            {t('admin.notifications.form.targetType')}
                        </label>

                        <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
                            {[
                                { id: 'USER', label: t('admin.notifications.types.USER'), icon: 'person' },
                                { id: 'ROLE', label: t('admin.notifications.types.ROLE'), icon: 'group' },
                                { id: 'ALL', label: t('admin.notifications.types.ALL'), icon: 'public' }
                            ].map((type) => (
                                <label
                                    key={type.id}
                                    className={`
                                            relative flex flex-col items-center justify-center p-4 rounded-xl border-2 cursor-pointer transition-all duration-200
                                            ${targetType === type.id
                                            ? 'border-dashboard-primary bg-dashboard-primary/5 dark:bg-dashboard-primary/10'
                                            : 'border-slate-200 dark:border-gray-700 hover:border-slate-300 dark:hover:border-gray-600 bg-white dark:bg-gray-800'
                                        }
                                        `}
                                >
                                    <input
                                        type="radio"
                                        name="targetType"
                                        value={type.id}
                                        checked={targetType === type.id}
                                        onChange={() => setTargetType(type.id)}
                                        className="sr-only"
                                    />
                                    <span className={`material-symbols-outlined text-3xl mb-2 ${targetType === type.id ? 'text-dashboard-primary' : 'text-slate-400'}`}>
                                        {type.icon}
                                    </span>
                                    <span className={`font-semibold ${targetType === type.id ? 'text-dashboard-primary' : 'text-slate-600 dark:text-slate-300'}`}>
                                        {type.label}
                                    </span>
                                </label>
                            ))}
                        </div>
                    </div>

                    {/* Conditional Inputs */}
                    <div className="transition-all duration-300 ease-in-out">
                        {targetType === 'USER' && (
                            <div className="bg-slate-50 dark:bg-gray-900/50 p-6 rounded-xl border border-slate-200 dark:border-gray-700 space-y-4 animate-fadeIn">
                                <label className="block text-sm font-medium text-slate-700 dark:text-slate-300">
                                    {t('admin.notifications.form.targetUser')}
                                </label>

                                {!selectedUser ? (
                                    <div className="relative">
                                        <div className="flex gap-2">
                                            <div className="relative flex-grow">
                                                <span className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                                                    <span className="material-symbols-outlined text-slate-400">search</span>
                                                </span>
                                                <input
                                                    type="text"
                                                    value={searchQuery}
                                                    onChange={(e) => setSearchQuery(e.target.value)}
                                                    placeholder={t('admin.users.searchPlaceholder')}
                                                    className="block w-full pl-10 pr-3 py-2.5 border border-slate-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-700 text-slate-900 dark:text-white placeholder-slate-400 focus:ring-2 focus:ring-dashboard-primary focus:border-dashboard-primary transition-colors sm:text-sm"
                                                />
                                            </div>
                                            <button
                                                type="button"
                                                onClick={handleSearchUser}
                                                disabled={searching || !searchQuery}
                                                className="px-6 py-2.5 bg-slate-900 dark:bg-white text-white dark:text-slate-900 font-medium rounded-lg hover:bg-slate-800 dark:hover:bg-slate-100 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
                                            >
                                                {searching ? t('common.loading') : t('admin.buttons.search')}
                                            </button>
                                        </div>

                                        {/* Search Results Dropdown */}
                                        {searchResults.length > 0 && (
                                            <div className="absolute z-10 w-full mt-2 bg-white dark:bg-gray-800 rounded-lg shadow-xl border border-slate-200 dark:border-gray-700 max-h-60 overflow-y-auto">
                                                {searchResults.map((user) => (
                                                    <button
                                                        key={user.id}
                                                        type="button"
                                                        onClick={() => {
                                                            setSelectedUser(user);
                                                            setSearchResults([]);
                                                            setSearchQuery('');
                                                        }}
                                                        className="w-full text-left px-4 py-3 hover:bg-slate-50 dark:hover:bg-gray-700 border-b border-slate-100 dark:border-gray-700 last:border-0 transition-colors flex items-center gap-3"
                                                    >
                                                        <div className="h-8 w-8 rounded-full bg-dashboard-primary/10 flex items-center justify-center text-dashboard-primary font-bold text-xs">
                                                            {user.fullName.charAt(0).toUpperCase()}
                                                        </div>
                                                        <div>
                                                            <div className="font-medium text-slate-900 dark:text-white">{user.fullName}</div>
                                                            <div className="text-xs text-slate-500">{user.email}</div>
                                                        </div>
                                                    </button>
                                                ))}
                                            </div>
                                        )}
                                    </div>
                                ) : (
                                    <div className="flex items-center justify-between p-4 bg-white dark:bg-gray-800 border border-dashboard-primary/30 rounded-lg shadow-sm">
                                        <div className="flex items-center gap-3">
                                            <div className="h-10 w-10 rounded-full bg-dashboard-primary text-white flex items-center justify-center font-bold">
                                                {selectedUser.fullName.charAt(0).toUpperCase()}
                                            </div>
                                            <div>
                                                <div className="font-bold text-slate-900 dark:text-white">{selectedUser.fullName}</div>
                                                <div className="text-sm text-slate-500">{selectedUser.email}</div>
                                            </div>
                                        </div>
                                        <button
                                            type="button"
                                            onClick={() => setSelectedUser(null)}
                                            className="p-2 text-slate-400 hover:text-red-500 hover:bg-red-50 dark:hover:bg-red-900/20 rounded-full transition-colors"
                                        >
                                            <span className="material-symbols-outlined">close</span>
                                        </button>
                                    </div>
                                )}
                            </div>
                        )}

                        {targetType === 'ROLE' && (
                            <div className="bg-slate-50 dark:bg-gray-900/50 p-6 rounded-xl border border-slate-200 dark:border-gray-700 animate-fadeIn">
                                <label className="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-2">
                                    {t('admin.notifications.form.targetRole')}
                                </label>
                                <div className="relative">
                                    <select
                                        value={targetRole}
                                        onChange={(e) => setTargetRole(e.target.value)}
                                        className="block w-full pl-4 pr-10 py-3 text-base border-slate-300 dark:border-gray-600 focus:outline-none focus:ring-2 focus:ring-dashboard-primary focus:border-dashboard-primary sm:text-sm rounded-lg bg-white dark:bg-gray-700 dark:text-white appearance-none"
                                    >
                                        <option value="STUDENT">{t('admin.notifications.roles.STUDENT')}</option>
                                        <option value="LECTURER">{t('admin.notifications.roles.LECTURER')}</option>
                                        <option value="AGENT">{t('admin.notifications.roles.AGENT')}</option>
                                        <option value="CARE">{t('admin.notifications.roles.CARE')}</option>
                                        <option value="ADMIN">{t('admin.notifications.roles.ADMIN')}</option>
                                    </select>
                                    <div className="pointer-events-none absolute inset-y-0 right-0 flex items-center px-3 text-slate-500">
                                        <span className="material-symbols-outlined">expand_more</span>
                                    </div>
                                </div>
                            </div>
                        )}
                    </div>

                    <div className="border-t border-slate-100 dark:border-gray-700 my-8"></div>

                    {/* Content Fields */}
                    <div className="space-y-6">
                        <div>
                            <label className="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-2">
                                {t('admin.notifications.form.title')} <span className="text-red-500">*</span>
                            </label>
                            <input
                                type="text"
                                value={title}
                                onChange={(e) => setTitle(e.target.value)}
                                placeholder="Enter notification title..."
                                className="block w-full px-4 py-3 rounded-lg border-slate-300 dark:border-gray-600 bg-white dark:bg-gray-700 text-slate-900 dark:text-white focus:ring-2 focus:ring-dashboard-primary focus:border-dashboard-primary shadow-sm placeholder-slate-400"
                                required
                            />
                        </div>

                        <div>
                            <label className="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-2">
                                {t('admin.notifications.form.content')} <span className="text-red-500">*</span>
                            </label>
                            <textarea
                                value={content}
                                onChange={(e) => setContent(e.target.value)}
                                rows={5}
                                placeholder="Enter notification content here..."
                                className="block w-full px-4 py-3 rounded-lg border-slate-300 dark:border-gray-600 bg-white dark:bg-gray-700 text-slate-900 dark:text-white focus:ring-2 focus:ring-dashboard-primary focus:border-dashboard-primary shadow-sm placeholder-slate-400 resize-none"
                                required
                            />
                        </div>
                    </div>

                    {/* Submit Button */}
                    <div className="pt-4 flex justify-end">
                        <button
                            type="submit"
                            disabled={sending}
                            className={`
                                flex items-center gap-2 px-8 py-3 rounded-lg text-white font-semibold shadow-dashboard-lg transition-all transform hover:-translate-y-0.5
                                ${sending
                                    ? 'bg-dashboard-primary/70 cursor-not-allowed'
                                    : 'bg-dashboard-primary hover:bg-dashboard-primary-dark hover:shadow-dashboard-primary/30'
                                }
                            `}
                        >
                            {sending ? (
                                <>
                                    <div className="w-5 h-5 border-2 border-white/30 border-t-white rounded-full animate-spin"></div>
                                    <span>{t('admin.notifications.form.sending')}</span>
                                </>
                            ) : (
                                <>
                                    <span>{t('admin.notifications.form.send')}</span>
                                    <span className="material-symbols-outlined text-[20px]">send</span>
                                </>
                            )}
                        </button>
                    </div>
                </form>
            </div>
        </AdminLayout>
    );
}
