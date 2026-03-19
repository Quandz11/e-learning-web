import React, { useEffect, useState } from 'react';
import { toast } from 'react-hot-toast';
import { aiSettingsApi, type AiSettings } from '../../../services/aiSettingsApi';
import AdminLayout from '../../../components/admin/AdminLayout';

const DEFAULT_AI_SETTINGS: AiSettings = {
    id: '',
    apiKey: '',
    modelName: 'gemini-2.5-flash',
    systemPrompt: '',
    isEnabled: false
};

const SUPPORTED_MODELS = [
    {
        value: 'gemini-2.5-flash',
        label: 'Gemini 2.5 Flash',
        description: 'Stable, cân bằng giữa tốc độ, chi phí và chất lượng.'
    },
    {
        value: 'gemini-2.5-flash-lite',
        label: 'Gemini 2.5 Flash-Lite',
        description: 'Stable, tiết kiệm chi phí nhất cho các tác vụ ngắn.'
    },
    {
        value: 'gemini-2.5-pro',
        label: 'Gemini 2.5 Pro',
        description: 'Stable, mạnh hơn cho reasoning sâu và phản hồi dài.'
    }
] as const;

const AdminAiSettingsPage: React.FC = () => {
    const [settings, setSettings] = useState<AiSettings | null>(null);
    const [loading, setLoading] = useState(true);
    const [saving, setSaving] = useState(false);

    useEffect(() => {
        void fetchSettings();
    }, []);

    const fetchSettings = async () => {
        try {
            setLoading(true);
            const data = await aiSettingsApi.getSettings();
            setSettings({
                ...DEFAULT_AI_SETTINGS,
                ...data
            });
        } catch (error: any) {
            toast.error(error.message || 'Lỗi khi tải cấu hình AI');
        } finally {
            setLoading(false);
        }
    };

    const handleSave = async (event: React.FormEvent) => {
        event.preventDefault();
        if (!settings) {
            return;
        }

        try {
            setSaving(true);
            await aiSettingsApi.updateSettings(settings);
            toast.success('Đã lưu cấu hình AI thành công');
        } catch (error: any) {
            toast.error(error.message || 'Lỗi khi lưu cấu hình AI');
        } finally {
            setSaving(false);
        }
    };

    const currentModel = SUPPORTED_MODELS.find((model) => model.value === (settings?.modelName || DEFAULT_AI_SETTINGS.modelName));

    if (loading) {
        return (
            <AdminLayout>
                <div className="p-6">
                    <div className="animate-pulse space-y-6">
                        <div className="h-8 w-1/4 rounded bg-gray-200 dark:bg-gray-700" />
                        <div className="h-64 rounded-xl bg-gray-200 dark:bg-gray-700" />
                    </div>
                </div>
            </AdminLayout>
        );
    }

    return (
        <AdminLayout>
            <div className="mx-auto max-w-4xl p-6">
                <div className="mb-6 flex items-center justify-between">
                    <div>
                        <div className="mb-2 flex items-center gap-2 text-sm text-gray-500">
                            <span className="material-symbols-outlined text-[16px]">smart_toy</span>
                            <span>AI Coach</span>
                            <span className="material-symbols-outlined text-[14px]">chevron_right</span>
                            <span className="font-medium text-gray-900 dark:text-gray-100">Cấu hình hệ thống</span>
                        </div>
                        <h1 className="text-2xl font-bold text-gray-900 dark:text-white">Cấu hình Gemini API</h1>
                        <p className="mt-1 text-sm text-gray-500">
                            Dùng model Gemini 2.5 còn hỗ trợ để chatbot và lộ trình cá nhân hóa hoạt động ổn định.
                        </p>
                    </div>
                </div>

                <form onSubmit={handleSave} className="overflow-hidden rounded-xl border border-gray-100 bg-white shadow-sm dark:border-gray-700 dark:bg-gray-800">
                    <div className="space-y-8 p-6">
                        <div>
                            <label className="mb-2 block text-sm font-semibold text-gray-900 dark:text-gray-200">
                                Gemini API Key <span className="text-red-500">*</span>
                            </label>
                            <input
                                type="password"
                                value={settings?.apiKey || ''}
                                onChange={(event) => setSettings((prev) => ({ ...(prev || DEFAULT_AI_SETTINGS), apiKey: event.target.value }))}
                                className="w-full rounded-lg border border-gray-300 bg-gray-50 px-4 py-2 font-mono text-gray-900 transition-all focus:border-transparent focus:ring-2 focus:ring-primary dark:border-gray-600 dark:bg-gray-900 dark:text-white"
                                placeholder="AIzaSy..."
                                required
                            />
                            <p className="mt-2 flex items-center gap-1 text-xs text-gray-500">
                                <span className="material-symbols-outlined text-[14px]">info</span>
                                Lấy API key tại{' '}
                                <a href="https://aistudio.google.com/app/apikey" target="_blank" rel="noreferrer" className="text-primary hover:underline">
                                    Google AI Studio
                                </a>
                                .
                            </p>
                        </div>

                        <div className="grid grid-cols-1 gap-6 md:grid-cols-2">
                            <div>
                                <label className="mb-2 block text-sm font-semibold text-gray-900 dark:text-gray-200">
                                    AI Model Name
                                </label>
                                <select
                                    value={settings?.modelName || DEFAULT_AI_SETTINGS.modelName}
                                    onChange={(event) => setSettings((prev) => ({ ...(prev || DEFAULT_AI_SETTINGS), modelName: event.target.value }))}
                                    className="w-full rounded-lg border border-gray-300 bg-gray-50 px-4 py-2 text-gray-900 transition-all focus:border-transparent focus:ring-2 focus:ring-primary dark:border-gray-600 dark:bg-gray-900 dark:text-white"
                                >
                                    {SUPPORTED_MODELS.map((model) => (
                                        <option key={model.value} value={model.value}>
                                            {model.label}
                                        </option>
                                    ))}
                                </select>
                                <p className="mt-2 text-xs text-gray-500">{currentModel?.description}</p>
                                <p className="mt-2 text-xs text-gray-500">
                                    Model legacy như `gemini-1.5-pro` và `gemini-exp-1206` đã bị loại khỏi cấu hình để tránh lỗi gọi API.
                                </p>
                            </div>

                            <div>
                                <label className="mb-2 block text-sm font-semibold text-gray-900 dark:text-gray-200">
                                    Trạng thái hoạt động
                                </label>
                                <label className="mt-3 flex cursor-pointer items-center">
                                    <div className="relative">
                                        <input
                                            type="checkbox"
                                            className="sr-only"
                                            checked={settings?.isEnabled || false}
                                            onChange={(event) => setSettings((prev) => ({ ...(prev || DEFAULT_AI_SETTINGS), isEnabled: event.target.checked }))}
                                        />
                                        <div className={`block h-8 w-14 rounded-full transition-colors ${settings?.isEnabled ? 'bg-primary' : 'bg-gray-300 dark:bg-gray-600'}`}></div>
                                        <div className={`absolute left-1 top-1 h-6 w-6 rounded-full bg-white transition-transform ${settings?.isEnabled ? 'translate-x-6 transform' : ''}`}></div>
                                    </div>
                                    <div className="ml-3 font-medium text-gray-700 dark:text-gray-300">
                                        {settings?.isEnabled ? 'Đang bật' : 'Đang tắt'}
                                    </div>
                                </label>
                            </div>
                        </div>

                        <div className="rounded-xl border border-amber-200 bg-amber-50 p-4 text-sm text-amber-800 dark:border-amber-500/20 dark:bg-amber-500/10 dark:text-amber-200">
                            Google hiện liệt kê `gemini-2.5-flash`, `gemini-2.5-flash-lite` và `gemini-2.5-pro` là các model Gemini 2.5 đang còn hỗ trợ cho Gemini API.
                        </div>

                        <div>
                            <label className="mb-2 block text-sm font-semibold text-gray-900 dark:text-gray-200">
                                System Prompt
                            </label>
                            <textarea
                                value={settings?.systemPrompt || ''}
                                onChange={(event) => setSettings((prev) => ({ ...(prev || DEFAULT_AI_SETTINGS), systemPrompt: event.target.value }))}
                                rows={5}
                                className="w-full resize-none rounded-lg border border-gray-300 bg-gray-50 px-4 py-3 leading-relaxed text-gray-900 transition-all focus:border-transparent focus:ring-2 focus:ring-primary dark:border-gray-600 dark:bg-gray-900 dark:text-white"
                                placeholder="Bạn là một AI coach thân thiện, theo dõi tiến độ học và đưa ra lời khuyên kịp thời..."
                            />
                            <p className="mt-2 text-xs text-gray-500">
                                Prompt này định hướng cách AI phản hồi khi chat, nhắc việc, tư vấn và điều chỉnh lộ trình học.
                            </p>
                        </div>
                    </div>

                    <div className="flex justify-end border-t border-gray-100 bg-gray-50 p-6 dark:border-gray-700 dark:bg-gray-900/50">
                        <button
                            type="submit"
                            disabled={saving}
                            className="flex items-center gap-2 rounded-lg bg-primary px-6 py-2.5 font-medium text-white transition-colors hover:bg-primary-dark disabled:opacity-70"
                        >
                            {saving ? (
                                <>
                                    <span className="material-symbols-outlined animate-spin text-[20px]">progress_activity</span>
                                    Đang lưu...
                                </>
                            ) : (
                                <>
                                    <span className="material-symbols-outlined text-[20px]">save</span>
                                    Lưu cấu hình
                                </>
                            )}
                        </button>
                    </div>
                </form>
            </div>
        </AdminLayout>
    );
};

export default AdminAiSettingsPage;
