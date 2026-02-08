import { apiClient } from './apiClient';

// Forum Category
export interface ForumCategoryDto {
    id: string;
    name: string;
    description?: string;
    icon?: string;
    order: number;
    isActive: boolean;
    threadCount: number;
    createdAt: string;
}

export interface CreateForumCategoryRequest {
    name: string;
    description?: string;
    icon?: string;
    order: number;
    isActive: boolean;
}

export interface UpdateForumCategoryRequest {
    name: string;
    description?: string;
    icon?: string;
    order: number;
    isActive: boolean;
}

// Forum Thread
export interface ForumThreadDto {
    id: string;
    categoryId: string;
    categoryName: string;
    authorId: string;
    authorName: string;
    authorAvatarUrl?: string;
    title: string;
    content: string;
    viewCount: number;
    postCount: number;
    createdAt: string;
    updatedAt?: string;
    lastPostAt?: string;
}

export interface CreateForumThreadRequest {
    categoryId: string;
    title: string;
    content: string;
}

export interface UpdateForumThreadRequest {
    title: string;
    content: string;
}

// Forum Post
export interface ForumPostDto {
    id: string;
    threadId: string;
    authorId: string;
    authorName: string;
    authorAvatarUrl?: string;
    content: string;
    createdAt: string;
    updatedAt?: string;
}

export interface CreateForumPostRequest {
    threadId: string;
    content: string;
}

export interface UpdateForumPostRequest {
    content: string;
}

export const forumApi = {
    // Categories
    categories: {
        async getAll(): Promise<ForumCategoryDto[]> {
            return apiClient('/forum/categories');
        },

        async getById(id: string): Promise<ForumCategoryDto> {
            return apiClient(`/forum/categories/${id}`);
        },

        async create(data: CreateForumCategoryRequest): Promise<ForumCategoryDto> {
            return apiClient('/forum/categories', {
                method: 'POST',
                body: JSON.stringify(data),
            });
        },

        async update(id: string, data: UpdateForumCategoryRequest): Promise<ForumCategoryDto> {
            return apiClient(`/forum/categories/${id}`, {
                method: 'PUT',
                body: JSON.stringify(data),
            });
        },

        async delete(id: string): Promise<void> {
            return apiClient(`/forum/categories/${id}`, {
                method: 'DELETE',
            });
        },
    },

    // Threads
    threads: {
        async getByCategory(categoryId: string): Promise<ForumThreadDto[]> {
            return apiClient(`/forum/categories/${categoryId}/threads`);
        },

        async getById(id: string): Promise<ForumThreadDto> {
            return apiClient(`/forum/threads/${id}`);
        },

        async create(data: CreateForumThreadRequest): Promise<ForumThreadDto> {
            return apiClient('/forum/threads', {
                method: 'POST',
                body: JSON.stringify(data),
            });
        },

        async update(id: string, data: UpdateForumThreadRequest): Promise<ForumThreadDto> {
            return apiClient(`/forum/threads/${id}`, {
                method: 'PUT',
                body: JSON.stringify(data),
            });
        },

        async delete(id: string): Promise<void> {
            return apiClient(`/forum/threads/${id}`, {
                method: 'DELETE',
            });
        },
    },

    // Posts
    posts: {
        async getByThread(threadId: string): Promise<ForumPostDto[]> {
            return apiClient(`/forum/threads/${threadId}/posts`);
        },

        async create(data: CreateForumPostRequest): Promise<ForumPostDto> {
            return apiClient('/forum/posts', {
                method: 'POST',
                body: JSON.stringify(data),
            });
        },

        async update(id: string, data: UpdateForumPostRequest): Promise<ForumPostDto> {
            return apiClient(`/forum/posts/${id}`, {
                method: 'PUT',
                body: JSON.stringify(data),
            });
        },

        async delete(id: string): Promise<void> {
            return apiClient(`/forum/posts/${id}`, {
                method: 'DELETE',
            });
        },
    },
};
