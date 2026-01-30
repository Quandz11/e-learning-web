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
            .Include(c => c.Lecturer)
            .Include(c => c.CourseSections)
                .ThenInclude(s => s.CourseLessons)
                    .ThenInclude(l => l.Video)
            .Include(c => c.CourseSections)
                .ThenInclude(s => s.CourseLessons)
                    .ThenInclude(l => l.Document)
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
            .Include(c => c.CourseSections)
                .ThenInclude(s => s.CourseLessons)
                    .ThenInclude(l => l.Video)
            .Include(c => c.CourseSections)
                .ThenInclude(s => s.CourseLessons)
                    .ThenInclude(l => l.Document)
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

        // Preload video durations to auto-fill lesson duration
        var createVideoIds = request.Sections
            .SelectMany(s => s.Lessons)
            .Where(l => l.VideoId != Guid.Empty)
            .Select(l => l.VideoId)
            .Distinct()
            .ToList();

        var createVideoDurations = await _dbContext.Videos
            .Where(v => createVideoIds.Contains(v.Id))
            .ToDictionaryAsync(v => v.Id, v => v.Duration, cancellationToken);

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
                var resolvedDuration = lessonDto.Duration;
                if (resolvedDuration <= 0 && lessonDto.VideoId != Guid.Empty && createVideoDurations.TryGetValue(lessonDto.VideoId, out var videoDuration))
                {
                    resolvedDuration = videoDuration;
                }

                var lesson = new CourseLesson
                {
                    Id = Guid.NewGuid(),
                    SectionId = section.Id,
                    Title = lessonDto.Title,
                    Duration = resolvedDuration,
                    VideoId = lessonDto.VideoId,
                    DocumentId = lessonDto.DocumentId,
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
        // Load course without tracking to avoid stale tracked entities when rebuilding children
        var course = await _dbContext.Courses
            .AsNoTracking()
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

        // Preload video durations for lessons so duration is always derived from stored video metadata when absent
        var updateVideoIds = request.Sections
            .SelectMany(s => s.Lessons)
            .Where(l => l.VideoId != Guid.Empty)
            .Select(l => l.VideoId)
            .Distinct()
            .ToList();

        var updateVideoDurations = await _dbContext.Videos
            .Where(v => updateVideoIds.Contains(v.Id))
            .ToDictionaryAsync(v => v.Id, v => v.Duration, cancellationToken);

        // Remove existing sections/lessons set-based to avoid per-row concurrency
        var sectionIds = await _dbContext.CourseSections
            .Where(s => s.CourseId == course.Id)
            .Select(s => s.Id)
            .ToListAsync(cancellationToken);

        if (sectionIds.Count > 0)
        {
            await _dbContext.CourseLessons
                .Where(l => sectionIds.Contains(l.SectionId))
                .ExecuteDeleteAsync(cancellationToken);

            await _dbContext.CourseSections
                .Where(s => s.CourseId == course.Id)
                .ExecuteDeleteAsync(cancellationToken);
        }

        // Rebuild sections/lessons
        var newSections = new List<CourseSection>();

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
                var resolvedDuration = lessonDto.Duration;
                if (resolvedDuration <= 0 && lessonDto.VideoId != Guid.Empty && updateVideoDurations.TryGetValue(lessonDto.VideoId, out var videoDuration))
                {
                    resolvedDuration = videoDuration;
                }

                section.CourseLessons.Add(new CourseLesson
                {
                    Id = Guid.NewGuid(),
                    SectionId = section.Id,
                    Title = lessonDto.Title,
                    Duration = resolvedDuration,
                    VideoId = lessonDto.VideoId,
                    DocumentId = lessonDto.DocumentId,
                    OrderIndex = lessonDto.OrderIndex,
                    IsPreview = lessonDto.IsPreview
                });
            }

            newSections.Add(section);
        }

        // Re-attach course and mark modified (no tracked children lingering)
        _dbContext.Courses.Update(course);
        _dbContext.CourseSections.AddRange(newSections);

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
            Lecturer = course.Lecturer != null ? new LecturerInfo
            {
                Id = course.Lecturer.Id,
                FullName = course.Lecturer.FullName ?? string.Empty,
                Email = course.Lecturer.Email,
                AvatarUrl = course.Lecturer.AvatarUrl
            } : null,
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

                var embedUrl = lesson.Video != null && !string.IsNullOrWhiteSpace(lesson.Video.BunnyLibraryId) && !string.IsNullOrWhiteSpace(lesson.Video.BunnyVideoId)
                    ? $"https://iframe.mediadelivery.net/embed/{lesson.Video.BunnyLibraryId}/{lesson.Video.BunnyVideoId}"
                    : null;

                sectionResponse.Lessons.Add(new CourseLessonResponse
                {
                    Id = lesson.Id,
                    Title = lesson.Title,
                    Duration = lesson.Video != null && lesson.Video.Duration > 0 ? lesson.Video.Duration : lesson.Duration,
                    VideoId = lesson.VideoId,
                    OrderIndex = lesson.OrderIndex,
                    IsPreview = lesson.IsPreview,
                    PlaybackUrl = playbackUrl,
                    EmbedUrl = embedUrl,
                    DocumentId = lesson.DocumentId,
                    DocumentUrl = lesson.Document?.BunnyStoragePath, // This is already the full CDN URL from DocumentService
                    DocumentFileName = lesson.Document?.FileName
                });
            }

            response.Sections.Add(sectionResponse);
        }

        return response;
    }
}
