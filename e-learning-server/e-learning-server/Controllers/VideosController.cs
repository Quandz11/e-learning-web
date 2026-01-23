using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SKVI.Application.DTOs.Videos;
using SKVI.Application.Interfaces;

namespace SKVI.Controllers;

[Authorize]
[ApiController]
[Route("api/[controller]")]
public class VideosController : ControllerBase
{
    private readonly IVideoService _videoService;

    public VideosController(IVideoService videoService)
    {
        _videoService = videoService;
    }

    [HttpGet("{id:guid}/embed-url")]
    public async Task<ActionResult<EmbedUrlResponse>> GetEmbedUrl(Guid id, CancellationToken cancellationToken)
    {
        var embedUrl = await _videoService.GetEmbedUrlAsync(id, cancellationToken);
        
        if (embedUrl == null)
        {
            return NotFound(new { message = "Video not found" });
        }

        return Ok(new EmbedUrlResponse { EmbedUrl = embedUrl });
    }

    [HttpPost("upload")]
    [DisableRequestSizeLimit]
    [RequestFormLimits(MultipartBodyLengthLimit = 2147483648)] // 2GB
    public async Task<ActionResult<VideoUploadResponse>> Upload(IFormFile file, [FromForm] string? title, CancellationToken cancellationToken)
    {
        try
        {
            var result = await _videoService.UploadAsync(file, title, cancellationToken);
            return Ok(result);
        }
        catch (ArgumentException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
        catch (Exception ex)
        {
            return StatusCode(500, new { message = $"Upload failed: {ex.Message}" });
        }
    }

    [HttpPost("{id:guid}/sync-duration")]
    public async Task<ActionResult<object>> SyncDuration(Guid id, CancellationToken cancellationToken)
    {
        try
        {
            var duration = await _videoService.SyncDurationAsync(id, cancellationToken);
            return Ok(new { duration });
        }
        catch (ArgumentException ex)
        {
            return NotFound(new { message = ex.Message });
        }
        catch (Exception ex)
        {
            return StatusCode(500, new { message = $"Sync failed: {ex.Message}" });
        }
    }

    [HttpPost("{id:guid}/thumbnail")]
    public async Task<ActionResult> UploadThumbnail(Guid id, IFormFile file, CancellationToken cancellationToken)
    {
        try
        {
            await _videoService.SetThumbnailAsync(id, file, cancellationToken);
            return Ok(new { message = "Thumbnail uploaded successfully" });
        }
        catch (ArgumentException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
        catch (Exception ex)
        {
            return StatusCode(500, new { message = $"Thumbnail upload failed: {ex.Message}" });
        }
    }
}
