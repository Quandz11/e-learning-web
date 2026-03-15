using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SKVI.Application.DTOs.Dashboard;
using SKVI.Application.Interfaces;
using System.Security.Claims;

namespace e_learning_server.Controllers;

[ApiController]
[Route("api/agent/dashboard")]
[Authorize(Roles = "CABIN_OWNER")]
public class AgentDashboardController : ControllerBase
{
    private readonly IAgentDashboardService _agentDashboardService;
    private readonly ILogger<AgentDashboardController> _logger;

    public AgentDashboardController(IAgentDashboardService agentDashboardService, ILogger<AgentDashboardController> logger)
    {
        _agentDashboardService = agentDashboardService;
        _logger = logger;
    }

    /// <summary>
    /// Get agent dashboard statistics for the current user
    /// </summary>
    [HttpGet("stats")]
    public async Task<IActionResult> GetStats(CancellationToken cancellationToken = default)
    {
        try
        {
            var agentId = GetCurrentUserId();
            var stats = await _agentDashboardService.GetStatsAsync(agentId, cancellationToken);
            return Ok(stats);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error retrieving agent dashboard stats");
            return StatusCode(500, new { message = "Failed to retrieve dashboard statistics" });
        }
    }

    /// <summary>
    /// Get sales chart data
    /// </summary>
    [HttpGet("sales-chart")]
    public async Task<IActionResult> GetSalesChart(
        [FromQuery] int month = 0,  // 0 = current month
        CancellationToken cancellationToken = default)
    {
        try
        {
            var agentId = GetCurrentUserId();
            var chartData = await _agentDashboardService.GetSalesChartAsync(agentId, month, cancellationToken);
            return Ok(chartData);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error retrieving sales chart");
            return StatusCode(500, new { message = "Failed to retrieve sales chart" });
        }
    }

    /// <summary>
    /// Get referrals with pagination and filtering
    /// </summary>
    [HttpGet("referrals")]
    public async Task<IActionResult> GetReferrals(
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 20,
        [FromQuery] string? status = null,
        CancellationToken cancellationToken = default)
    {
        try
        {
            var agentId = GetCurrentUserId();
            var referrals = await _agentDashboardService.GetReferralsAsync(agentId, page, pageSize, status, cancellationToken);
            return Ok(referrals);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error retrieving referrals");
            return StatusCode(500, new { message = "Failed to retrieve referrals" });
        }
    }

    /// <summary>
    /// Get commission breakdown and history
    /// </summary>
    [HttpGet("commission")]
    public async Task<IActionResult> GetCommission(CancellationToken cancellationToken = default)
    {
        try
        {
            var agentId = GetCurrentUserId();
            var commission = await _agentDashboardService.GetCommissionAsync(agentId, cancellationToken);
            return Ok(commission);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error retrieving commission");
            return StatusCode(500, new { message = "Failed to retrieve commission" });
        }
    }

    /// <summary>
    /// Get students enrolled through agent's referral
    /// </summary>
    [HttpGet("students")]
    public async Task<IActionResult> GetStudents(
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 20,
        CancellationToken cancellationToken = default)
    {
        try
        {
            var agentId = GetCurrentUserId();
            var students = await _agentDashboardService.GetStudentsAsync(agentId, page, pageSize, cancellationToken);
            return Ok(students);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error retrieving students");
            return StatusCode(500, new { message = "Failed to retrieve students" });
        }
    }

    /// <summary>
    /// Get agent leaderboard
    /// </summary>
    [HttpGet("leaderboard")]
    public async Task<IActionResult> GetLeaderboard(CancellationToken cancellationToken = default)
    {
        try
        {
            var leaderboard = await _agentDashboardService.GetLeaderboardAsync(cancellationToken);
            return Ok(leaderboard);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error retrieving leaderboard");
            return StatusCode(500, new { message = "Failed to retrieve leaderboard" });
        }
    }

    /// <summary>
    /// Generate a new referral link
    /// </summary>
    [HttpPost("referral-link")]
    public async Task<IActionResult> GenerateReferralLink(GenerateReferralLinkRequestDto request, CancellationToken cancellationToken = default)
    {
        try
        {
            var agentId = GetCurrentUserId();
            var link = await _agentDashboardService.GenerateReferralLinkAsync(agentId, request, cancellationToken);
            return Ok(link);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error generating referral link");
            return StatusCode(500, new { message = "Failed to generate referral link" });
        }
    }

    /// <summary>
    /// Get performance report for a specific month
    /// </summary>
    [HttpGet("report")]
    public async Task<IActionResult> GetReport(
        [FromQuery] int year,
        [FromQuery] int month,
        CancellationToken cancellationToken = default)
    {
        try
        {
            var agentId = GetCurrentUserId();
            var report = await _agentDashboardService.GetReportAsync(agentId, year, month, cancellationToken);
            return Ok(report);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error retrieving report");
            return StatusCode(500, new { message = "Failed to retrieve report" });
        }
    }

    private Guid GetCurrentUserId()
    {
        var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        return Guid.TryParse(userIdClaim, out var userId) ? userId : Guid.Empty;
    }
}
