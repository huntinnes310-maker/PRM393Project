import 'package:flutter/material.dart';
import '../core/network/api_client.dart';
import '../data/models/customer_profile.dart';

class ProfileProvider extends ChangeNotifier {
  final ApiClient _apiClient = ApiClient();

  CustomerProfile? _profile;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isSaving = false;
  String? _saveMessage;

  CustomerProfile? get profile => _profile;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isSaving => _isSaving;
  String? get saveMessage => _saveMessage;
  bool get hasProfile => _profile != null;

  /// Lấy thông tin hồ sơ cá nhân theo userId
  Future<void> fetchProfile(String userId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiClient.get('/customer/user/$userId');
      if (response.statusCode == 200) {
        final data = ApiClient.decodeResponse(response);
        _profile = CustomerProfile.fromJson(data as Map<String, dynamic>);
      } else if (response.statusCode == 404) {
        _profile = null; // Chưa có hồ sơ
      } else {
        _errorMessage = 'Không thể tải hồ sơ.';
      }
    } catch (e) {
      _errorMessage = 'Lỗi kết nối. Vui lòng thử lại.';
      debugPrint('fetchProfile error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Tạo hoặc cập nhật hồ sơ
  Future<bool> saveProfile({
    required String userId,
    required String gender,
    required int age,
    required int heightCm,
    required int weightKg,
    required String goal,
    required String experienceLevel,
    String? injuryNotes,
  }) async {
    _isSaving = true;
    _saveMessage = null;
    notifyListeners();

    try {
      final body = {
        'userId': userId,
        'gender': gender,
        'age': age,
        'heightCm': heightCm,
        'weightKg': weightKg,
        'goal': goal,
        'experienceLevel': experienceLevel,
        'injuryNotes': injuryNotes ?? '',
      };

      if (_profile == null) {
        // Chưa có hồ sơ → POST để tạo mới
        final response = await _apiClient.post('/customer', body);
        if (response.statusCode == 201 || response.statusCode == 200) {
          _saveMessage = 'Tạo hồ sơ thành công! 🎉';
          await fetchProfile(userId);
          return true;
        } else {
          _saveMessage = 'Không thể tạo hồ sơ.';
          return false;
        }
      } else {
        // Đã có hồ sơ → PUT để cập nhật
        final response = await _apiClient.put('/customer/${_profile!.id}', body);
        if (response.statusCode == 204 || response.statusCode == 200) {
          _saveMessage = 'Cập nhật hồ sơ thành công! ✅';
          await fetchProfile(userId);
          return true;
        } else {
          _saveMessage = 'Không thể cập nhật hồ sơ.';
          return false;
        }
      }
    } catch (e) {
      _saveMessage = 'Lỗi kết nối. Vui lòng thử lại.';
      debugPrint('saveProfile error: $e');
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  void clearSaveMessage() {
    _saveMessage = null;
    notifyListeners();
  }
}
