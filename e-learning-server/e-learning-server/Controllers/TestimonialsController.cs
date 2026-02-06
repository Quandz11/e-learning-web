using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SKVI.Application.DTOs.Testimonial;
using SKVI.Application.Interfaces;

namespace e_learning_server.Controllers;

[Route("api/[controller]")]
[ApiController]
public class TestimonialsController : ControllerBase
{
    private readonly ITestimonialService _testimonialService;

    public TestimonialsController(ITestimonialService testimonialService)
    {
        _testimonialService = testimonialService;
    }

    [HttpGet("active")]
    public async Task<ActionResult<List<TestimonialDto>>> GetActiveTestimonials()
    {
        var testimonials = await _testimonialService.GetActiveAsync();
        return Ok(testimonials);
    }

    [Authorize(Roles = "ADMIN")]
    [HttpGet]
    public async Task<ActionResult<List<TestimonialDto>>> GetAllTestimonials()
    {
        var testimonials = await _testimonialService.GetAllAsync();
        return Ok(testimonials);
    }

    [Authorize(Roles = "ADMIN")]
    [HttpGet("{id}")]
    public async Task<ActionResult<TestimonialDto>> GetTestimonialById(Guid id)
    {
        var testimonial = await _testimonialService.GetByIdAsync(id);
        if (testimonial == null) return NotFound();
        return Ok(testimonial);
    }

    [Authorize(Roles = "ADMIN")]
    [HttpPost]
    public async Task<ActionResult<TestimonialDto>> CreateTestimonial(CreateTestimonialRequest request)
    {
        var testimonial = await _testimonialService.CreateAsync(request);
        return CreatedAtAction(nameof(GetTestimonialById), new { id = testimonial.Id }, testimonial);
    }

    [Authorize(Roles = "ADMIN")]
    [HttpPut("{id}")]
    public async Task<ActionResult<TestimonialDto>> UpdateTestimonial(Guid id, UpdateTestimonialRequest request)
    {
        try
        {
            var testimonial = await _testimonialService.UpdateAsync(id, request);
            return Ok(testimonial);
        }
        catch (Exception ex)
        {
            return BadRequest(ex.Message);
        }
    }

    [Authorize(Roles = "ADMIN")]
    [HttpDelete("{id}")]
    public async Task<ActionResult> DeleteTestimonial(Guid id)
    {
        var success = await _testimonialService.DeleteAsync(id);
        if (!success) return NotFound();
        return NoContent();
    }
}
