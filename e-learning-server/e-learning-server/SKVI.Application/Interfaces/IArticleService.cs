using SKVI.Application.DTOs.Articles;
using SKVI.Shared;

namespace SKVI.Application.Interfaces;

public interface IArticleService
{
    // Article operations
    Task<List<ArticleListDto>> GetAllArticlesAsync(bool includeUnpublished = false);
    Task<PagedResult<ArticleListDto>> GetAllArticlesPaginatedAsync(int page, int pageSize, bool includeUnpublished = false);
    Task<ArticleDto?> GetArticleByIdAsync(Guid id);
    Task<ArticleDto?> GetArticleBySlugAsync(string slug);
    Task<List<ArticleListDto>> GetArticlesByCategoryAsync(Guid categoryId);
    Task<PagedResult<ArticleListDto>> GetArticlesCategoryPaginatedAsync(Guid categoryId, int page, int pageSize);
    Task<List<ArticleListDto>> SearchArticlesAsync(string query);
    Task<PagedResult<ArticleListDto>> SearchArticlesPaginatedAsync(string query, int page, int pageSize);
    Task<ArticleDto> CreateArticleAsync(CreateArticleDto dto, Guid authorId);
    Task<ArticleDto> UpdateArticleAsync(Guid id, UpdateArticleDto dto);
    Task DeleteArticleAsync(Guid id);
    Task IncrementViewCountAsync(Guid id);

    // Category operations
    Task<List<ArticleCategoryDto>> GetAllCategoriesAsync();
    Task<ArticleCategoryDto?> GetCategoryByIdAsync(Guid id);
    Task<ArticleCategoryDto> CreateCategoryAsync(CreateArticleCategoryDto dto);
    Task<ArticleCategoryDto> UpdateCategoryAsync(Guid id, CreateArticleCategoryDto dto);
    Task DeleteCategoryAsync(Guid id);
}
