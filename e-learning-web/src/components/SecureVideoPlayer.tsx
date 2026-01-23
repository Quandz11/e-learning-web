import React, { useEffect, useState } from 'react';
import { videoApi } from '../services/videoApi';
import { authApi } from '../services/authApi';

interface SecureVideoPlayerProps {
    videoId: string;
    className?: string;
    autoPlay?: boolean;
    controls?: boolean;
    onEnded?: () => void;
}

const SecureVideoPlayer = React.forwardRef<HTMLVideoElement, SecureVideoPlayerProps>(({
    videoId,
    className = '',
    autoPlay = false,
    controls = true,
    onEnded,
}, ref) => {
    const [embedUrl, setEmbedUrl] = useState<string | null>(null);
    const [error, setError] = useState<string | null>(null);
    const [loading, setLoading] = useState(true);

    useEffect(() => {
        const fetchEmbedUrl = async () => {
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

            try {
                console.log('Fetching embed URL for video:', videoId);
                const { embedUrl: url } = await videoApi.getEmbedUrl(videoId);
                console.log('Received embed URL:', url);
                setEmbedUrl(url);
                setLoading(false);
            } catch (err: any) {
                console.error('Failed to fetch embed URL:', err);
                setError(err.message || 'Failed to load video');
                setLoading(false);
            }
        };

        fetchEmbedUrl();
    }, [videoId]);

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
