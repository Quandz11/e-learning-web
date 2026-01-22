import React, { useEffect, useRef, useState } from 'react';
import { videoApi } from '../services/videoApi';
import { authApi } from '../services/authApi';

interface SecureVideoPlayerProps {
    videoId: string;
    className?: string;
    autoPlay?: boolean;
    controls?: boolean;
}

const SecureVideoPlayer: React.FC<SecureVideoPlayerProps> = ({
    videoId,
    className = '',
    autoPlay = false,
    controls = true,
}) => {
    const [streamUrl, setStreamUrl] = useState<string | null>(null);
    const [error, setError] = useState<string | null>(null);
    const [loading, setLoading] = useState(true);
    const videoRef = useRef<HTMLVideoElement>(null);
    const refreshTimerRef = useRef<number | null>(null);

    const fetchStreamUrl = async () => {
        try {
            setError(null);
            const { streamUrl: url, expiresIn } = await videoApi.getStreamUrl(videoId);
            setStreamUrl(url);
            setLoading(false);

            // Schedule refresh 2 minutes before expiration (to be safe)
            const refreshTime = (expiresIn - 120) * 1000; // Convert to milliseconds
            if (refreshTime > 0) {
                refreshTimerRef.current = setTimeout(() => {
                    console.log('Refreshing video URL...');
                    fetchStreamUrl();
                }, refreshTime);
            }
        } catch (err: any) {
            console.error('Failed to fetch stream URL:', err);
            setError(err.message || 'Failed to load video');
            setLoading(false);
        }
    };

    useEffect(() => {
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

        fetchStreamUrl();

        // Cleanup timer on unmount
        return () => {
            if (refreshTimerRef.current) {
                clearTimeout(refreshTimerRef.current);
            }
        };
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

    if (!streamUrl) {
        return (
            <div className={`flex items-center justify-center bg-slate-900 ${className}`}>
                <p className="text-slate-400">No video available</p>
            </div>
        );
    }

    return (
        <video
            ref={videoRef}
            className={className}
            controls={controls}
            autoPlay={autoPlay}
            playsInline
            controlsList="nodownload" // Hint to browser to hide download button
            onContextMenu={(e) => e.preventDefault()} // Disable right-click
        >
            <source src={streamUrl} type="application/x-mpegURL" />
            Your browser does not support HLS video playback.
        </video>
    );
};

export default SecureVideoPlayer;
