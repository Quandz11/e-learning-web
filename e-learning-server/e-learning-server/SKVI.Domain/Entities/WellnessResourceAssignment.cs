using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace SKVI.Domain.Entities;

[Table("WellnessResourceAssignments")]
public class WellnessResourceAssignment
{
    [Key]
    public Guid Id { get; set; } = Guid.NewGuid();

    public Guid PlanId { get; set; }

    public DateTime AssignmentDate { get; set; }

    public Guid MeditationResourceId { get; set; }

    public Guid BreathingResourceId { get; set; }

    public Guid WorkoutResourceId { get; set; }

    [MaxLength(24)]
    public string SelectionStrategy { get; set; } = "ROTATION";

    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    [ForeignKey(nameof(PlanId))]
    public virtual WellnessPlan Plan { get; set; } = null!;

    [ForeignKey(nameof(MeditationResourceId))]
    public virtual WellnessResource MeditationResource { get; set; } = null!;

    [ForeignKey(nameof(BreathingResourceId))]
    public virtual WellnessResource BreathingResource { get; set; } = null!;

    [ForeignKey(nameof(WorkoutResourceId))]
    public virtual WellnessResource WorkoutResource { get; set; } = null!;
}

