import React, { useState, useEffect, useRef } from 'react';
import AdminLayout from '../../../components/admin/AdminLayout';
import { homeSectionApi, type UpdateHomeVideoSectionDto } from '../../../services/homeSectionApi';
import { authApi } from '../../../services/authApi';

interface VideoUploadResponse {
    videoId: string;
    bunnyVideoId: string;
    playlistUrl: string;
    duration: number;
}

const AdminHomeSectionPage: React.FC = () => {
    const [loading, setLoading] = useState(true);
    const [saving, setSaving] = useState(false);
    const [uploading, setUploading] = useState(false);
    const [uploadProgress, setUploadProgress] = useState(0);
    const [saved, setSaved] = useState(false);
    const fileInputRef = useRef<HTMLInputElement>(null);

    const [form, setForm] = useState<UpdateHomeVideoSectionDto>({
        contentHtml: '',
        videoType: 'youtube',
        videoId: null,
        videoUrl: null,
    });

    useEffect(() => {
        fetchData();
    }, []);

    const fetchData = async () => {
        try {
            const section = await homeSectionApi.getHomeSection();
            if (section) {
                setForm({
                    contentHtml: section.contentHtml || '',
                    videoType: section.videoType || 'youtube',
                    videoId: section.videoId || null,
                    videoUrl: section.videoUrl || null,
                });
            }
        } catch (err) {
            console.error('Failed to load home section', err);
        } finally {
            setLoading(false);
        }
    };

    const handleSave = async () => {
        try {
            setSaving(true);
            await homeSectionApi.updateHomeSection(form);
            setSaved(true);
            setTimeout(() => setSaved(false), 3000);
        } catch (err) {
            console.error('Failed to save', err);
        } finally {
            setSaving(false);
        }
    };

    const handleVideoUpload = async (file: File) => {
        try {
            setUploading(true);
            setUploadProgress(10); // fake start progress

            const formData = new FormData();
            formData.append('file', file);
            formData.append('title', file.name);

            const token = authApi.getAccessToken();
            const apiBase = import.meta.env.VITE_API_URL || 'https://localhost:7145/api';
            const response = await fetch(`${apiBase}/videos/upload`, {
                method: 'POST',
                headers: token ? { Authorization: `Bearer ${token}` } : {},
                credentials: 'include',
                body: formData,
            });

            if (!response.ok) throw new Error('Upload failed');
            const result: VideoUploadResponse = await response.json();

            setUploadProgress(100);
            setForm(prev => ({
                ...prev,
                videoType: 'bunny',
                videoId: result.videoId,
                videoUrl: null,
            }));
        } catch (err) {
            console.error('Upload failed', err);
        } finally {
            setUploading(false);
            setUploadProgress(0);
        }
    };

    if (loading) {
        return (
            <AdminLayout>
                <div className="flex items-center justify-center h-64">
                    <div className="animate-spin rounded-full h-10 w-10 border-b-2 border-dashboard-primary"></div>
                </div>
            </AdminLayout>
        );
    }

    return (
        <AdminLayout>
            <div className="mx-auto max-w-5xl p-6 space-y-6">
                {/* Header */}
                <div className="flex items-center justify-between">
                    <div>
                        <h1 className="text-2xl font-bold text-slate-900 dark:text-white">
                            Quản lý Section Video Trang chủ
                        </h1>
                        <p className="mt-1 text-sm text-slate-500 dark:text-slate-400">
                            Cấu hình nội dung chữ và video hiển thị ở mục tuyên ngôn trang chủ.
                        </p>
                    </div>
                    <button
                        onClick={handleSave}
                        disabled={saving}
                        className="flex items-center gap-2 px-5 py-2.5 bg-dashboard-primary text-white font-semibold rounded-lg hover:bg-dashboard-primary-dark transition-colors disabled:opacity-50 shadow-sm"
                    >
                        {saving ? (
                            <div className="w-4 h-4 border-2 border-white/30 border-t-white rounded-full animate-spin"></div>
                        ) : saved ? (
                            <span className="material-symbols-outlined text-[20px]">check_circle</span>
                        ) : (
                            <span className="material-symbols-outlined text-[20px]">save</span>
                        )}
                        <span>{saving ? 'Đang lưu...' : saved ? 'Đã lưu!' : 'Lưu thay đổi'}</span>
                    </button>
                </div>

                <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
                    {/* Left: Text Content */}
                    <div className="rounded-xl border border-slate-200 bg-white shadow-sm dark:border-slate-800 dark:bg-dashboard-surface-dark">
                        <div className="border-b border-slate-200 dark:border-slate-800 px-6 py-4 flex items-center gap-2">
                            <span className="material-symbols-outlined text-dashboard-primary">text_fields</span>
                            <h2 className="text-base font-semibold text-slate-900 dark:text-white">Nội dung chữ (cột trái)</h2>
                        </div>
                        <div className="p-6">
                            <p className="text-sm text-slate-500 dark:text-slate-400 mb-3">
                                Hỗ trợ HTML. Ví dụ: <code className="bg-slate-100 dark:bg-slate-800 px-1 rounded text-xs">&lt;h2&gt;Tuyên Ngôn&lt;/h2&gt; &lt;ul&gt;&lt;li&gt;...&lt;/li&gt;&lt;/ul&gt;</code>
                            </p>
                            <textarea
                                value={form.contentHtml}
                                onChange={(e) => setForm(prev => ({ ...prev, contentHtml: e.target.value }))}
                                rows={16}
                                placeholder="Bạn có thể nhập văn bản thông thường hoặc HTML. Ví dụ:&#10;&#10;&lt;h2&gt;Về Chúng Tôi&lt;/h2&gt;&#10;&lt;ul&gt;&#10;  &lt;li&gt;Sứ mệnh 1&lt;/li&gt;&#10;  &lt;li&gt;Sứ mệnh 2&lt;/li&gt;&#10;&lt;/ul&gt;"
                                className="w-full px-4 py-3 border border-slate-300 dark:border-gray-600 rounded-lg bg-slate-50 dark:bg-gray-800 text-slate-900 dark:text-white font-mono text-sm focus:ring-2 focus:ring-dashboard-primary focus:border-transparent transition-colors resize-y"
                            />
                        </div>
                    </div>

                    {/* Right: Video */}
                    <div className="rounded-xl border border-slate-200 bg-white shadow-sm dark:border-slate-800 dark:bg-dashboard-surface-dark">
                        <div className="border-b border-slate-200 dark:border-slate-800 px-6 py-4 flex items-center gap-2">
                            <span className="material-symbols-outlined text-dashboard-primary">videocam</span>
                            <h2 className="text-base font-semibold text-slate-900 dark:text-white">Video (cột phải)</h2>
                        </div>
                        <div className="p-6 space-y-5">
                            {/* Video Type Toggle */}
                            <div>
                                <label className="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-2">Loại video</label>
                                <div className="flex gap-3">
                                    <button
                                        type="button"
                                        onClick={() => setForm(prev => ({ ...prev, videoType: 'youtube' }))}
                                        className={`flex-1 flex items-center justify-center gap-2 px-4 py-2.5 rounded-lg border text-sm font-medium transition-colors ${form.videoType === 'youtube'
                                            ? 'bg-dashboard-primary text-white border-dashboard-primary'
                                            : 'border-slate-300 dark:border-slate-600 text-slate-700 dark:text-slate-300 hover:bg-slate-50 dark:hover:bg-slate-800'}`}
                                    >
                                        <span className="material-symbols-outlined text-[18px]">smart_display</span>
                                        YouTube / Iframe
                                    </button>
                                    <button
                                        type="button"
                                        onClick={() => setForm(prev => ({ ...prev, videoType: 'bunny' }))}
                                        className={`flex-1 flex items-center justify-center gap-2 px-4 py-2.5 rounded-lg border text-sm font-medium transition-colors ${form.videoType === 'bunny'
                                            ? 'bg-dashboard-primary text-white border-dashboard-primary'
                                            : 'border-slate-300 dark:border-slate-600 text-slate-700 dark:text-slate-300 hover:bg-slate-50 dark:hover:bg-slate-800'}`}
                                    >
                                        <span className="material-symbols-outlined text-[18px]">cloud_upload</span>
                                        Upload Video
                                    </button>
                                </div>
                            </div>

                            {/* YouTube Input */}
                            {form.videoType === 'youtube' && (
                                <div>
                                    <label className="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-2">
                                        Link hoặc thẻ nhúng iframe YouTube
                                    </label>
                                    <textarea
                                        value={form.videoUrl || ''}
                                        onChange={(e) => setForm(prev => ({ ...prev, videoUrl: e.target.value, videoId: null }))}
                                        rows={4}
                                        placeholder="Ví dụ:&#10;https://www.youtube.com/watch?v=abc123&#10;hoặc&#10;&lt;iframe src=&quot;...&quot;&gt;&lt;/iframe&gt;"
                                        className="w-full px-4 py-3 border border-slate-300 dark:border-gray-600 rounded-lg bg-slate-50 dark:bg-gray-800 text-slate-900 dark:text-white font-mono text-sm focus:ring-2 focus:ring-dashboard-primary focus:border-transparent transition-colors resize-none"
                                    />
                                    <p className="mt-1.5 text-xs text-slate-500 dark:text-slate-400">
                                        Dán link YouTube hoặc thẻ iframe embed. Nếu dán link, hệ thống sẽ tự convert sang player nhúng.
                                    </p>

                                    {/* YouTube Preview */}
                                    {form.videoUrl && (() => {
                                        const youtubeMatch = form.videoUrl.match(/(?:v=|youtu\.be\/)([a-zA-Z0-9_-]{11})/);
                                        const isIframe = form.videoUrl.includes('<iframe');
                                        if (youtubeMatch) {
                                            return (
                                                <div className="mt-3 rounded-lg overflow-hidden border border-slate-200 dark:border-slate-700">
                                                    <iframe
                                                        src={`https://www.youtube.com/embed/${youtubeMatch[1]}`}
                                                        className="w-full h-44"
                                                        allow="autoplay; encrypted-media"
                                                        allowFullScreen
                                                    />
                                                </div>
                                            );
                                        }
                                        if (isIframe) {
                                            return (
                                                <div className="mt-3 rounded-lg overflow-hidden border border-slate-200 dark:border-slate-700"
                                                    dangerouslySetInnerHTML={{ __html: form.videoUrl }}
                                                />
                                            );
                                        }
                                        return null;
                                    })()}
                                </div>
                            )}

                            {/* Upload Video */}
                            {form.videoType === 'bunny' && (
                                <div>
                                    <label className="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-2">Upload file video</label>
                                    
                                    {/* Current video indicator */}
                                    {form.videoId && (
                                        <div className="mb-3 flex items-center gap-2 p-3 bg-green-50 dark:bg-green-900/20 border border-green-200 dark:border-green-800 rounded-lg">
                                            <span className="material-symbols-outlined text-green-600 text-[20px]">check_circle</span>
                                            <span className="text-sm text-green-700 dark:text-green-300">Video đã tải lên thành công</span>
                                        </div>
                                    )}

                                    <div
                                        className="border-2 border-dashed border-slate-300 dark:border-slate-600 rounded-xl p-8 text-center cursor-pointer hover:border-dashboard-primary hover:bg-dashboard-primary/5 transition-colors"
                                        onClick={() => fileInputRef.current?.click()}
                                        onDragOver={(e) => e.preventDefault()}
                                        onDrop={(e) => {
                                            e.preventDefault();
                                            const file = e.dataTransfer.files[0];
                                            if (file) handleVideoUpload(file);
                                        }}
                                    >
                                        {uploading ? (
                                            <div className="space-y-3">
                                                <div className="animate-spin rounded-full h-10 w-10 border-b-2 border-dashboard-primary mx-auto"></div>
                                                <p className="text-sm text-slate-600 dark:text-slate-400">Đang tải lên... {uploadProgress}%</p>
                                                <div className="w-full bg-slate-200 rounded-full h-2">
                                                    <div
                                                        className="bg-dashboard-primary h-2 rounded-full transition-all"
                                                        style={{ width: `${uploadProgress}%` }}
                                                    />
                                                </div>
                                            </div>
                                        ) : (
                                            <div className="space-y-2">
                                                <span className="material-symbols-outlined text-slate-400 text-[48px]">cloud_upload</span>
                                                <p className="text-sm font-medium text-slate-700 dark:text-slate-300">
                                                    Kéo thả video vào đây hoặc click để chọn
                                                </p>
                                                <p className="text-xs text-slate-500">MP4, MOV, AVI · Tối đa 2GB</p>
                                            </div>
                                        )}
                                    </div>
                                    <input
                                        ref={fileInputRef}
                                        type="file"
                                        accept="video/*"
                                        className="hidden"
                                        onChange={(e) => {
                                            const file = e.target.files?.[0];
                                            if (file) handleVideoUpload(file);
                                        }}
                                    />
                                    {form.videoId && (
                                        <button
                                            type="button"
                                            onClick={() => setForm(prev => ({ ...prev, videoId: null }))}
                                            className="mt-2 text-xs text-red-500 hover:underline"
                                        >
                                            Xóa video hiện tại
                                        </button>
                                    )}
                                </div>
                            )}
                        </div>
                    </div>
                </div>

                {/* Live Preview */}
                <div className="rounded-xl border border-slate-200 bg-white shadow-sm dark:border-slate-800 dark:bg-dashboard-surface-dark">
                    <div className="border-b border-slate-200 dark:border-slate-800 px-6 py-4 flex items-center gap-2">
                        <span className="material-symbols-outlined text-dashboard-primary">preview</span>
                        <h2 className="text-base font-semibold text-slate-900 dark:text-white">Xem trước (Preview)</h2>
                    </div>
                    <div className="p-6">
                        <div className="grid grid-cols-1 md:grid-cols-2 gap-6 bg-gray-50 dark:bg-gray-900 rounded-xl p-6">
                            {/* Text Preview */}
                            <div
                                className="rich-text text-slate-700 dark:text-slate-300"
                                dangerouslySetInnerHTML={{ __html: form.contentHtml || '<p class="text-gray-400 italic">Nội dung chữ sẽ hiển thị ở đây...</p>' }}
                            />
                            {/* Video Preview */}
                            <div>
                                {form.videoType === 'youtube' && form.videoUrl ? (() => {
                                    const match = form.videoUrl.match(/(?:v=|youtu\.be\/)([a-zA-Z0-9_-]{11})/);
                                    if (match) {
                                        return <iframe src={`https://www.youtube.com/embed/${match[1]}`} className="w-full h-52 rounded-xl" allowFullScreen />;
                                    }
                                    if (form.videoUrl.includes('<iframe')) {
                                        return <div className="rounded-xl overflow-hidden" dangerouslySetInnerHTML={{ __html: form.videoUrl }} />;
                                    }
                                    return <div className="h-52 rounded-xl bg-slate-200 dark:bg-slate-700 flex items-center justify-center text-slate-400">No preview</div>;
                                })() : (
                                    <div className="h-52 rounded-xl bg-slate-200 dark:bg-slate-700 flex items-center justify-center">
                                        {form.videoId ? (
                                            <div className="text-center text-slate-500">
                                                <span className="material-symbols-outlined text-[48px]">play_circle</span>
                                                <p className="text-sm mt-2">Video đã tải lên (BunnyStream)</p>
                                            </div>
                                        ) : (
                                            <span className="text-slate-400 text-sm">Chưa có video</span>
                                        )}
                                    </div>
                                )}
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </AdminLayout>
    );
};

export default AdminHomeSectionPage;
