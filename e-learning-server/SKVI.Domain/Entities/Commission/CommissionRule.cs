using SKVI.Domain.Common;

namespace SKVI.Domain.Entities.Commission;

public class CommissionRule : BaseEntity
{
    public Guid? CabinId { get; set; }
    public Guid? CourseId { get; set; }
    public decimal Rate { get; set; }
    
    // Navigation properties
    public Cabin.Cabin? Cabin { get; set; }
    public Course.Course? Course { get; set; }
}
