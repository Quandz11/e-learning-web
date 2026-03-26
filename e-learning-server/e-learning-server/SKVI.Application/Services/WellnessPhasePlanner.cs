namespace SKVI.Application.Services;

public static class WellnessPhasePlanner
{
    public const string PhasePrepare = "PREPARE";
    public const string PhaseFasting = "FASTING";
    public const string PhaseRefeed = "REFEED";

    public readonly record struct PhaseBreakdown(int TotalDays, int PreparationDays, int FastingDays, int RefeedDays);
    public readonly record struct PhaseDetail(string Phase, int DayIndex, int TotalDays);

    public static PhaseBreakdown BuildPhaseBreakdown(DateTime startDate, DateTime endDate)
    {
        var totalDays = (endDate.Date - startDate.Date).Days + 1;
        if (totalDays <= 0)
        {
            throw new InvalidOperationException("Schedule is invalid.");
        }

        if (totalDays == 1)
        {
            return new PhaseBreakdown(totalDays, 1, 0, 0);
        }

        if (totalDays == 2)
        {
            return new PhaseBreakdown(totalDays, 1, 1, 0);
        }

        var preparationDays = totalDays <= 5 ? 1 : 2;
        var remainingDays = totalDays - preparationDays;
        var fastingDays = (int)Math.Floor((remainingDays * 2d) / 3d);
        fastingDays = Math.Clamp(fastingDays, 1, remainingDays - 1);
        var refeedDays = remainingDays - fastingDays;

        return new PhaseBreakdown(totalDays, preparationDays, fastingDays, refeedDays);
    }

    public static void ValidateScheduleDuration(DateTime startDate, DateTime endDate)
    {
        var totalDays = (endDate.Date - startDate.Date).Days + 1;
        if (totalDays < 3)
        {
            throw new InvalidOperationException("Schedule must be at least 3 days to split into preparation, fasting, and refeed phases.");
        }
    }

    public static PhaseDetail ResolvePhaseForDate(DateTime date, DateTime planStartDate, PhaseBreakdown breakdown)
    {
        var dayNumber = (date.Date - planStartDate.Date).Days + 1;
        if (dayNumber < 1 || dayNumber > breakdown.TotalDays)
        {
            throw new InvalidOperationException("Timeline date is outside plan range.");
        }

        if (dayNumber <= breakdown.PreparationDays)
        {
            return new PhaseDetail(PhasePrepare, dayNumber, breakdown.PreparationDays);
        }

        var fastingStartDay = breakdown.PreparationDays + 1;
        var fastingEndDay = breakdown.PreparationDays + breakdown.FastingDays;
        if (dayNumber <= fastingEndDay)
        {
            return new PhaseDetail(PhaseFasting, dayNumber - fastingStartDay + 1, breakdown.FastingDays);
        }

        var refeedStartDay = fastingEndDay + 1;
        return new PhaseDetail(PhaseRefeed, dayNumber - refeedStartDay + 1, breakdown.RefeedDays);
    }
}
