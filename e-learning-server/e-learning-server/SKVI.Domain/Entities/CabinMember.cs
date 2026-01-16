namespace SKVI.Domain.Entities;

public class CabinMember
{
    public Guid Id { get; set; }
    public Guid ParentCabinId { get; set; }
    public Guid ChildCabinId { get; set; }
    public int Level { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
}
