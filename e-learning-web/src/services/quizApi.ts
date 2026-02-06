import { apiClient } from './apiClient';

export const QuestionType = {
    Text: 0,
    MultipleChoice: 1,
    SingleChoice: 2,
    LongText: 3,
} as const;

export type QuestionType = typeof QuestionType[keyof typeof QuestionType];

export interface QuizOptionDto {
    id: string;
    text: string;
    value?: string;
    order: number;
}

export interface QuizQuestionDto {
    id: string;
    text: string;
    type: QuestionType;
    order: number;
    isRequired: boolean;
    options: QuizOptionDto[];
}

export interface QuizDto {
    id: string;
    title: string;
    description?: string;
    isActive: boolean;
    createdAt: string;
    questions: QuizQuestionDto[];
}

// Creation / Update Inputs
export interface CreateOptionInput {
    id?: string;
    text: string;
    value?: string;
    order: number;
}

export interface CreateQuestionInput {
    id?: string;
    text: string;
    type: QuestionType;
    order: number;
    isRequired: boolean;
    options: CreateOptionInput[];
}

export interface CreateQuizInput {
    title: string;
    description?: string;
    isActive: boolean;
    questions: CreateQuestionInput[];
}

// Submission
export interface SubmitAnswerInput {
    questionId: string;
    textValue?: string;
    selectedOptionId?: string;
}

export interface SubmitQuizInput {
    quizId: string;
    fullName?: string;
    phoneNumber?: string;
    email?: string;
    answers: SubmitAnswerInput[];
}

export interface QuizSubmissionDto {
    id: string;
    quizId: string;
    userId?: string;
    fullName?: string;
    phoneNumber?: string;
    email?: string;
    submittedAt: string;
    answers: {
        id: string;
        questionId: string;
        questionText: string;
        textValue?: string;
        selectedOptionId?: string;
        selectedOptionText?: string;
    }[];
}

export const quizApi = {
    async getActive(): Promise<QuizDto | null> {
        try {
            return await apiClient('/quizzes/active');
        } catch (err: any) {
            if (err.status === 404) return null;
            throw err;
        }
    },

    async getAll(): Promise<QuizDto[]> {
        return apiClient('/quizzes');
    },

    async getById(id: string): Promise<QuizDto> {
        return apiClient(`/quizzes/${id}`);
    },

    async create(payload: CreateQuizInput): Promise<QuizDto> {
        return apiClient('/quizzes', {
            method: 'POST',
            body: JSON.stringify(payload),
        });
    },

    async update(id: string, payload: CreateQuizInput): Promise<QuizDto> {
        return apiClient(`/quizzes/${id}`, {
            method: 'PUT',
            body: JSON.stringify(payload),
        });
    },

    async delete(id: string): Promise<void> {
        return apiClient(`/quizzes/${id}`, {
            method: 'DELETE',
        });
    },

    async submit(payload: SubmitQuizInput): Promise<string> {
        return apiClient('/quizsubmissions', {
            method: 'POST',
            body: JSON.stringify(payload),
        });
    },

    async getSubmissions(quizId: string): Promise<QuizSubmissionDto[]> {
        return apiClient(`/quizsubmissions/quiz/${quizId}`);
    }
};
