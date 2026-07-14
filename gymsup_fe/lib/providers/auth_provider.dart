import 'package:flutter/foundation.dart';
import '../data/services/auth_service.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  AuthStatus _status = AuthStatus.unknown;
  String? _userId;
  String? _errorMessage;
  bool _isLoading = false;
  bool _justLoggedIn = false;

  AuthStatus get status => _status;
  String? get userId => _userId;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get justLoggedIn => _justLoggedIn;

  void clearJustLoggedIn() {
    _justLoggedIn = false;
  }

  /// Kiểm tra trạng thái đăng nhập khi app khởi động
  Future<void> checkAuthStatus() async {
    final loggedIn = await _authService.isLoggedIn();
    if (loggedIn) {
      _userId = await _authService.getCurrentUserId();
      _status = AuthStatus.authenticated;
    } else {
      _status = AuthStatus.unauthenticated;
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
      _status = AuthStatus.authenticated;
      _justLoggedIn = true;
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

  /// Đăng xuất
  Future<void> logout() async {
    await _authService.logout();
    _userId = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
