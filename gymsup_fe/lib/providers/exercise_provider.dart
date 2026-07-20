import 'package:flutter/material.dart';
import '../core/network/api_client.dart';
import '../core/constants/app_constants.dart';
import '../data/models/exercise.dart';
import '../data/models/muscle.dart';

class ExerciseProvider extends ChangeNotifier {
  final ApiClient _apiClient = ApiClient();

  List<Exercise> _exercises = [];
  List<Muscle> _muscles = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Exercise> get exercises => _exercises;
  List<Muscle> get muscles => _muscles;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Danh sách category thật lấy từ dữ liệu muscle (khớp với cách backend
  /// lọc exercise theo category), thay vì danh sách hardcode.
  List<String> get categories {
    final set = _muscles.map((m) => m.category).where((c) => c.isNotEmpty).toSet().toList();
    set.sort();
    return set;
  }

  /// Tải danh sách bài tập từ backend (có hỗ trợ lọc theo nhóm cơ/category)
  Future<void> fetchExercises({String? category, String? muscleId}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      String path = AppConstants.exercises;
      Map<String, String> queryParameters = {};
      if (category != null && category.isNotEmpty) {
        queryParameters['category'] = category;
      }
      if (muscleId != null && muscleId.isNotEmpty) {
        queryParameters['muscleId'] = muscleId;
      }

      // Tạo query string
      if (queryParameters.isNotEmpty) {
        final uri = Uri(path: path, queryParameters: queryParameters);
        path = uri.toString();
      }

      final response = await _apiClient.get(path);
      final data = ApiClient.decodeResponse(response);

      if (response.statusCode == 200) {
        // API có thể trả về {value: [...]} hoặc trực tiếp [...]
        List rawList;
        if (data is List) {
          rawList = data;
        } else if (data is Map && data['value'] != null) {
          rawList = data['value'] as List;
        } else {
          rawList = [];
        }
        // Lọc bỏ exercise có name null
        _exercises = rawList
            .map((x) => Exercise.fromJson(x as Map<String, dynamic>))
            .where((e) => e.name.isNotEmpty)
            .toList();
      } else {
        _errorMessage = (data is Map ? data['message'] : null) ?? 'Không thể tải danh sách bài tập.';
      }
    } catch (e) {
      _errorMessage = 'Lỗi kết nối tới server. Vui lòng thử lại.';
      debugPrint('fetchExercises error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Tải danh sách tất cả các nhóm cơ để đối chiếu
  Future<void> fetchMuscles() async {
    try {
      final response = await _apiClient.get('/muscles');
      final data = ApiClient.decodeResponse(response);

      if (response.statusCode == 200) {
        // API có thể trả về {value: [...]} hoặc trực tiếp [...]
        List rawList;
        if (data is List) {
          rawList = data;
        } else if (data is Map && data['value'] != null) {
          rawList = data['value'] as List;
        } else {
          rawList = [];
        }
        _muscles = rawList.map((x) => Muscle.fromJson(x as Map<String, dynamic>)).toList();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('fetchMuscles error: $e');
    }
  }

  /// Tìm tên của nhóm cơ theo ID
  String getMuscleNameById(String muscleId) {
    final m = _muscles.firstWhere(
      (element) => element.id == muscleId,
      orElse: () => Muscle(id: '', name: 'Không xác định', category: ''),
    );
    return m.name;
  }
}
