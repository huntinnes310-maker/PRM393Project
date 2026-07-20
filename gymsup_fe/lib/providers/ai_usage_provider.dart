import 'package:flutter/material.dart';
import '../core/constants/app_constants.dart';
import '../core/network/api_client.dart';
import '../data/models/ai_usage_status.dart';

/// Theo dõi hạn mức dùng AI (chat/generate/analyze) của người dùng hiện tại,
/// dùng để hiển thị "X/Y lượt hôm nay" và khoá nút khi đã hết lượt.
class AiUsageProvider extends ChangeNotifier {
  final ApiClient _apiClient = ApiClient();

  AiUsageStatus? _status;
  bool _isLoading = false;

  AiUsageStatus? get status => _status;
  bool get isLoading => _isLoading;

  Future<void> refresh() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiClient.get(AppConstants.aiUsage);
      if (response.statusCode == 200) {
        final data = ApiClient.decodeResponse(response);
        _status = AiUsageStatus.fromJson(data as Map<String, dynamic>);
      }
    } catch (e) {
      debugPrint('AiUsageProvider.refresh error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
