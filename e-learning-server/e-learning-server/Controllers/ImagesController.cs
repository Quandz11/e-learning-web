using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SKVI.Application.Interfaces;

namespace SKVI.Controllers;

[ApiController]
[Route("api/[controller]")]
public class ImagesController : ControllerBase
{
    private readonly IBunnyStreamService _bunnyService;
    private readonly ILogger<ImagesController> _logger;

    public ImagesController(IBunnyStreamService bunnyService, ILogger<ImagesController> logger)
    {
        _bunnyService = bunnyService;
        _logger = logger;
    }

    /// <summary>
    /// Upload image to Bunny CDN (general purpose)
    /// </summary>
    [HttpPost("upload")]
    [Authorize]
    public async Task<IActionResult> UploadImage(IFormFile file, [FromQuery] string folder = "images")
    {
        try
        {
            if (file == null || file.Length == 0)
            {
                return BadRequest(new { message = "No file uploaded" });
            }

            // Validate file type
            var allowedExtensions = new[] { ".jpg", ".jpeg", ".png", ".webp", ".gif" };
            var extension = Path.GetExtension(file.FileName).ToLowerInvariant();
            if (!allowedExtensions.Contains(extension))
            {
                return BadRequest(new { message = "Invalid file type. Only images are allowed." });
            }

            // Validate file size (max 5MB)
            if (file.Length > 5 * 1024 * 1024)
            {
                return BadRequest(new { message = "File size exceeds 5MB limit" });
            }

            using var stream = file.OpenReadStream();
            var url = await _bunnyService.UploadImageAsync(stream, file.FileName, folder);

            return Ok(new { url });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to upload image");
            return StatusCode(500, new { message = "Failed to upload image" });
        }
    }

    /// <summary>
    /// Upload featured image for an article
    /// </summary>
    [HttpPost("article/{articleId}")]
    [Authorize(Roles = "ADMIN")]
    public async Task<IActionResult> UploadArticleImage(Guid articleId, IFormFile file)
    {
        try
        {
            if (file == null || file.Length == 0)
            {
                return BadRequest(new { message = "No file uploaded" });
            }

            // Validate file type
            var allowedExtensions = new[] { ".jpg", ".jpeg", ".png", ".webp" };
            var extension = Path.GetExtension(file.FileName).ToLowerInvariant();
            if (!allowedExtensions.Contains(extension))
            {
                return BadRequest(new { message = "Invalid file type. Only images are allowed." });
            }

            // Validate file size (max 5MB)
            if (file.Length > 5 * 1024 * 1024)
            {
                return BadRequest(new { message = "File size exceeds 5MB limit" });
            }

            using var stream = file.OpenReadStream();
            var url = await _bunnyService.UploadImageAsync(stream, file.FileName, $"articles/featured");

            return Ok(new { url });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to upload article image for article {ArticleId}", articleId);
            return StatusCode(500, new { message = "Failed to upload image" });
        }
    }

    /// <summary>
    /// Upload image for article content
    /// </summary>
    [HttpPost("article-content")]
    [Authorize(Roles = "ADMIN")]
    public async Task<IActionResult> UploadArticleContentImage(IFormFile file)
    {
        try
        {
            if (file == null || file.Length == 0)
            {
                return BadRequest(new { message = "No file uploaded" });
            }

            // Validate file type
            var allowedExtensions = new[] { ".jpg", ".jpeg", ".png", ".webp", ".gif" };
            var extension = Path.GetExtension(file.FileName).ToLowerInvariant();
            if (!allowedExtensions.Contains(extension))
            {
                return BadRequest(new { message = "Invalid file type. Only images are allowed." });
            }

            // Validate file size (max 5MB)
            if (file.Length > 5 * 1024 * 1024)
            {
                return BadRequest(new { message = "File size exceeds 5MB limit" });
            }

            using var stream = file.OpenReadStream();
            var url = await _bunnyService.UploadImageAsync(stream, file.FileName, "articles/content");

            return Ok(new { url });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to upload article content image");
            return StatusCode(500, new { message = "Failed to upload image" });
        }
    }
}
