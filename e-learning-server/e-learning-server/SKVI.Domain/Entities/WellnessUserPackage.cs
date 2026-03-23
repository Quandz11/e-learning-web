using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace SKVI.Domain.Entities;

[Table("WellnessUserPackages")]
public class WellnessUserPackage
{
    [Key]
    public Guid Id { get; set; } = Guid.NewGuid();

    public Guid UserId { get; set; }

    public Guid PackageId { get; set; }

    [Required]
    [MaxLength(16)]
    public string Status { get; set; } = "ACTIVE";

    [Required]
    [MaxLength(16)]
    public string Source { get; set; } = "MANUAL";

    public Guid? GrantedByUserId { get; set; }

    [MaxLength(1024)]
    public string Notes { get; set; } = string.Empty;

    public DateTime GrantedAt { get; set; } = DateTime.UtcNow;

    public DateTime StartsAt { get; set; } = DateTime.UtcNow;

    public DateTime? ExpiresAt { get; set; }

    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;

    [ForeignKey(nameof(UserId))]
    public virtual User User { get; set; } = null!;

    [ForeignKey(nameof(PackageId))]
    public virtual WellnessPackage Package { get; set; } = null!;

    [ForeignKey(nameof(GrantedByUserId))]
    public virtual User? GrantedByUser { get; set; }
}

