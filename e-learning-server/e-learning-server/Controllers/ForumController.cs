using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SKVI.Application.DTOs.Forum;
using SKVI.Application.Services;
using System.Security.Claims;

namespace e_learning_server.Controllers;

[ApiController]
[Route("api/[controller]")]
public class ForumController : ControllerBase
{
    private readonly ForumService _forumService;

    public ForumController(ForumService forumService)
    {
        _forumService = forumService;
    }

    #region Categories - Public

    [HttpGet("categories")]
    public async Task<ActionResult<List<ForumCategoryDto>>> GetCategories()
    {
        var categories = await _forumService.GetAllCategoriesAsync();
        return Ok(categories);
    }

    [HttpGet("categories/{id}")]
    public async Task<ActionResult<ForumCategoryDto>> GetCategoryById(Guid id)
    {
        var category = await _forumService.GetCategoryByIdAsync(id);
        if (category == null)
        {
            return NotFound();
        }
        return Ok(category);
    }

    #endregion

    #region Categories - Admin

    [HttpPost("categories")]
    [Authorize(Roles = "ADMIN")]
    public async Task<ActionResult<ForumCategoryDto>> CreateCategory([FromBody] CreateForumCategoryRequest request)
    {
        var category = await _forumService.CreateCategoryAsync(request);
        return CreatedAtAction(nameof(GetCategoryById), new { id = category.Id }, category);
    }

    [HttpPut("categories/{id}")]
    [Authorize(Roles = "ADMIN")]
    public async Task<ActionResult<ForumCategoryDto>> UpdateCategory(Guid id, [FromBody] UpdateForumCategoryRequest request)
    {
        try
        {
            var category = await _forumService.UpdateCategoryAsync(id, request);
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
            await _forumService.DeleteCategoryAsync(id);
            return NoContent();
        }
        catch (Exception ex)
        {
            return NotFound(ex.Message);
        }
    }

    #endregion

    #region Threads

    [HttpGet("categories/{categoryId}/threads")]
    public async Task<ActionResult<List<ForumThreadDto>>> GetThreadsByCategory(Guid categoryId)
    {
        var threads = await _forumService.GetThreadsByCategoryAsync(categoryId);
        return Ok(threads);
    }

    [HttpGet("threads/{id}")]
    public async Task<ActionResult<ForumThreadDto>> GetThreadById(Guid id)
    {
        var thread = await _forumService.GetThreadByIdAsync(id);
        if (thread == null)
        {
            return NotFound();
        }
        return Ok(thread);
    }

    [HttpPost("threads")]
    [Authorize]
    public async Task<ActionResult<ForumThreadDto>> CreateThread([FromBody] CreateForumThreadRequest request)
    {
        var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (string.IsNullOrEmpty(userId))
        {
            return Unauthorized();
        }

        var thread = await _forumService.CreateThreadAsync(request, Guid.Parse(userId));
        return CreatedAtAction(nameof(GetThreadById), new { id = thread.Id }, thread);
    }

    [HttpPut("threads/{id}")]
    [Authorize]
    public async Task<ActionResult<ForumThreadDto>> UpdateThread(Guid id, [FromBody] UpdateForumThreadRequest request)
    {
        var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (string.IsNullOrEmpty(userId))
        {
            return Unauthorized();
        }

        try
        {
            var thread = await _forumService.UpdateThreadAsync(id, request, Guid.Parse(userId));
            return Ok(thread);
        }
        catch (UnauthorizedAccessException ex)
        {
            return Forbid(ex.Message);
        }
        catch (Exception ex)
        {
            return NotFound(ex.Message);
        }
    }

    [HttpDelete("threads/{id}")]
    [Authorize]
    public async Task<ActionResult> DeleteThread(Guid id)
    {
        var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (string.IsNullOrEmpty(userId))
        {
            return Unauthorized();
        }

        var isAdmin = User.IsInRole("ADMIN");

        try
        {
            await _forumService.DeleteThreadAsync(id, Guid.Parse(userId), isAdmin);
            return NoContent();
        }
        catch (UnauthorizedAccessException ex)
        {
            return Forbid(ex.Message);
        }
        catch (Exception ex)
        {
            return NotFound(ex.Message);
        }
    }

    #endregion

    #region Posts

    [HttpGet("threads/{threadId}/posts")]
    public async Task<ActionResult<List<ForumPostDto>>> GetPostsByThread(Guid threadId)
    {
        var posts = await _forumService.GetPostsByThreadAsync(threadId);
        return Ok(posts);
    }

    [HttpPost("posts")]
    [Authorize]
    public async Task<ActionResult<ForumPostDto>> CreatePost([FromBody] CreateForumPostRequest request)
    {
        var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (string.IsNullOrEmpty(userId))
        {
            return Unauthorized();
        }

        var post = await _forumService.CreatePostAsync(request, Guid.Parse(userId));
        return CreatedAtAction(nameof(GetPostsByThread), new { threadId = post.ThreadId }, post);
    }

    [HttpPut("posts/{id}")]
    [Authorize]
    public async Task<ActionResult<ForumPostDto>> UpdatePost(Guid id, [FromBody] UpdateForumPostRequest request)
    {
        var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (string.IsNullOrEmpty(userId))
        {
            return Unauthorized();
        }

        try
        {
            var post = await _forumService.UpdatePostAsync(id, request, Guid.Parse(userId));
            return Ok(post);
        }
        catch (UnauthorizedAccessException ex)
        {
            return Forbid(ex.Message);
        }
        catch (Exception ex)
        {
            return NotFound(ex.Message);
        }
    }

    [HttpDelete("posts/{id}")]
    [Authorize]
    public async Task<ActionResult> DeletePost(Guid id)
    {
        var userId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (string.IsNullOrEmpty(userId))
        {
            return Unauthorized();
        }

        var isAdmin = User.IsInRole("ADMIN");

        try
        {
            await _forumService.DeletePostAsync(id, Guid.Parse(userId), isAdmin);
            return NoContent();
        }
        catch (UnauthorizedAccessException ex)
        {
            return Forbid(ex.Message);
        }
        catch (Exception ex)
        {
            return NotFound(ex.Message);
        }
    }

    #endregion
}
