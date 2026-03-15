using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SKVI.Application.DTOs.Dashboard;
using SKVI.Application.Interfaces;

namespace e_learning_server.Controllers;

[ApiController]
[Route("api/care/dashboard")]
[Authorize(Roles = "CARE")]
public class CareDashboardController : ControllerBase
{
    private readonly ICareDashboardService _careDashboardService;
    private readonly ILogger<CareDashboardController> _logger;

    public CareDashboardController(ICareDashboardService careDashboardService, ILogger<CareDashboardController> logger)
    {
        _careDashboardService = careDashboardService;
        _logger = logger;
    }

    /// <summary>
    /// Get care dashboard statistics
    /// </summary>
    [HttpGet("stats")]
    public async Task<IActionResult> GetStats(CancellationToken cancellationToken = default)
    {
        try
        {
            var stats = await _careDashboardService.GetStatsAsync(cancellationToken);
            return Ok(stats);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error retrieving care dashboard stats");
            return StatusCode(500, new { message = "Failed to retrieve dashboard statistics" });
        }
    }

    /// <summary>
    /// Get support tickets with pagination and filtering
    /// </summary>
    [HttpGet("support-tickets")]
    public async Task<IActionResult> GetSupportTickets(
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 20,
        [FromQuery] string? status = null,
        [FromQuery] string? search = null,
        CancellationToken cancellationToken = default)
    {
        try
        {
            var tickets = await _careDashboardService.GetSupportTicketsAsync(page, pageSize, status, search, cancellationToken);
            return Ok(tickets);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error retrieving support tickets");
            return StatusCode(500, new { message = "Failed to retrieve support tickets" });
        }
    }

    /// <summary>
    /// Get a specific support ticket
    /// </summary>
    [HttpGet("support-tickets/{ticketId}")]
    public async Task<IActionResult> GetSupportTicket(string ticketId, CancellationToken cancellationToken = default)
    {
        try
        {
            var ticket = await _careDashboardService.GetSupportTicketAsync(ticketId, cancellationToken);
            return Ok(ticket);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error retrieving support ticket {TicketId}", ticketId);
            return StatusCode(500, new { message = "Failed to retrieve support ticket" });
        }
    }

    /// <summary>
    /// Create a new support ticket
    /// </summary>
    [HttpPost("support-tickets")]
    [AllowAnonymous]  // Allow customers to create tickets
    public async Task<IActionResult> CreateSupportTicket(CreateSupportTicketDto request, CancellationToken cancellationToken = default)
    {
        try
        {
            var ticketId = await _careDashboardService.CreateSupportTicketAsync(request, cancellationToken);
            return Created($"/api/care/dashboard/support-tickets/{ticketId}", new { ticketId });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error creating support ticket");
            return StatusCode(500, new { message = "Failed to create support ticket" });
        }
    }

    /// <summary>
    /// Update support ticket status and assignment
    /// </summary>
    [HttpPut("support-tickets/{ticketId}")]
    public async Task<IActionResult> UpdateSupportTicket(string ticketId, UpdateSupportTicketDto request, CancellationToken cancellationToken = default)
    {
        try
        {
            await _careDashboardService.UpdateSupportTicketAsync(ticketId, request, cancellationToken);
            return Ok(new { message = "Ticket updated successfully" });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error updating support ticket {TicketId}", ticketId);
            return StatusCode(500, new { message = "Failed to update support ticket" });
        }
    }

    /// <summary>
    /// Get customers list with pagination and search
    /// </summary>
    [HttpGet("customers")]
    public async Task<IActionResult> GetCustomers(
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 20,
        [FromQuery] string? search = null,
        CancellationToken cancellationToken = default)
    {
        try
        {
            var customers = await _careDashboardService.GetCustomersAsync(page, pageSize, search, cancellationToken);
            return Ok(customers);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error retrieving customers");
            return StatusCode(500, new { message = "Failed to retrieve customers" });
        }
    }

    /// <summary>
    /// Get satisfaction feedback trend
    /// </summary>
    [HttpGet("satisfaction-trend")]
    public async Task<IActionResult> GetSatisfactionTrend(
        [FromQuery] int days = 30,
        CancellationToken cancellationToken = default)
    {
        try
        {
            var trend = await _careDashboardService.GetSatisfactionTrendAsync(days, cancellationToken);
            return Ok(trend);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error retrieving satisfaction trend");
            return StatusCode(500, new { message = "Failed to retrieve satisfaction trend" });
        }
    }

    /// <summary>
    /// Get inbox messages
    /// </summary>
    [HttpGet("messages")]
    public async Task<IActionResult> GetMessages(CancellationToken cancellationToken = default)
    {
        try
        {
            var messages = await _careDashboardService.GetInboxMessagesAsync(cancellationToken);
            return Ok(messages);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error retrieving messages");
            return StatusCode(500, new { message = "Failed to retrieve messages" });
        }
    }
}
