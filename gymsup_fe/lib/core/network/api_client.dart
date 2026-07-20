import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';

class ApiClient {
  /// Gọi khi bất kỳ request nào trả về 401 (token thiếu/hết hạn) - đăng ký
  /// một lần ở main.dart để tự động đăng xuất và điều hướng về màn đăng nhập,
  /// thay vì để mỗi màn hình tự hiện thông báo lỗi kết nối chung chung.
  static void Function()? onUnauthorized;

  void _checkUnauthorized(http.Response response, bool requireAuth) {
    // Chỉ coi là "phiên hết hạn" khi request này lẽ ra phải có token
    // (login/register dùng requireAuth:false nên sai mật khẩu không kích hoạt đăng xuất).
    if (requireAuth && response.statusCode == 401) {
      onUnauthorized?.call();
    }
  }

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
    final response = await http.get(url, headers: headers);
    _checkUnauthorized(response, requireAuth);
    return response;
  }

  // --- POST ---
  Future<http.Response> post(
    String endpoint,
    Map<String, dynamic> body, {
    bool requireAuth = true,
  }) async {
    final headers = await _buildHeaders(requireAuth: requireAuth);
    final url = Uri.parse('${AppConstants.baseUrl}$endpoint');
    final response = await http.post(
      url,
      headers: headers,
      body: jsonEncode(body),
    );
    _checkUnauthorized(response, requireAuth);
    return response;
  }

  // --- PUT ---
  Future<http.Response> put(
    String endpoint,
    Map<String, dynamic> body, {
    bool requireAuth = true,
  }) async {
    final headers = await _buildHeaders(requireAuth: requireAuth);
    final url = Uri.parse('${AppConstants.baseUrl}$endpoint');
    final response = await http.put(
      url,
      headers: headers,
      body: jsonEncode(body),
    );
    _checkUnauthorized(response, requireAuth);
    return response;
  }

  // --- PATCH ---
  Future<http.Response> patch(
    String endpoint,
    Map<String, dynamic> body, {
    bool requireAuth = true,
  }) async {
    final headers = await _buildHeaders(requireAuth: requireAuth);
    final url = Uri.parse('${AppConstants.baseUrl}$endpoint');
    final response = await http.patch(
      url,
      headers: headers,
      body: jsonEncode(body),
    );
    _checkUnauthorized(response, requireAuth);
    return response;
  }

  // --- DELETE ---
  Future<http.Response> delete(
    String endpoint, {
    bool requireAuth = true,
  }) async {
    final headers = await _buildHeaders(requireAuth: requireAuth);
    final url = Uri.parse('${AppConstants.baseUrl}$endpoint');
    final response = await http.delete(url, headers: headers);
    _checkUnauthorized(response, requireAuth);
    return response;
  }

  // --- POST multipart (upload file, vd: ảnh/video cho AI phân tích) ---
  Future<http.Response> postMultipart(
    String endpoint, {
    required String fileField,
    required List<int> fileBytes,
    required String filename,
    String? contentType,
    Map<String, String> fields = const {},
    bool requireAuth = true,
  }) async {
    final headers = await _buildHeaders(requireAuth: requireAuth);
    headers.remove('Content-Type'); // để http tự set multipart boundary
    final url = Uri.parse('${AppConstants.baseUrl}$endpoint');
    final request = http.MultipartRequest('POST', url)
      ..headers.addAll(headers)
      ..fields.addAll(fields)
      ..files.add(
        http.MultipartFile.fromBytes(
          fileField,
          fileBytes,
          filename: filename,
          // Không set contentType thì package http mặc định gửi
          // application/octet-stream, khiến backend luôn từ chối vì không
          // khớp danh sách image/jpeg|png|webp - phải truyền đúng mimeType thật.
          contentType: contentType != null
              ? MediaType.parse(contentType)
              : null,
        ),
      );
    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    _checkUnauthorized(response, requireAuth);
    return response;
  }

  // Helper: decode response body sang dynamic (có thể là Map hoặc List)
  static dynamic decodeResponse(http.Response response) {
    return jsonDecode(utf8.decode(response.bodyBytes));
  }
}
