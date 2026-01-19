using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using SKVI.Application.Interfaces;

namespace e_learning_server.Controllers;

[ApiController]
[Route("api/videos")]
public class VideosController : ControllerBase
{
    private readonly IVideoService _videoService;
    private readonly IBunnyStreamService _bunnyStreamService;

    public VideosController(IVideoService videoService, IBunnyStreamService bunnyStreamService)
    {
        _videoService = videoService;
        _bunnyStreamService = bunnyStreamService;
    }

    [HttpPost("upload")]
    [Authorize(Roles = "ADMIN,LECTURER")]
    [RequestSizeLimit(1_000_000_000)] // Allow up to ~1GB, adjust as needed
    public async Task<IActionResult> Upload([FromForm] IFormFile file, [FromForm] string? title, CancellationToken cancellationToken)
    {
        if (file == null)
        {
            return BadRequest(new { message = "File is required" });
        }

        try
        {
            var result = await _videoService.UploadAsync(file, title, cancellationToken);
            return Ok(result);
        }
        catch (ArgumentException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    [HttpPost("{videoId}/thumbnail")]
    [Authorize(Roles = "ADMIN,LECTURER")]
    [RequestSizeLimit(20_000_000)]
    public async Task<IActionResult> UploadThumbnail(Guid videoId, [FromForm] IFormFile file, CancellationToken cancellationToken)
    {
        if (file == null)
        {
            return BadRequest(new { message = "File is required" });
        }

        if (!file.ContentType.StartsWith("image/", StringComparison.OrdinalIgnoreCase))
        {
            return BadRequest(new { message = "Only image files are allowed" });
        }

        try
        {
            var video = await _videoService.GetByIdAsync(videoId, cancellationToken);
            if (video == null || string.IsNullOrWhiteSpace(video.BunnyVideoId))
            {
                return NotFound(new { message = "Video not found" });
            }

            await using var stream = file.OpenReadStream();
            await _bunnyStreamService.UploadVideoThumbnailAsync(video.BunnyVideoId, stream, file.FileName, cancellationToken);
            return Ok(new { message = "Thumbnail uploaded" });
        }
        catch (ArgumentException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }
}
