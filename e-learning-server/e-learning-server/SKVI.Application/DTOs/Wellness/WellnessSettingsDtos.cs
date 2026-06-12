using System.ComponentModel.DataAnnotations;

namespace SKVI.Application.DTOs.Wellness;

public class WellnessAdminSettingsDto
{
    public Guid Id { get; set; }
    public List<WellnessPackageAdminDto> Packages { get; set; } = [];
    public string CtaPath { get; set; } = "/pricing";
    public bool IsPersonalizedRoadmapPaid { get; set; }
    public DateTime UpdatedAt { get; set; }
}

public class UpdateWellnessAdminSettingsRequest
{
    [Required]
    public List<WellnessPackageUpsertRequest> Packages { get; set; } = [];

    [MaxLength(128)]
    public string CtaPath { get; set; } = "/pricing";

    public bool IsPersonalizedRoadmapPaid { get; set; } = true;
}

public class WellnessPackageAdminDto
{
    public Guid Id { get; set; }
    public string Code { get; set; } = string.Empty;
    public string Name { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
    public decimal PriceVnd { get; set; }
    public int DurationDays { get; set; }
    public bool IsActive { get; set; }
    public bool IsFeatured { get; set; }
    public int SortOrder { get; set; }
    public DateTime UpdatedAt { get; set; }
    public List<WellnessPackageLessonDto> Lessons { get; set; } = [];
}

public class WellnessPackageLessonDto
{
    public Guid Id { get; set; }
    public Guid LessonId { get; set; }
    public string LessonTitle { get; set; } = string.Empty;
    public int DayIndex { get; set; }
    public int SortOrder { get; set; }
}

public class WellnessPackageUpsertRequest
{
    [Required]
    [MaxLength(32)]
    public string Code { get; set; } = string.Empty;

    [Required]
    [MaxLength(128)]
    public string Name { get; set; } = string.Empty;

    [MaxLength(512)]
    public string Description { get; set; } = string.Empty;

    [Range(0, 999999999)]
    public decimal PriceVnd { get; set; }

    [Range(1, 3650)]
    public int DurationDays { get; set; } = 30;

    public bool IsActive { get; set; } = true;

    public bool IsFeatured { get; set; }

    [Range(-1000, 1000)]
    public int SortOrder { get; set; }

    public List<WellnessPackageLessonUpsertRequest> Lessons { get; set; } = [];
}

public class WellnessPackageLessonUpsertRequest
{
    [Required]
    public Guid LessonId { get; set; }

    [Range(1, 365)]
    public int DayIndex { get; set; }

    public int SortOrder { get; set; }
}

public class WellnessUserPackageDto
{
    public Guid Id { get; set; }
    public Guid UserId { get; set; }
    public Guid PackageId { get; set; }
    public string PackageCode { get; set; } = string.Empty;
    public string PackageName { get; set; } = string.Empty;
    public decimal PriceVnd { get; set; }
    public int DurationDays { get; set; }
    public string Status { get; set; } = string.Empty;
    public string Source { get; set; } = string.Empty;
    public Guid? GrantedByUserId { get; set; }
    public string Notes { get; set; } = string.Empty;
    public DateTime GrantedAt { get; set; }
    public DateTime StartsAt { get; set; }
    public DateTime? ExpiresAt { get; set; }
}

public class GrantWellnessUserPackageRequest
{
    [Required]
    [MaxLength(32)]
    public string PackageCode { get; set; } = string.Empty;

    public DateTime? StartsAt { get; set; }

    public DateTime? ExpiresAt { get; set; }

    [MaxLength(16)]
    public string Source { get; set; } = "MANUAL";

    [MaxLength(1024)]
    public string Notes { get; set; } = string.Empty;
}

public class UpdateWellnessUserPackageRequest
{
    [Required]
    [MaxLength(16)]
    public string Status { get; set; } = "ACTIVE";

    public DateTime? ExpiresAt { get; set; }

    [MaxLength(1024)]
    public string Notes { get; set; } = string.Empty;
}
