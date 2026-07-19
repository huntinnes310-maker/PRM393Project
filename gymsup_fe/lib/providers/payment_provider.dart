import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../data/services/payment_service.dart';

class PaymentProvider extends ChangeNotifier {
  final PaymentService _paymentService = PaymentService();

  List<SubscriptionPlan> _plans = [];
  UserSubscriptionInfo? _mySubscription;
  bool _isLoading = false;
  String? _errorMessage;

  // Active checkout details
  String? _checkoutUrl;
  String? _qrCode;
  int? _orderCode;

  List<SubscriptionPlan> get plans => _plans;
  UserSubscriptionInfo? get mySubscription => _mySubscription;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  String? get checkoutUrl => _checkoutUrl;
  String? get qrCode => _qrCode;
  int? get orderCode => _orderCode;

  /// Fetch active packages
  Future<void> fetchActivePlans() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _plans = await _paymentService.getActivePlans();
    } catch (e) {
      _errorMessage = 'Không thể tải danh sách gói dịch vụ.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Fetch user subscription status
  Future<void> fetchMySubscription() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _mySubscription = await _paymentService.getMySubscription();
    } catch (e) {
      _errorMessage = 'Không thể tải thông tin gói đăng ký.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Create a transaction and generate QR
  Future<bool> startCheckout(String planId) async {
    _isLoading = true;
    _errorMessage = null;
    _checkoutUrl = null;
    _qrCode = null;
    _orderCode = null;
    notifyListeners();

    String? returnUrl;
    String? cancelUrl;

    if (kIsWeb) {
      try {
        final uri = Uri.base;
        final origin = '${uri.scheme}://${uri.host}${uri.port != 0 && uri.port != 80 && uri.port != 443 ? ":${uri.port}" : ""}';
        returnUrl = '$origin/#/home';
        cancelUrl = '$origin/#/subscription';
      } catch (_) {}
    }

    if (returnUrl == null || cancelUrl == null) {
      _errorMessage = kIsWeb
          ? 'Không thể xác định địa chỉ quay lại ứng dụng.'
          : 'Thanh toán PayOS hiện chỉ được hỗ trợ trên phiên bản web.';
      _isLoading = false;
      notifyListeners();
      return false;
    }

    try {
      final result = await _paymentService.createPurchase(
        planId: planId,
        returnUrl: returnUrl,
        cancelUrl: cancelUrl,
      );
      if (result != null) {
        _checkoutUrl = result['checkoutUrl'];
        _qrCode = result['qrCode'];
        _orderCode = result['orderCode'];
        notifyListeners();
        return true;
      } else {
        _errorMessage = 'Khởi tạo đơn hàng thanh toán thất bại.';
        return false;
      }
    } catch (e) {
      _errorMessage = 'Lỗi kết nối khi khởi tạo thanh toán.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Check if active transaction has been paid successfully
  Future<bool> checkPaymentSuccess() async {
    if (_orderCode == null) return false;
    try {
      final status = await _paymentService.getPaymentStatus(_orderCode!);
      if (status?.toLowerCase() == 'paid') {
        // Reset active checkout state
        _checkoutUrl = null;
        _qrCode = null;
        _orderCode = null;
        notifyListeners();
        // Refresh local subscription state
        await fetchMySubscription();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  void clearCheckout() {
    _checkoutUrl = null;
    _qrCode = null;
    _orderCode = null;
    notifyListeners();
  }
}
