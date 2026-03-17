using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SKVI.Application.DTOs.Articles;
using SKVI.Application.Interfaces;
using SKVI.Shared;
using System.Security.Claims;

namespace e_learning_server.Controllers;

[ApiController]
[Route("api/[controller]")]
public class ArticlesController : ControllerBase
{
    private readonly IArticleService _articleService;

    public ArticlesController(IArticleService articleService)
    {
        _articleService = articleService;
    }

    // Public endpoints
    [HttpGet]
    public async Task<ActionResult<PagedResult<ArticleListDto>>> GetAllArticles([FromQuery] int page = 1, [FromQuery] int pageSize = 10)
    {
        var result = await _articleService.GetAllArticlesPaginatedAsync(page, pageSize, includeUnpublished: false);
        return Ok(result);
    }

    [HttpGet("{slug}")]
    public async Task<ActionResult<ArticleDto>> GetArticleBySlug(string slug)
    {
        var article = await _articleService.GetArticleBySlugAsync(slug);
        if (article == null)
        {
            return NotFound();
        }

        // Increment view count
        await _articleService.IncrementViewCountAsync(article.Id);

        return Ok(article);
    }

    [HttpGet("category/{categoryId}")]
    public async Task<ActionResult<PagedResult<ArticleListDto>>> GetArticlesByCategory(Guid categoryId, [FromQuery] int page = 1, [FromQuery] int pageSize = 10)
    {
        var result = await _articleService.GetArticlesCategoryPaginatedAsync(categoryId, page, pageSize);
        return Ok(result);
    }

    [HttpGet("search")]
    public async Task<ActionResult<PagedResult<ArticleListDto>>> SearchArticles([FromQuery] string q, [FromQuery] int page = 1, [FromQuery] int pageSize = 10)
    {
        if (string.IsNullOrWhiteSpace(q))
        {
            return BadRequest("Search query is required");
        }

        var result = await _articleService.SearchArticlesPaginatedAsync(q, page, pageSize);
        return Ok(result);
    }

    [HttpGet("categories")]
    public async Task<ActionResult<List<ArticleCategoryDto>>> GetCategories()
    {
        var categories = await _articleService.GetAllCategoriesAsync();
        return Ok(categories);
    }

    // Admin endpoints
    [HttpGet("admin")]
    [Authorize(Roles = "ADMIN")]
    public async Task<ActionResult<List<ArticleListDto>>> GetAllArticlesAdmin()
    {
        var articles = await _articleService.GetAllArticlesAsync(includeUnpublished: true);
        return Ok(articles);
    }

    [HttpGet("admin/{id}")]
    [Authorize(Roles = "ADMIN")]
    public async Task<ActionResult<ArticleDto>> GetArticleById(Guid id)
    {
        var article = await _articleService.GetArticleByIdAsync(id);
        if (article == null)
        {
            return NotFound();
        }

        return Ok(article);
    }

    [HttpPost]
    [Authorize(Roles = "ADMIN")]
    public async Task<ActionResult<ArticleDto>> CreateArticle([FromBody] CreateArticleDto dto)
    {
        var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (string.IsNullOrEmpty(userId))
        {
            return Unauthorized();
        }

        try
        {
            var article = await _articleService.CreateArticleAsync(dto, Guid.Parse(userId));
            return CreatedAtAction(nameof(GetArticleById), new { id = article.Id }, article);
        }
        catch (Exception ex)
        {
            // Duplicate slug or other DB constraint violation
            if (ex.InnerException?.Message.Contains("UNIQUE") == true ||
                ex.InnerException?.Message.Contains("duplicate") == true ||
                ex.InnerException?.Message.Contains("Duplicate") == true)
            {
                return Conflict(new { message = "Slug bài viết đã tồn tại. Vui lòng đổi slug." });
            }
            return StatusCode(500, new { message = ex.Message });
        }
    }

    [HttpPut("{id}")]
    [Authorize(Roles = "ADMIN")]
    public async Task<ActionResult<ArticleDto>> UpdateArticle(Guid id, [FromBody] UpdateArticleDto dto)
    {
        try
        {
            var article = await _articleService.UpdateArticleAsync(id, dto);
            return Ok(article);
        }
        catch (Exception ex)
        {
            return NotFound(ex.Message);
        }
    }

    [HttpDelete("{id}")]
    [Authorize(Roles = "ADMIN")]
    public async Task<ActionResult> DeleteArticle(Guid id)
    {
        try
        {
            await _articleService.DeleteArticleAsync(id);
            return NoContent();
        }
        catch (Exception ex)
        {
            return NotFound(ex.Message);
        }
    }

    // Category management
    [HttpPost("categories")]
    [Authorize(Roles = "ADMIN")]
    public async Task<ActionResult<ArticleCategoryDto>> CreateCategory([FromBody] CreateArticleCategoryDto dto)
    {
        var category = await _articleService.CreateCategoryAsync(dto);
        return CreatedAtAction(nameof(GetCategories), new { id = category.Id }, category);
    }

    [HttpPut("categories/{id}")]
    [Authorize(Roles = "ADMIN")]
    public async Task<ActionResult<ArticleCategoryDto>> UpdateCategory(Guid id, [FromBody] CreateArticleCategoryDto dto)
    {
        try
        {
            var category = await _articleService.UpdateCategoryAsync(id, dto);
            return Ok(category);
        }
        catch (Exception ex)
        {
            return NotFound(ex.Message);
        }
    }

    [HttpDelete("categories/{id}")]
    [Authorize(Roles = "ADMIN")]
    public async Task<ActionResult> DeleteCategory(Guid id)
    {
        try
        {
            await _articleService.DeleteCategoryAsync(id);
            return NoContent();
        }
        catch (Exception ex)
        {
            return NotFound(ex.Message);
        }
    }
}
