using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace SKVI.Domain.Entities;

[Table("WellnessSettings")]
public class WellnessSettings
{
    [Key]
    public Guid Id { get; set; } = Guid.NewGuid();

    [Required]
    [MaxLength(128)]
    public string CtaPath { get; set; } = "/pricing";

    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;
}
