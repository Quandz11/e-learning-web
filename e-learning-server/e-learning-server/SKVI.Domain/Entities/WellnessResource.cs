using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace SKVI.Domain.Entities;

[Table("WellnessResources")]
public class WellnessResource
{
    [Key]
    public Guid Id { get; set; } = Guid.NewGuid();

    [Required]
    [MaxLength(32)]
    public string ResourceType { get; set; } = "MEDITATION";

    [Required]
    [MaxLength(256)]
    public string Title { get; set; } = string.Empty;

    [Required]
    [MaxLength(1024)]
    public string Url { get; set; } = string.Empty;

    [MaxLength(1024)]
    public string Description { get; set; } = string.Empty;

    public bool IsActive { get; set; } = true;

    public int RotationWeight { get; set; } = 1;

    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;
}

