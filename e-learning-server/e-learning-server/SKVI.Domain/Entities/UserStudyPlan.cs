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

        public string Motivation { get; set; } = string.Empty;

        public int TimeBudgetMinutesPerDay { get; set; } = 45;

        public string PreferredStudyTime { get; set; } = string.Empty;

        public string Constraints { get; set; } = string.Empty;

        public Guid? PrimaryCourseId { get; set; }

        public string Status { get; set; } = "Active"; // Active, Completed

        public int CurrentStreakDays { get; set; }

        public DateTime? LastCheckInDate { get; set; }

        public string LatestGuidanceMessage { get; set; } = string.Empty;

        public int PlanVersion { get; set; } = 1;

        public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

        [ForeignKey("UserId")]
        public virtual User User { get; set; } = null!;

        [ForeignKey(nameof(PrimaryCourseId))]
        public virtual Course? PrimaryCourse { get; set; }

        public virtual ICollection<DailyStudyTask> DailyTasks { get; set; } = new List<DailyStudyTask>();
        public virtual ICollection<DailyStudyCheckIn> DailyCheckIns { get; set; } = new List<DailyStudyCheckIn>();
        public virtual ICollection<StudentSupportAlert> SupportAlerts { get; set; } = new List<StudentSupportAlert>();
    }
}
