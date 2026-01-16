using SKVI.Domain.Common;
using SKVI.Domain.Entities.Auth;

namespace SKVI.Domain.Entities.Course;

public class Course : BaseEntity
{
    public string Title { get; set; } = string.Empty;
    public string? Description { get; set; }
    public decimal Price { get; set; }
    public bool IsFree { get; set; } = false;
    public Guid? LecturerId { get; set; }
    public string? ThumbnailUrl { get; set; }
    public bool IsPublished { get; set; } = false;
    
    // Navigation properties
    public User? Lecturer { get; set; }
    public ICollection<CourseSection> Sections { get; set; } = new List<CourseSection>();
    public ICollection<Enrollment.Enrollment> Enrollments { get; set; } = new List<Enrollment.Enrollment>();
    public ICollection<Payment.OrderItem> OrderItems { get; set; } = new List<Payment.OrderItem>();
}
