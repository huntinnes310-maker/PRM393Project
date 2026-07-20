import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../presentation/screens/auth/login_screen.dart';
import '../presentation/screens/auth/register_screen.dart';
import '../presentation/screens/home/home_screen.dart';
import '../presentation/screens/exercise/exercise_list_screen.dart';
import '../presentation/screens/exercise/exercise_detail_screen.dart';
import '../presentation/screens/onboarding/onboarding_name_step_screen.dart';
import '../presentation/screens/onboarding/onboarding_metrics_step_screen.dart';
import '../presentation/screens/onboarding/onboarding_goal_step_screen.dart';
import '../presentation/screens/onboarding/onboarding_schedule_step_screen.dart';
import '../presentation/screens/profile/survey_screen.dart';
import '../presentation/screens/manager/manager_dashboard_screen.dart';
import '../presentation/screens/subscription/subscription_screen.dart';
import '../presentation/screens/subscription/checkout_screen.dart';
import '../presentation/screens/workout/today_workout_screen.dart';
import '../presentation/screens/workout/workout_session_screen.dart';
import '../presentation/screens/workout/workout_summary_screen.dart';
import '../presentation/screens/workout/workout_history_screen.dart';
import '../presentation/screens/workout/workout_plans_screen.dart';
import '../presentation/screens/workout/workout_plan_detail_screen.dart';
import '../presentation/screens/workout/build_routine_screen.dart';
import '../data/models/finish_workout_result.dart';

class AppRouter {
  static GoRouter createRouter(AuthProvider authProvider) {
    return GoRouter(
      initialLocation: '/',
      refreshListenable: authProvider,
      redirect: (context, state) {
        final status = authProvider.status;
        final isOnAuthPage =
            state.matchedLocation == '/login' ||
            state.matchedLocation == '/register';

        // Chưa biết trạng thái -> không redirect
        if (status == AuthStatus.unknown) return null;

        // Chưa đăng nhập -> vào trang login
        if (status == AuthStatus.unauthenticated && !isOnAuthPage) {
          return '/login';
        }

        // Đã đăng nhập
        if (status == AuthStatus.authenticated) {
          final isManagerOrAdmin = authProvider.isManagerOrAdmin;
          final isOnOnboardingPath =
              state.matchedLocation.startsWith('/onboarding');

          if (isManagerOrAdmin) {
            // Manager/Admin đăng nhập thành công -> luôn đưa về /manager/dashboard
            if (isOnAuthPage || state.matchedLocation == '/home') {
              return '/manager/dashboard';
            }
          } else if (authProvider.needsOnboarding) {
            // Khách hàng chưa hoàn tất hồ sơ -> ép vào wizard onboarding
            if (!isOnOnboardingPath) {
              return '/onboarding/name';
            }
          } else if (isOnAuthPage ||
              state.matchedLocation == '/manager/dashboard' ||
              isOnOnboardingPath) {
            // Khách hàng đã hoàn tất hồ sơ nhưng ở trang auth/onboarding -> vào home
            return '/home';
          }
        }

        return null;
      },
      routes: [
        GoRoute(
          path: '/',
          redirect: (context, state) => '/login',
        ),
        GoRoute(
          path: '/login',
          name: 'login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/register',
          name: 'register',
          builder: (context, state) => const RegisterScreen(),
        ),
        GoRoute(
          path: '/home',
          name: 'home',
          builder: (context, state) => const HomeScreen(),
        ),
        GoRoute(
          path: '/exercises',
          name: 'exercises',
          builder: (context, state) => const ExerciseListScreen(),
        ),
        GoRoute(
          path: '/exercises/:id',
          name: 'exercise_detail',
          builder: (context, state) {
            final id = state.pathParameters['id']!;
            return ExerciseDetailScreen(exerciseId: id);
          },
        ),
        GoRoute(
          path: '/profile/survey',
          name: 'survey',
          builder: (context, state) => const SurveyScreen(),
        ),
        GoRoute(
          path: '/onboarding/name',
          name: 'onboarding_name',
          builder: (context, state) => const OnboardingNameStepScreen(),
        ),
        GoRoute(
          path: '/onboarding/metrics',
          name: 'onboarding_metrics',
          builder: (context, state) => const OnboardingMetricsStepScreen(),
        ),
        GoRoute(
          path: '/onboarding/goal',
          name: 'onboarding_goal',
          builder: (context, state) => const OnboardingGoalStepScreen(),
        ),
        GoRoute(
          path: '/onboarding/schedule',
          name: 'onboarding_schedule',
          builder: (context, state) => const OnboardingScheduleStepScreen(),
        ),
        GoRoute(
          path: '/manager/dashboard',
          name: 'manager_dashboard',
          builder: (context, state) => const ManagerDashboardScreen(),
        ),
        GoRoute(
          path: '/subscription',
          name: 'subscription',
          builder: (context, state) => const SubscriptionScreen(),
        ),
        GoRoute(
          path: '/subscription/checkout',
          name: 'checkout',
          builder: (context, state) => const CheckoutScreen(),
        ),
        GoRoute(
          path: '/workout/today',
          name: 'workout_today',
          builder: (context, state) => const TodayWorkoutScreen(),
        ),
        GoRoute(
          path: '/workout/session',
          name: 'workout_session',
          builder: (context, state) => const WorkoutSessionScreen(),
        ),
        GoRoute(
          path: '/workout/summary',
          name: 'workout_summary',
          builder: (context, state) =>
              WorkoutSummaryScreen(result: state.extra as FinishWorkoutResult),
        ),
        GoRoute(
          path: '/workout/history',
          name: 'workout_history',
          builder: (context, state) => const WorkoutHistoryScreen(),
        ),
        GoRoute(
          path: '/workout-plans',
          name: 'workout_plans',
          builder: (context, state) => const WorkoutPlansScreen(),
        ),
        GoRoute(
          path: '/workout-plans/build',
          name: 'workout_plans_build',
          builder: (context, state) => const BuildRoutineScreen(),
        ),
        GoRoute(
          path: '/workout-plans/:id',
          name: 'workout_plan_detail',
          builder: (context, state) =>
              WorkoutPlanDetailScreen(planId: state.pathParameters['id']!),
        ),
      ],
    );
  }
}
