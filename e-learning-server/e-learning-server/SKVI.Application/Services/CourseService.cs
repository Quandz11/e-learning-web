using Microsoft.EntityFrameworkCore;
using System.Linq;
using SKVI.Application.DTOs.Courses;
using SKVI.Application.Interfaces;
using SKVI.Domain.Entities;
using SKVI.Infrastructure;

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
            .Include(c => c.CourseSections)
                .ThenInclude(s => s.CourseLessons)
                    .ThenInclude(l => l.Video)
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
            .Include(c => c.CourseSections)
                .ThenInclude(s => s.CourseLessons)
                    .ThenInclude(l => l.Video)
            .FirstOrDefaultAsync(c => c.Id == id, cancellationToken);

        if (course == null)
        {
            throw new KeyNotFoundException("Course not found");
        }

        return MapToResponse(course);
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
            CreatedAt = DateTime.UtcNow
        };

        foreach (var sectionDto in request.Sections.OrderBy(s => s.OrderIndex))
        {
            var section = new CourseSection
            {
                Id = Guid.NewGuid(),
                CourseId = course.Id,
                Title = sectionDto.Title,
                OrderIndex = sectionDto.OrderIndex
            };

            foreach (var lessonDto in sectionDto.Lessons.OrderBy(l => l.OrderIndex))
            {
                var lesson = new CourseLesson
                {
                    Id = Guid.NewGuid(),
                    SectionId = section.Id,
                    Title = lessonDto.Title,
                    Duration = lessonDto.Duration,
                    VideoId = lessonDto.VideoId,
                    OrderIndex = lessonDto.OrderIndex,
                    IsPreview = lessonDto.IsPreview
                };

                section.CourseLessons.Add(lesson);
            }

            course.CourseSections.Add(section);
        }

        _dbContext.Courses.Add(course);
        await _dbContext.SaveChangesAsync(cancellationToken);

        return await GetByIdAsync(course.Id, cancellationToken);
    }

    public async Task<CourseResponse> UpdateAsync(Guid id, UpdateCourseRequest request, CancellationToken cancellationToken = default)
    {
        var course = await _dbContext.Courses
            .Include(c => c.CourseSections)
                .ThenInclude(s => s.CourseLessons)
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
        course.CreatedAt = course.CreatedAt == default ? DateTime.UtcNow : course.CreatedAt;

        // Remove existing sections/lessons then re-add to simplify ordering consistency
        var existingSections = course.CourseSections.ToList();
        var existingLessons = existingSections.SelectMany(s => s.CourseLessons).ToList();

        _dbContext.CourseLessons.RemoveRange(existingLessons);
        _dbContext.CourseSections.RemoveRange(existingSections);

        foreach (var sectionDto in request.Sections.OrderBy(s => s.OrderIndex))
        {
            var section = new CourseSection
            {
                Id = Guid.NewGuid(),
                CourseId = course.Id,
                Title = sectionDto.Title,
                OrderIndex = sectionDto.OrderIndex
            };

            foreach (var lessonDto in sectionDto.Lessons.OrderBy(l => l.OrderIndex))
            {
                var lesson = new CourseLesson
                {
                    Id = Guid.NewGuid(),
                    SectionId = section.Id,
                    Title = lessonDto.Title,
                    Duration = lessonDto.Duration,
                    VideoId = lessonDto.VideoId,
                    OrderIndex = lessonDto.OrderIndex,
                    IsPreview = lessonDto.IsPreview
                };

                section.CourseLessons.Add(lesson);
            }

            course.CourseSections.Add(section);
        }

        await _dbContext.SaveChangesAsync(cancellationToken);

        return await GetByIdAsync(course.Id, cancellationToken);
    }

    public async Task DeleteAsync(Guid id, CancellationToken cancellationToken = default)
    {
        var course = await _dbContext.Courses
            .Include(c => c.CourseSections)
                .ThenInclude(s => s.CourseLessons)
            .FirstOrDefaultAsync(c => c.Id == id, cancellationToken);

        if (course == null)
        {
            throw new KeyNotFoundException("Course not found");
        }

        var sections = course.CourseSections.ToList();
        var lessons = sections.SelectMany(s => s.CourseLessons).ToList();

        _dbContext.CourseLessons.RemoveRange(lessons);
        _dbContext.CourseSections.RemoveRange(sections);
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
            ThumbnailUrl = course.ThumbnailUrl,
            IsPublished = course.IsPublished,
            CreatedAt = course.CreatedAt,
            Sections = new List<CourseSectionResponse>()
        };

        foreach (var section in course.CourseSections.OrderBy(s => s.OrderIndex))
        {
            var sectionResponse = new CourseSectionResponse
            {
                Id = section.Id,
                Title = section.Title,
                OrderIndex = section.OrderIndex,
                Lessons = new List<CourseLessonResponse>()
            };

            foreach (var lesson in section.CourseLessons.OrderBy(l => l.OrderIndex))
            {
                var playbackUrl = lesson.Video != null && !string.IsNullOrWhiteSpace(lesson.Video.BunnyVideoId)
                    ? _bunnyStreamService.GetPlaybackUrl(lesson.Video.BunnyVideoId)
                    : null;

                sectionResponse.Lessons.Add(new CourseLessonResponse
                {
                    Id = lesson.Id,
                    Title = lesson.Title,
                    Duration = lesson.Duration,
                    VideoId = lesson.VideoId,
                    OrderIndex = lesson.OrderIndex,
                    IsPreview = lesson.IsPreview,
                    PlaybackUrl = playbackUrl
                });
            }

            response.Sections.Add(sectionResponse);
        }

        return response;
    }
}
