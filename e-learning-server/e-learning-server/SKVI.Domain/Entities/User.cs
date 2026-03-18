namespace SKVI.Domain.Entities;

public class User
{
    public Guid Id { get; set; }
    public string Email { get; set; } = string.Empty;
    public string? Phone { get; set; }
    public string PasswordHash { get; set; } = string.Empty;
    public string? FullName { get; set; }
    public string? AvatarUrl { get; set; }
    public string Role { get; set; } = string.Empty; // STUDENT, CARE, CABIN_OWNER, LECTURER, ADMIN
    public string Status { get; set; } = "ACTIVE";
    public bool IsEmailVerified { get; set; } = false;
    public bool IsPhoneVerified { get; set; } = false;
    public string? OtpCode { get; set; }
    public DateTime? OtpExpiration { get; set; }
    public Guid? ReferredByUserId { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;
    public bool IsDeleted { get; set; } = false;

    // 2FA
    public string? TwoFactorSecret { get; set; }
    public bool IsTwoFactorEnabled { get; set; } = false;

    // Navigation properties
    public ICollection<RefreshToken> RefreshTokens { get; set; } = new List<RefreshToken>();
    public ICollection<Enrollment> Enrollments { get; set; } = new List<Enrollment>();
    public ICollection<Order> Orders { get; set; } = new List<Order>();
    public ICollection<UserReferral> ReferralProfiles { get; set; } = new List<UserReferral>();
    public ICollection<ReferralTransaction> SentReferrals { get; set; } = new List<ReferralTransaction>();
    public ICollection<ReferralTransaction> ReceivedReferrals { get; set; } = new List<ReferralTransaction>();
}
