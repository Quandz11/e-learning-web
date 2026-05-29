using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SKVI.Application.DTOs.Payments;
using SKVI.Application.Interfaces;

namespace e_learning_server.Controllers;

[ApiController]
[Route("api/payments")]
public class PaymentsController : ControllerBase
{
    private readonly ICheckoutService _checkoutService;
    private readonly ILogger<PaymentsController> _logger;

    public PaymentsController(ICheckoutService checkoutService, ILogger<PaymentsController> logger)
    {
        _checkoutService = checkoutService;
        _logger = logger;
    }

    [HttpGet("referrals/preview")]
    [AllowAnonymous]
    public async Task<IActionResult> PreviewReferral([FromQuery] string? code, CancellationToken cancellationToken)
    {
        if (string.IsNullOrWhiteSpace(code))
        {
            return ApiError(StatusCodes.Status400BadRequest, "PAYMENT_REFERRAL_CODE_REQUIRED", "Referral code is required.");
        }

        try
        {
            var result = await _checkoutService.PreviewReferralAsync(code, cancellationToken);
            if (result == null)
            {
                return ApiError(StatusCodes.Status404NotFound, "PAYMENT_REFERRAL_NOT_FOUND", "Invalid referral code.");
            }

            return Ok(result);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error previewing referral code {ReferralCode}", code);
            return ApiError(StatusCodes.Status500InternalServerError, "PAYMENT_REFERRAL_PREVIEW_FAILED", "Failed to preview referral code.");
        }
    }

    [HttpPost("checkout")]
    [Authorize]
    public async Task<IActionResult> CreateCheckout([FromBody] CheckoutRequest request, CancellationToken cancellationToken)
    {
        try
        {
            var userId = GetUserId();
            var result = await _checkoutService.CreateCheckoutAsync(userId, request, cancellationToken);
            return Ok(result);
        }
        catch (UnauthorizedAccessException ex)
        {
            return ApiError(StatusCodes.Status401Unauthorized, "PAYMENT_UNAUTHORIZED", ex.Message);
        }
        catch (ArgumentException ex)
        {
            return ApiError(StatusCodes.Status400BadRequest, "PAYMENT_INVALID_REQUEST", ex.Message);
        }
        catch (InvalidOperationException ex)
        {
            return ApiError(StatusCodes.Status400BadRequest, "PAYMENT_OPERATION_INVALID", ex.Message);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error creating checkout");
            return ApiError(StatusCodes.Status500InternalServerError, "PAYMENT_CHECKOUT_FAILED", "Failed to create checkout.");
        }
    }

    [HttpGet("orders")]
    [Authorize]
    public async Task<IActionResult> GetMyOrders(CancellationToken cancellationToken)
    {
        try
        {
            var userId = GetUserId();
            var orders = await _checkoutService.GetUserOrdersAsync(userId, cancellationToken);
            return Ok(orders);
        }
        catch (UnauthorizedAccessException ex)
        {
            return ApiError(StatusCodes.Status401Unauthorized, "PAYMENT_UNAUTHORIZED", ex.Message);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error fetching user orders");
            return ApiError(StatusCodes.Status500InternalServerError, "PAYMENT_GET_ORDERS_FAILED", "Failed to fetch orders.");
        }
    }

    [HttpGet("orders/{orderId}")]
    [Authorize]
    public async Task<IActionResult> GetOrderStatus(
        string orderId,
        [FromQuery] bool refresh = true,
        CancellationToken cancellationToken = default)
    {
        if (!Guid.TryParse(orderId, out var orderGuid))
        {
            return ApiError(StatusCodes.Status400BadRequest, "PAYMENT_INVALID_ORDER_ID", "Invalid order id.");
        }

        try
        {
            var userId = GetUserId();
            var result = await _checkoutService.GetOrderStatusAsync(userId, orderGuid, refresh, cancellationToken);
            if (result == null)
            {
                return ApiError(StatusCodes.Status404NotFound, "PAYMENT_ORDER_NOT_FOUND", "Order not found.");
            }

            return Ok(result);
        }
        catch (UnauthorizedAccessException ex)
        {
            return ApiError(StatusCodes.Status401Unauthorized, "PAYMENT_UNAUTHORIZED", ex.Message);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error getting order status for {OrderId}", orderId);
            return ApiError(StatusCodes.Status500InternalServerError, "PAYMENT_GET_ORDER_STATUS_FAILED", "Failed to fetch order status.");
        }
    }

    [HttpGet("orders/by-code/{orderCode:int}")]
    [Authorize]
    public async Task<IActionResult> GetOrderStatusByCode(
        int orderCode,
        [FromQuery] bool refresh = true,
        CancellationToken cancellationToken = default)
    {
        try
        {
            var userId = GetUserId();
            var result = await _checkoutService.GetOrderStatusByCodeAsync(userId, orderCode, refresh, cancellationToken);
            if (result == null)
            {
                return ApiError(StatusCodes.Status404NotFound, "PAYMENT_ORDER_NOT_FOUND", "Order not found.");
            }

            return Ok(result);
        }
        catch (UnauthorizedAccessException ex)
        {
            return ApiError(StatusCodes.Status401Unauthorized, "PAYMENT_UNAUTHORIZED", ex.Message);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error getting order status for orderCode {OrderCode}", orderCode);
            return ApiError(StatusCodes.Status500InternalServerError, "PAYMENT_GET_ORDER_STATUS_FAILED", "Failed to fetch order status.");
        }
    }

    [HttpPost("webhook/payos")]
    [AllowAnonymous]
    public async Task<IActionResult> ReceivePayOSWebhook([FromBody] PayOSWebhookRequest request, CancellationToken cancellationToken)
    {
        try
        {
            await _checkoutService.HandlePayOSWebhookAsync(request, cancellationToken);
            return Ok(new { message = "Webhook received" });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error handling PayOS webhook");
            return Ok(new { message = "Webhook ignored" });
        }
    }

    [HttpPost("webhook/payos/confirm")]
    [Authorize(Roles = "ADMIN")]
    public async Task<IActionResult> ConfirmPayOSWebhook(CancellationToken cancellationToken)
    {
        try
        {
            await _checkoutService.ConfirmWebhookUrlAsync(cancellationToken);
            return Ok(new { message = "PayOS webhook URL confirmed" });
        }
        catch (InvalidOperationException ex)
        {
            return ApiError(StatusCodes.Status400BadRequest, "PAYMENT_WEBHOOK_CONFIRM_INVALID", ex.Message);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error confirming PayOS webhook URL");
            return ApiError(StatusCodes.Status500InternalServerError, "PAYMENT_WEBHOOK_CONFIRM_FAILED", "Failed to confirm PayOS webhook.");
        }
    }

    private Guid GetUserId()
    {
        var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (string.IsNullOrWhiteSpace(userIdClaim) || !Guid.TryParse(userIdClaim, out var userId))
        {
            throw new UnauthorizedAccessException("Invalid user ID");
        }

        return userId;
    }

    private IActionResult ApiError(int statusCode, string code, string message, object? errors = null)
    {
        return StatusCode(statusCode, new { code, message, errors });
    }
}
