import React, { useCallback, useEffect, useRef, useState } from 'react';
import { videoApi } from '../services/videoApi';
import { authApi } from '../services/authApi';

interface SecureVideoPlayerProps {
    videoId: string;
    className?: string;
    autoPlay?: boolean;
    controls?: boolean;
    onEnded?: () => void;
}

const MAX_RETRIES = 2;

const SecureVideoPlayer = React.forwardRef<HTMLVideoElement, SecureVideoPlayerProps>(({
    videoId,
    className = '',
    autoPlay = false,
}, _) => {
    const [embedUrl, setEmbedUrl] = useState<string | null>(null);
    const [error, setError] = useState<string | null>(null);
    const [loading, setLoading] = useState(true);
    const retryCount = useRef(0);

    const fetchEmbedUrl = useCallback(async () => {
        if (!videoId) {
            setError('No video ID provided');
            setLoading(false);
            return;
        }

        const token = authApi.getAccessToken();
        if (!token) {
            setError('Please login to watch videos');
            setLoading(false);
            return;
        }

        setLoading(true);
        setError(null);
        try {
            const { embedUrl: url } = await videoApi.getEmbedUrl(videoId);
            setEmbedUrl(url);
            setLoading(false);
        } catch (err: any) {
            if (retryCount.current < MAX_RETRIES) {
                retryCount.current += 1;
                const delay = retryCount.current * 1500;
                setTimeout(fetchEmbedUrl, delay);
            } else {
                setError(err.message || 'Failed to load video');
                setLoading(false);
            }
        }
    }, [videoId]);

    useEffect(() => {
        retryCount.current = 0;
        fetchEmbedUrl();
    }, [fetchEmbedUrl]);

    if (loading) {
        return (
            <div className={`flex items-center justify-center bg-slate-900 ${className}`}>
                <div className="text-center">
                    <div className="inline-block h-8 w-8 animate-spin rounded-full border-4 border-solid border-white border-r-transparent"></div>
                    <p className="mt-2 text-sm text-slate-400">Loading video...</p>
                </div>
            </div>
        );
    }

    if (error) {
        return (
            <div className={`flex items-center justify-center bg-slate-900 ${className}`}>
                <div className="text-center text-red-400">
                    <span className="material-symbols-outlined text-5xl">error</span>
                    <p className="mt-2 text-sm">{error}</p>
                    <button
                        onClick={() => { retryCount.current = 0; fetchEmbedUrl(); }}
                        className="mt-3 px-4 py-2 text-sm bg-slate-700 hover:bg-slate-600 text-white rounded transition-colors"
                    >
                        Thử lại
                    </button>
                </div>
            </div>
        );
    }

    if (!embedUrl) {
        return (
            <div className={`flex items-center justify-center bg-slate-900 ${className}`}>
                <p className="text-slate-400">No video available</p>
            </div>
        );
    }

    // Use Bunny's embed player (no token needed, built-in controls)
    return (
        <iframe
            src={`${embedUrl}&autoplay=${autoPlay ? 'true' : 'false'}`}
            loading="lazy"
            className={className}
            allow="accelerometer; gyroscope; autoplay; encrypted-media; picture-in-picture;"
            allowFullScreen
            style={{ border: 'none', width: '100%', height: '100%' }}
        />
    );
});

SecureVideoPlayer.displayName = 'SecureVideoPlayer';

export default SecureVideoPlayer;
