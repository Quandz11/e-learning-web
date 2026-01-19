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

    public VideosController(IVideoService videoService)
    {
        _videoService = videoService;
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
}
