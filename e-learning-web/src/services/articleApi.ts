import { apiClient } from './apiClient';

export interface Article {
    id: string;
    title: string;
    slug: string;
    content: string;
    excerpt?: string;
    featuredImageUrl?: string;
    categoryId?: string;
    categoryName?: string;
    authorId: string;
    authorName?: string;
    isPublished: boolean;
    publishedAt?: string;
    viewCount: number;
    metaDescription?: string;
    metaKeywords?: string;
    createdAt: string;
    updatedAt: string;
}

export interface ArticleListItem {
    id: string;
    title: string;
    slug: string;
    excerpt?: string;
    featuredImageUrl?: string;
    categoryName?: string;
    authorName?: string;
    isPublished: boolean;
    publishedAt?: string;
    viewCount: number;
    createdAt: string;
}

export interface CreateArticleDto {
    title: string;
    slug: string;
    content: string;
    excerpt?: string;
    featuredImageUrl?: string;
    categoryId?: string;
    isPublished: boolean;
    metaDescription?: string;
    metaKeywords?: string;
}

export interface UpdateArticleDto {
    title: string;
    slug: string;
    content: string;
    excerpt?: string;
    featuredImageUrl?: string;
    categoryId?: string;
    isPublished: boolean;
    metaDescription?: string;
    metaKeywords?: string;
}

export interface ArticleCategory {
    id: string;
    name: string;
    slug: string;
    description?: string;
    displayOrder: number;
    isActive: boolean;
    articleCount: number;
}

export interface CreateArticleCategoryDto {
    name: string;
    slug: string;
    description?: string;
    displayOrder: number;
}

export const articleApi = {
    // Public endpoints
    async getAll(): Promise<ArticleListItem[]> {
        return apiClient('/articles');
    },

    async getBySlug(slug: string): Promise<Article> {
        return apiClient(`/articles/${slug}`);
    },

    async getByCategory(categoryId: string): Promise<ArticleListItem[]> {
        return apiClient(`/articles/category/${categoryId}`);
    },

    async search(query: string): Promise<ArticleListItem[]> {
        return apiClient(`/articles/search?q=${encodeURIComponent(query)}`);
    },

    async getCategories(): Promise<ArticleCategory[]> {
        return apiClient('/articles/categories');
    },

    // Admin endpoints
    async getAllAdmin(): Promise<ArticleListItem[]> {
        return apiClient('/articles/admin');
    },

    async getById(id: string): Promise<Article> {
        return apiClient(`/articles/admin/${id}`);
    },

    async create(data: CreateArticleDto): Promise<Article> {
        return apiClient('/articles', {
            method: 'POST',
            body: JSON.stringify(data),
        });
    },

    async update(id: string, data: UpdateArticleDto): Promise<Article> {
        return apiClient(`/articles/${id}`, {
            method: 'PUT',
            body: JSON.stringify(data),
        });
    },

    async delete(id: string): Promise<void> {
        return apiClient(`/articles/${id}`, {
            method: 'DELETE',
        });
    },

    // Category management
    async createCategory(data: CreateArticleCategoryDto): Promise<ArticleCategory> {
        return apiClient('/articles/categories', {
            method: 'POST',
            body: JSON.stringify(data),
        });
    },

    async updateCategory(id: string, data: CreateArticleCategoryDto): Promise<ArticleCategory> {
        return apiClient(`/articles/categories/${id}`, {
            method: 'PUT',
            body: JSON.stringify(data),
        });
    },

    async deleteCategory(id: string): Promise<void> {
        return apiClient(`/articles/categories/${id}`, {
            method: 'DELETE',
        });
    },

    // Image upload
    async uploadImage(file: File, folder: string = 'images'): Promise<{ url: string }> {
        const formData = new FormData();
        formData.append('file', file);
        return apiClient(`/images/upload?folder=${folder}`, {
            method: 'POST',
            body: formData,
        });
    },

    async uploadArticleImage(articleId: string, file: File): Promise<{ url: string }> {
        const formData = new FormData();
        formData.append('file', file);
        return apiClient(`/images/article/${articleId}`, {
            method: 'POST',
            body: formData,
        });
    },

    async uploadArticleContentImage(file: File): Promise<{ url: string }> {
        const formData = new FormData();
        formData.append('file', file);
        return apiClient('/images/article-content', {
            method: 'POST',
            body: formData,
        });
    },
};
