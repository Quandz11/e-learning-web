namespace SKVI.Domain.Entities;

public class MenuItem
{
    public Guid Id { get; set; }
    public string Title { get; set; } = string.Empty;
    public string Url { get; set; } = string.Empty;
    public Guid? ParentId { get; set; }
    public int DisplayOrder { get; set; } = 0;
    public bool IsActive { get; set; } = true;
    public bool OpenInNewTab { get; set; } = false;
    public string MenuLocation { get; set; } = "Header"; // Header, Footer, Sidebar
    public string? Icon { get; set; } // Material icon name
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    // Navigation properties for nested menus
    public MenuItem? Parent { get; set; }
    public ICollection<MenuItem> Children { get; set; } = new List<MenuItem>();
}
