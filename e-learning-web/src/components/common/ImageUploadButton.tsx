import React, { useState, useRef } from 'react';
import { useTranslation } from 'react-i18next';

interface ImageUploadButtonProps {
    onUpload: (file: File) => Promise<string>;
    currentImageUrl?: string;
    onImageChange: (url: string) => void;
    label?: string;
    folder?: string;
    className?: string;
}

const ImageUploadButton: React.FC<ImageUploadButtonProps> = ({
    onUpload,
    currentImageUrl,
    onImageChange,
    label,
    className = ''
}) => {
    const { t } = useTranslation();
    const [uploading, setUploading] = useState(false);
    const [preview, setPreview] = useState<string | undefined>(currentImageUrl);
    const [dragActive, setDragActive] = useState(false);
    const fileInputRef = useRef<HTMLInputElement>(null);

    const handleFileSelect = async (file: File) => {
        if (!file.type.startsWith('image/')) {
            alert(t('admin.articles.invalidFileType', { defaultValue: 'Vui lòng chọn file ảnh' }));
            return;
        }

        if (file.size > 5 * 1024 * 1024) {
            alert(t('admin.articles.fileTooLarge', { defaultValue: 'Kích thước file không được vượt quá 5MB' }));
            return;
        }

        try {
            setUploading(true);

            // Show preview immediately
            const reader = new FileReader();
            reader.onloadend = () => {
                setPreview(reader.result as string);
            };
            reader.readAsDataURL(file);

            // Upload to server
            const url = await onUpload(file);
            setPreview(url);
            onImageChange(url);
        } catch (err) {
            console.error('Upload failed', err);
            alert(t('admin.articles.uploadFailed', { defaultValue: 'Tải ảnh lên thất bại' }));
            setPreview(currentImageUrl);
        } finally {
            setUploading(false);
        }
    };

    const handleFileInputChange = (e: React.ChangeEvent<HTMLInputElement>) => {
        const file = e.target.files?.[0];
        if (file) {
            handleFileSelect(file);
        }
    };

    const handleDrag = (e: React.DragEvent) => {
        e.preventDefault();
        e.stopPropagation();
        if (e.type === 'dragenter' || e.type === 'dragover') {
            setDragActive(true);
        } else if (e.type === 'dragleave') {
            setDragActive(false);
        }
    };

    const handleDrop = (e: React.DragEvent) => {
        e.preventDefault();
        e.stopPropagation();
        setDragActive(false);

        const file = e.dataTransfer.files?.[0];
        if (file) {
            handleFileSelect(file);
        }
    };

    const handleRemove = () => {
        setPreview(undefined);
        onImageChange('');
        if (fileInputRef.current) {
            fileInputRef.current.value = '';
        }
    };

    return (
        <div className={className}>
            {label && (
                <label className="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-2">
                    {label}
                </label>
            )}

            <div
                className={`relative border-2 border-dashed rounded-lg transition-colors ${dragActive
                        ? 'border-dashboard-primary bg-dashboard-primary/5'
                        : 'border-slate-300 dark:border-gray-600'
                    }`}
                onDragEnter={handleDrag}
                onDragLeave={handleDrag}
                onDragOver={handleDrag}
                onDrop={handleDrop}
            >
                {preview ? (
                    <div className="relative group">
                        <img
                            src={preview}
                            alt="Preview"
                            className="w-full h-48 object-cover rounded-lg"
                        />
                        <div className="absolute inset-0 bg-black/50 opacity-0 group-hover:opacity-100 transition-opacity rounded-lg flex items-center justify-center gap-2">
                            <button
                                type="button"
                                onClick={() => fileInputRef.current?.click()}
                                className="px-4 py-2 bg-white text-slate-900 rounded-lg hover:bg-slate-100 transition-colors font-medium"
                            >
                                {t('admin.articles.changeImage', { defaultValue: 'Đổi ảnh' })}
                            </button>
                            <button
                                type="button"
                                onClick={handleRemove}
                                className="px-4 py-2 bg-red-600 text-white rounded-lg hover:bg-red-700 transition-colors font-medium"
                            >
                                {t('common.remove', { defaultValue: 'Xóa' })}
                            </button>
                        </div>
                    </div>
                ) : (
                    <div
                        className="p-8 text-center cursor-pointer"
                        onClick={() => fileInputRef.current?.click()}
                    >
                        <div className="flex flex-col items-center gap-2">
                            <span className="material-symbols-outlined text-4xl text-slate-400">
                                {uploading ? 'progress_activity' : 'cloud_upload'}
                            </span>
                            <p className="text-sm text-slate-600 dark:text-slate-400">
                                {uploading
                                    ? t('admin.articles.uploadingImage', { defaultValue: 'Đang tải ảnh lên...' })
                                    : t('admin.articles.uploadImageHint', { defaultValue: 'Click hoặc kéo thả ảnh vào đây' })
                                }
                            </p>
                            <p className="text-xs text-slate-500 dark:text-slate-500">
                                {t('admin.articles.uploadImageLimit', { defaultValue: 'JPG, PNG, WEBP, GIF (tối đa 5MB)' })}
                            </p>
                        </div>
                    </div>
                )}

                <input
                    ref={fileInputRef}
                    type="file"
                    accept="image/*"
                    onChange={handleFileInputChange}
                    className="hidden"
                    disabled={uploading}
                />
            </div>
        </div>
    );
};

export default ImageUploadButton;
