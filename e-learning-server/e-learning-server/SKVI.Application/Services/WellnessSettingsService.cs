using System.Text.Json;
using System.Text.RegularExpressions;
using Microsoft.EntityFrameworkCore;
using SKVI.Application.DTOs.Wellness;
using SKVI.Application.Interfaces;
using SKVI.Domain.Entities;
using SKVI.Infrastructure;

namespace SKVI.Application.Services;

public class WellnessSettingsService : IWellnessSettingsService
{
    private static readonly Regex PackageCodeRegex = new("^[A-Z0-9_]{3,32}$", RegexOptions.Compiled);
    private static readonly string[] AllowedAssignmentStatus = ["ACTIVE", "REVOKED", "EXPIRED"];
    private static readonly string[] AllowedAssignmentSource = ["MANUAL", "PURCHASE"];
    private readonly ApplicationDbContext _dbContext;

    public WellnessSettingsService(ApplicationDbContext dbContext)
    {
        _dbContext = dbContext;
    }

    public async Task<WellnessCheckoutConfigDto> GetCheckoutConfigAsync(CancellationToken cancellationToken = default)
    {
        var settings = await EnsureSettingsAsync(cancellationToken);
        await EnsureDefaultPackagesAsync(cancellationToken);

        var packages = await _dbContext.WellnessPackages
            .AsNoTracking()
            .Where(p => p.IsActive)
            .OrderBy(p => p.SortOrder)
            .ThenBy(p => p.DurationDays)
            .ThenBy(p => p.Code)
            .Select(p => new WellnessCheckoutPackageDto
            {
                Code = p.Code,
                Name = p.Name,
                Description = p.Description,
                PriceVnd = p.PriceVnd,
                DurationDays = p.DurationDays,
                IsFeatured = p.IsFeatured,
                SortOrder = p.SortOrder
            })
            .ToListAsync(cancellationToken);

        return new WellnessCheckoutConfigDto
        {
            Packages = packages,
            CtaPath = NormalizeCtaPath(settings.CtaPath),
            IsPersonalizedRoadmapPaid = settings.IsPersonalizedRoadmapPaid
        };
    }

    public async Task<WellnessAdminSettingsDto> GetAdminSettingsAsync(CancellationToken cancellationToken = default)
    {
        var settings = await EnsureSettingsAsync(cancellationToken);
        await EnsureDefaultPackagesAsync(cancellationToken);

        var packages = await _dbContext.WellnessPackages
            .AsNoTracking()
            .Include(p => p.PackageLessons)
                .ThenInclude(l => l.Lesson)
            .OrderBy(p => p.SortOrder)
            .ThenBy(p => p.DurationDays)
            .ThenBy(p => p.Code)
            .ToListAsync(cancellationToken);

        return new WellnessAdminSettingsDto
        {
            Id = settings.Id,
            CtaPath = NormalizeCtaPath(settings.CtaPath),
            IsPersonalizedRoadmapPaid = settings.IsPersonalizedRoadmapPaid,
            UpdatedAt = settings.UpdatedAt,
            Packages = packages.Select(MapAdminPackage).ToList()
        };
    }

    public async Task<WellnessAdminSettingsDto> UpdateSettingsAsync(
        Guid actorUserId,
        UpdateWellnessAdminSettingsRequest request,
        CancellationToken cancellationToken = default)
    {
        var normalizedRequests = NormalizePackageRequests(request.Packages);
        var settings = await EnsureSettingsAsync(cancellationToken);
        var now = DateTime.UtcNow;

        var existingPackages = await _dbContext.WellnessPackages
            .ToDictionaryAsync(p => p.Code, StringComparer.OrdinalIgnoreCase, cancellationToken);

        var existingPackageIds = existingPackages.Values.Select(p => p.Id).ToList();
        if (existingPackageIds.Any())
        {
            await _dbContext.WellnessPackageLessons
                .Where(l => existingPackageIds.Contains(l.WellnessPackageId))
                .ExecuteDeleteAsync(cancellationToken);
        }

        var incomingCodes = new HashSet<string>(normalizedRequests.Select(p => p.Code), StringComparer.OrdinalIgnoreCase);

        foreach (var packageRequest in normalizedRequests)
        {
            if (existingPackages.TryGetValue(packageRequest.Code, out var existing))
            {
                existing.Name = packageRequest.Name;
                existing.Description = packageRequest.Description;
                existing.PriceVnd = packageRequest.PriceVnd;
                existing.DurationDays = packageRequest.DurationDays;
                existing.IsActive = packageRequest.IsActive;
                existing.IsFeatured = packageRequest.IsFeatured;
                existing.SortOrder = packageRequest.SortOrder;
                existing.UpdatedAt = now;

                foreach(var lessonRequest in packageRequest.Lessons)
                {
                    _dbContext.WellnessPackageLessons.Add(new WellnessPackageLesson
                    {
                        Id = Guid.NewGuid(),
                        WellnessPackageId = existing.Id,
                        LessonId = lessonRequest.LessonId,
                        DayIndex = lessonRequest.DayIndex,
                        SortOrder = lessonRequest.SortOrder,
                        CreatedAt = now
                    });
                }
            }
            else
            {
                var newPackage = new WellnessPackage
                {
                    Id = Guid.NewGuid(),
                    Code = packageRequest.Code,
                    Name = packageRequest.Name,
                    Description = packageRequest.Description,
                    PriceVnd = packageRequest.PriceVnd,
                    DurationDays = packageRequest.DurationDays,
                    IsActive = packageRequest.IsActive,
                    IsFeatured = packageRequest.IsFeatured,
                    SortOrder = packageRequest.SortOrder,
                    CreatedAt = now,
                    UpdatedAt = now
                };
                
                _dbContext.WellnessPackages.Add(newPackage);
                
                foreach(var l in packageRequest.Lessons)
                {
                    _dbContext.WellnessPackageLessons.Add(new WellnessPackageLesson
                    {
                        Id = Guid.NewGuid(),
                        WellnessPackageId = newPackage.Id,
                        LessonId = l.LessonId,
                        DayIndex = l.DayIndex,
                        SortOrder = l.SortOrder,
                        CreatedAt = now
                    });
                }
            }
        }

        foreach (var package in existingPackages.Values.Where(p => !incomingCodes.Contains(p.Code)))
        {
            package.IsActive = false;
            package.IsFeatured = false;
            package.UpdatedAt = now;
        }

        settings.CtaPath = NormalizeCtaPath(request.CtaPath);
        settings.IsPersonalizedRoadmapPaid = request.IsPersonalizedRoadmapPaid;
        settings.UpdatedAt = now;

        _dbContext.AuditLogs.Add(new AuditLog
        {
            Id = Guid.NewGuid(),
            UserId = actorUserId,
            Action = "WELLNESS_SETTINGS_UPDATE",
            TargetTable = nameof(WellnessSettings),
            TargetId = settings.Id,
            Metadata = JsonSerializer.Serialize(new
            {
                settings.CtaPath,
                PackageCount = normalizedRequests.Count
            }),
            CreatedAt = now
        });

        await _dbContext.SaveChangesAsync(cancellationToken);
        return await GetAdminSettingsAsync(cancellationToken);
    }

    public async Task<List<WellnessUserPackageDto>> GetUserPackagesAsync(Guid userId, CancellationToken cancellationToken = default)
    {
        var rows = await _dbContext.WellnessUserPackages
            .AsNoTracking()
            .Include(p => p.Package)
            .Where(p => p.UserId == userId)
            .OrderByDescending(p => p.CreatedAt)
            .ToListAsync(cancellationToken);

        return rows.Select(MapUserPackage).ToList();
    }

    public async Task<WellnessUserPackageDto> GrantPackageToUserAsync(
        Guid actorUserId,
        Guid userId,
        GrantWellnessUserPackageRequest request,
        CancellationToken cancellationToken = default)
    {
        var userExists = await _dbContext.Users.AnyAsync(u => u.Id == userId && !u.IsDeleted, cancellationToken);
        if (!userExists)
        {
            throw new InvalidOperationException("User not found.");
        }

        var normalizedCode = NormalizePackageCode(request.PackageCode);
        var package = await _dbContext.WellnessPackages
            .FirstOrDefaultAsync(p => p.Code == normalizedCode && p.IsActive, cancellationToken);

        if (package == null)
        {
            throw new InvalidOperationException("Wellness package does not exist or is inactive.");
        }

        var now = DateTime.UtcNow;
        var startsAt = request.StartsAt?.ToUniversalTime() ?? now;
        var expiresAt = request.ExpiresAt?.ToUniversalTime() ?? startsAt.AddDays(package.DurationDays);
        if (expiresAt <= startsAt)
        {
            throw new InvalidOperationException("Package expiry must be after start time.");
        }

        var source = NormalizeAssignmentSource(request.Source);
        var row = new WellnessUserPackage
        {
            Id = Guid.NewGuid(),
            UserId = userId,
            PackageId = package.Id,
            Status = "ACTIVE",
            Source = source,
            GrantedByUserId = actorUserId,
            Notes = (request.Notes ?? string.Empty).Trim(),
            GrantedAt = now,
            StartsAt = startsAt,
            ExpiresAt = expiresAt,
            CreatedAt = now,
            UpdatedAt = now
        };

        _dbContext.WellnessUserPackages.Add(row);
        _dbContext.AuditLogs.Add(new AuditLog
        {
            Id = Guid.NewGuid(),
            UserId = actorUserId,
            Action = "WELLNESS_PACKAGE_GRANT",
            TargetTable = nameof(WellnessUserPackage),
            TargetId = row.Id,
            Metadata = JsonSerializer.Serialize(new
            {
                row.UserId,
                PackageCode = package.Code,
                row.Status,
                row.Source,
                row.StartsAt,
                row.ExpiresAt
            }),
            CreatedAt = now
        });

        await _dbContext.SaveChangesAsync(cancellationToken);
        row.Package = package;
        return MapUserPackage(row);
    }

    public async Task<WellnessUserPackageDto> UpdateUserPackageAsync(
        Guid actorUserId,
        Guid userId,
        Guid userPackageId,
        UpdateWellnessUserPackageRequest request,
        CancellationToken cancellationToken = default)
    {
        var row = await _dbContext.WellnessUserPackages
            .Include(p => p.Package)
            .FirstOrDefaultAsync(p => p.Id == userPackageId && p.UserId == userId, cancellationToken);

        if (row == null)
        {
            throw new InvalidOperationException("User package assignment not found.");
        }

        var normalizedStatus = NormalizeAssignmentStatus(request.Status);
        var now = DateTime.UtcNow;
        var expiresAt = request.ExpiresAt?.ToUniversalTime() ?? row.ExpiresAt;
        if (expiresAt.HasValue && expiresAt.Value <= row.StartsAt)
        {
            throw new InvalidOperationException("Package expiry must be after start time.");
        }

        row.Status = normalizedStatus;
        row.ExpiresAt = expiresAt;
        row.Notes = (request.Notes ?? string.Empty).Trim();
        row.UpdatedAt = now;

        _dbContext.AuditLogs.Add(new AuditLog
        {
            Id = Guid.NewGuid(),
            UserId = actorUserId,
            Action = "WELLNESS_PACKAGE_ASSIGNMENT_UPDATE",
            TargetTable = nameof(WellnessUserPackage),
            TargetId = row.Id,
            Metadata = JsonSerializer.Serialize(new
            {
                row.UserId,
                row.Status,
                row.ExpiresAt
            }),
            CreatedAt = now
        });

        await _dbContext.SaveChangesAsync(cancellationToken);
        return MapUserPackage(row);
    }

    private async Task EnsureDefaultPackagesAsync(CancellationToken cancellationToken)
    {
        var hasPackage = await _dbContext.WellnessPackages.AnyAsync(cancellationToken);
        if (hasPackage)
        {
            return;
        }

        var now = DateTime.UtcNow;
        _dbContext.WellnessPackages.AddRange(
            new WellnessPackage
            {
                Id = Guid.NewGuid(),
                Code = "TRIAL_3_DAYS",
                Name = "Trial 3 days",
                Description = "Quick start package to test wellness roadmap.",
                PriceVnd = 99000,
                DurationDays = 3,
                IsActive = true,
                IsFeatured = false,
                SortOrder = 10,
                CreatedAt = now,
                UpdatedAt = now
            },
            new WellnessPackage
            {
                Id = Guid.NewGuid(),
                Code = "PLAN_30_DAYS",
                Name = "Plan 30 days",
                Description = "Full package for long-term wellness improvement.",
                PriceVnd = 499000,
                DurationDays = 30,
                IsActive = true,
                IsFeatured = true,
                SortOrder = 20,
                CreatedAt = now,
                UpdatedAt = now
            });

        await _dbContext.SaveChangesAsync(cancellationToken);
    }

    private async Task<WellnessSettings> EnsureSettingsAsync(CancellationToken cancellationToken)
    {
        var settings = await _dbContext.WellnessSettings.FirstOrDefaultAsync(cancellationToken);
        if (settings != null)
        {
            return settings;
        }

        settings = new WellnessSettings();
        _dbContext.WellnessSettings.Add(settings);
        await _dbContext.SaveChangesAsync(cancellationToken);
        return settings;
    }

    private static List<WellnessPackageUpsertRequest> NormalizePackageRequests(IEnumerable<WellnessPackageUpsertRequest>? requests)
    {
        var result = new List<WellnessPackageUpsertRequest>();
        var seenCodes = new HashSet<string>(StringComparer.OrdinalIgnoreCase);

        foreach (var request in requests ?? [])
        {
            var code = NormalizePackageCode(request.Code);
            if (!seenCodes.Add(code))
            {
                throw new InvalidOperationException($"Duplicate package code: {code}");
            }

            var name = (request.Name ?? string.Empty).Trim();
            if (string.IsNullOrWhiteSpace(name))
            {
                throw new InvalidOperationException($"Package {code} must have a name.");
            }

            if (request.DurationDays <= 0)
            {
                throw new InvalidOperationException($"Package {code} must have duration > 0.");
            }

            if (request.PriceVnd < 0)
            {
                throw new InvalidOperationException($"Package {code} has invalid price.");
            }

            result.Add(new WellnessPackageUpsertRequest
            {
                Code = code,
                Name = name,
                Description = (request.Description ?? string.Empty).Trim(),
                PriceVnd = decimal.Round(request.PriceVnd, 0, MidpointRounding.AwayFromZero),
                DurationDays = request.DurationDays,
                IsActive = request.IsActive,
                IsFeatured = request.IsFeatured,
                SortOrder = request.SortOrder,
                Lessons = request.Lessons?.Select(l => new WellnessPackageLessonUpsertRequest
                {
                    LessonId = l.LessonId,
                    DayIndex = l.DayIndex,
                    SortOrder = l.SortOrder
                }).ToList() ?? []
            });
        }

        return result;
    }

    private static WellnessPackageAdminDto MapAdminPackage(WellnessPackage package)
    {
        return new WellnessPackageAdminDto
        {
            Id = package.Id,
            Code = package.Code,
            Name = package.Name,
            Description = package.Description,
            PriceVnd = package.PriceVnd,
            DurationDays = package.DurationDays,
            IsActive = package.IsActive,
            IsFeatured = package.IsFeatured,
            SortOrder = package.SortOrder,
            UpdatedAt = package.UpdatedAt,
            Lessons = package.PackageLessons?.OrderBy(l => l.DayIndex).ThenBy(l => l.SortOrder).Select(l => new WellnessPackageLessonDto
            {
                Id = l.Id,
                LessonId = l.LessonId,
                LessonTitle = l.Lesson?.Title ?? string.Empty,
                DayIndex = l.DayIndex,
                SortOrder = l.SortOrder
            }).ToList() ?? []
        };
    }

    private static WellnessUserPackageDto MapUserPackage(WellnessUserPackage row)
    {
        return new WellnessUserPackageDto
        {
            Id = row.Id,
            UserId = row.UserId,
            PackageId = row.PackageId,
            PackageCode = row.Package.Code,
            PackageName = row.Package.Name,
            PriceVnd = row.Package.PriceVnd,
            DurationDays = row.Package.DurationDays,
            Status = row.Status,
            Source = row.Source,
            GrantedByUserId = row.GrantedByUserId,
            Notes = row.Notes,
            GrantedAt = row.GrantedAt,
            StartsAt = row.StartsAt,
            ExpiresAt = row.ExpiresAt
        };
    }

    private static string NormalizePackageCode(string? code)
    {
        var value = (code ?? string.Empty).Trim().ToUpperInvariant();
        if (!PackageCodeRegex.IsMatch(value))
        {
            throw new InvalidOperationException("Package code is invalid. Use A-Z, 0-9 and underscore.");
        }

        return value;
    }

    private static string NormalizeAssignmentSource(string? source)
    {
        var normalized = (source ?? string.Empty).Trim().ToUpperInvariant();
        if (!AllowedAssignmentSource.Contains(normalized, StringComparer.OrdinalIgnoreCase))
        {
            return "MANUAL";
        }

        return normalized;
    }

    private static string NormalizeAssignmentStatus(string? status)
    {
        var normalized = (status ?? string.Empty).Trim().ToUpperInvariant();
        if (!AllowedAssignmentStatus.Contains(normalized, StringComparer.OrdinalIgnoreCase))
        {
            throw new InvalidOperationException("Assignment status is invalid.");
        }

        return normalized;
    }

    private static string NormalizeCtaPath(string? path)
    {
        var value = string.IsNullOrWhiteSpace(path) ? "/pricing" : path.Trim();
        if (!value.StartsWith('/'))
        {
            throw new InvalidOperationException("CTA path must start with '/'.");
        }

        if (value.StartsWith("//", StringComparison.Ordinal))
        {
            throw new InvalidOperationException("CTA path is invalid.");
        }

        return value;
    }
}

