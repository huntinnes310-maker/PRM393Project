import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';

class ApiClient {
  // Lấy JWT token từ shared preferences
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.tokenKey);
  }

  // Tạo headers mặc định (có kèm Authorization nếu có token)
  Future<Map<String, String>> _buildHeaders({bool requireAuth = true}) async {
    final headers = {'Content-Type': 'application/json'};
    if (requireAuth) {
      final token = await _getToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  // --- GET ---
  Future<http.Response> get(String endpoint, {bool requireAuth = true}) async {
    final headers = await _buildHeaders(requireAuth: requireAuth);
    final url = Uri.parse('${AppConstants.baseUrl}$endpoint');
    return await http.get(url, headers: headers);
  }

  // --- POST ---
  Future<http.Response> post(
    String endpoint,
    Map<String, dynamic> body, {
    bool requireAuth = true,
  }) async {
    final headers = await _buildHeaders(requireAuth: requireAuth);
    final url = Uri.parse('${AppConstants.baseUrl}$endpoint');
    return await http.post(url, headers: headers, body: jsonEncode(body));
  }

  // --- PUT ---
  Future<http.Response> put(
    String endpoint,
    Map<String, dynamic> body, {
    bool requireAuth = true,
  }) async {
    final headers = await _buildHeaders(requireAuth: requireAuth);
    final url = Uri.parse('${AppConstants.baseUrl}$endpoint');
    return await http.put(url, headers: headers, body: jsonEncode(body));
  }

  // --- PATCH ---
  Future<http.Response> patch(
    String endpoint,
    Map<String, dynamic> body, {
    bool requireAuth = true,
  }) async {
    final headers = await _buildHeaders(requireAuth: requireAuth);
    final url = Uri.parse('${AppConstants.baseUrl}$endpoint');
    return await http.patch(url, headers: headers, body: jsonEncode(body));
  }

  // --- DELETE ---
  Future<http.Response> delete(
    String endpoint, {
    bool requireAuth = true,
  }) async {
    final headers = await _buildHeaders(requireAuth: requireAuth);
    final url = Uri.parse('${AppConstants.baseUrl}$endpoint');
    return await http.delete(url, headers: headers);
  }

  // Helper: decode response body sang dynamic (có thể là Map hoặc List)
  static dynamic decodeResponse(http.Response response) {
    return jsonDecode(utf8.decode(response.bodyBytes));
  }
}
