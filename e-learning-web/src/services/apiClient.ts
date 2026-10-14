import { ApiError } from '../types/apiErrors';
export { ApiError };
import { tokenService } from './tokenService';
import { authUtils } from './authUtils';

const API_BASE_URL = import.meta.env.VITE_API_URL || 'https://skvi-api.azurewebsites.net/api';

interface RequestConfig extends RequestInit {
    _retry?: boolean;
}

// Queue mechanism to handle multiple 401s
let isRefreshing = false;
let failedQueue: Array<{
    resolve: (token: string) => void;
    reject: (error: any) => void;
}> = [];

const processQueue = (error: any, token: string | null = null) => {
    failedQueue.forEach((prom) => {
        if (error) {
            prom.reject(error);
        } else {
            prom.resolve(token!);
        }
    });

    failedQueue = [];
};

const DEFAULT_TIMEOUT_MS = 60_000;

export const apiClient = async <T = any>(endpoint: string, options: RequestConfig = {}): Promise<T> => {
    const url = endpoint.startsWith('http') ? endpoint : `${API_BASE_URL}${endpoint}`;

    const getHeaders = () => {
        const headers = new Headers(options.headers || {});
        // Only set Content-Type if body is not FormData
        if (!(options.body instanceof FormData) && !headers.has('Content-Type')) {
            headers.set('Content-Type', 'application/json');
        }

        const token = tokenService.getAccessToken();
        if (token) {
            headers.set('Authorization', `Bearer ${token}`);
        }
        return headers;
    };

    const config: RequestConfig = {
        ...options,
        headers: getHeaders(),
    };

    if (!config.credentials) {
        config.credentials = 'include';
    }

    const controller = new AbortController();
    if (!config.signal) {
        const timeoutId = setTimeout(() => controller.abort(), DEFAULT_TIMEOUT_MS);
        config.signal = controller.signal;
        const originalSignal = options.signal;
        if (originalSignal) {
            originalSignal.addEventListener('abort', () => controller.abort());
        }
        // Clear timeout when the request completes via the response handling below
        (config as any)._timeoutId = timeoutId;
    }

    const generation = tokenService.getGeneration();
    try {
        const response = await fetch(url, config);
        clearTimeout((config as any)._timeoutId);
        if (generation !== tokenService.getGeneration()) throw new ApiError('Session changed', 401);
        if (response.status === 401) {
            const body = await response.clone().json().catch(() => null);
            if (body?.code === 'AUTH_SESSION_REVOKED') {
                tokenService.clearToken();
                throw new ApiError(body.message || 'Session revoked', 401, undefined, body.code);
            }
        }

        // 401 Interceptor
        if (response.status === 401 && !config._retry && !/^\/auth\/(login|refresh|register|verify-otp|2fa\/login-verify|logout)/.test(endpoint)) {
            if (isRefreshing) {
                // If already refreshing, queue this request
                try {
                    const newToken = await new Promise<string>((resolve, reject) => {
                        failedQueue.push({ resolve, reject });
                    });
                    // Retry with new token
                    const retryOptions = {
                        ...options,
                        _retry: true,
                        headers: {
                            ...options.headers,
                            'Authorization': `Bearer ${newToken}`
                        }
                    };
                    return apiClient<T>(endpoint, retryOptions);
                } catch (err) {
                    throw err;
                }
            }

            config._retry = true;
            isRefreshing = true;

            try {
                const refreshData = await authUtils.refreshToken();
                if (generation !== tokenService.getGeneration()) throw new ApiError('Session changed', 401);
                tokenService.setAccessToken(refreshData.accessToken);
                processQueue(null, refreshData.accessToken);

                // Retry original request
                return apiClient<T>(endpoint, { ...options, _retry: true });
            } catch (refreshError) {
                processQueue(refreshError, null);
                throw refreshError;
            } finally {
                isRefreshing = false;
            }
        }

        if (!response.ok) {
            let errorMessage = response.statusText;
            let errorCode: string | undefined;
            let errors: Record<string, string[]> | undefined;

            try {
                const errorData = await response.clone().json();
                errorMessage = errorData.message || errorMessage;
                errorCode = errorData.code;
                errors = errorData.errors;
            } catch (e) {
                try {
                    const textError = await response.text();
                    if (textError) errorMessage = textError;
                } catch (e2) { }
            }

            throw new ApiError(errorMessage, response.status, errors, errorCode);
        }

        if (response.status === 204) {
            return {} as T;
        }

        // Check content type json
        const contentType = response.headers.get('content-type');
        if (contentType && contentType.indexOf('application/json') !== -1) {
            return await response.json();
        }

        try {
            return await response.json();
        } catch (e) {
            return (await response.text()) as unknown as T;
        }
    } catch (error) {
        clearTimeout((config as any)._timeoutId);
        throw error;
    }
};
