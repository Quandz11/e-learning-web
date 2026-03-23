export const HttpStatusCode = {
    OK: 200,
    CREATED: 201,
    NO_CONTENT: 204,
    BAD_REQUEST: 400,
    UNAUTHORIZED: 401,
    FORBIDDEN: 403,
    NOT_FOUND: 404,
    CONFLICT: 409,
    INTERNAL_SERVER_ERROR: 500,
} as const;

export interface ApiErrorResponse {
    message: string;
    code?: string;
    statusCode?: number;
    errors?: Record<string, string[]>;
}

export class ApiError extends Error {
    statusCode: number;
    code?: string;
    errors?: Record<string, string[]>;

    constructor(message: string, statusCode: number, errors?: Record<string, string[]>, code?: string) {
        super(message);
        this.name = 'ApiError';
        this.statusCode = statusCode;
        this.errors = errors;
        this.code = code;
    }
}
