using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SKVI.Application.Interfaces;

namespace e_learning_server.Controllers;

[ApiController]
[Route("api/admin/dashboard")]
[Authorize(Roles = "ADMIN")]
public class DashboardController : ControllerBase
{
    private readonly IDashboardService _dashboardService;
    private readonly ILogger<DashboardController> _logger;

    public DashboardController(IDashboardService dashboardService, ILogger<DashboardController> logger)
    {
        _dashboardService = dashboardService;
        _logger = logger;
    }

    /// <summary>
    /// Get admin dashboard statistics
    /// </summary>
    [HttpGet("stats")]
    public async Task<IActionResult> GetStats(CancellationToken cancellationToken = default)
    {
        try
        {
            var stats = await _dashboardService.GetDashboardStatsAsync(cancellationToken);
            return Ok(stats);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error retrieving dashboard stats");
            return StatusCode(500, new { message = "Failed to retrieve dashboard statistics" });
        }
    }

    /// <summary>
    /// Get recent orders for admin dashboard
    /// </summary>
    [HttpGet("recent-orders")]
    public async Task<IActionResult> GetRecentOrders([FromQuery] int limit = 10, CancellationToken cancellationToken = default)
    {
        try
        {
            var orders = await _dashboardService.GetRecentOrdersAsync(limit, cancellationToken);
            return Ok(orders);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error retrieving recent orders");
            return StatusCode(500, new { message = "Failed to retrieve recent orders" });
        }
    }

    /// <summary>
    /// Get top agents/cabins for admin dashboard
    /// </summary>
    [HttpGet("top-agents")]
    public async Task<IActionResult> GetTopAgents([FromQuery] int limit = 5, CancellationToken cancellationToken = default)
    {
        try
        {
            var agents = await _dashboardService.GetTopAgentsAsync(limit, cancellationToken);
            return Ok(agents);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error retrieving top agents");
            return StatusCode(500, new { message = "Failed to retrieve top agents" });
        }
    }
}
