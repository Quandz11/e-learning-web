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

    try {
        const response = await fetch(url, config);

        // 401 Interceptor
        if (response.status === 401 && !config._retry) {
            if (isRefreshing) {
                // If already refreshing, queue this request
                try {
                    const newToken = await new Promise<string>((resolve, reject) => {
                        failedQueue.push({ resolve, reject });
                    });
                    // Retry with new token
                    const retryOptions = {
                        ...options,
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
                tokenService.setAccessToken(refreshData.accessToken);
                processQueue(null, refreshData.accessToken);

                // Retry original request
                return apiClient<T>(endpoint, { ...options, _retry: true });
            } catch (refreshError) {
                processQueue(refreshError, null);
                tokenService.clearToken();
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
        throw error;
    }
};
