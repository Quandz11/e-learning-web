namespace SKVI.Application.DTOs.Menu;

public class MenuItemDto
{
    public Guid Id { get; set; }
    public string Title { get; set; } = string.Empty;
    public string Url { get; set; } = string.Empty;
    public Guid? ParentId { get; set; }
    public int DisplayOrder { get; set; }
    public bool IsActive { get; set; }
    public bool OpenInNewTab { get; set; }
    public string MenuLocation { get; set; } = "Header";
    public string? Icon { get; set; }
    public List<MenuItemDto> Children { get; set; } = new();
}

public class CreateMenuItemDto
{
    public string Title { get; set; } = string.Empty;
    public string Url { get; set; } = string.Empty;
    public Guid? ParentId { get; set; }
    public int DisplayOrder { get; set; }
    public bool OpenInNewTab { get; set; }
    public string MenuLocation { get; set; } = "Header";
    public string? Icon { get; set; }
}

public class UpdateMenuItemDto
{
    public string Title { get; set; } = string.Empty;
    public string Url { get; set; } = string.Empty;
    public Guid? ParentId { get; set; }
    public int DisplayOrder { get; set; }
    public bool IsActive { get; set; }
    public bool OpenInNewTab { get; set; }
    public string MenuLocation { get; set; } = "Header";
    public string? Icon { get; set; }
}
