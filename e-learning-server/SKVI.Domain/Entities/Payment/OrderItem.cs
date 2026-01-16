using SKVI.Domain.Common;

namespace SKVI.Domain.Entities.Payment;

public class OrderItem : BaseEntity
{
    public Guid OrderId { get; set; }
    public Guid CourseId { get; set; }
    public decimal Price { get; set; }
    
    // Navigation properties
    public Order Order { get; set; } = null!;
    public Course.Course Course { get; set; } = null!;
}
