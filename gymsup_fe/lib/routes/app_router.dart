import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../presentation/screens/auth/login_screen.dart';
import '../presentation/screens/auth/register_screen.dart';
import '../presentation/screens/home/home_screen.dart';
import '../presentation/screens/exercise/exercise_list_screen.dart';
import '../presentation/screens/exercise/exercise_detail_screen.dart';

import '../presentation/screens/profile/survey_screen.dart';

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

        // Đã đăng nhập nhưng đang ở trang auth -> vào home
        if (status == AuthStatus.authenticated && isOnAuthPage) {
          return '/home';
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
      ],
    );
  }
}
