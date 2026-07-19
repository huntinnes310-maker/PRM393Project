import '../../core/network/api_client.dart';

class SubscriptionPlan {
  final String id;
  final String name;
  final int durationMonths;
  final double price;
  final bool isActive;

  SubscriptionPlan({
    required this.id,
    required this.name,
    required this.durationMonths,
    required this.price,
    required this.isActive,
  });

  factory SubscriptionPlan.fromJson(Map<String, dynamic> json) {
    return SubscriptionPlan(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      durationMonths: json['durationMonths'] ?? 0,
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      isActive: json['isActive'] ?? true,
    );
  }
}

class UserSubscriptionInfo {
  final String planName;
  final DateTime? startDate;
  final DateTime? endDate;
  final int daysRemaining;
  final String status;

  UserSubscriptionInfo({
    required this.planName,
    this.startDate,
    this.endDate,
    required this.daysRemaining,
    required this.status,
  });

  factory UserSubscriptionInfo.fromJson(Map<String, dynamic> json) {
    return UserSubscriptionInfo(
      planName: json['planName'] ?? 'free',
      startDate: json['startDate'] != null ? DateTime.parse(json['startDate']) : null,
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
      daysRemaining: json['daysRemaining'] ?? 0,
      status: json['status'] ?? 'None',
    );
  }
}

class PaymentService {
  final ApiClient _apiClient = ApiClient();

  /// Get active subscription plans
  Future<List<SubscriptionPlan>> getActivePlans() async {
    try {
      final response = await _apiClient.get('/subscriptions/plans/active', requireAuth: false);
      if (response.statusCode == 200) {
        final List<dynamic> data = ApiClient.decodeResponse(response);
        return data.map((json) => SubscriptionPlan.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Create purchase transaction on PayOS
  Future<Map<String, dynamic>?> createPurchase({
    required String planId,
    required String cancelUrl,
    required String returnUrl,
  }) async {
    try {
      final response = await _apiClient.post(
        '/subscriptions/purchase',
        {
          'planId': planId,
          'cancelUrl': cancelUrl,
          'returnUrl': returnUrl,
        },
        requireAuth: true,
      );

      if (response.statusCode == 200) {
        return ApiClient.decodeResponse(response);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Get transaction status by orderCode
  Future<String?> getPaymentStatus(int orderCode) async {
    try {
      final response = await _apiClient.get('/subscriptions/payment-status/$orderCode', requireAuth: true);
      if (response.statusCode == 200) {
        final data = ApiClient.decodeResponse(response);
        return data['status']; // "Pending", "Paid", "Failed", etc.
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Get authenticated user's current subscription
  Future<UserSubscriptionInfo?> getMySubscription() async {
    try {
      final response = await _apiClient.get('/subscriptions/me', requireAuth: true);
      if (response.statusCode == 200) {
        final data = ApiClient.decodeResponse(response);
        // Backend returns Ok(new { message = "No active subscription" }) if empty
        if (data is Map<String, dynamic> && data.containsKey('message')) {
          return null;
        }
        return UserSubscriptionInfo.fromJson(data);
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
