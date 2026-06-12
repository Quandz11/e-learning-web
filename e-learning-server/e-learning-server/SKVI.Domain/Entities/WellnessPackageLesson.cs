using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace SKVI.Domain.Entities;

[Table("WellnessPackageLessons")]
public class WellnessPackageLesson
{
    [Key]
    public Guid Id { get; set; } = Guid.NewGuid();

    public Guid WellnessPackageId { get; set; }

    public Guid LessonId { get; set; }

    public int DayIndex { get; set; }

    public int SortOrder { get; set; }

    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    [ForeignKey(nameof(WellnessPackageId))]
    public virtual WellnessPackage WellnessPackage { get; set; } = null!;

    [ForeignKey(nameof(LessonId))]
    public virtual Lesson Lesson { get; set; } = null!;
}
