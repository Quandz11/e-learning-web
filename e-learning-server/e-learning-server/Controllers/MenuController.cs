using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SKVI.Application.DTOs.Menu;
using SKVI.Application.Interfaces;

namespace e_learning_server.Controllers;

[ApiController]
[Route("api/[controller]")]
public class MenuController : ControllerBase
{
    private readonly IMenuService _menuService;

    public MenuController(IMenuService menuService)
    {
        _menuService = menuService;
    }

    // Public endpoint
    [HttpGet("{location}")]
    public async Task<ActionResult<List<MenuItemDto>>> GetMenuByLocation(string location)
    {
        var menuItems = await _menuService.GetMenuItemsByLocationAsync(location);
        return Ok(menuItems);
    }

    // Admin endpoints
    [HttpGet("admin")]
    [Authorize(Roles = "ADMIN")]
    public async Task<ActionResult<List<MenuItemDto>>> GetAllMenuItems()
    {
        var menuItems = await _menuService.GetAllMenuItemsAsync();
        return Ok(menuItems);
    }

    [HttpGet("admin/{id}")]
    [Authorize(Roles = "ADMIN")]
    public async Task<ActionResult<MenuItemDto>> GetMenuItemById(Guid id)
    {
        var menuItem = await _menuService.GetMenuItemByIdAsync(id);
        if (menuItem == null)
        {
            return NotFound();
        }

        return Ok(menuItem);
    }

    [HttpPost]
    [Authorize(Roles = "ADMIN")]
    public async Task<ActionResult<MenuItemDto>> CreateMenuItem([FromBody] CreateMenuItemDto dto)
    {
        var menuItem = await _menuService.CreateMenuItemAsync(dto);
        return CreatedAtAction(nameof(GetMenuItemById), new { id = menuItem.Id }, menuItem);
    }

    [HttpPut("{id}")]
    [Authorize(Roles = "ADMIN")]
    public async Task<ActionResult<MenuItemDto>> UpdateMenuItem(Guid id, [FromBody] UpdateMenuItemDto dto)
    {
        try
        {
            var menuItem = await _menuService.UpdateMenuItemAsync(id, dto);
            return Ok(menuItem);
        }
        catch (Exception ex)
        {
            return NotFound(ex.Message);
        }
    }

    [HttpDelete("{id}")]
    [Authorize(Roles = "ADMIN")]
    public async Task<ActionResult> DeleteMenuItem(Guid id)
    {
        try
        {
            await _menuService.DeleteMenuItemAsync(id);
            return NoContent();
        }
        catch (Exception ex)
        {
            return NotFound(ex.Message);
        }
    }
}
