import React, { useState, useEffect } from 'react';
import { toast } from 'react-hot-toast';
import { aiSettingsApi, type AiSettings } from '../../../services/aiSettingsApi';
import AdminLayout from '../../../components/admin/AdminLayout';

const AdminAiSettingsPage: React.FC = () => {
    const [settings, setSettings] = useState<AiSettings | null>(null);
    const [loading, setLoading] = useState(true);
    const [saving, setSaving] = useState(false);

    useEffect(() => {
        fetchSettings();
    }, []);

    const fetchSettings = async () => {
        try {
            setLoading(true);
            const data = await aiSettingsApi.getSettings();
            setSettings(data);
        } catch (error: any) {
            toast.error(error.message || 'Lỗi khi tải cấu hình AI');
        } finally {
            setLoading(false);
        }
    };

    const handleSave = async (e: React.FormEvent) => {
        e.preventDefault();
        if (!settings) return;

        try {
            setSaving(true);
            await aiSettingsApi.updateSettings(settings);
            toast.success('Đã lưu cấu hình AI thành công');
        } catch (error: any) {
            toast.error(error.message || 'Lỗi khi lưu cấu hình');
        } finally {
            setSaving(false);
        }
    };

    if (loading) {
        return (
            <AdminLayout>
                <div className="p-6">
                    <div className="animate-pulse space-y-6">
                        <div className="h-8 bg-gray-200 dark:bg-gray-700 rounded w-1/4" />
                        <div className="h-64 bg-gray-200 dark:bg-gray-700 rounded-xl" />
                    </div>
                </div>
            </AdminLayout>
        );
    }

    return (
        <AdminLayout>
            <div className="p-6 max-w-4xl mx-auto">
                <div className="mb-6 flex items-center justify-between">
                    <div>
                        <div className="flex items-center gap-2 text-sm text-gray-500 mb-2">
                            <span className="material-symbols-outlined text-[16px]">smart_toy</span>
                            <span>AI Gia sư</span>
                            <span className="material-symbols-outlined text-[14px]">chevron_right</span>
                            <span className="text-gray-900 dark:text-gray-100 font-medium">Cấu hình hệ thống</span>
                        </div>
                        <h1 className="text-2xl font-bold text-gray-900 dark:text-white">Cấu hình AI Trợ lý ảo (Gemini)</h1>
                        <p className="text-gray-500 text-sm mt-1">Cài đặt API Key và đóng vai cho trợ lý ảo thông minh.</p>
                    </div>
                </div>

                <form onSubmit={handleSave} className="bg-white dark:bg-gray-800 rounded-xl shadow-sm border border-gray-100 dark:border-gray-700 overflow-hidden">
                    <div className="p-6 space-y-8">
                        {/* API Key */}
                        <div>
                            <label className="block text-sm font-semibold text-gray-900 dark:text-gray-200 mb-2">
                                Gemini API Key <span className="text-red-500">*</span>
                            </label>
                            <input
                                type="password"
                                value={settings?.apiKey || ''}
                                onChange={(e) => setSettings(prev => ({ ...(prev || { id: '', apiKey: '', modelName: 'gemini-1.5-pro', systemPrompt: '', isEnabled: false }), apiKey: e.target.value }))}
                                className="w-full px-4 py-2 border border-gray-300 dark:border-gray-600 rounded-lg bg-gray-50 dark:bg-gray-900 text-gray-900 dark:text-white focus:ring-2 focus:ring-primary focus:border-transparent transition-all font-mono"
                                placeholder="AIzaSy..."
                                required
                            />
                            <p className="text-xs text-gray-500 mt-2 flex items-center gap-1">
                                <span className="material-symbols-outlined text-[14px]">info</span>
                                Lấy API Key tại <a href="https://aistudio.google.com/app/apikey" target="_blank" rel="noreferrer" className="text-primary hover:underline">Google AI Studio</a>.
                            </p>
                        </div>

                        {/* Model Info */}
                        <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                            <div>
                                <label className="block text-sm font-semibold text-gray-900 dark:text-gray-200 mb-2">
                                    AI Model Name
                                </label>
                                <select
                                    value={settings?.modelName || 'gemini-1.5-pro'}
                                    onChange={(e) => setSettings(prev => ({ ...(prev || { id: '', apiKey: '', modelName: 'gemini-1.5-pro', systemPrompt: '', isEnabled: false }), modelName: e.target.value }))}
                                    className="w-full px-4 py-2 border border-gray-300 dark:border-gray-600 rounded-lg bg-gray-50 dark:bg-gray-900 text-gray-900 dark:text-white focus:ring-2 focus:ring-primary focus:border-transparent transition-all"
                                >
                                    <option value="gemini-1.5-pro">Gemini 1.5 Pro (Khuyên dùng, thông minh hơn)</option>
                                    <option value="gemini-2.5-flash">Gemini 2.5 Flash (Nhanh, rẻ, phù hợp task ngắn)</option>
                                    <option value="gemini-exp-1206">Gemini Experimental 1206</option>
                                </select>
                            </div>

                            <div>
                                <label className="block text-sm font-semibold text-gray-900 dark:text-gray-200 mb-2">
                                    Trạng thái hoạt động
                                </label>
                                <label className="flex items-center cursor-pointer mt-3">
                                    <div className="relative">
                                        <input
                                            type="checkbox"
                                            className="sr-only"
                                            checked={settings?.isEnabled || false}
                                            onChange={(e) => setSettings(prev => ({ ...(prev || { id: '', apiKey: '', modelName: 'gemini-1.5-pro', systemPrompt: '', isEnabled: false }), isEnabled: e.target.checked }))}
                                        />
                                        <div className={`block w-14 h-8 rounded-full transition-colors ${settings?.isEnabled ? 'bg-primary' : 'bg-gray-300 dark:bg-gray-600'}`}></div>
                                        <div className={`dot absolute left-1 top-1 bg-white w-6 h-6 rounded-full transition-transform ${settings?.isEnabled ? 'transform translate-x-6' : ''}`}></div>
                                    </div>
                                    <div className="ml-3 text-gray-700 dark:text-gray-300 font-medium">
                                        {settings?.isEnabled ? 'Đang bật (Hiển thị Chatbot)' : 'Đang tắt'}
                                    </div>
                                </label>
                            </div>
                        </div>

                        {/* System Prompt */}
                        <div>
                            <label className="block text-sm font-semibold text-gray-900 dark:text-gray-200 mb-2">
                                System Prompt (Định hướng tính cách)
                            </label>
                            <textarea
                                value={settings?.systemPrompt || ''}
                                onChange={(e) => setSettings(prev => ({ ...(prev || { id: '', apiKey: '', modelName: 'gemini-1.5-pro', systemPrompt: '', isEnabled: false }), systemPrompt: e.target.value }))}
                                rows={5}
                                className="w-full px-4 py-3 border border-gray-300 dark:border-gray-600 rounded-lg bg-gray-50 dark:bg-gray-900 text-gray-900 dark:text-white focus:ring-2 focus:ring-primary focus:border-transparent transition-all resize-none leading-relaxed"
                                placeholder="Bắt đầu prompt với: Bạn là một gia sư AI thân thiện..."
                            />
                            <p className="text-xs text-gray-500 mt-2">
                                Đây là chỉ thị ngầm định hướng cách AI phản hồi. Ví dụ nói AI đóng vai chuyên gia lập trình, hay một gia sư nghiêm khắc.
                            </p>
                        </div>
                    </div>

                    <div className="p-6 bg-gray-50 dark:bg-gray-900/50 border-t border-gray-100 dark:border-gray-700 flex justify-end">
                        <button
                            type="submit"
                            disabled={saving}
                            className="flex items-center gap-2 px-6 py-2.5 bg-primary text-white rounded-lg hover:bg-primary-dark transition-colors disabled:opacity-70 font-medium"
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
