import React, { useState } from 'react';

interface PdfViewerProps {
    documentUrl: string;
    className?: string;
}

const PdfViewer: React.FC<PdfViewerProps> = ({ documentUrl, className = '' }) => {
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState(false);

    const getFullUrl = (url: string) => {
        if (!url) return '';
        if (url.startsWith('http') || url.startsWith('blob:')) return url;

        // Get base URL from env or default, strip /api if present since uploads are usually at root
        const apiBase = import.meta.env.VITE_API_URL || 'https://localhost:7145/api';
        const rootUrl = apiBase.replace(/\/api\/?$/, '');

        return `${rootUrl}${url.startsWith('/') ? '' : '/'}${url}`;
    };

    const handleLoad = () => {
        setLoading(false);
    };

    const handleError = () => {
        setLoading(false);
        setError(true);
    };

    // Prevent right-click for download protection
    const handleContextMenu = (e: React.MouseEvent) => {
        e.preventDefault();
    };

    const fullUrl = getFullUrl(documentUrl);
    // Add URL parameters to hide toolbar (works in Chrome PDF viewer)
    const pdfUrl = `${fullUrl}#toolbar=0&navpanes=0&scrollbar=0`;

    return (
        <div
            className={`relative w-full h-full ${className}`}
            onContextMenu={handleContextMenu}
        >
            {loading && (
                <div className="absolute inset-0 flex items-center justify-center bg-black/5">
                    <div className="text-center">
                        <div className="inline-block h-12 w-12 animate-spin rounded-full border-4 border-solid border-dashboard-primary border-r-transparent" />
                        <p className="mt-4 text-slate-500 font-medium">Loading PDF...</p>
                    </div>
                </div>
            )}

            {error ? (
                <div className="flex flex-col items-center justify-center h-full bg-slate-50 text-slate-900 p-6 rounded-lg border border-slate-200 dark:bg-slate-900 dark:text-white dark:border-slate-700">
                    <span className="material-symbols-outlined text-6xl text-red-500 mb-4">error</span>
                    <p className="text-slate-600 mb-4 font-medium dark:text-slate-300">Failed to load PDF document</p>
                    <a
                        href={fullUrl}
                        target="_blank"
                        rel="noopener noreferrer"
                        className="px-6 py-2.5 bg-dashboard-primary text-white rounded-lg hover:bg-dashboard-primary-dark inline-flex items-center gap-2 font-medium transition-colors"
                    >
                        <span className="material-symbols-outlined text-[20px]">open_in_new</span>
                        Open in New Tab
                    </a>
                </div>
            ) : (
                <iframe
                    src={pdfUrl}
                    className="w-full h-full border-0 rounded-lg"
                    style={{ minHeight: '100vh' }}
                    title="PDF Document Viewer"
                    onLoad={handleLoad}
                    onError={handleError}
                />
            )}
        </div>
    );
};

export default PdfViewer;
