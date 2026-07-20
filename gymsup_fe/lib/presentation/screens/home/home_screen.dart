import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/home_provider.dart';
import '../../../providers/profile_provider.dart';
import '../../../providers/payment_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_images.dart';
import '../../../data/models/home_data.dart';
import '../exercise/exercise_list_screen.dart';
import '../profile/profile_screen.dart';
import '../workout/today_workout_screen.dart';
import '../ai/ai_chat_screen.dart';
import '../nutrition/nutrition_detail_screen.dart';
import '../subscription/subscription_screen.dart';
import 'muscle_detail_screen.dart';
import '../../widgets/common/section_header.dart';
import '../../widgets/home/nutrition_card.dart';
import '../../widgets/home/muscle_progress_teaser.dart';
import '../../widgets/home/popular_exercises_section.dart';
import '../../widgets/home/weekly_activity_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _loadData() {
    final authProvider = context.read<AuthProvider>();
    final homeProvider = context.read<HomeProvider>();
    final profileProvider = context.read<ProfileProvider>();
    final paymentProvider = context.read<PaymentProvider>();

    if (authProvider.userId != null) {
      homeProvider.fetchHomeData(authProvider.userId!);
      profileProvider.fetchProfile(authProvider.userId!);
      paymentProvider.fetchMySubscription();
    }

    // Hiện thông báo chào mừng nếu vừa đăng nhập
    if (authProvider.justLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đăng nhập thành công! Chào mừng bạn quay trở lại. 💪'),
          backgroundColor: AppColors.success,
          duration: Duration(seconds: 3),
        ),
      );
      authProvider.clearJustLoggedIn();
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final homeProvider = context.watch<HomeProvider>();
    final profileProvider = context.watch<ProfileProvider>();
    final paymentProvider = context.watch<PaymentProvider>();

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildDashboardTab(
            authProvider,
            homeProvider,
            profileProvider,
            paymentProvider,
          ),
          const TodayWorkoutScreen(),
          const ExerciseListScreen(),
          const AiChatScreen(),
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: AppColors.surfaceVariant, width: 0.5),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: AppColors.surface,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textSecondary,
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
          unselectedLabelStyle: const TextStyle(fontSize: 12),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home_rounded),
              label: 'Trang chủ',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.event_note_outlined),
              activeIcon: Icon(Icons.event_note_rounded),
              label: 'Lịch tập',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.fitness_center_outlined),
              activeIcon: Icon(Icons.fitness_center),
              label: 'Tập luyện',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.chat_bubble_outline),
              activeIcon: Icon(Icons.chat_bubble),
              label: 'AI Coach',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Cá nhân',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardTab(
    AuthProvider authProvider,
    HomeProvider homeProvider,
    ProfileProvider profileProvider,
    PaymentProvider paymentProvider,
  ) {
    return Scaffold(
      body: homeProvider.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : homeProvider.errorMessage != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: AppColors.error,
                      size: 60,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      homeProvider.errorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadData,
                      child: const Text('Thử lại'),
                    ),
                  ],
                ),
              ),
            )
          : homeProvider.homeData == null
          ? const Center(child: Text('Không có dữ liệu hiển thị.'))
          : RefreshIndicator(
              onRefresh: () async => _loadData(),
              color: AppColors.primary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeroHeader(
                      authProvider,
                      homeProvider.homeData!,
                      profileProvider,
                      paymentProvider,
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildQuickActions(),
                          const SizedBox(height: 28),

                          _buildSectionTitle('Kế hoạch hôm nay'),
                          const SizedBox(height: 12),
                          _buildTodayPlanCard(
                            homeProvider.homeData!.todayPlan,
                            homeProvider.homeData!.plans,
                          ),
                          const SizedBox(height: 24),

                          _buildSectionTitle('Bài tập phổ biến'),
                          const SizedBox(height: 12),
                          PopularExercisesSection(
                            exercises: homeProvider.homeData!.popularExercises,
                          ),
                          const SizedBox(height: 24),

                          _buildSectionTitle('Hoạt động tuần này'),
                          const SizedBox(height: 12),
                          WeeklyActivityCard(
                            history: homeProvider.homeData!.history,
                          ),
                          const SizedBox(height: 24),

                          _buildSectionTitle('Tiến trình cơ bắp'),
                          const SizedBox(height: 12),
                          MuscleProgressTeaser(
                            muscleProgress:
                                homeProvider.homeData!.muscleProgress,
                            onViewAll: () => _openScreen(
                              MuscleDetailScreen(
                                muscleProgress:
                                    homeProvider.homeData!.muscleProgress,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          _buildSectionTitle('Dinh dưỡng hôm nay'),
                          const SizedBox(height: 12),
                          NutritionCard(
                            nutrition: homeProvider.homeData!.nutrition,
                            bmi: profileProvider.profile?.bmi,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildHeroHeader(
    AuthProvider authProvider,
    HomeData data,
    ProfileProvider profileProvider,
    PaymentProvider paymentProvider,
  ) {
    final subscription = paymentProvider.mySubscription;
    final normalizedPlanName =
        subscription?.planName.trim().toLowerCase() ?? '';
    final showVipBadge =
        subscription != null &&
        subscription.status.toLowerCase() == 'active' &&
        (normalizedPlanName == 'hội viên tháng' ||
            normalizedPlanName == 'hội viên năm');

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
      child: Stack(
        children: [
          // Ảnh nền hero (giống gym_support) + lớp phủ gradient để chữ dễ đọc
          Positioned.fill(
            child: Image.network(
              AppImages.gymHero,
              fit: BoxFit.cover,
              alignment: Alignment.centerRight,
              errorBuilder: (_, _, _) => Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primaryDark, AppColors.primary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.background.withValues(alpha: 0.92),
                    AppColors.primaryDark.withValues(alpha: 0.75),
                    AppColors.primary.withValues(alpha: 0.55),
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.fitness_center_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Chào buổi tập,',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.85),
                                fontSize: 12,
                              ),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Flexible(
                                  child: Text(
                                    profileProvider
                                                .profile
                                                ?.fullName
                                                .isNotEmpty ==
                                            true
                                        ? profileProvider.profile!.fullName
                                        : (authProvider.userId != null
                                              ? 'Gymer'
                                              : 'GymSup Member'),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                                if (showVipBadge) ...[
                                  const SizedBox(width: 8),
                                  _buildVipBadge(),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: _buildHeroStatChip(
                          Icons.local_fire_department_rounded,
                          '${data.streak} ngày',
                          'Chuỗi tập',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildHeroStatChip(
                          Icons.bolt_rounded,
                          '${data.workoutCount} buổi',
                          'Hoàn thành',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroStatChip(IconData icon, String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(width: 10),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVipBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFB347), Color(0xFFFF6B35)],
        ),
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.workspace_premium_rounded, size: 12, color: Colors.white),
          SizedBox(width: 3),
          Text(
            'VIP',
            style: TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return SectionHeader(title: title);
  }

  void _openScreen(Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  Widget _buildQuickActions() {
    final actions = [
      (
        Icons.restaurant_rounded,
        'Dinh dưỡng',
        'Theo dõi mục tiêu',
        const Color(0xFF58C996),
        () => _openScreen(const NutritionDetailScreen()),
      ),
      (
        Icons.workspace_premium_rounded,
        'Hội viên',
        'Đặc quyền GymSup',
        const Color(0xFFE4C46C),
        () => _openScreen(const SubscriptionScreen()),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Truy cập nhanh'),
        const SizedBox(height: 12),
        Row(
          children: actions.map((action) {
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  right: action == actions.last ? 0 : 10,
                ),
                child: _buildQuickActionCard(
                  icon: action.$1,
                  title: action.$2,
                  subtitle: action.$3,
                  accent: action.$4,
                  onTap: action.$5,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildQuickActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color accent,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        hoverColor: accent.withValues(alpha: 0.04),
        splashColor: accent.withValues(alpha: 0.1),
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                accent.withValues(alpha: 0.085),
                AppColors.cardBackground,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: accent.withValues(alpha: 0.24)),
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: 0.045),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: accent.withValues(alpha: 0.16)),
                    ),
                    child: Icon(icon, color: accent, size: 22),
                  ),
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.035),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.arrow_outward_rounded,
                      color: accent.withValues(alpha: 0.85),
                      size: 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Today's Workout Card
  Widget _buildTodayPlanCard(TodayPlan? plan, List<dynamic> plans) {
    if (plan == null) {
      // Tìm plan active để lấy danh sách các buổi tập trong tuần làm mẫu cho người dùng nhìn
      final activePlan = plans.firstWhere(
        (p) => p['isActive'] == true,
        orElse: () => plans.isNotEmpty ? plans.first : null,
      );

      final sessions = activePlan != null
          ? (activePlan['sessions'] as List? ?? [])
          : [];

      String translateDay(String d) {
        switch (d.toLowerCase()) {
          case 'monday':
            return 'Thứ 2';
          case 'tuesday':
            return 'Thứ 3';
          case 'wednesday':
            return 'Thứ 4';
          case 'thursday':
            return 'Thứ 5';
          case 'friday':
            return 'Thứ 6';
          case 'saturday':
            return 'Thứ 7';
          case 'sunday':
            return 'Chủ nhật';
          default:
            return d;
        }
      }

      return Container(
        width: double.infinity,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.surfaceVariant),
        ),
        child: Column(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
              child: Image.network(
                AppImages.workoutBanner,
                height: 110,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  height: 110,
                  color: AppColors.surfaceVariant,
                  child: const Icon(
                    Icons.hotel,
                    size: 40,
                    color: AppColors.textHint,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const Text(
                    'Hôm nay là ngày nghỉ ngơi! 😴',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Hãy để cơ bắp của bạn phục hồi và phát triển.',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (sessions.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    const Divider(color: AppColors.surfaceVariant, height: 1),
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Lịch tập của bạn tuần này (${activePlan!['name']}):',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    ...sessions.map((s) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.check_circle_outline,
                              size: 16,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${translateDay(s['dayOfWeek'] ?? '')}: ',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              s['focus'] ?? 'Tập luyện',
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.surfaceVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plan.day,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    Text(
                      plan.focus ?? 'Tập luyện tự do',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() => _currentIndex = 1);
                  },
                  icon: const Icon(Icons.play_arrow, size: 18),
                  label: const Text('Bắt đầu'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    minimumSize: Size.zero,
                  ),
                ),
              ],
            ),
          ),
          // List Exercises
          if (plan.exercises.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24.0),
              child: Center(
                child: Text('Không có bài tập nào được lên lịch cho hôm nay.'),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: plan.exercises.length,
              separatorBuilder: (context, index) =>
                  const Divider(height: 1, color: AppColors.surfaceVariant),
              itemBuilder: (context, index) {
                final ex = plan.exercises[index];
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  leading: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ex.displayImageUrl.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: ex.isAssetImage
                                ? Image.asset(
                                    ex.displayImageUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, _, _) => const Icon(
                                      Icons.fitness_center,
                                      color: AppColors.primary,
                                    ),
                                  )
                                : Image.network(
                                    ex.displayImageUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, _, _) => const Icon(
                                      Icons.fitness_center,
                                      color: AppColors.primary,
                                    ),
                                  ),
                          )
                        : const Icon(
                            Icons.fitness_center,
                            color: AppColors.primary,
                          ),
                  ),
                  title: Text(
                    ex.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  subtitle: Text(
                    'Nhóm cơ: ${ex.muscle}',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  trailing: Text(
                    '${ex.sets ?? 0} Sets x ${ex.reps ?? "—"} Reps',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
