import { ApiError, HttpStatusCode } from '../types/apiErrors';

export interface ErrorHandlerOptions {
    defaultMessage?: string;
    showToast?: boolean;
}

/**
 * Extract error message from various error formats
 */
export const extractErrorMessage = (error: unknown): string => {
    // If it's our custom ApiError
    if (error instanceof ApiError) {
        return error.message;
    }

    // If it's a standard Error
    if (error instanceof Error) {
        return error.message;
    }

    // If it's an object with a message property
    if (typeof error === 'object' && error !== null && 'message' in error) {
        return String((error as any).message);
    }

    // If it's a string
    if (typeof error === 'string') {
        return error;
    }

    return 'An unexpected error occurred';
};

/**
 * Get user-friendly error message based on status code
 */
export const getErrorMessageByStatusCode = (
    statusCode: number,
    defaultMessage?: string
): string => {
    switch (statusCode) {
        case HttpStatusCode.BAD_REQUEST:
            return defaultMessage || 'Invalid request. Please check your input.';
        case HttpStatusCode.UNAUTHORIZED:
            return 'You are not authorized. Please login again.';
        case HttpStatusCode.FORBIDDEN:
            return "You don't have permission to perform this action.";
        case HttpStatusCode.NOT_FOUND:
            return 'The requested resource was not found.';
        case HttpStatusCode.CONFLICT:
            return defaultMessage || 'A conflict occurred. The resource may already exist.';
        case HttpStatusCode.INTERNAL_SERVER_ERROR:
            return 'Server error. Please try again later.';
        default:
            return defaultMessage || 'An error occurred. Please try again.';
    }
};

/**
 * Map error message to i18n key
 */
export const getErrorI18nKey = (errorMessage: string): string | null => {
    const lowerMessage = errorMessage.toLowerCase();

    // Authentication errors
    if (lowerMessage.includes('invalid email or password')) {
        return 'notifications.error.invalidCredentials';
    }
    if (lowerMessage.includes('email already exists') || lowerMessage.includes('already exists')) {
        return 'notifications.error.emailExists';
    }
    if (lowerMessage.includes('already enrolled')) {
        return 'notifications.error.alreadyEnrolled';
    }

    // Network errors
    if (lowerMessage.includes('network') || lowerMessage.includes('fetch')) {
        return 'notifications.error.networkError';
    }

    // Generic errors by status code patterns
    if (lowerMessage.includes('not found')) {
        return 'notifications.error.notFound';
    }
    if (lowerMessage.includes('forbidden') || lowerMessage.includes('permission')) {
        return 'notifications.error.forbidden';
    }
    if (lowerMessage.includes('unauthorized')) {
        return 'notifications.error.unauthorized';
    }
    if (lowerMessage.includes('server error')) {
        return 'notifications.error.serverError';
    }

    return null;
};

/**
 * Handle API errors and optionally show toast
 */
export const handleApiError = (
    error: unknown,
    _options: ErrorHandlerOptions = {}
): string => {
    const message = extractErrorMessage(error);

    // Log error for debugging
    console.error('API Error:', error);

    return message;
};

/**
 * Format validation errors from API
 */
export const formatValidationErrors = (
    errors?: Record<string, string[]>
): string => {
    if (!errors) return '';

    const errorMessages = Object.entries(errors)
        .map(([field, messages]) => {
            const fieldName = field.charAt(0).toUpperCase() + field.slice(1);
            return `${fieldName}: ${messages.join(', ')}`;
        })
        .join('\n');

    return errorMessages;
};
