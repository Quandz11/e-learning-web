import { authApi } from './authApi';

const API_BASE_URL = import.meta.env.VITE_API_URL || 'https://localhost:7145/api';

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

        const token = authApi.getAccessToken();
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
        let response = await fetch(url, config);

        // 401 Interceptor
        if (response.status === 401 && !config._retry) {
            if (isRefreshing) {
                // If already refreshing, queue this request
                try {
                    await new Promise<string>((resolve, reject) => {
                        failedQueue.push({ resolve, reject });
                    });
                    // Retry with new token
                    config.headers = getHeaders(); // Re-fetch headers to get new token
                    return apiClient<T>(endpoint, options);
                } catch (err) {
                    throw err;
                }
            }

            config._retry = true;
            isRefreshing = true;

            try {
                const refreshData = await authApi.refreshToken();
                authApi.setAccessToken(refreshData.accessToken);
                processQueue(null, refreshData.accessToken);

                // Retry original request
                return apiClient<T>(endpoint, { ...options, _retry: true });
            } catch (refreshError) {
                processQueue(refreshError, null);
                authApi.setAccessToken(null);
                throw refreshError;
            } finally {
                isRefreshing = false;
            }
        }

        if (!response.ok) {
            let errorMessage = response.statusText;
            let errors: Record<string, string[]> | undefined;

            try {
                // Clone response because json() consumes it
                const errorData = await response.clone().json();
                errorMessage = errorData.message || errorMessage;
                errors = errorData.errors;
            } catch (e) {
                try {
                    const textError = await response.text();
                    if (textError) errorMessage = textError;
                } catch (e2) { }
            }

            // Import ApiError dynamically to avoid circular dependency
            const { ApiError } = await import('../types/apiErrors');
            throw new ApiError(errorMessage, response.status, errors);
        }

        if (response.status === 204) {
            return {} as T;
        }

        // Check content type json
        const contentType = response.headers.get('content-type');
        if (contentType && contentType.indexOf('application/json') !== -1) {
            return response.json();
        }
        // Fallback for text/blob if needed, but for now assuming JSON mostly
        // If strict JSON is required we can keep it as is.
        // However, some endpoints return text strings.
        try {
            return response.json();
        } catch (e) {
            // If json parse fails, maybe it's just text
            return (await response.text()) as unknown as T;
        }
    } catch (error) {
        throw error;
    }
};
