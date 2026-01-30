import React, { useState } from 'react';

interface PdfViewerProps {
    documentUrl: string;
    className?: string;
}

const PdfViewer: React.FC<PdfViewerProps> = ({ documentUrl, className = '' }) => {
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState(false);

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

    // Add URL parameters to hide toolbar (works in Chrome PDF viewer)
    const pdfUrl = `${documentUrl}#toolbar=0&navpanes=0&scrollbar=0`;

    return (
        <div
            className={`relative w-full h-full ${className}`}
            onContextMenu={handleContextMenu}
        >
            {loading && (
                <div className="absolute inset-0 flex items-center justify-center bg-black">
                    <div className="text-center">
                        <div className="inline-block h-12 w-12 animate-spin rounded-full border-4 border-solid border-primary border-r-transparent" />
                        <p className="mt-4 text-gray-300">Loading PDF...</p>
                    </div>
                </div>
            )}

            {error ? (
                <div className="flex flex-col items-center justify-center h-full bg-gray-900 text-white p-6">
                    <span className="material-symbols-outlined text-6xl text-red-500 mb-4">error</span>
                    <p className="text-gray-300 mb-4">Failed to load PDF document</p>
                    <a
                        href={documentUrl}
                        target="_blank"
                        rel="noopener noreferrer"
                        className="px-6 py-3 bg-primary text-white rounded-lg hover:bg-primary/90 inline-flex items-center gap-2"
                    >
                        <span className="material-symbols-outlined">open_in_new</span>
                        Open in New Tab
                    </a>
                </div>
            ) : (
                <iframe
                    src={pdfUrl}
                    className="w-full h-full border-0"
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
