using System.Security.Claims;
using System.Security.Cryptography;
using System.Text;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using SKVI.Application.Interfaces;
using SKVI.Infrastructure;

namespace SKVI.Controllers;

[Authorize]
[ApiController]
[Route("api/videos")]
public class VideoPlaybackController(ApplicationDbContext db, IBunnyStreamService bunny,
    IConfiguration configuration) : ControllerBase
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
        if (!allowed) return StatusCode(403, new { code = "VIDEO_ACCESS_DENIED", message = "Bạn không có quyền xem video này." });
        var video = await db.Videos.AsNoTracking().FirstOrDefaultAsync(v => v.Id == id, cancellationToken);
        if (video == null || string.IsNullOrWhiteSpace(video.BunnyVideoId)) return NotFound();
        var expires = DateTimeOffset.UtcNow.AddHours(1);
        var url = bunny.GetPlaybackUrl(video.BunnyVideoId);
        // CDN keys and embed signing keys are different. Without a configured CDN
        // key, attempt the existing direct source and retain the signed embed fallback.
        var cdnKey = configuration["BunnySettings:CdnTokenKey"];
        if (!string.IsNullOrWhiteSpace(cdnKey)) url = SignDirectoryUrl(url, cdnKey, expires);
        Response.Headers.CacheControl = "no-store";
        return Ok(new { playbackUrl = url, expiresAt = string.IsNullOrWhiteSpace(cdnKey) ? (DateTimeOffset?)null : expires,
            embedUrl = bunny.GetEmbedUrl(video.BunnyVideoId) });
    }

    public static string SignDirectoryUrl(string url, string key, DateTimeOffset expires)
    {
        var uri = new Uri(url);
        var path = uri.AbsolutePath[..(uri.AbsolutePath.LastIndexOf('/') + 1)];
        var timestamp = expires.ToUnixTimeSeconds();
        var signingData = $"token_path={path}";
        var hash = HMACSHA256.HashData(Encoding.UTF8.GetBytes(key), Encoding.UTF8.GetBytes($"{path}{timestamp}{signingData}"));
        var token = "HS256-" + Convert.ToBase64String(hash).TrimEnd('=').Replace('+', '-').Replace('/', '_');
        return $"{uri.GetLeftPart(UriPartial.Authority)}/bcdn_token={token}&expires={timestamp}&token_path={Uri.EscapeDataString(path)}{uri.AbsolutePath}";
    }
}
