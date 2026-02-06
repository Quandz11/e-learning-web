using SKVI.Application.DTOs.Menu;

namespace SKVI.Application.Interfaces;

public interface IMenuService
{
    Task<List<MenuItemDto>> GetMenuItemsByLocationAsync(string location);
    Task<List<MenuItemDto>> GetAllMenuItemsAsync();
    Task<MenuItemDto?> GetMenuItemByIdAsync(Guid id);
    Task<MenuItemDto> CreateMenuItemAsync(CreateMenuItemDto dto);
    Task<MenuItemDto> UpdateMenuItemAsync(Guid id, UpdateMenuItemDto dto);
    Task DeleteMenuItemAsync(Guid id);
}
