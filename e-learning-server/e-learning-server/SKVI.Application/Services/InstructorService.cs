using Microsoft.EntityFrameworkCore;
using SKVI.Application.DTOs.Instructors;
using SKVI.Application.Interfaces;
using SKVI.Domain.Entities;
using SKVI.Infrastructure;
using SKVI.Infrastructure.Security;
using SKVI.Shared;

namespace SKVI.Application.Services;

public class InstructorService : IInstructorService
{
    private static readonly HashSet<string> AllowedStatuses = new(new[] { "ACTIVE", "INACTIVE", "SUSPENDED" }, StringComparer.OrdinalIgnoreCase);

    private readonly ApplicationDbContext _dbContext;
    private readonly IPasswordHasher _passwordHasher;

    public InstructorService(ApplicationDbContext dbContext, IPasswordHasher passwordHasher)
    {
        _dbContext = dbContext;
        _passwordHasher = passwordHasher;
    }

    public async Task<PagedResult<InstructorDto>> GetPagedAsync(string? search, string? status, int page, int pageSize, CancellationToken cancellationToken = default)
    {
        page = page <= 0 ? 1 : page;
        pageSize = pageSize <= 0 ? 20 : Math.Min(pageSize, 100);

        var query = _dbContext.Users
            .AsNoTracking()
            .Where(u => !u.IsDeleted && u.Role == "LECTURER");

        if (!string.IsNullOrWhiteSpace(search))
        {
            var term = search.Trim().ToLower();
            query = query.Where(u =>
                (u.Email != null && u.Email.ToLower().Contains(term)) ||
                (u.FullName != null && u.FullName.ToLower().Contains(term)) ||
                (u.Phone != null && u.Phone.ToLower().Contains(term)));
        }

        if (!string.IsNullOrWhiteSpace(status))
        {
            query = query.Where(u => u.Status == status);
        }

        var total = await query.CountAsync(cancellationToken);
        var items = await query
            .OrderByDescending(u => u.CreatedAt)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync(cancellationToken);

        var instructorDtos = new List<InstructorDto>();
        foreach (var instructor in items)
        {
            var courseCount = await _dbContext.Courses.CountAsync(c => c.LecturerId == instructor.Id, cancellationToken);
            var studentCount = await _dbContext.Enrollments
                .Where(e => _dbContext.Courses.Any(c => c.Id == e.CourseId && c.LecturerId == instructor.Id))
                .Select(e => e.StudentId)
                .Distinct()
                .CountAsync(cancellationToken);

            instructorDtos.Add(MapToDto(instructor, courseCount, studentCount));
        }

        return new PagedResult<InstructorDto>
        {
            Items = instructorDtos,
            Total = total,
            Page = page,
            PageSize = pageSize
        };
    }

    public async Task<InstructorDetailDto> GetByIdAsync(Guid id, CancellationToken cancellationToken = default)
    {
        var instructor = await _dbContext.Users
            .AsNoTracking()
            .FirstOrDefaultAsync(u => u.Id == id && !u.IsDeleted && u.Role == "LECTURER", cancellationToken);

        if (instructor == null)
        {
            throw new KeyNotFoundException("Instructor not found");
        }

        var stats = await GetStatsAsync(id, cancellationToken);

        return new InstructorDetailDto
        {
            Id = instructor.Id,
            Email = instructor.Email,
            FullName = instructor.FullName,
            Phone = instructor.Phone,
            Status = instructor.Status,
            AvatarUrl = instructor.AvatarUrl,
            IsEmailVerified = instructor.IsEmailVerified,
            IsPhoneVerified = instructor.IsPhoneVerified,
            IsTwoFactorEnabled = instructor.IsTwoFactorEnabled,
            CreatedAt = instructor.CreatedAt,
            UpdatedAt = instructor.UpdatedAt,
            Stats = stats
        };
    }

    public async Task<InstructorStatsDto> GetStatsAsync(Guid id, CancellationToken cancellationToken = default)
    {
        var instructorExists = await _dbContext.Users.AnyAsync(u => u.Id == id && !u.IsDeleted && u.Role == "LECTURER", cancellationToken);
        if (!instructorExists)
        {
            throw new KeyNotFoundException("Instructor not found");
        }

        var courses = await _dbContext.Courses
            .Where(c => c.LecturerId == id)
            .ToListAsync(cancellationToken);

        var totalCourses = courses.Count;
        var publishedCourses = courses.Count(c => c.IsPublished);

        var courseIds = courses.Select(c => c.Id).ToList();
        var totalStudents = await _dbContext.Enrollments
            .Where(e => courseIds.Contains(e.CourseId))
            .Select(e => e.StudentId)
            .Distinct()
            .CountAsync(cancellationToken);

        var totalRevenue = await _dbContext.OrderItems
            .Where(oi => courseIds.Contains(oi.CourseId))
            .SumAsync(oi => oi.Price, cancellationToken);

        // Get last activity from course updates
        var lastActive = courses.Any() ? courses.Max(c => c.CreatedAt) : (DateTime?)null;

        return new InstructorStatsDto
        {
            TotalCourses = totalCourses,
            PublishedCourses = publishedCourses,
            TotalStudents = totalStudents,
            TotalRevenue = totalRevenue,
            AverageRating = 0, // TODO: Implement when rating system is added
            LastActive = lastActive
        };
    }

    public async Task<IReadOnlyList<InstructorCourseDto>> GetCoursesAsync(Guid id, CancellationToken cancellationToken = default)
    {
        var instructorExists = await _dbContext.Users.AnyAsync(u => u.Id == id && !u.IsDeleted && u.Role == "LECTURER", cancellationToken);
        if (!instructorExists)
        {
            throw new KeyNotFoundException("Instructor not found");
        }

        var courses = await _dbContext.Courses
            .AsNoTracking()
            .Where(c => c.LecturerId == id)
            .OrderByDescending(c => c.CreatedAt)
            .ToListAsync(cancellationToken);

        var courseDtos = new List<InstructorCourseDto>();
        foreach (var course in courses)
        {
            var enrollmentCount = await _dbContext.Enrollments.CountAsync(e => e.CourseId == course.Id, cancellationToken);
            courseDtos.Add(new InstructorCourseDto
            {
                Id = course.Id,
                Title = course.Title,
                Description = course.Description,
                Price = course.Price,
                IsFree = course.IsFree,
                IsPublished = course.IsPublished,
                ThumbnailUrl = course.ThumbnailUrl,
                EnrollmentCount = enrollmentCount,
                CreatedAt = course.CreatedAt
            });
        }

        return courseDtos;
    }

    public async Task<InstructorDto> CreateAsync(CreateInstructorRequest request, CancellationToken cancellationToken = default)
    {
        ValidateStatus(request.Status);

        var email = request.Email.Trim().ToLower();
        var exists = await _dbContext.Users.AnyAsync(u => u.Email.ToLower() == email && !u.IsDeleted, cancellationToken);
        if (exists)
        {
            throw new InvalidOperationException("Email already exists");
        }

        var instructor = new User
        {
            Id = Guid.NewGuid(),
            Email = request.Email.Trim(),
            PasswordHash = _passwordHasher.HashPassword(request.Password),
            FullName = request.FullName?.Trim(),
            Phone = request.Phone?.Trim(),
            Role = "LECTURER", // Always set to LECTURER for instructors
            Status = request.Status.ToUpper(),
            AvatarUrl = request.AvatarUrl,
            IsEmailVerified = false,
            IsPhoneVerified = false,
            CreatedAt = DateTime.UtcNow,
            UpdatedAt = DateTime.UtcNow,
            IsDeleted = false
        };

        _dbContext.Users.Add(instructor);
        await _dbContext.SaveChangesAsync(cancellationToken);

        return MapToDto(instructor, 0, 0);
    }

    public async Task<InstructorDto> UpdateAsync(Guid id, UpdateInstructorRequest request, CancellationToken cancellationToken = default)
    {
        ValidateStatus(request.Status);

        var instructor = await _dbContext.Users.FirstOrDefaultAsync(u => u.Id == id && !u.IsDeleted && u.Role == "LECTURER", cancellationToken);
        if (instructor == null)
        {
            throw new KeyNotFoundException("Instructor not found");
        }

        instructor.FullName = request.FullName?.Trim();
        instructor.Phone = request.Phone?.Trim();
        instructor.Status = request.Status.ToUpper();
        instructor.AvatarUrl = request.AvatarUrl;
        instructor.UpdatedAt = DateTime.UtcNow;

        await _dbContext.SaveChangesAsync(cancellationToken);

        var courseCount = await _dbContext.Courses.CountAsync(c => c.LecturerId == instructor.Id, cancellationToken);
        var studentCount = await _dbContext.Enrollments
            .Where(e => _dbContext.Courses.Any(c => c.Id == e.CourseId && c.LecturerId == instructor.Id))
            .Select(e => e.StudentId)
            .Distinct()
            .CountAsync(cancellationToken);

        return MapToDto(instructor, courseCount, studentCount);
    }

    public async Task DeleteAsync(Guid id, CancellationToken cancellationToken = default)
    {
        var instructor = await _dbContext.Users
            .Include(u => u.RefreshTokens)
            .FirstOrDefaultAsync(u => u.Id == id && !u.IsDeleted && u.Role == "LECTURER", cancellationToken);

        if (instructor == null)
        {
            throw new KeyNotFoundException("Instructor not found");
        }

        // Check if instructor has courses
        var hasCourses = await _dbContext.Courses.AnyAsync(c => c.LecturerId == id, cancellationToken);
        if (hasCourses)
        {
            throw new InvalidOperationException("Cannot delete instructor with existing courses. Please reassign or delete courses first.");
        }

        instructor.IsDeleted = true;
        instructor.Status = "INACTIVE";
        instructor.RefreshTokens.Clear();
        instructor.UpdatedAt = DateTime.UtcNow;

        await _dbContext.SaveChangesAsync(cancellationToken);
    }

    private static void ValidateStatus(string status)
    {
        if (!AllowedStatuses.Contains(status))
        {
            throw new InvalidOperationException("Invalid status");
        }
    }

    private static InstructorDto MapToDto(User instructor, int totalCourses, int totalStudents) => new()
    {
        Id = instructor.Id,
        Email = instructor.Email,
        FullName = instructor.FullName,
        Phone = instructor.Phone,
        Status = instructor.Status,
        AvatarUrl = instructor.AvatarUrl,
        IsEmailVerified = instructor.IsEmailVerified,
        IsPhoneVerified = instructor.IsPhoneVerified,
        CreatedAt = instructor.CreatedAt,
        TotalCourses = totalCourses,
        TotalStudents = totalStudents
    };
}
