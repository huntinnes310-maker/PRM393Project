import 'package:flutter/foundation.dart';
import '../core/network/api_client.dart';
import '../core/constants/app_constants.dart';
import '../data/models/workout_plan.dart';

class WorkoutPlanProvider extends ChangeNotifier {
  final ApiClient _apiClient = ApiClient();

  List<WorkoutPlan> _plans = [];
  WorkoutPlan? _activePlan;
  WorkoutPlan? _selectedPlan;
  bool _isLoading = false;
  String? _errorMessage;

  List<WorkoutPlan> get plans => _plans;
  WorkoutPlan? get activePlan => _activePlan;
  WorkoutPlan? get selectedPlan => _selectedPlan;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchPlans(String userId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final response = await _apiClient.get('${AppConstants.workoutPlans}/user/$userId');
      if (response.statusCode == 200) {
        final data = ApiClient.decodeResponse(response) as List;
        _plans = data.map((x) => WorkoutPlan.fromJson(x)).toList();
      } else {
        _errorMessage = 'Không thể tải danh sách lịch tập.';
      }
    } catch (e) {
      _errorMessage = 'Lỗi kết nối. Vui lòng thử lại.';
      debugPrint('fetchPlans error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchActivePlan(String userId) async {
    try {
      final response =
          await _apiClient.get('${AppConstants.workoutPlans}/user/$userId/active');
      if (response.statusCode == 200) {
        _activePlan = WorkoutPlan.fromJson(ApiClient.decodeResponse(response));
      } else {
        _activePlan = null;
      }
    } catch (e) {
      _activePlan = null;
      debugPrint('fetchActivePlan error: $e');
    }
    notifyListeners();
  }

  Future<WorkoutPlan?> fetchPlanById(String id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final response = await _apiClient.get('${AppConstants.workoutPlans}/$id');
      if (response.statusCode == 200) {
        _selectedPlan = WorkoutPlan.fromJson(ApiClient.decodeResponse(response));
        return _selectedPlan;
      }
      _errorMessage = 'Không tìm thấy lịch tập.';
      return null;
    } catch (e) {
      _errorMessage = 'Lỗi kết nối. Vui lòng thử lại.';
      debugPrint('fetchPlanById error: $e');
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<WorkoutPlan?> createRoutine(Map<String, dynamic> payload) async {
    try {
      final response =
          await _apiClient.post('${AppConstants.workoutPlans}/create-routine', payload);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return WorkoutPlan.fromJson(ApiClient.decodeResponse(response));
      }
      _errorMessage = 'Không thể tạo lịch tập.';
      return null;
    } catch (e) {
      _errorMessage = 'Lỗi kết nối. Vui lòng thử lại.';
      debugPrint('createRoutine error: $e');
      return null;
    }
  }

  Future<bool> updatePlan(String id, Map<String, dynamic> body) async {
    try {
      final response = await _apiClient.put('${AppConstants.workoutPlans}/$id', body);
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('updatePlan error: $e');
      return false;
    }
  }

  Future<bool> activatePlan(String id) async {
    try {
      final response = await _apiClient.put('${AppConstants.workoutPlans}/$id/activate', {});
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('activatePlan error: $e');
      return false;
    }
  }

  Future<bool> deactivatePlan(String id) async {
    try {
      final response = await _apiClient.put('${AppConstants.workoutPlans}/$id/deactivate', {});
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('deactivatePlan error: $e');
      return false;
    }
  }

  Future<bool> deletePlan(String id) async {
    try {
      final response = await _apiClient.delete('${AppConstants.workoutPlans}/$id');
      return response.statusCode == 204 || response.statusCode == 200;
    } catch (e) {
      debugPrint('deletePlan error: $e');
      return false;
    }
  }

  Future<bool> addExerciseToSession({
    required String planId,
    required String sessionId,
    required String exerciseId,
    required String exerciseName,
    required int sets,
    required String reps,
    String notes = '',
  }) async {
    try {
      final response = await _apiClient.post(
        '${AppConstants.workoutPlans}/$planId/sessions/$sessionId/exercises',
        {
          'exerciseId': exerciseId,
          'exerciseName': exerciseName,
          'sets': sets,
          'reps': reps,
          'notes': notes,
        },
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      debugPrint('addExerciseToSession error: $e');
      return false;
    }
  }

  Future<bool> updateExerciseInSession({
    required String planId,
    required String sessionId,
    required String exerciseId,
    required int sets,
    required String reps,
    String notes = '',
  }) async {
    try {
      final response = await _apiClient.put(
        '${AppConstants.workoutPlans}/$planId/sessions/$sessionId/exercises/$exerciseId',
        {'sets': sets, 'reps': reps, 'notes': notes},
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('updateExerciseInSession error: $e');
      return false;
    }
  }

  Future<bool> deleteExerciseFromSession({
    required String planId,
    required String sessionId,
    required String exerciseId,
  }) async {
    try {
      final response = await _apiClient.delete(
        '${AppConstants.workoutPlans}/$planId/sessions/$sessionId/exercises/$exerciseId',
      );
      return response.statusCode == 204 || response.statusCode == 200;
    } catch (e) {
      debugPrint('deleteExerciseFromSession error: $e');
      return false;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
