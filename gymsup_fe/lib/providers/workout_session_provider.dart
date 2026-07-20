import 'package:flutter/foundation.dart';
import '../core/network/api_client.dart';
import '../core/constants/app_constants.dart';
import '../data/models/workout_session_log.dart';
import '../data/models/finish_workout_result.dart';

class WorkoutSessionProvider extends ChangeNotifier {
  final ApiClient _apiClient = ApiClient();

  WorkoutSessionLog? _activeSession;
  List<WorkoutSessionLog> _history = [];
  bool _isLoading = false;
  String? _errorMessage;
  final Map<String, Map<String, dynamic>> _exerciseStats = {};

  WorkoutSessionLog? get activeSession => _activeSession;
  List<WorkoutSessionLog> get history => _history;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<WorkoutSessionLog?> fetchActiveSession(String userId) async {
    try {
      final response =
          await _apiClient.get('${AppConstants.workoutSessions}/active/$userId');
      if (response.statusCode == 200) {
        _activeSession = WorkoutSessionLog.fromJson(ApiClient.decodeResponse(response));
      } else {
        _activeSession = null;
      }
    } catch (e) {
      _activeSession = null;
      debugPrint('fetchActiveSession error: $e');
    }
    notifyListeners();
    return _activeSession;
  }

  Future<WorkoutSessionLog?> startSession({
    required String userId,
    required String workoutPlanId,
    required String planSessionId,
  }) async {
    // Kiểm tra session đang diễn ra trước - backend sẽ báo lỗi 400 nếu start
    // trong khi đã có session IN_PROGRESS.
    final existing = await fetchActiveSession(userId);
    if (existing != null) return existing;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final response = await _apiClient.post('${AppConstants.workoutSessions}/start', {
        'userId': userId,
        'workoutPlanId': workoutPlanId,
        'planSessionId': planSessionId,
      });
      if (response.statusCode == 200 || response.statusCode == 201) {
        _activeSession = WorkoutSessionLog.fromJson(ApiClient.decodeResponse(response));
        return _activeSession;
      }
      _errorMessage = 'Không thể bắt đầu buổi tập.';
      return null;
    } catch (e) {
      _errorMessage = 'Lỗi kết nối. Vui lòng thử lại.';
      debugPrint('startSession error: $e');
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Tìm exerciseLogId (id của WorkoutExerciseLog trong session hiện tại)
  /// tương ứng với 1 exerciseId trong catalog.
  String? resolveExerciseLogId(String exerciseId) {
    if (_activeSession == null) return null;
    for (final ex in _activeSession!.exercises) {
      if (ex.exerciseId == exerciseId) return ex.id;
    }
    return null;
  }

  Future<bool> logSet({
    required String sessionLogId,
    required String exerciseLogId,
    required int setNumber,
    double? weight,
    int? reps,
    int? durationSeconds,
    int? rpe,
  }) async {
    try {
      final response = await _apiClient.post(
        '${AppConstants.workoutSessions}/$sessionLogId/exercises/$exerciseLogId/sets',
        {
          'setNumber': setNumber,
          if (weight != null) 'weight': weight,
          if (reps != null) 'reps': reps,
          if (durationSeconds != null) 'durationSeconds': durationSeconds,
          if (rpe != null) 'rpe': rpe,
        },
      );
      if (response.statusCode == 200) {
        _activeSession = WorkoutSessionLog.fromJson(ApiClient.decodeResponse(response));
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('logSet error: $e');
      return false;
    }
  }

  Future<FinishWorkoutResult?> finishSession(String sessionLogId) async {
    try {
      final response =
          await _apiClient.put('${AppConstants.workoutSessions}/$sessionLogId/finish', {});
      if (response.statusCode == 200) {
        final result = FinishWorkoutResult.fromJson(ApiClient.decodeResponse(response));
        _activeSession = null;
        notifyListeners();
        return result;
      }
      return null;
    } catch (e) {
      debugPrint('finishSession error: $e');
      return null;
    }
  }

  Future<void> fetchHistory(String userId) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response =
          await _apiClient.get('${AppConstants.workoutSessions}/user/$userId/history');
      if (response.statusCode == 200) {
        final data = ApiClient.decodeResponse(response) as List;
        _history = data.map((x) => WorkoutSessionLog.fromJson(x)).toList();
      }
    } catch (e) {
      debugPrint('fetchHistory error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>?> fetchExerciseStats(String userId, String exerciseId) async {
    if (_exerciseStats.containsKey(exerciseId)) return _exerciseStats[exerciseId];
    try {
      final response = await _apiClient.get('/users/$userId/exercise-stats/$exerciseId');
      if (response.statusCode == 200) {
        final data = ApiClient.decodeResponse(response) as Map<String, dynamic>;
        _exerciseStats[exerciseId] = data;
        return data;
      }
    } catch (e) {
      debugPrint('fetchExerciseStats error: $e');
    }
    return null;
  }

  void clearActiveSession() {
    _activeSession = null;
    notifyListeners();
  }
}
