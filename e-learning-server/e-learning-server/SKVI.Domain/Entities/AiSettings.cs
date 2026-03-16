using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace SKVI.Domain.Entities
{
    [Table("AiSettings")]
    public class AiSettings
    {
        [Key]
        public Guid Id { get; set; } = Guid.NewGuid();

        [Required]
        [StringLength(500)]
        public string ApiKey { get; set; } = string.Empty;

        [Required]
        [StringLength(100)]
        public string ModelName { get; set; } = "gemini-1.5-pro";

        public string SystemPrompt { get; set; } = "Bạn là một gia sư AI thân thiện, giúp đỡ người dùng lên lịch học tập, tạo động lực và đưa ra các lời khuyên chuyên nghiệp.";

        public bool IsEnabled { get; set; } = true;

        public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;
    }
}
