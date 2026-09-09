using Microsoft.EntityFrameworkCore;
using SKVI.Application.DTOs.Courses;
using SKVI.Application.DTOs.Lessons;
using SKVI.Application.Interfaces;
using SKVI.Domain.Entities;
using SKVI.Infrastructure;
using System.Text.Json;

namespace SKVI.Application.Services;

public class CourseService : ICourseService
{
    private readonly ApplicationDbContext _dbContext;
    private readonly IBunnyStreamService _bunnyStreamService;

    public CourseService(ApplicationDbContext dbContext, IBunnyStreamService bunnyStreamService)
    {
        _dbContext = dbContext;
        _bunnyStreamService = bunnyStreamService;
    }

    public async Task<IReadOnlyList<CourseResponse>> GetAllAsync(bool? isPublished, CancellationToken cancellationToken = default)
    {
        var query = _dbContext.Courses
            .Include(c => c.Lecturer)
            .Include(c => c.CourseLessons)
                .ThenInclude(cl => cl.Lesson)
                    .ThenInclude(l => l.LessonParts)
                        .ThenInclude(p => p.Video)
            .Include(c => c.CourseLessons)
                .ThenInclude(cl => cl.Lesson)
                    .ThenInclude(l => l.LessonParts)
                        .ThenInclude(p => p.Document)
            .AsNoTracking()
            .AsQueryable();

        if (isPublished.HasValue)
        {
            query = query.Where(c => c.IsPublished == isPublished.Value);
        }

        var courses = await query
            .OrderByDescending(c => c.CreatedAt)
            .ToListAsync(cancellationToken);

        return courses.Select(MapToResponse).ToList();
    }

    public async Task<CourseResponse> GetByIdAsync(Guid id, CancellationToken cancellationToken = default)
    {
        var course = await _dbContext.Courses
            .Include(c => c.Lecturer)
            .Include(c => c.CourseLessons)
                .ThenInclude(cl => cl.Lesson)
                    .ThenInclude(l => l.LessonParts)
                        .ThenInclude(p => p.Video)
            .Include(c => c.CourseLessons)
                .ThenInclude(cl => cl.Lesson)
                    .ThenInclude(l => l.LessonParts)
                        .ThenInclude(p => p.Document)
            .AsNoTracking()
            .FirstOrDefaultAsync(c => c.Id == id, cancellationToken);

        if (course == null)
        {
            throw new KeyNotFoundException("Course not found");
        }

        return MapToResponse(course);
    }

    public async Task<IReadOnlyList<StudentDto>> GetEnrolledStudentsAsync(Guid courseId, CancellationToken cancellationToken = default)
    {
        var enrollments = await _dbContext.Enrollments
            .Include(e => e.User)
            .Where(e => e.CourseId == courseId)
            .OrderByDescending(e => e.EnrolledAt)
            .ToListAsync(cancellationToken);

        return enrollments.Select(e => new StudentDto
        {
            Id = e.User.Id,
            FullName = e.User.FullName ?? "Unknown User",
            Email = e.User.Email,
            AvatarUrl = e.User.AvatarUrl,
            EnrolledAt = e.EnrolledAt
        }).ToList();
    }

    public async Task<CourseResponse> CreateAsync(CreateCourseRequest request, CancellationToken cancellationToken = default)
    {
        var course = new Course
        {
            Id = Guid.NewGuid(),
            Title = request.Title,
            Description = request.Description,
            Price = request.Price,
            IsFree = request.IsFree,
            LecturerId = request.LecturerId,
            ThumbnailUrl = request.ThumbnailUrl,
            IsPublished = request.IsPublished,
            DefaultAccessDurationDays = request.DefaultAccessDurationDays,
            LearningOutcomes = request.LearningOutcomes != null ? JsonSerializer.Serialize(request.LearningOutcomes) : null,
            CreatedAt = DateTime.UtcNow
        };

        // Link existing lessons
        if (request.LessonIds != null && request.LessonIds.Any())
        {
            for (int i = 0; i < request.LessonIds.Count; i++)
            {
                course.CourseLessons.Add(new CourseLesson
                {
                    CourseId = course.Id,
                    LessonId = request.LessonIds[i],
                    OrderIndex = i
                });
            }
        }

        _dbContext.Courses.Add(course);
        await _dbContext.SaveChangesAsync(cancellationToken);

        return await GetByIdAsync(course.Id, cancellationToken);
    }

    public async Task<CourseResponse> UpdateAsync(Guid id, UpdateCourseRequest request, CancellationToken cancellationToken = default)
    {
        var course = await _dbContext.Courses
            .Include(c => c.CourseLessons)
            .FirstOrDefaultAsync(c => c.Id == id, cancellationToken);

        if (course == null)
        {
            throw new KeyNotFoundException("Course not found");
        }

        course.Title = request.Title;
        course.Description = request.Description;
        course.Price = request.Price;
        course.IsFree = request.IsFree;
        course.LecturerId = request.LecturerId;
        course.ThumbnailUrl = request.ThumbnailUrl;
        course.IsPublished = request.IsPublished;
        course.DefaultAccessDurationDays = request.DefaultAccessDurationDays;
        course.LearningOutcomes = request.LearningOutcomes != null ? JsonSerializer.Serialize(request.LearningOutcomes) : null;
        
        // Update Course Lessons (Links)
        // Clear existing links
        _dbContext.CourseLessons.RemoveRange(course.CourseLessons);
        
        // Add new links
        if (request.LessonIds != null && request.LessonIds.Any())
        {
            for (int i = 0; i < request.LessonIds.Count; i++)
            {
                _dbContext.CourseLessons.Add(new CourseLesson
                {
                    CourseId = course.Id,
                    LessonId = request.LessonIds[i],
                    OrderIndex = i
                });
            }
        }

        await _dbContext.SaveChangesAsync(cancellationToken);

        return await GetByIdAsync(course.Id, cancellationToken);
    }

    public async Task DeleteAsync(Guid id, CancellationToken cancellationToken = default)
    {
        var course = await _dbContext.Courses
            .Include(c => c.CourseLessons)
            .FirstOrDefaultAsync(c => c.Id == id, cancellationToken);

        if (course == null)
        {
            throw new KeyNotFoundException("Course not found");
        }

        // Clear optional study-plan references before deleting the course because SQL Server
        // cannot combine these nullable FKs with the existing cascade graph.
        var plansUsingCourse = await _dbContext.UserStudyPlans
            .Where(plan => plan.PrimaryCourseId == id)
            .ToListAsync(cancellationToken);

        foreach (var plan in plansUsingCourse)
        {
            plan.PrimaryCourseId = null;
        }

        var tasksUsingCourse = await _dbContext.DailyStudyTasks
            .Where(task => task.RelatedCourseId == id)
            .ToListAsync(cancellationToken);

        foreach (var task in tasksUsingCourse)
        {
            task.RelatedCourseId = null;
        }

        if (plansUsingCourse.Count > 0 || tasksUsingCourse.Count > 0)
        {
            await _dbContext.SaveChangesAsync(cancellationToken);
        }

        // Only delete the course and links, NOT the lessons themselves (reusable)
        _dbContext.Courses.Remove(course);
        await _dbContext.SaveChangesAsync(cancellationToken);
    }

    private CourseResponse MapToResponse(Course course)
    {
        var response = new CourseResponse
        {
            Id = course.Id,
            Title = course.Title,
            Description = course.Description,
            Price = course.Price,
            IsFree = course.IsFree,
            LecturerId = course.LecturerId,
            Lecturer = course.Lecturer != null ? new LecturerInfo
            {
                Id = course.Lecturer.Id,
                FullName = course.Lecturer.FullName ?? string.Empty,
                Email = course.Lecturer.Email,
                AvatarUrl = course.Lecturer.AvatarUrl
            } : null,
            ThumbnailUrl = course.ThumbnailUrl,
            IsPublished = course.IsPublished,
            DefaultAccessDurationDays = course.DefaultAccessDurationDays,
            LearningOutcomes = !string.IsNullOrEmpty(course.LearningOutcomes) 
                ? JsonSerializer.Deserialize<List<string>>(course.LearningOutcomes) ?? new List<string>() 
                : new List<string>(),
            CreatedAt = course.CreatedAt,
            Lessons = new List<LessonDto>()
        };

        foreach (var cl in course.CourseLessons.OrderBy(x => x.OrderIndex))
        {
            if (cl.Lesson == null) continue;

            var lessonDto = new LessonDto
            {
                Id = cl.Lesson.Id,
                Title = cl.Lesson.Title,
                Description = cl.Lesson.Description,
                ThumbnailUrl = cl.Lesson.ThumbnailUrl,
                CreatedAt = cl.Lesson.CreatedAt,
                UpdatedAt = cl.Lesson.UpdatedAt,
                Parts = new List<LessonPartDto>()
            };

            if (cl.Lesson.LessonParts != null)
            {
                foreach (var part in cl.Lesson.LessonParts.OrderBy(p => p.OrderIndex))
                {
                    var playbackUrl = part.Video != null && !string.IsNullOrWhiteSpace(part.Video.BunnyVideoId)
                         ? _bunnyStreamService.GetPlaybackUrl(part.Video.BunnyVideoId) 
                         : null;
                    var embedUrl = part.Video != null && !string.IsNullOrWhiteSpace(part.Video.BunnyVideoId)
                         ? _bunnyStreamService.GetEmbedUrl(part.Video.BunnyVideoId)
                         : null;

                    lessonDto.Parts.Add(new LessonPartDto
                    {
                        Id = part.Id,
                        Title = part.Title,
                        Type = part.Type,
                        OrderIndex = part.OrderIndex,
                        IsPreview = part.IsPreview,
                        VideoId = part.VideoId,
                        VideoDuration = part.Video?.Duration ?? 0,
                        PlaybackUrl = playbackUrl,
                        EmbedUrl = embedUrl,
                        DocumentId = part.DocumentId,
                        DocumentUrl = part.Document?.BunnyStoragePath,
                        Content = part.Content
                    });
                }
            }
            response.Lessons.Add(lessonDto);
        }

        return response;
    }
}
