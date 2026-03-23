using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace SKVI.Domain.Entities;

[Table("WellnessMealSuggestions")]
public class WellnessMealSuggestion
{
    [Key]
    public Guid Id { get; set; } = Guid.NewGuid();

    public Guid PlanId { get; set; }

    public string IngredientsEncrypted { get; set; } = string.Empty;

    public int Servings { get; set; } = 1;

    public string SuggestedMenuEncrypted { get; set; } = string.Empty;

    public string NutritionNotesEncrypted { get; set; } = string.Empty;

    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    [ForeignKey(nameof(PlanId))]
    public virtual WellnessPlan Plan { get; set; } = null!;
}

