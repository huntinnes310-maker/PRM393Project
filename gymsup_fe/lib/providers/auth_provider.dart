import 'package:flutter/foundation.dart';
import '../core/network/api_client.dart';
import '../data/services/auth_service.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final ApiClient _apiClient = ApiClient();

  AuthStatus _status = AuthStatus.unknown;
  String? _userId;
  String? _role;
  String? _errorMessage;
  bool _isLoading = false;
  bool _justLoggedIn = false;
  bool _needsOnboarding = false;

  AuthStatus get status => _status;
  String? get userId => _userId;
  String? get role => _role;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get justLoggedIn => _justLoggedIn;
  bool get isManager => _role == 'Manager';
  bool get isAdmin => _role == 'Admin';
  bool get isManagerOrAdmin => _role == 'Manager' || _role == 'Admin';
  bool get needsOnboarding => _needsOnboarding;

  /// Kiểm tra hồ sơ Customer đã đủ goal/heightCm/weightKg chưa.
  /// Manager/Admin không có hồ sơ Customer nên luôn bỏ qua.
  /// Lỗi mạng/parse khi kiểm tra sẽ "fail open" (coi như đã hoàn tất onboarding)
  /// vì màn hình khảo sát ở tab Profile vẫn là lối thoát để hoàn thiện hồ sơ sau.
  Future<void> _refreshOnboardingStatus() async {
    if (_role != 'Customer' || _userId == null) {
      _needsOnboarding = false;
      return;
    }
    try {
      final response = await _apiClient.get('/customer/user/$_userId');
      if (response.statusCode == 200) {
        final data = ApiClient.decodeResponse(response) as Map<String, dynamic>;
        final goal = (data['goal'] as String?) ?? '';
        final heightCm = (data['heightCm'] as num?) ?? 0;
        final weightKg = (data['weightKg'] as num?) ?? 0;
        _needsOnboarding = goal.isEmpty || heightCm <= 0 || weightKg <= 0;
      } else {
        _needsOnboarding = false;
      }
    } catch (e) {
      debugPrint('_refreshOnboardingStatus error: $e');
      _needsOnboarding = false;
    }
  }

  /// Gọi khi hoàn tất wizard onboarding để thoát khỏi màn hình onboarding.
  void markOnboardingComplete() {
    _needsOnboarding = false;
    notifyListeners();
  }

  void clearJustLoggedIn() {
    _justLoggedIn = false;
  }

  /// Kiểm tra trạng thái đăng nhập khi app khởi động
  Future<void> checkAuthStatus() async {
    final loggedIn = await _authService.isLoggedIn();
    if (loggedIn) {
      _userId = await _authService.getCurrentUserId();
      _role = await _authService.getCurrentUserRole();
      _status = AuthStatus.authenticated;
      await _refreshOnboardingStatus();
    } else {
      _status = AuthStatus.unauthenticated;
      _role = null;
    }
    notifyListeners();
  }

  /// Đăng nhập
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _authService.login(email, password);

    _isLoading = false;

    if (result['success']) {
      _userId = result['data']['userId'];
      _role = result['data']['role'];
      _status = AuthStatus.authenticated;
      _justLoggedIn = true;
      await _refreshOnboardingStatus();
      notifyListeners();
      return true;
    } else {
      _errorMessage = result['message'];
      notifyListeners();
      return false;
    }
  }

  /// Đăng ký
  Future<bool> register({
    required String email,
    required String password,
    required String fullName,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _authService.register(
      email: email,
      password: password,
      fullName: fullName,
    );

    _isLoading = false;

    if (result['success']) {
      notifyListeners();
      return true;
    } else {
      _errorMessage = result['message'];
      notifyListeners();
      return false;
    }
  }

  /// Đăng xuất - xóa token
  Future<void> logout() async {
    await _authService.logout();
    _userId = null;
    _role = null;
    _needsOnboarding = false;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
