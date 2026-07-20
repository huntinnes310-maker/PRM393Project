using System.Net.Http.Headers;
using System.Security.Cryptography;
using System.Text;
using System.Text.Json;
using GymSupport.Repository.Interfaces;
using GymSupport.Repository.Models.Entities;
using GymSupport.Service.Interfaces;

namespace GymSupport.API.Services;

public interface IStorePurchaseService
{
    Task<StorePurchaseResult> VerifyAsync(string userId, VerifyStorePurchaseRequest request);
}

public sealed class StorePurchaseService : IStorePurchaseService
{
    private readonly IConfiguration _configuration;
    private readonly IHttpClientFactory _httpClientFactory;
    private readonly IPaymentRepository _payments;
    private readonly ISubscriptionPlanRepository _plans;
    private readonly ISubscriptionService _subscriptions;

    public StorePurchaseService(
        IConfiguration configuration,
        IHttpClientFactory httpClientFactory,
        IPaymentRepository payments,
        ISubscriptionPlanRepository plans,
        ISubscriptionService subscriptions)
    {
        _configuration = configuration;
        _httpClientFactory = httpClientFactory;
        _payments = payments;
        _plans = plans;
        _subscriptions = subscriptions;
    }

    public async Task<StorePurchaseResult> VerifyAsync(
        string userId,
        VerifyStorePurchaseRequest request)
    {
        if (string.IsNullOrWhiteSpace(request.ProductId) ||
            string.IsNullOrWhiteSpace(request.VerificationData))
        {
            throw new InvalidOperationException("Thiếu productId hoặc verificationData.");
        }

        var settings = GetSettings();
        var platform = request.Platform.Trim().ToLowerInvariant();
        var verified = platform switch
        {
            "android" => await VerifyGooglePlayAsync(request, settings),
            "ios" => await VerifyAppleAsync(request, settings),
            _ => throw new InvalidOperationException("Platform phải là android hoặc ios.")
        };

        var plan = (await _plans.GetActiveAsync()).FirstOrDefault(p =>
            p.Name.Equals(settings.PremiumPlanName, StringComparison.OrdinalIgnoreCase))
            ?? throw new InvalidOperationException(
                $"Không tìm thấy gói {settings.PremiumPlanName} đang hoạt động.");

        var existing = await _payments.GetByOrderIdAsync(verified.OrderId);
        if (existing != null && existing.UserId != userId)
            throw new InvalidOperationException("Giao dịch Store đã thuộc về tài khoản khác.");

        await _subscriptions.ActivateVerifiedSubscriptionAsync(
            userId,
            plan.Id,
            verified.ExpiresAt);

        if (existing == null)
        {
            try
            {
                await _payments.CreateAsync(new Payment
                {
                    UserId = userId,
                    PlanId = plan.Id,
                    PlanName = plan.Name,
                    Amount = plan.Price,
                    PaymentMethod = verified.PaymentMethod,
                    Status = "Paid",
                    OrderId = verified.OrderId,
                    RequestId = HashToken(request.VerificationData),
                    TransactionId = verified.TransactionId,
                    ProviderMessage = verified.Status,
                    PaidAt = verified.PurchasedAt,
                    CreatedAt = DateTime.UtcNow,
                    UpdatedAt = DateTime.UtcNow
                });
            }
            catch (Exception)
            {
                // Một request verify song song có thể đã chèn Payment cho cùng
                // OrderId (unique index chặn trùng). Nếu bản ghi đã tồn tại thì coi
                // như thành công — verify là idempotent; nếu không thì ném lại lỗi.
                var raced = await _payments.GetByOrderIdAsync(verified.OrderId);
                if (raced == null) throw;
            }
        }

        return new StorePurchaseResult(
            true,
            verified.ProductId,
            verified.ExpiresAt,
            "Premium đã được kích hoạt.");
    }

    private async Task<VerifiedStorePurchase> VerifyGooglePlayAsync(
        VerifyStorePurchaseRequest request,
        StoreBillingSettings settings)
    {
        if (request.ProductId != settings.AndroidProductId)
            throw new InvalidOperationException("Google Play product ID không hợp lệ.");
        if (string.IsNullOrWhiteSpace(settings.AndroidPackageName) ||
            string.IsNullOrWhiteSpace(settings.GoogleServiceAccountJsonPath))
        {
            throw new InvalidOperationException("Chưa cấu hình Google Play service account.");
        }

        var accessToken = await GetGoogleAccessTokenAsync(settings.GoogleServiceAccountJsonPath);
        var url = "https://androidpublisher.googleapis.com/androidpublisher/v3/applications/" +
            $"{Uri.EscapeDataString(settings.AndroidPackageName)}/purchases/subscriptionsv2/tokens/" +
            Uri.EscapeDataString(request.VerificationData);
        var client = _httpClientFactory.CreateClient();
        using var message = new HttpRequestMessage(HttpMethod.Get, url);
        message.Headers.Authorization = new AuthenticationHeaderValue("Bearer", accessToken);
        using var response = await client.SendAsync(message);
        var body = await response.Content.ReadAsStringAsync();
        if (!response.IsSuccessStatusCode)
            throw new InvalidOperationException($"Google Play từ chối purchase token: {body}");

        using var document = JsonDocument.Parse(body);
        var root = document.RootElement;
        var state = GetString(root, "subscriptionState");
        if (state is not "SUBSCRIPTION_STATE_ACTIVE" and not "SUBSCRIPTION_STATE_IN_GRACE_PERIOD")
            throw new InvalidOperationException($"Google Play subscription không hoạt động: {state}");

        if (!root.TryGetProperty("lineItems", out var lineItems) ||
            lineItems.ValueKind != JsonValueKind.Array)
            throw new InvalidOperationException("Google Play không trả về subscription line item.");

        JsonElement? matched = null;
        foreach (var item in lineItems.EnumerateArray())
        {
            if (GetString(item, "productId") == request.ProductId)
            {
                matched = item;
                break;
            }
        }
        if (!matched.HasValue)
            throw new InvalidOperationException("Purchase token không thuộc product đã yêu cầu.");

        var expiryText = GetString(matched.Value, "expiryTime");
        if (!DateTime.TryParse(expiryText, null,
                System.Globalization.DateTimeStyles.AdjustToUniversal, out var expiresAt) ||
            expiresAt <= DateTime.UtcNow)
        {
            throw new InvalidOperationException("Google Play subscription đã hết hạn.");
        }

        var orderId = GetString(root, "latestOrderId");
        if (string.IsNullOrWhiteSpace(orderId)) orderId = HashToken(request.VerificationData);

        if (GetString(root, "acknowledgementState") == "ACKNOWLEDGEMENT_STATE_PENDING")
            await AcknowledgeGooglePurchaseAsync(request, settings, accessToken);

        return new VerifiedStorePurchase(
            request.ProductId,
            orderId,
            orderId,
            "GOOGLE_PLAY",
            state,
            expiresAt.ToUniversalTime(),
            DateTime.UtcNow);
    }

    private async Task AcknowledgeGooglePurchaseAsync(
        VerifyStorePurchaseRequest request,
        StoreBillingSettings settings,
        string accessToken)
    {
        var url = "https://androidpublisher.googleapis.com/androidpublisher/v3/applications/" +
            $"{Uri.EscapeDataString(settings.AndroidPackageName)}/purchases/subscriptions/" +
            $"{Uri.EscapeDataString(request.ProductId)}/tokens/" +
            $"{Uri.EscapeDataString(request.VerificationData)}:acknowledge";
        var client = _httpClientFactory.CreateClient();
        using var message = new HttpRequestMessage(HttpMethod.Post, url)
        {
            Content = new StringContent("{}", Encoding.UTF8, "application/json")
        };
        message.Headers.Authorization = new AuthenticationHeaderValue("Bearer", accessToken);
        using var response = await client.SendAsync(message);
        if (!response.IsSuccessStatusCode)
            throw new InvalidOperationException("Không acknowledge được Google Play purchase.");
    }

    private async Task<string> GetGoogleAccessTokenAsync(string jsonPath)
    {
        if (!File.Exists(jsonPath))
            throw new InvalidOperationException("Không tìm thấy Google service-account JSON.");
        using var json = JsonDocument.Parse(await File.ReadAllTextAsync(jsonPath));
        var email = GetString(json.RootElement, "client_email");
        var privateKey = GetString(json.RootElement, "private_key");
        if (string.IsNullOrWhiteSpace(email) || string.IsNullOrWhiteSpace(privateKey))
            throw new InvalidOperationException("Google service-account JSON không hợp lệ.");

        var now = DateTimeOffset.UtcNow.ToUnixTimeSeconds();
        var header = Base64Url(JsonSerializer.SerializeToUtf8Bytes(new { alg = "RS256", typ = "JWT" }));
        var payload = Base64Url(JsonSerializer.SerializeToUtf8Bytes(new
        {
            iss = email,
            scope = "https://www.googleapis.com/auth/androidpublisher",
            aud = "https://oauth2.googleapis.com/token",
            iat = now,
            exp = now + 3600
        }));
        var unsigned = $"{header}.{payload}";
        using var rsa = RSA.Create();
        rsa.ImportFromPem(privateKey);
        var signature = Base64Url(rsa.SignData(
            Encoding.UTF8.GetBytes(unsigned),
            HashAlgorithmName.SHA256,
            RSASignaturePadding.Pkcs1));

        var client = _httpClientFactory.CreateClient();
        using var content = new FormUrlEncodedContent(new Dictionary<string, string>
        {
            ["grant_type"] = "urn:ietf:params:oauth:grant-type:jwt-bearer",
            ["assertion"] = $"{unsigned}.{signature}"
        });
        using var response = await client.PostAsync("https://oauth2.googleapis.com/token", content);
        var body = await response.Content.ReadAsStringAsync();
        if (!response.IsSuccessStatusCode)
            throw new InvalidOperationException($"Không lấy được Google access token: {body}");
        using var tokenJson = JsonDocument.Parse(body);
        return GetString(tokenJson.RootElement, "access_token");
    }

    private async Task<VerifiedStorePurchase> VerifyAppleAsync(
        VerifyStorePurchaseRequest request,
        StoreBillingSettings settings)
    {
        if (request.ProductId != settings.AppleProductId)
            throw new InvalidOperationException("App Store product ID không hợp lệ.");
        if (string.IsNullOrWhiteSpace(settings.AppleSharedSecret))
            throw new InvalidOperationException("Chưa cấu hình App Store shared secret.");

        var payload = JsonSerializer.Serialize(new Dictionary<string, object?>
        {
            ["receipt-data"] = request.VerificationData,
            ["password"] = settings.AppleSharedSecret,
            ["exclude-old-transactions"] = false
        });

        var result = await PostAppleReceiptAsync(
            "https://buy.itunes.apple.com/verifyReceipt",
            payload);
        if (GetInt(result.RootElement, "status") == 21007)
        {
            result.Dispose();
            result = await PostAppleReceiptAsync(
                "https://sandbox.itunes.apple.com/verifyReceipt",
                payload);
        }
        using (result)
        {
            var status = GetInt(result.RootElement, "status");
            if (status != 0)
                throw new InvalidOperationException($"App Store receipt không hợp lệ: {status}");
            if (!result.RootElement.TryGetProperty("latest_receipt_info", out var receipts) ||
                receipts.ValueKind != JsonValueKind.Array)
                throw new InvalidOperationException("App Store không trả về subscription receipt.");

            JsonElement? latest = null;
            long latestExpiry = 0;
            foreach (var item in receipts.EnumerateArray())
            {
                if (GetString(item, "product_id") != request.ProductId) continue;
                _ = long.TryParse(GetString(item, "expires_date_ms"), out var expiry);
                if (expiry > latestExpiry) { latestExpiry = expiry; latest = item; }
            }
            if (!latest.HasValue || latestExpiry <= DateTimeOffset.UtcNow.ToUnixTimeMilliseconds())
                throw new InvalidOperationException("App Store subscription đã hết hạn.");

            var transactionId = GetString(latest.Value, "transaction_id");
            return new VerifiedStorePurchase(
                request.ProductId,
                transactionId,
                transactionId,
                "APP_STORE",
                "active",
                DateTimeOffset.FromUnixTimeMilliseconds(latestExpiry).UtcDateTime,
                DateTime.UtcNow);
        }
    }

    private async Task<JsonDocument> PostAppleReceiptAsync(string url, string payload)
    {
        var client = _httpClientFactory.CreateClient();
        using var response = await client.PostAsync(
            url,
            new StringContent(payload, Encoding.UTF8, "application/json"));
        var body = await response.Content.ReadAsStringAsync();
        if (!response.IsSuccessStatusCode)
            throw new InvalidOperationException($"App Store verifyReceipt lỗi: {body}");
        return JsonDocument.Parse(body);
    }

    private StoreBillingSettings GetSettings() =>
        _configuration.GetSection("StoreBilling").Get<StoreBillingSettings>() ?? new();

    private static string GetString(JsonElement element, string name) =>
        element.TryGetProperty(name, out var value) ? value.GetString() ?? string.Empty : string.Empty;
    private static int GetInt(JsonElement element, string name) =>
        element.TryGetProperty(name, out var value) && value.TryGetInt32(out var parsed) ? parsed : -1;
    private static string HashToken(string value) =>
        Convert.ToHexString(SHA256.HashData(Encoding.UTF8.GetBytes(value))).ToLowerInvariant();
    private static string Base64Url(byte[] value) =>
        Convert.ToBase64String(value).TrimEnd('=').Replace('+', '-').Replace('/', '_');
}

public sealed class StoreBillingSettings
{
    public string PremiumPlanName { get; set; } = "Premium";
    public string AndroidPackageName { get; set; } = string.Empty;
    public string AndroidProductId { get; set; } = "gymsupport_premium_monthly";
    public string GoogleServiceAccountJsonPath { get; set; } = string.Empty;
    public string AppleProductId { get; set; } = "gymsupport_premium_monthly";
    public string AppleSharedSecret { get; set; } = string.Empty;
}

public sealed class VerifyStorePurchaseRequest
{
    public string Platform { get; set; } = string.Empty;
    public string ProductId { get; set; } = string.Empty;
    public string VerificationData { get; set; } = string.Empty;
    public string? TransactionId { get; set; }
}

public sealed record StorePurchaseResult(
    bool IsPremium,
    string ProductId,
    DateTime ExpiresAt,
    string Message);

internal sealed record VerifiedStorePurchase(
    string ProductId,
    string OrderId,
    string TransactionId,
    string PaymentMethod,
    string Status,
    DateTime ExpiresAt,
    DateTime PurchasedAt);
