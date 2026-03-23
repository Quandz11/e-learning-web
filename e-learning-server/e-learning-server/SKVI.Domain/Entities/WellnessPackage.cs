using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace SKVI.Domain.Entities;

[Table("WellnessPackages")]
public class WellnessPackage
{
    [Key]
    public Guid Id { get; set; } = Guid.NewGuid();

    [Required]
    [MaxLength(32)]
    public string Code { get; set; } = string.Empty;

    [Required]
    [MaxLength(128)]
    public string Name { get; set; } = string.Empty;

    [MaxLength(512)]
    public string Description { get; set; } = string.Empty;

    [Column(TypeName = "decimal(18,0)")]
    public decimal PriceVnd { get; set; }

    public int DurationDays { get; set; } = 30;

    public bool IsActive { get; set; } = true;

    public bool IsFeatured { get; set; }

    public int SortOrder { get; set; }

    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;

    public virtual ICollection<WellnessUserPackage> UserPackages { get; set; } = new List<WellnessUserPackage>();
}

