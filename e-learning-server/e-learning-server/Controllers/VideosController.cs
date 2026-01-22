using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SKVI.Infrastructure.VideoStreaming;

namespace e_learning_server.Controllers;

[ApiController]
[Route("api/videos")]
public class VideosController : ControllerBase
{
    private readonly IVideoSecurityService _videoSecurityService;
    private readonly ILogger<VideosController> _logger;

    public VideosController(IVideoSecurityService videoSecurityService, ILogger<VideosController> logger)
    {
        _videoSecurityService = videoSecurityService;
        _logger = logger;
    }

    [Authorize]
    [HttpGet("{videoId}/stream-url")]
    public IActionResult GetStreamUrl(string videoId)
    {
        try
        {
            // Generate signed URL that expires in 30 minutes
            var signedUrl = _videoSecurityService.GenerateSignedUrl(videoId, expirationMinutes: 30);
            
            _logger.LogInformation($"Generated signed URL for video {videoId}");
            
            return Ok(new 
            { 
                streamUrl = signedUrl,
                expiresIn = 1800 // 30 minutes in seconds
            });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, $"Error generating stream URL for video {videoId}");
            return StatusCode(500, new { message = "Failed to generate stream URL" });
        }
    }

    [Authorize]
    [HttpGet("{videoId}/embed-url")]
    public IActionResult GetEmbedUrl(string videoId)
    {
        try
        {
            var embedUrl = _videoSecurityService.GenerateEmbedUrl(videoId);
            
            return Ok(new 
            { 
                embedUrl = embedUrl
            });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, $"Error generating embed URL for video {videoId}");
            return StatusCode(500, new { message = "Failed to generate embed URL" });
        }
    }
}
