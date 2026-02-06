using Microsoft.EntityFrameworkCore;
using SKVI.Application.DTOs.Menu;
using SKVI.Application.Interfaces;
using SKVI.Domain.Entities;
using SKVI.Infrastructure;

namespace SKVI.Application.Services;

public class MenuService : IMenuService
{
    private readonly ApplicationDbContext _context;

    public MenuService(ApplicationDbContext context)
    {
        _context = context;
    }

    public async Task<List<MenuItemDto>> GetMenuItemsByLocationAsync(string location)
    {
        var menuItems = await _context.MenuItems
            .Where(m => m.MenuLocation == location && m.IsActive && m.ParentId == null)
            .OrderBy(m => m.DisplayOrder)
            .ToListAsync();

        return await BuildMenuHierarchy(menuItems);
    }

    public async Task<List<MenuItemDto>> GetAllMenuItemsAsync()
    {
        var menuItems = await _context.MenuItems
            .Where(m => m.ParentId == null)
            .OrderBy(m => m.MenuLocation)
            .ThenBy(m => m.DisplayOrder)
            .ToListAsync();

        return await BuildMenuHierarchy(menuItems);
    }

    public async Task<MenuItemDto?> GetMenuItemByIdAsync(Guid id)
    {
        var menuItem = await _context.MenuItems.FindAsync(id);
        if (menuItem == null) return null;

        return MapToDto(menuItem);
    }

    public async Task<MenuItemDto> CreateMenuItemAsync(CreateMenuItemDto dto)
    {
        var menuItem = new MenuItem
        {
            Id = Guid.NewGuid(),
            Title = dto.Title,
            Url = dto.Url,
            ParentId = dto.ParentId,
            DisplayOrder = dto.DisplayOrder,
            IsActive = true,
            OpenInNewTab = dto.OpenInNewTab,
            MenuLocation = dto.MenuLocation,
            Icon = dto.Icon,
            CreatedAt = DateTime.UtcNow
        };

        _context.MenuItems.Add(menuItem);
        await _context.SaveChangesAsync();

        return (await GetMenuItemByIdAsync(menuItem.Id))!;
    }

    public async Task<MenuItemDto> UpdateMenuItemAsync(Guid id, UpdateMenuItemDto dto)
    {
        var menuItem = await _context.MenuItems.FindAsync(id);
        if (menuItem == null)
        {
            throw new Exception("Menu item not found");
        }

        menuItem.Title = dto.Title;
        menuItem.Url = dto.Url;
        menuItem.ParentId = dto.ParentId;
        menuItem.DisplayOrder = dto.DisplayOrder;
        menuItem.IsActive = dto.IsActive;
        menuItem.OpenInNewTab = dto.OpenInNewTab;
        menuItem.MenuLocation = dto.MenuLocation;
        menuItem.Icon = dto.Icon;

        await _context.SaveChangesAsync();

        return (await GetMenuItemByIdAsync(menuItem.Id))!;
    }

    public async Task DeleteMenuItemAsync(Guid id)
    {
        var menuItem = await _context.MenuItems.FindAsync(id);
        if (menuItem == null)
        {
            throw new Exception("Menu item not found");
        }

        _context.MenuItems.Remove(menuItem);
        await _context.SaveChangesAsync();
    }

    private async Task<List<MenuItemDto>> BuildMenuHierarchy(List<MenuItem> parentItems)
    {
        var result = new List<MenuItemDto>();

        foreach (var item in parentItems)
        {
            var dto = MapToDto(item);
            
            // Load children
            var children = await _context.MenuItems
                .Where(m => m.ParentId == item.Id && m.IsActive)
                .OrderBy(m => m.DisplayOrder)
                .ToListAsync();

            if (children.Any())
            {
                dto.Children = await BuildMenuHierarchy(children);
            }

            result.Add(dto);
        }

        return result;
    }

    private MenuItemDto MapToDto(MenuItem item)
    {
        return new MenuItemDto
        {
            Id = item.Id,
            Title = item.Title,
            Url = item.Url,
            ParentId = item.ParentId,
            DisplayOrder = item.DisplayOrder,
            IsActive = item.IsActive,
            OpenInNewTab = item.OpenInNewTab,
            MenuLocation = item.MenuLocation,
            Icon = item.Icon,
            Children = new List<MenuItemDto>()
        };
    }
}
