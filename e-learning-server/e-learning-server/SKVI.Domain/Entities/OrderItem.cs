namespace SKVI.Domain.Entities;

public class OrderItem
{
    public Guid Id { get; set; }
    public Guid OrderId { get; set; }
    public Guid CourseId { get; set; }
    public decimal Price { get; set; }

    // Navigation properties
    public Order Order { get; set; } = null!;
    public Course Course { get; set; } = null!;
}
