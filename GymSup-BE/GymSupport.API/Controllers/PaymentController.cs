using GymSupport.Repository.Interfaces;
using GymSupport.Repository.Models.Entities;
using GymSupport.Service.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using PayOS;
using PayOS.Models;
using PayOS.Models.Webhooks;
using PayOS.Models.V2.PaymentRequests;
using PayOS.Models.V2.PaymentRequests.Invoices;
using System;
using System.Collections.Generic;
using System.Security.Claims;
using System.Threading.Tasks;

namespace GymSupport.API.Controllers
{
    [ApiController]
    [Route("api/subscriptions")]
    [Authorize]
    public class PaymentController : ControllerBase
    {
        private readonly PayOSClient _payOS;
        private readonly ISubscriptionService _subscriptionService;
        private readonly IPaymentRepository _paymentRepository;

        public PaymentController(
            PayOSClient payOS,
            ISubscriptionService subscriptionService,
            IPaymentRepository paymentRepository)
        {
            _payOS = payOS;
            _subscriptionService = subscriptionService;
            _paymentRepository = paymentRepository;
        }

        [HttpPost("purchase")]
        public async Task<IActionResult> CreatePurchase([FromBody] CreatePurchaseDto dto)
        {
            try
            {
                var userId = User.FindFirstValue(ClaimTypes.NameIdentifier)
                    ?? User.FindFirstValue(System.IdentityModel.Tokens.Jwt.JwtRegisteredClaimNames.Sub);

                if (string.IsNullOrWhiteSpace(userId))
                    return Unauthorized(new { message = "User ID not found in token." });

                if (string.IsNullOrWhiteSpace(dto.PlanId))
                    return BadRequest(new { message = "PlanId is required." });

                var plan = await _subscriptionService.GetSubscriptionPlanAsync(dto.PlanId);
                if (plan == null)
                    return BadRequest(new { message = "Subscription plan not found." });

                // Generate unique 64-bit integer order code based on current timestamp
                long orderCode = long.Parse(DateTime.UtcNow.ToString("yyMMddHHmmssfff"));

                // Create Pending Payment record in Database
                var payment = new Payment
                {
                    UserId = userId,
                    PlanId = plan.Id,
                    PlanName = plan.Name,
                    // OrderId has a unique MongoDB index. Leaving it as an empty
                    // string makes every PayOS payment after the first one fail
                    // with E11000 duplicate key, even though the index is sparse.
                    OrderId = $"payos:{orderCode}",
                    Amount = plan.Price,
                    PaymentMethod = "PayOS",
                    Status = "Pending",
                    OrderCode = orderCode,
                    CreatedAt = DateTime.UtcNow,
                    UpdatedAt = DateTime.UtcNow
                };
                await _paymentRepository.CreateAsync(payment);

                // Setup PayOS payment data
                if (!Uri.TryCreate(dto.CancelUrl, UriKind.Absolute, out var cancelUri) ||
                    !Uri.TryCreate(dto.ReturnUrl, UriKind.Absolute, out var returnUri) ||
                    (cancelUri.Scheme != Uri.UriSchemeHttp && cancelUri.Scheme != Uri.UriSchemeHttps) ||
                    (returnUri.Scheme != Uri.UriSchemeHttp && returnUri.Scheme != Uri.UriSchemeHttps))
                {
                    return BadRequest(new { message = "CancelUrl and ReturnUrl must be valid HTTP(S) URLs." });
                }

                var cancelUrl = cancelUri.ToString();
                var returnUrl = returnUri.ToString();

                var items = new List<PaymentLinkItem>
                {
                    new PaymentLinkItem
                    {
                        Name = plan.Name,
                        Quantity = 1,
                        Price = (long)plan.Price
                    }
                };

                var paymentRequest = new CreatePaymentLinkRequest
                {
                    OrderCode = orderCode,
                    Amount = (int)plan.Price,
                    Description = $"Mua goi {plan.Name}",
                    Items = items,
                    CancelUrl = cancelUrl,
                    ReturnUrl = returnUrl
                };

                var result = await _payOS.PaymentRequests.CreateAsync(paymentRequest);
                return Ok(new
                {
                    checkoutUrl = result.CheckoutUrl,
                    qrCode = result.QrCode,
                    orderCode = orderCode
                });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = "Error creating payment link", error = ex.Message });
            }
        }

        [HttpGet("payment-status/{orderCode}")]
        public async Task<IActionResult> GetPaymentStatus(long orderCode)
        {
            try
            {
                var payment = await _paymentRepository.GetByOrderCodeAsync(orderCode);
                if (payment == null)
                    return NotFound(new { message = "Payment transaction not found." });

                var userId = User.FindFirstValue(ClaimTypes.NameIdentifier)
                    ?? User.FindFirstValue(System.IdentityModel.Tokens.Jwt.JwtRegisteredClaimNames.Sub);
                if (string.IsNullOrWhiteSpace(userId) || payment.UserId != userId)
                    return Forbid();

                // Fallback: If local status is Pending, query PayOS API directly to check status
                if (payment.Status == "Pending")
                {
                    try
                    {
                        var payOsInfo = await _payOS.PaymentRequests.GetAsync(orderCode);
                        if (payOsInfo != null && payOsInfo.Status.ToString().Equals("PAID", StringComparison.OrdinalIgnoreCase))
                        {
                            // Activate VIP before marking the payment as paid. If activation
                            // fails, the next poll can safely retry instead of leaving a Paid
                            // payment with no active subscription.
                            var plan = await _subscriptionService.GetSubscriptionPlanAsync(payment.PlanId);
                            int durationMonths = plan != null ? plan.DurationMonths : 1;
                            var currentSubscription = await _subscriptionService
                                .GetUserCurrentSubscriptionAsync(payment.UserId);
                            var extensionStart = currentSubscription != null &&
                                currentSubscription.Status.Equals("active", StringComparison.OrdinalIgnoreCase) &&
                                currentSubscription.EndDate > DateTime.UtcNow
                                    ? currentSubscription.EndDate
                                    : DateTime.UtcNow;
                            var expiryDate = extensionStart.AddMonths(durationMonths);

                            await _subscriptionService.ActivateVerifiedSubscriptionAsync(
                                payment.UserId,
                                payment.PlanId,
                                expiryDate
                            );

                            payment.Status = "Paid";
                            payment.PaidAt = DateTime.UtcNow;
                            payment.UpdatedAt = DateTime.UtcNow;
                            await _paymentRepository.UpdateAsync(payment);
                        }
                        else if (payOsInfo != null && (payOsInfo.Status.ToString().Equals("CANCELLED", StringComparison.OrdinalIgnoreCase) || 
                                                       payOsInfo.Status.ToString().Equals("EXPIRED", StringComparison.OrdinalIgnoreCase)))
                        {
                            payment.Status = "Failed";
                            payment.UpdatedAt = DateTime.UtcNow;
                            await _paymentRepository.UpdateAsync(payment);
                        }
                    }
                    catch (Exception ex)
                    {
                        Console.WriteLine($"[PayOS Sync Fallback Error]: {ex.Message}");
                    }
                }

                // Repair payments that were marked Paid by an older version before
                // subscription activation completed.
                if (payment.Status.Equals("Paid", StringComparison.OrdinalIgnoreCase))
                {
                    var currentSubscription = await _subscriptionService.GetUserCurrentSubscriptionAsync(payment.UserId);
                    if (currentSubscription == null ||
                        !currentSubscription.Status.Equals("active", StringComparison.OrdinalIgnoreCase))
                    {
                        var plan = await _subscriptionService.GetSubscriptionPlanAsync(payment.PlanId);
                        var durationMonths = plan?.DurationMonths ?? 1;
                        await _subscriptionService.ActivateVerifiedSubscriptionAsync(
                            payment.UserId,
                            payment.PlanId,
                            DateTime.UtcNow.AddMonths(durationMonths));
                    }
                }

                return Ok(new
                {
                    orderCode = payment.OrderCode,
                    status = payment.Status,
                    planName = payment.PlanName,
                    amount = payment.Amount
                });
            }
            catch (Exception ex)
            {
                return StatusCode(500, new { message = "Error checking payment status", error = ex.Message });
            }
        }

        [HttpPost("payos-webhook")]
        [AllowAnonymous]
        public async Task<IActionResult> PayOSWebhook([FromBody] Webhook webhookData)
        {
            try
            {
                // Verify signature and decrypt Webhook payload
                var verifiedData = await _payOS.Webhooks.VerifyAsync(webhookData);
                if (verifiedData == null)
                    return BadRequest(new { message = "Invalid signature." });

                if (!string.Equals(verifiedData.Code, "00", StringComparison.OrdinalIgnoreCase))
                    return Ok(new { message = "Non-successful payment event ignored." });

                long orderCode = verifiedData.OrderCode;
                var payment = await _paymentRepository.GetByOrderCodeAsync(orderCode);
                if (payment != null && payment.Status == "Pending")
                {
                    // Get Plan to find duration months
                    var plan = await _subscriptionService.GetSubscriptionPlanAsync(payment.PlanId);
                    int durationMonths = plan != null ? plan.DurationMonths : 1;
                    var currentSubscription = await _subscriptionService
                        .GetUserCurrentSubscriptionAsync(payment.UserId);
                    var extensionStart = currentSubscription != null &&
                        currentSubscription.Status.Equals("active", StringComparison.OrdinalIgnoreCase) &&
                        currentSubscription.EndDate > DateTime.UtcNow
                            ? currentSubscription.EndDate
                            : DateTime.UtcNow;
                    var expiryDate = extensionStart.AddMonths(durationMonths);

                    // Activate subscription
                    await _subscriptionService.ActivateVerifiedSubscriptionAsync(
                        payment.UserId,
                        payment.PlanId,
                        expiryDate
                    );

                    payment.Status = "Paid";
                    payment.PaidAt = DateTime.UtcNow;
                    payment.UpdatedAt = DateTime.UtcNow;
                    await _paymentRepository.UpdateAsync(payment);
                }

                return Ok(new { message = "Webhook processed successfully." });
            }
            catch (Exception ex)
            {
                return BadRequest(new { message = "Error processing webhook", error = ex.Message });
            }
        }
    }

    public class CreatePurchaseDto
    {
        public string PlanId { get; set; } = string.Empty;
        public string CancelUrl { get; set; } = string.Empty;
        public string ReturnUrl { get; set; } = string.Empty;
    }
}
