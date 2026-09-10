namespace SKVI.Domain.Entities;

public class UserReminder
{
    public Guid Id { get; set; }
    public Guid UserId { get; set; }
    public string ClientId { get; set; } = string.Empty;
    public string Type { get; set; } = "custom";
    public string Title { get; set; } = string.Empty;
    public string Message { get; set; } = string.Empty;
    public bool Enabled { get; set; } = true;
    public int StartTimeHour { get; set; } = 8;
    public int StartTimeMinute { get; set; } = 0;
    public int EndTimeHour { get; set; } = 21;
    public int EndTimeMinute { get; set; } = 0;
    public string RepeatDays { get; set; } = "1,2,3,4,5,6,7";
    public bool SoundEnabled { get; set; } = true;
    public bool VibrationEnabled { get; set; } = true;
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;
}
