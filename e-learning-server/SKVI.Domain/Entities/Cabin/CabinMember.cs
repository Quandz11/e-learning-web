using SKVI.Domain.Common;

namespace SKVI.Domain.Entities.Cabin;

public class CabinMember : BaseEntity
{
    public Guid? ParentCabinId { get; set; }
    public Guid ChildCabinId { get; set; }
    public int Level { get; set; }
    
    // Navigation properties
    public Cabin? ParentCabin { get; set; }
    public Cabin ChildCabin { get; set; } = null!;
}
