using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SKVI.Application.DTOs.Home;
using SKVI.Application.Interfaces;

namespace e_learning_server.Controllers;

[ApiController]
[Route("api/[controller]")]
public class HomeSectionController : ControllerBase
{
    private readonly IHomeVideoSectionService _homeVideoSectionService;

    public HomeSectionController(IHomeVideoSectionService homeVideoSectionService)
    {
        _homeVideoSectionService = homeVideoSectionService;
    }

    [HttpGet]
    public async Task<ActionResult<HomeVideoSectionDto>> Get()
    {
        var section = await _homeVideoSectionService.GetHomeVideoSectionAsync();
        return Ok(section); // If null, return 204 or empty object if preferred, but frontend should handle null. 
    }

    [HttpPut]
    [Authorize(Roles = "ADMIN")]
    public async Task<ActionResult<HomeVideoSectionDto>> Update([FromBody] UpdateHomeVideoSectionDto dto)
    {
        var result = await _homeVideoSectionService.UpdateHomeVideoSectionAsync(dto);
        return Ok(result);
    }
}
