using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace SKVI.Domain.Entities
{
    [Table("UserStudyPlans")]
    public class UserStudyPlan
    {
        [Key]
        public Guid Id { get; set; } = Guid.NewGuid();

        public Guid UserId { get; set; }

        [Required]
        public string Goal { get; set; } = string.Empty;

        [Required]
        public string CurrentKnowledgeLevel { get; set; } = string.Empty;

        public string Status { get; set; } = "Active"; // Active, Completed

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

        [ForeignKey("UserId")]
        public virtual User User { get; set; }

        public virtual ICollection<DailyStudyTask> DailyTasks { get; set; } = new List<DailyStudyTask>();
    }
}
