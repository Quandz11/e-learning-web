using SKVI.Application.Services;

namespace SKVI.Application.Tests;

public class WellnessPhasePlannerTests
{
    [Theory]
    [InlineData(3, 1, 1, 1)]
    [InlineData(4, 1, 2, 1)]
    [InlineData(5, 1, 2, 2)]
    [InlineData(6, 2, 2, 2)]
    [InlineData(10, 2, 5, 3)]
    [InlineData(30, 2, 18, 10)]
    [InlineData(1, 1, 0, 0)]
    [InlineData(2, 1, 1, 0)]
    public void BuildPhaseBreakdown_UsesExpectedDistribution(int totalDays, int expectedPrepare, int expectedFasting, int expectedRefeed)
    {
        var start = new DateTime(2026, 1, 1);
        var end = start.AddDays(totalDays - 1);

        var breakdown = WellnessPhasePlanner.BuildPhaseBreakdown(start, end);

        Assert.Equal(totalDays, breakdown.TotalDays);
        Assert.Equal(expectedPrepare, breakdown.PreparationDays);
        Assert.Equal(expectedFasting, breakdown.FastingDays);
        Assert.Equal(expectedRefeed, breakdown.RefeedDays);
        Assert.Equal(totalDays, breakdown.PreparationDays + breakdown.FastingDays + breakdown.RefeedDays);
    }

    [Theory]
    [InlineData(1)]
    [InlineData(2)]
    public void ValidateScheduleDuration_Throws_WhenShorterThanThreeDays(int totalDays)
    {
        var start = new DateTime(2026, 1, 1);
        var end = start.AddDays(totalDays - 1);

        var ex = Assert.Throws<InvalidOperationException>(() => WellnessPhasePlanner.ValidateScheduleDuration(start, end));
        Assert.Contains("at least 3 days", ex.Message, StringComparison.OrdinalIgnoreCase);
    }

    [Fact]
    public void ResolvePhaseForDate_ReturnsCorrectPhaseAndDayIndex()
    {
        var start = new DateTime(2026, 1, 1);
        var end = start.AddDays(9);
        var breakdown = WellnessPhasePlanner.BuildPhaseBreakdown(start, end);

        var day1 = WellnessPhasePlanner.ResolvePhaseForDate(start, start, breakdown);
        var day3 = WellnessPhasePlanner.ResolvePhaseForDate(start.AddDays(2), start, breakdown);
        var day7 = WellnessPhasePlanner.ResolvePhaseForDate(start.AddDays(6), start, breakdown);
        var day8 = WellnessPhasePlanner.ResolvePhaseForDate(start.AddDays(7), start, breakdown);
        var day10 = WellnessPhasePlanner.ResolvePhaseForDate(end, start, breakdown);

        Assert.Equal(WellnessPhasePlanner.PhasePrepare, day1.Phase);
        Assert.Equal(1, day1.DayIndex);
        Assert.Equal(2, day1.TotalDays);

        Assert.Equal(WellnessPhasePlanner.PhaseFasting, day3.Phase);
        Assert.Equal(1, day3.DayIndex);
        Assert.Equal(5, day3.TotalDays);

        Assert.Equal(WellnessPhasePlanner.PhaseFasting, day7.Phase);
        Assert.Equal(5, day7.DayIndex);
        Assert.Equal(5, day7.TotalDays);

        Assert.Equal(WellnessPhasePlanner.PhaseRefeed, day8.Phase);
        Assert.Equal(1, day8.DayIndex);
        Assert.Equal(3, day8.TotalDays);

        Assert.Equal(WellnessPhasePlanner.PhaseRefeed, day10.Phase);
        Assert.Equal(3, day10.DayIndex);
        Assert.Equal(3, day10.TotalDays);
    }
}
