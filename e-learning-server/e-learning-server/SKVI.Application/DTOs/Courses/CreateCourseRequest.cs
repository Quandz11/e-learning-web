using System.ComponentModel.DataAnnotations;

namespace SKVI.Application.DTOs.Courses;

public class CreateCourseRequest
{
    [Required]
    public string Title { get; set; } = string.Empty;

    public string? Description { get; set; }

    [Range(0, double.MaxValue)]
    public decimal Price { get; set; }

    public bool IsFree { get; set; }

    [Required]
    public Guid LecturerId { get; set; }

    public string? ThumbnailUrl { get; set; }

    public bool IsPublished { get; set; }

    [MinLength(0)]
    public List<CreateCourseSectionDto> Sections { get; set; } = new();
}

public class CreateCourseSectionDto
{
    [Required]
    public string Title { get; set; } = string.Empty;

    public int OrderIndex { get; set; }

    public List<CreateCourseLessonDto> Lessons { get; set; } = new();
}

public class CreateCourseLessonDto
{
    [Required]
    public string Title { get; set; } = string.Empty;

    [Range(0, int.MaxValue)]
    public int Duration { get; set; }

    [Required]
    public Guid VideoId { get; set; }

    public int OrderIndex { get; set; }

    public bool IsPreview { get; set; }
}
