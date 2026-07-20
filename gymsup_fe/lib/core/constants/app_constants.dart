class AppConstants {
  // --- Base API URL ---
  // Backend đã được host trên VPS (cùng backend mà gym_support đang dùng).
  static const String baseUrl = 'https://api.gsfitness.id.vn/api';

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
  static const String workoutPlans = '/workoutplans';
  static const String workoutSessions = '/workout-session-logs';
  static const String exercises = '/exercises';
  static const String muscles = '/muscles';

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
