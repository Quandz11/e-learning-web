namespace SKVI.Domain.Entities;

public class CommissionRule
{
    public Guid Id { get; set; }
    public Guid? CabinId { get; set; }
    public Guid? CourseId { get; set; }
    public decimal Rate { get; set; }
}
