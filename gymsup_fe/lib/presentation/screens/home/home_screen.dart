import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:percent_indicator/percent_indicator.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/home_provider.dart';
import '../../../providers/profile_provider.dart';
import '../../../providers/payment_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/home_data.dart';
import '../exercise/exercise_list_screen.dart';
import '../profile/profile_screen.dart';
import '../todo/todo_screen.dart';
import '../ai/ai_chat_screen.dart';
import '../nutrition/nutrition_detail_screen.dart';
import '../subscription/subscription_screen.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/section_header.dart';

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
    final subscription = paymentProvider.mySubscription;
    final normalizedPlanName =
        subscription?.planName.trim().toLowerCase() ?? '';
    final showVipBadge =
        subscription != null &&
        subscription.status.toLowerCase() == 'active' &&
        (normalizedPlanName == 'hội viên tháng' ||
            normalizedPlanName == 'hội viên năm');

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 76,
        title: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.fitness_center_rounded,
                color: AppColors.primary,
                size: 21,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Chào buổi tập,',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          profileProvider.profile?.fullName.isNotEmpty == true
                              ? profileProvider.profile!.fullName
                              : (authProvider.userId != null
                                    ? 'Gymer'
                                    : 'GymSup Member'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
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
      ),
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
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Streak & Activity Banner
                    _buildActivitySection(homeProvider.homeData!),
                    const SizedBox(height: 20),

                    _buildQuickActions(),
                    const SizedBox(height: 28),

                    // 2. Nutrition Progress Section
                    _buildSectionTitle('Dinh dưỡng hôm nay'),
                    const SizedBox(height: 12),
                    _buildNutritionCard(homeProvider.homeData!.nutrition),
                    const SizedBox(height: 24),

                    // 3. Today's Workout Section
                    _buildSectionTitle('Kế hoạch hôm nay'),
                    const SizedBox(height: 12),
                    _buildTodayPlanCard(
                      homeProvider.homeData!.todayPlan,
                      homeProvider.homeData!.plans,
                    ),
                    const SizedBox(height: 24),

                    // 4. RPG Muscle Levels Progress
                    _buildSectionTitle('Tiến trình cơ bắp'),
                    const SizedBox(height: 12),
                    _buildMuscleProgressList(
                      homeProvider.homeData!.muscleProgress,
                    ),
                  ],
                ),
              ),
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
            color: AppColors.primary.withValues(alpha: 0.25),
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
        Icons.event_note_rounded,
        'Lịch tập',
        'Kế hoạch hôm nay',
        const Color(0xFF8290FF),
        () => _openScreen(const TodoScreen()),
      ),
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

  // 1. Activity Section (Streak & Workouts count)
  Widget _buildActivitySection(HomeData data) {
    return Row(
      children: [
        Expanded(
          child: AppCard(
            child: Row(
              children: [
                _buildMetricIcon(Icons.local_fire_department_rounded),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricText('${data.streak} ngày', 'Chuỗi tập'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: AppCard(
            child: Row(
              children: [
                _buildMetricIcon(Icons.bolt_rounded),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricText(
                    '${data.workoutCount} buổi',
                    'Hoàn thành',
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMetricIcon(IconData icon) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: AppColors.primary, size: 21),
    );
  }

  Widget _buildMetricText(String value, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  // 2. Nutrition Cards
  Widget _buildNutritionCard(HomeNutrition nutrition) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const NutritionDetailScreen(),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.surfaceVariant),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                // Calorie Indicator
                _buildNutritionCircle(
                  label: 'Calo mục tiêu',
                  value: nutrition.calories,
                  icon: Icons.local_fire_department,
                  color: Colors.orange,
                  percent: nutrition.caloriesPercent,
                ),
                // Protein Indicator
                _buildNutritionCircle(
                  label: 'Protein',
                  value: nutrition.protein,
                  icon: Icons.fitness_center,
                  color: AppColors.primary,
                  percent: nutrition.proteinPercent,
                ),
                // Water Indicator
                _buildNutritionCircle(
                  label: 'Nước uống',
                  value: nutrition.water,
                  icon: Icons.local_drink,
                  color: Colors.blue,
                  percent: nutrition.waterPercent,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNutritionCircle({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    required double percent,
  }) {
    return Column(
      children: [
        CircularPercentIndicator(
          radius: 35.0,
          lineWidth: 6.0,
          percent: percent.clamp(0.0, 1.0),
          center: Icon(icon, color: color, size: 24),
          progressColor: color,
          backgroundColor: AppColors.surfaceVariant,
          circularStrokeCap: CircularStrokeCap.round,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  // 3. Today's Workout Card
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
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.surfaceVariant),
        ),
        child: Column(
          children: [
            const Icon(Icons.hotel, size: 44, color: Colors.blueGrey),
            const SizedBox(height: 12),
            const Text(
              'Hôm nay là ngày nghỉ ngơi! 😴',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text(
              'Hãy để cơ bắp của bạn phục hồi và phát triển.',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
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
                    _openScreen(const TodoScreen());
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

  // 4. RPG Muscle Progress
  Widget _buildMuscleProgressList(List<MuscleProgress> progressList) {
    if (progressList.isEmpty) {
      return const Center(
        child: Text('Chưa có tiến trình cơ bắp nào ghi nhận.'),
      );
    }

    // Sắp xếp danh sách giảm dần theo Cấp độ và Tổng điểm kinh nghiệm (XP)
    final sortedList = List<MuscleProgress>.from(progressList);
    sortedList.sort((a, b) {
      if (b.level != a.level) {
        return b.level.compareTo(a.level);
      }
      return b.totalExp.compareTo(a.totalExp);
    });

    // Lấy top 6 nhóm cơ có tiến trình cao nhất
    final mainMuscles = sortedList.take(6).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.surfaceVariant),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: mainMuscles.length,
        separatorBuilder: (context, index) => const SizedBox(height: 14),
        itemBuilder: (context, index) {
          final mp = mainMuscles[index];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        mp.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Tier badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: _getTierColor(mp.tier).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: _getTierColor(mp.tier),
                            width: 0.5,
                          ),
                        ),
                        child: Text(
                          mp.tier,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: _getTierColor(mp.tier),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    'Lvl ${mp.level} (${mp.currentLevelExp}/${mp.expToNextLevel} XP)',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              LinearPercentIndicator(
                lineHeight: 8.0,
                percent: mp.progress,
                progressColor: AppColors.primary,
                backgroundColor: AppColors.surfaceVariant,
                barRadius: const Radius.circular(4),
                animation: true,
                padding: EdgeInsets.zero,
              ),
            ],
          );
        },
      ),
    );
  }

  Color _getTierColor(String tier) {
    switch (tier.toLowerCase()) {
      case 'champion':
        return Colors.amber;
      case 'diamond':
        return Colors.cyan;
      case 'platinum':
        return Colors.purpleAccent;
      case 'gold':
        return Colors.amberAccent;
      case 'silver':
        return Colors.blueGrey;
      case 'bronze':
        return Colors.brown;
      default:
        return Colors.grey;
    }
  }
}
