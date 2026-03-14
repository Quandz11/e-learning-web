using System.ComponentModel.DataAnnotations;

namespace SKVI.Domain.Entities;

public class Enrollment
{
    [Key]
    public Guid Id { get; set; }

    [Required]
    public Guid UserId { get; set; }

    [Required]
    public Guid CourseId { get; set; }

    public Guid? OrderId { get; set; }

    [Required]
    public DateTime EnrolledAt { get; set; }

    public DateTime? CompletedAt { get; set; }

    [Range(0, 100)]
    public int ProgressPercentage { get; set; } = 0;

    public DateTime LastAccessedAt { get; set; }

    /// <summary>ACTIVE | INACTIVE</summary>
    [Required]
    public string Status { get; set; } = "ACTIVE";

    /// <summary>FREE | PAYMENT | ADMIN</summary>
    [Required]
    public string SourceType { get; set; } = "FREE";

    // Navigation properties
    public User User { get; set; } = null!;
    public Course Course { get; set; } = null!;
    public Order? Order { get; set; }
    public ICollection<LessonProgress> LessonProgress { get; set; } = new List<LessonProgress>();
}
