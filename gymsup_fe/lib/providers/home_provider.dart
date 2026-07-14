import 'package:flutter/material.dart';
import '../core/network/api_client.dart';
import '../core/constants/app_constants.dart';
import '../data/models/home_data.dart';

class HomeProvider extends ChangeNotifier {
  final ApiClient _apiClient = ApiClient();

  HomeData? _homeData;
  bool _isLoading = false;
  String? _errorMessage;

  HomeData? get homeData => _homeData;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Gọi API lấy dữ liệu trang chủ
  Future<void> fetchHomeData(String userId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiClient.get('${AppConstants.home}/$userId');
      final data = ApiClient.decodeResponse(response);

      if (response.statusCode == 200) {
        _homeData = HomeData.fromJson(data);
      } else {
        _errorMessage = data['message'] ?? 'Không thể tải dữ liệu trang chủ.';
      }
    } catch (e) {
      _errorMessage = 'Lỗi kết nối tới server. Vui lòng kiểm tra lại.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearHomeData() {
    _homeData = null;
    notifyListeners();
  }
}
