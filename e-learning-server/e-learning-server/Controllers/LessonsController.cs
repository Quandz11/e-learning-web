using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SKVI.Application.DTOs.Lessons;
using SKVI.Application.Interfaces;

namespace SKVI.API.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class LessonsController : ControllerBase
{
    private readonly ILessonService _lessonService;

    public LessonsController(ILessonService lessonService)
    {
        _lessonService = lessonService;
    }

    [HttpGet]
    [Authorize(Roles = "ADMIN,LECTURER")]
    public async Task<ActionResult<List<LessonDto>>> GetAll(CancellationToken cancellationToken)
    {
        var lessons = await _lessonService.GetAllAsync(cancellationToken);
        return Ok(lessons);
    }

    [HttpGet("{id:guid}")]
    [Authorize(Roles = "ADMIN,LECTURER,STUDENT")] // Students may need to view lessons if enrolled? 
                                                 // Actually Course API returns embedded lessons.
                                                 // This API is for Management mainly.
    public async Task<ActionResult<LessonDto>> GetById(Guid id, CancellationToken cancellationToken)
    {
        try
        {
            var lesson = await _lessonService.GetByIdAsync(id, cancellationToken);
            return Ok(lesson);
        }
        catch (KeyNotFoundException)
        {
            return NotFound();
        }
    }

    [HttpPost]
    [Authorize(Roles = "ADMIN,LECTURER")]
    public async Task<ActionResult<LessonDto>> Create([FromBody] CreateLessonRequest request, CancellationToken cancellationToken)
    {
        var created = await _lessonService.CreateAsync(request, cancellationToken);
        return CreatedAtAction(nameof(GetById), new { id = created.Id }, created);
    }

    [HttpPut("{id:guid}")]
    [Authorize(Roles = "ADMIN,LECTURER")]
    public async Task<ActionResult<LessonDto>> Update(Guid id, [FromBody] UpdateLessonRequest request, CancellationToken cancellationToken)
    {
        try
        {
            var updated = await _lessonService.UpdateAsync(id, request, cancellationToken);
            return Ok(updated);
        }
        catch (KeyNotFoundException)
        {
            return NotFound();
        }
    }

    [HttpDelete("{id:guid}")]
    [Authorize(Roles = "ADMIN,LECTURER")]
    public async Task<ActionResult> Delete(Guid id, CancellationToken cancellationToken)
    {
        try
        {
            await _lessonService.DeleteAsync(id, cancellationToken);
            return NoContent();
        }
        catch (KeyNotFoundException)
        {
            return NotFound();
        }
    }

    // Part Management Endpoints

    [HttpPost("{id:guid}/parts")]
    [Authorize(Roles = "ADMIN,LECTURER")]
    public async Task<ActionResult<LessonDto>> AddPart(Guid id, [FromBody] CreateLessonPartRequest request, CancellationToken cancellationToken)
    {
        try
        {
            var updated = await _lessonService.AddPartAsync(id, request, cancellationToken);
            return Ok(updated);
        }
        catch (KeyNotFoundException)
        {
            return NotFound();
        }
    }

    [HttpPut("{id:guid}/parts/{partId:guid}")]
    [Authorize(Roles = "ADMIN,LECTURER")]
    public async Task<ActionResult<LessonDto>> UpdatePart(Guid id, Guid partId, [FromBody] UpdateLessonPartRequest request, CancellationToken cancellationToken)
    {
        try
        {
            var updated = await _lessonService.UpdatePartAsync(id, partId, request, cancellationToken);
            return Ok(updated);
        }
        catch (KeyNotFoundException)
        {
            return NotFound();
        }
    }

    [HttpDelete("{id:guid}/parts/{partId:guid}")]
    [Authorize(Roles = "ADMIN,LECTURER")]
    public async Task<ActionResult<LessonDto>> DeletePart(Guid id, Guid partId, CancellationToken cancellationToken)
    {
        try
        {
            var updated = await _lessonService.DeletePartAsync(id, partId, cancellationToken);
            return Ok(updated);
        }
        catch (KeyNotFoundException)
        {
            return NotFound();
        }
    }
}
