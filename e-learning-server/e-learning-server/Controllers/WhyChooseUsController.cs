using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SKVI.Application.DTOs.WhyChooseUs;
using SKVI.Application.Interfaces;

namespace e_learning_server.Controllers;

[Route("api/why-choose-us")]
[ApiController]
public class WhyChooseUsController : ControllerBase
{
    private readonly IWhyChooseUsService _whyChooseUsService;

    public WhyChooseUsController(IWhyChooseUsService whyChooseUsService)
    {
        _whyChooseUsService = whyChooseUsService;
    }

    [HttpGet("active")]
    public async Task<ActionResult<List<WhyChooseUsItemDto>>> GetActiveItems()
    {
        var items = await _whyChooseUsService.GetActiveAsync();
        return Ok(items);
    }

    [Authorize(Roles = "ADMIN")]
    [HttpGet]
    public async Task<ActionResult<List<WhyChooseUsItemDto>>> GetAllItems()
    {
        var items = await _whyChooseUsService.GetAllAsync();
        return Ok(items);
    }

    [Authorize(Roles = "ADMIN")]
    [HttpGet("{id}")]
    public async Task<ActionResult<WhyChooseUsItemDto>> GetItemById(Guid id)
    {
        var item = await _whyChooseUsService.GetByIdAsync(id);
        if (item == null) return NotFound();
        return Ok(item);
    }

    [Authorize(Roles = "ADMIN")]
    [HttpPost]
    public async Task<ActionResult<WhyChooseUsItemDto>> CreateItem(CreateWhyChooseUsItemRequest request)
    {
        var item = await _whyChooseUsService.CreateAsync(request);
        return CreatedAtAction(nameof(GetItemById), new { id = item.Id }, item);
    }

    [Authorize(Roles = "ADMIN")]
    [HttpPut("{id}")]
    public async Task<ActionResult<WhyChooseUsItemDto>> UpdateItem(Guid id, UpdateWhyChooseUsItemRequest request)
    {
        try
        {
            var item = await _whyChooseUsService.UpdateAsync(id, request);
            return Ok(item);
        }
        catch (Exception ex)
        {
            return BadRequest(ex.Message);
        }
    }

    [Authorize(Roles = "ADMIN")]
    [HttpDelete("{id}")]
    public async Task<ActionResult> DeleteItem(Guid id)
    {
        var success = await _whyChooseUsService.DeleteAsync(id);
        if (!success) return NotFound();
        return NoContent();
    }
}
