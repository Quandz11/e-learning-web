using Microsoft.EntityFrameworkCore;
using SKVI.Application.DTOs.Wellness;
using SKVI.Application.Interfaces;
using SKVI.Application.Models;
using SKVI.Infrastructure;

namespace SKVI.Application.Services;

public class WellnessAccessService : IWellnessAccessService
{
    private const string CodeRequired = "WELLNESS_PACKAGE_REQUIRED";
    private const string CodeUpgradeRequired = "WELLNESS_PACKAGE_UPGRADE_REQUIRED";
    private const string CodeNotConfigured = "WELLNESS_PACKAGE_NOT_CONFIGURED";
    private const string CodeInvalid = "WELLNESS_PACKAGE_INVALID";

    private readonly ApplicationDbContext _dbContext;
    private readonly IWellnessSettingsService _wellnessSettingsService;

    public WellnessAccessService(
        ApplicationDbContext dbContext,
        IWellnessSettingsService wellnessSettingsService)
    {
        _dbContext = dbContext;
        _wellnessSettingsService = wellnessSettingsService;
    }

    public async Task<WellnessAccessEvaluationDto> EvaluateAccessAsync(
        Guid userId,
        string? requiredPackageType = null,
        CancellationToken cancellationToken = default)
    {
        var checkoutConfig = await _wellnessSettingsService.GetCheckoutConfigAsync(cancellationToken);
        var activeCatalog = checkoutConfig.Packages
            .OrderBy(p => p.SortOrder)
            .ThenBy(p => p.DurationDays)
            .ThenBy(p => p.Code)
            .ToList();

        var catalogCodes = new HashSet<string>(
            activeCatalog.Select(p => NormalizePackageCode(p.Code)),
            StringComparer.OrdinalIgnoreCase);
        var normalizedRequiredPackage = TryNormalizeRequiredPackage(requiredPackageType);
        var hasRequiredPackage = !string.IsNullOrWhiteSpace(requiredPackageType);
        var isUnknownRequiredPackage = hasRequiredPackage
            && (normalizedRequiredPackage == null || !catalogCodes.Contains(normalizedRequiredPackage));

        if (activeCatalog.Count == 0)
        {
            return new WellnessAccessEvaluationDto
            {
                CheckoutConfig = checkoutConfig,
                Access = new WellnessAccessDto
                {
                    IsUnlocked = false,
                    AllowedPackages = [],
                    RequiredPackages = normalizedRequiredPackage == null ? [] : [normalizedRequiredPackage],
                    CtaPath = checkoutConfig.CtaPath,
                    ReasonCode = CodeNotConfigured,
                    Message = "Wellness packages are not configured. Please contact admin."
                }
            };
        }

        var now = DateTime.UtcNow;
        var ownedRows = await _dbContext.WellnessUserPackages
            .AsNoTracking()
            .Include(p => p.Package)
            .Where(p =>
                p.UserId == userId
                && p.Status == "ACTIVE"
                && p.StartsAt <= now
                && (!p.ExpiresAt.HasValue || p.ExpiresAt.Value > now))
            .OrderByDescending(p => p.Package.DurationDays)
            .ThenBy(p => p.Package.SortOrder)
            .ThenByDescending(p => p.CreatedAt)
            .ToListAsync(cancellationToken);

        var allowedPackages = ownedRows
            .Select(row => NormalizePackageCode(row.Package.Code))
            .Distinct(StringComparer.OrdinalIgnoreCase)
            .ToList();

        var isUnlockedByAnyPackage = allowedPackages.Count > 0;
        var hasMatchedRequiredPackage = !hasRequiredPackage
            || (normalizedRequiredPackage != null && allowedPackages.Contains(normalizedRequiredPackage, StringComparer.OrdinalIgnoreCase));
        var isUnlocked = isUnlockedByAnyPackage && hasMatchedRequiredPackage && !isUnknownRequiredPackage;

        var requiredPackages = normalizedRequiredPackage == null
            ? activeCatalog.Select(p => NormalizePackageCode(p.Code)).ToList()
            : [normalizedRequiredPackage];

        var reasonCode = string.Empty;
        var message = string.Empty;
        if (isUnknownRequiredPackage)
        {
            reasonCode = CodeInvalid;
            message = "Selected wellness package is invalid or inactive.";
        }
        else if (isUnlockedByAnyPackage && !hasMatchedRequiredPackage)
        {
            reasonCode = CodeUpgradeRequired;
            message = BuildPackageRequiredMessage(normalizedRequiredPackage, activeCatalog);
        }
        else if (!isUnlockedByAnyPackage)
        {
            reasonCode = CodeRequired;
            message = BuildPackageRequiredMessage(normalizedRequiredPackage, activeCatalog);
        }

        return new WellnessAccessEvaluationDto
        {
            CheckoutConfig = checkoutConfig,
            Access = new WellnessAccessDto
            {
                IsUnlocked = isUnlocked,
                CurrentPackage = allowedPackages.FirstOrDefault(),
                AllowedPackages = allowedPackages,
                RequiredPackages = requiredPackages,
                CtaPath = checkoutConfig.CtaPath,
                ReasonCode = reasonCode,
                Message = message
            }
        };
    }

    public async Task EnsureAccessAsync(
        Guid userId,
        string packageType,
        CancellationToken cancellationToken = default)
    {
        var normalizedPackage = TryNormalizeRequiredPackage(packageType);
        if (normalizedPackage == null)
        {
            throw new WellnessAccessException(CodeInvalid, "Current wellness package is invalid.");
        }

        var evaluation = await EvaluateAccessAsync(userId, normalizedPackage, cancellationToken);
        if (evaluation.Access.IsUnlocked)
        {
            return;
        }

        var code = string.IsNullOrWhiteSpace(evaluation.Access.ReasonCode)
            ? CodeRequired
            : evaluation.Access.ReasonCode;
        var message = string.IsNullOrWhiteSpace(evaluation.Access.Message)
            ? "You need to purchase a wellness package to activate this feature."
            : evaluation.Access.Message;

        throw new WellnessAccessException(code, message);
    }

    private static string BuildPackageRequiredMessage(
        string? requiredPackageCode,
        IReadOnlyCollection<WellnessCheckoutPackageDto> activeCatalog)
    {
        if (!string.IsNullOrWhiteSpace(requiredPackageCode))
        {
            var required = activeCatalog.FirstOrDefault(p =>
                string.Equals(p.Code, requiredPackageCode, StringComparison.OrdinalIgnoreCase));
            if (required != null)
            {
                return $"You need package {required.Name} to activate this feature.";
            }
        }

        return "You need to purchase a wellness package to activate this feature.";
    }

    private static string NormalizePackageCode(string? packageCode)
    {
        return (packageCode ?? string.Empty).Trim().ToUpperInvariant();
    }

    private static string? TryNormalizeRequiredPackage(string? packageCode)
    {
        var normalized = NormalizePackageCode(packageCode);
        if (string.IsNullOrWhiteSpace(normalized))
        {
            return null;
        }

        if (normalized.Length < 3 || normalized.Length > 32)
        {
            return null;
        }

        return normalized;
    }
}

