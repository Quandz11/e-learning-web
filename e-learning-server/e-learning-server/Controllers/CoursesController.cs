using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using SKVI.Application.DTOs.Courses;
using SKVI.Application.Interfaces;

namespace e_learning_server.Controllers;

[ApiController]
[Route("api/[controller]")]
public class CoursesController : ControllerBase
{
    private readonly ICourseService _courseService;
    private readonly IBunnyStreamService _bunnyStreamService;
    private readonly ILogger<CoursesController> _logger;

    public CoursesController(ICourseService courseService, IBunnyStreamService bunnyStreamService, ILogger<CoursesController> logger)
    {
        _courseService = courseService;
        _bunnyStreamService = bunnyStreamService;
        _logger = logger;
    }

    [HttpGet]
    public async Task<IActionResult> GetAll([FromQuery] bool? isPublished, CancellationToken cancellationToken)
    {
        var result = await _courseService.GetAllAsync(isPublished, cancellationToken);
        return Ok(result);
    }

    [HttpGet("{id:guid}")]
    public async Task<IActionResult> GetById(Guid id, CancellationToken cancellationToken)
    {
        try
        {
            var result = await _courseService.GetByIdAsync(id, cancellationToken);
            return Ok(result);
        }
        catch (KeyNotFoundException)
        {
            return NotFound();
        }
    }

    [HttpPost]
    [Authorize(Roles = "ADMIN,LECTURER")]
    public async Task<IActionResult> Create([FromBody] CreateCourseRequest request, CancellationToken cancellationToken)
    {
        var created = await _courseService.CreateAsync(request, cancellationToken);
        _logger.LogInformation("Course created: {CourseId}", created.Id);
        return CreatedAtAction(nameof(GetById), new { id = created.Id }, created);
    }

    [HttpPut("{id:guid}")]
    [Authorize(Roles = "ADMIN,LECTURER")]
    public async Task<IActionResult> Update(Guid id, [FromBody] UpdateCourseRequest request, CancellationToken cancellationToken)
    {
        try
        {
            var updated = await _courseService.UpdateAsync(id, request, cancellationToken);
            return Ok(updated);
        }
        catch (KeyNotFoundException)
        {
            return NotFound();
        }
    }

    [HttpDelete("{id:guid}")]
    [Authorize(Roles = "ADMIN")]
    public async Task<IActionResult> Delete(Guid id, CancellationToken cancellationToken)
    {
        try
        {
            await _courseService.DeleteAsync(id, cancellationToken);
            return NoContent();
        }
        catch (KeyNotFoundException)
        {
            return NotFound();
        }
    }

    [HttpPost("thumbnail")]
    [Authorize(Roles = "ADMIN,LECTURER")]
    [RequestSizeLimit(20_000_000)]
    public async Task<IActionResult> UploadThumbnail([FromForm] IFormFile file, CancellationToken cancellationToken)
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
            await using var stream = file.OpenReadStream();
            var url = await _bunnyStreamService.UploadImageAsync(stream, file.FileName, cancellationToken);
            return Ok(new { url });
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

    [HttpOptions("thumbnail")]
    public IActionResult ThumbnailOptions()
    {
        return NoContent();
    }
}
