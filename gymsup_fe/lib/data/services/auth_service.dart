import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_constants.dart';
import '../../core/network/api_client.dart';

class AuthService {
  final ApiClient _apiClient = ApiClient();

  /// Đăng nhập - trả về JWT token nếu thành công
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await _apiClient.post(
        AppConstants.login,
        {'email': email, 'password': password},
        requireAuth: false,
      );

      final data = ApiClient.decodeResponse(response);

      if (response.statusCode == 200) {
        // Lưu token và userId vào shared preferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(AppConstants.tokenKey, data['token'] ?? '');
        await prefs.setString(AppConstants.userIdKey, data['userId'] ?? '');
        await prefs.setString(AppConstants.userEmailKey, email);
        return {'success': true, 'data': data};
      }

      return {
        'success': false,
        'message': data['message'] ?? 'Đăng nhập thất bại',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Không kết nối được tới server. Hãy kiểm tra backend đã chạy chưa.',
      };
    }
  }

  /// Đăng ký tài khoản mới
  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String fullName,
  }) async {
    try {
      final response = await _apiClient.post(
        AppConstants.register,
        {'email': email, 'password': password, 'fullName': fullName},
        requireAuth: false,
      );

      final data = ApiClient.decodeResponse(response);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'data': data};
      }

      return {
        'success': false,
        'message': data['message'] ?? 'Đăng ký thất bại',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Không kết nối được tới server.',
      };
    }
  }

  /// Đăng xuất - xóa token
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.tokenKey);
    await prefs.remove(AppConstants.userIdKey);
    await prefs.remove(AppConstants.userEmailKey);
  }

  /// Kiểm tra xem người dùng đã đăng nhập chưa
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(AppConstants.tokenKey);
    return token != null && token.isNotEmpty;
  }

  /// Lấy userId hiện tại
  Future<String?> getCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.userIdKey);
  }
}
