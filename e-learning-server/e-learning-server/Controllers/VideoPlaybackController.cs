using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using SKVI.Application.Interfaces;
using SKVI.Infrastructure;
using SKVI.Infrastructure.VideoStreaming;

namespace SKVI.Controllers;

[Authorize]
[ApiController]
[Route("api/videos")]
public class VideoPlaybackController(
    ApplicationDbContext db,
    IBunnyStreamService bunny,
    IVideoSecurityService security) : ControllerBase
{
    [HttpGet("{id:guid}/playback")]
    public async Task<IActionResult> GetPlayback(Guid id, CancellationToken cancellationToken)
    {
        if (!Guid.TryParse(User.FindFirstValue(ClaimTypes.NameIdentifier), out var userId))
            return Unauthorized();

        var now = DateTime.UtcNow;
        var allowed = User.IsInRole("ADMIN") || await db.LessonParts.AnyAsync(p =>
            p.VideoId == id && p.Lesson.CourseLessons.Any(cl =>
                cl.Course.LecturerId == userId || (cl.Course.IsPublished &&
                (p.IsPreview || cl.Course.IsFree || cl.Course.Enrollments.Any(e =>
                    e.UserId == userId && e.Status == "ACTIVE" &&
                    (e.AccessExpiresAt == null || e.AccessExpiresAt > now))))), cancellationToken);

        if (!allowed)
            return StatusCode(403, new { code = "VIDEO_ACCESS_DENIED", message = "Bạn không có quyền xem video này." });

        var video = await db.Videos.AsNoTracking().FirstOrDefaultAsync(v => v.Id == id, cancellationToken);
        if (video == null || string.IsNullOrWhiteSpace(video.BunnyVideoId))
            return NotFound();

        const int expiryMinutes = 120;
        var playbackUrl = security.GenerateSignedUrl(video.BunnyVideoId, expiryMinutes);
        var expiresAt = DateTimeOffset.UtcNow.AddMinutes(expiryMinutes);
        var embedUrl = bunny.GetEmbedUrl(video.BunnyVideoId);

        Response.Headers.CacheControl = "no-store";
        return Ok(new { playbackUrl, expiresAt, embedUrl });
    }
}
