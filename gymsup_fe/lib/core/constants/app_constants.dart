import 'package:flutter/foundation.dart' show kIsWeb;

class AppConstants {
  // --- Base API URL ---
  // Tự động chọn đúng địa chỉ theo nền tảng:
  // - Web (Chrome): dùng localhost
  // - Android Emulator: dùng 10.0.2.2 (alias của localhost trên máy ảo)
  // - Android thật (USB): đổi thành IP máy tính, VD: http://192.168.1.x:5000/api
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:5028/api';
    }
    return 'http://10.0.2.2:5028/api';
  }

  // --- API Endpoints ---
  // Auth
  static const String login = '/auth/login';
  static const String register = '/auth/register/customer';
  static const String verifyEmail = '/auth/verify-email';
  static const String refreshToken = '/auth/refresh';

  // User
  static const String userProfile = '/users';
  static const String userSurvey = '/users/survey';
  static const String userStats = '/user-stats';

  // Home
  static const String home = '/home';

  // Workout
  static const String workoutPlans = '/workout-plans';
  static const String workoutSessions = '/workout-session-logs';
  static const String exercises = '/exercises';

  // Analytics
  static const String analytics = '/analytics';
  static const String muscleProgress = '/muscle-progress';

  // AI
  static const String aiChat = '/ai/chat';
  static const String aiGeneratePlan = '/ai/generate-plan';
  static const String aiScanEquipment = '/ai/scan-equipment';

  // Store
  static const String subscription = '/subscription';
  static const String storePurchases = '/store-purchases';

  // --- Storage Keys ---
  static const String tokenKey = 'jwt_token';
  static const String userIdKey = 'user_id';
  static const String userEmailKey = 'user_email';
  static const String userRoleKey = 'user_role';

  // --- App Info ---
  static const String appName = 'GymSup';
  static const String appVersion = '1.0.0';
}
