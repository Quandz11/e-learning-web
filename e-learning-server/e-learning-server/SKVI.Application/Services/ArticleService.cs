using Microsoft.EntityFrameworkCore;
using SKVI.Application.DTOs.Articles;
using SKVI.Application.Interfaces;
using SKVI.Domain.Entities;
using SKVI.Infrastructure;

namespace SKVI.Application.Services;

public class ArticleService : IArticleService
{
    private readonly ApplicationDbContext _context;

    public ArticleService(ApplicationDbContext context)
    {
        _context = context;
    }

    public async Task<List<ArticleListDto>> GetAllArticlesAsync(bool includeUnpublished = false)
    {
        var query = _context.Articles
            .Include(a => a.Category)
            .Include(a => a.Author)
            .AsQueryable();

        if (!includeUnpublished)
        {
            query = query.Where(a => a.IsPublished);
        }

        return await query
            .OrderByDescending(a => a.PublishedAt ?? a.CreatedAt)
            .Select(a => new ArticleListDto
            {
                Id = a.Id,
                Title = a.Title,
                Slug = a.Slug,
                Excerpt = a.Excerpt,
                FeaturedImageUrl = a.FeaturedImageUrl,
                CategoryName = a.Category != null ? a.Category.Name : null,
                AuthorName = a.Author.FullName ?? a.Author.Email,
                IsPublished = a.IsPublished,
                PublishedAt = a.PublishedAt,
                ViewCount = a.ViewCount,
                CreatedAt = a.CreatedAt
            })
            .ToListAsync();
    }

    public async Task<ArticleDto?> GetArticleByIdAsync(Guid id)
    {
        return await _context.Articles
            .Include(a => a.Category)
            .Include(a => a.Author)
            .Where(a => a.Id == id)
            .Select(a => new ArticleDto
            {
                Id = a.Id,
                Title = a.Title,
                Slug = a.Slug,
                Content = a.Content,
                Excerpt = a.Excerpt,
                FeaturedImageUrl = a.FeaturedImageUrl,
                CategoryId = a.CategoryId,
                CategoryName = a.Category != null ? a.Category.Name : null,
                AuthorId = a.AuthorId,
                AuthorName = a.Author.FullName ?? a.Author.Email,
                IsPublished = a.IsPublished,
                PublishedAt = a.PublishedAt,
                ViewCount = a.ViewCount,
                MetaDescription = a.MetaDescription,
                MetaKeywords = a.MetaKeywords,
                CreatedAt = a.CreatedAt,
                UpdatedAt = a.UpdatedAt
            })
            .FirstOrDefaultAsync();
    }

    public async Task<ArticleDto?> GetArticleBySlugAsync(string slug)
    {
        return await _context.Articles
            .Include(a => a.Category)
            .Include(a => a.Author)
            .Where(a => a.Slug == slug && a.IsPublished)
            .Select(a => new ArticleDto
            {
                Id = a.Id,
                Title = a.Title,
                Slug = a.Slug,
                Content = a.Content,
                Excerpt = a.Excerpt,
                FeaturedImageUrl = a.FeaturedImageUrl,
                CategoryId = a.CategoryId,
                CategoryName = a.Category != null ? a.Category.Name : null,
                AuthorId = a.AuthorId,
                AuthorName = a.Author.FullName ?? a.Author.Email,
                IsPublished = a.IsPublished,
                PublishedAt = a.PublishedAt,
                ViewCount = a.ViewCount,
                MetaDescription = a.MetaDescription,
                MetaKeywords = a.MetaKeywords,
                CreatedAt = a.CreatedAt,
                UpdatedAt = a.UpdatedAt
            })
            .FirstOrDefaultAsync();
    }

    public async Task<List<ArticleListDto>> GetArticlesByCategoryAsync(Guid categoryId)
    {
        return await _context.Articles
            .Include(a => a.Category)
            .Include(a => a.Author)
            .Where(a => a.CategoryId == categoryId && a.IsPublished)
            .OrderByDescending(a => a.PublishedAt ?? a.CreatedAt)
            .Select(a => new ArticleListDto
            {
                Id = a.Id,
                Title = a.Title,
                Slug = a.Slug,
                Excerpt = a.Excerpt,
                FeaturedImageUrl = a.FeaturedImageUrl,
                CategoryName = a.Category != null ? a.Category.Name : null,
                AuthorName = a.Author.FullName ?? a.Author.Email,
                IsPublished = a.IsPublished,
                PublishedAt = a.PublishedAt,
                ViewCount = a.ViewCount,
                CreatedAt = a.CreatedAt
            })
            .ToListAsync();
    }

    public async Task<List<ArticleListDto>> SearchArticlesAsync(string query)
    {
        return await _context.Articles
            .Include(a => a.Category)
            .Include(a => a.Author)
            .Where(a => a.IsPublished && 
                   (a.Title.Contains(query) || 
                    a.Content.Contains(query) || 
                    (a.Excerpt != null && a.Excerpt.Contains(query))))
            .OrderByDescending(a => a.PublishedAt ?? a.CreatedAt)
            .Select(a => new ArticleListDto
            {
                Id = a.Id,
                Title = a.Title,
                Slug = a.Slug,
                Excerpt = a.Excerpt,
                FeaturedImageUrl = a.FeaturedImageUrl,
                CategoryName = a.Category != null ? a.Category.Name : null,
                AuthorName = a.Author.FullName ?? a.Author.Email,
                IsPublished = a.IsPublished,
                PublishedAt = a.PublishedAt,
                ViewCount = a.ViewCount,
                CreatedAt = a.CreatedAt
            })
            .ToListAsync();
    }

    public async Task<ArticleDto> CreateArticleAsync(CreateArticleDto dto, Guid authorId)
    {
        var article = new Article
        {
            Id = Guid.NewGuid(),
            Title = dto.Title,
            Slug = dto.Slug,
            Content = dto.Content,
            Excerpt = dto.Excerpt,
            FeaturedImageUrl = dto.FeaturedImageUrl,
            CategoryId = dto.CategoryId,
            AuthorId = authorId,
            IsPublished = dto.IsPublished,
            PublishedAt = dto.IsPublished ? DateTime.UtcNow : null,
            MetaDescription = dto.MetaDescription,
            MetaKeywords = dto.MetaKeywords,
            CreatedAt = DateTime.UtcNow,
            UpdatedAt = DateTime.UtcNow
        };

        _context.Articles.Add(article);
        await _context.SaveChangesAsync();

        return (await GetArticleByIdAsync(article.Id))!;
    }

    public async Task<ArticleDto> UpdateArticleAsync(Guid id, UpdateArticleDto dto)
    {
        var article = await _context.Articles.FindAsync(id);
        if (article == null)
        {
            throw new Exception("Article not found");
        }

        var wasPublished = article.IsPublished;

        article.Title = dto.Title;
        article.Slug = dto.Slug;
        article.Content = dto.Content;
        article.Excerpt = dto.Excerpt;
        article.FeaturedImageUrl = dto.FeaturedImageUrl;
        article.CategoryId = dto.CategoryId;
        article.IsPublished = dto.IsPublished;
        article.MetaDescription = dto.MetaDescription;
        article.MetaKeywords = dto.MetaKeywords;
        article.UpdatedAt = DateTime.UtcNow;

        // Set PublishedAt if publishing for the first time
        if (!wasPublished && dto.IsPublished)
        {
            article.PublishedAt = DateTime.UtcNow;
        }

        await _context.SaveChangesAsync();

        return (await GetArticleByIdAsync(article.Id))!;
    }

    public async Task DeleteArticleAsync(Guid id)
    {
        var article = await _context.Articles.FindAsync(id);
        if (article == null)
        {
            throw new Exception("Article not found");
        }

        _context.Articles.Remove(article);
        await _context.SaveChangesAsync();
    }

    public async Task IncrementViewCountAsync(Guid id)
    {
        var article = await _context.Articles.FindAsync(id);
        if (article != null)
        {
            article.ViewCount++;
            await _context.SaveChangesAsync();
        }
    }

    // Category operations
    public async Task<List<ArticleCategoryDto>> GetAllCategoriesAsync()
    {
        return await _context.ArticleCategories
            .OrderBy(c => c.DisplayOrder)
            .Select(c => new ArticleCategoryDto
            {
                Id = c.Id,
                Name = c.Name,
                Slug = c.Slug,
                Description = c.Description,
                DisplayOrder = c.DisplayOrder,
                IsActive = c.IsActive,
                ArticleCount = c.Articles.Count(a => a.IsPublished)
            })
            .ToListAsync();
    }

    public async Task<ArticleCategoryDto?> GetCategoryByIdAsync(Guid id)
    {
        return await _context.ArticleCategories
            .Where(c => c.Id == id)
            .Select(c => new ArticleCategoryDto
            {
                Id = c.Id,
                Name = c.Name,
                Slug = c.Slug,
                Description = c.Description,
                DisplayOrder = c.DisplayOrder,
                IsActive = c.IsActive,
                ArticleCount = c.Articles.Count(a => a.IsPublished)
            })
            .FirstOrDefaultAsync();
    }

    public async Task<ArticleCategoryDto> CreateCategoryAsync(CreateArticleCategoryDto dto)
    {
        var category = new ArticleCategory
        {
            Id = Guid.NewGuid(),
            Name = dto.Name,
            Slug = dto.Slug,
            Description = dto.Description,
            DisplayOrder = dto.DisplayOrder,
            IsActive = true,
            CreatedAt = DateTime.UtcNow
        };

        _context.ArticleCategories.Add(category);
        await _context.SaveChangesAsync();

        return (await GetCategoryByIdAsync(category.Id))!;
    }

    public async Task<ArticleCategoryDto> UpdateCategoryAsync(Guid id, CreateArticleCategoryDto dto)
    {
        var category = await _context.ArticleCategories.FindAsync(id);
        if (category == null)
        {
            throw new Exception("Category not found");
        }

        category.Name = dto.Name;
        category.Slug = dto.Slug;
        category.Description = dto.Description;
        category.DisplayOrder = dto.DisplayOrder;

        await _context.SaveChangesAsync();

        return (await GetCategoryByIdAsync(category.Id))!;
    }

    public async Task DeleteCategoryAsync(Guid id)
    {
        var category = await _context.ArticleCategories.FindAsync(id);
        if (category == null)
        {
            throw new Exception("Category not found");
        }

        _context.ArticleCategories.Remove(category);
        await _context.SaveChangesAsync();
    }
}
