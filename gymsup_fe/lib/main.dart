import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'core/theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/home_provider.dart';
import 'providers/exercise_provider.dart';
import 'providers/profile_provider.dart';
import 'providers/payment_provider.dart';
import 'providers/onboarding_provider.dart';
import 'providers/workout_plan_provider.dart';
import 'providers/workout_session_provider.dart';
import 'providers/ai_usage_provider.dart';
import 'core/network/api_client.dart';
import 'routes/app_router.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider()..checkAuthStatus(),
        ),
        ChangeNotifierProvider(create: (_) => HomeProvider()),
        ChangeNotifierProvider(create: (_) => ExerciseProvider()),
        ChangeNotifierProvider(create: (_) => ProfileProvider()),
        ChangeNotifierProvider(
          create: (_) => PaymentProvider()..fetchMySubscription(),
        ),
        ChangeNotifierProvider(create: (_) => OnboardingProvider()),
        ChangeNotifierProvider(create: (_) => WorkoutPlanProvider()),
        ChangeNotifierProvider(create: (_) => WorkoutSessionProvider()),
        ChangeNotifierProvider(create: (_) => AiUsageProvider()),
      ],
      child: const GymSupApp(),
    ),
  );
}

class GymSupApp extends StatefulWidget {
  const GymSupApp({super.key});

  @override
  State<GymSupApp> createState() => _GymSupAppState();
}

class _GymSupAppState extends State<GymSupApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    final authProvider = context.read<AuthProvider>();
    _router = AppRouter.createRouter(authProvider);

    // Token hết hạn/không hợp lệ ở bất kỳ request nào -> tự đăng xuất, router
    // sẽ tự điều hướng về /login (nghe qua refreshListenable: authProvider).
    ApiClient.onUnauthorized = () {
      if (authProvider.isAuthenticated) authProvider.logout();
    };
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'GymSup',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      routerConfig: _router,
    );
  }
}
