import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/profile_provider.dart';
import '../../../providers/home_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/customer_profile.dart';
import '../../../core/network/api_client.dart';
import 'achievements_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoadingStats = false;
  List<dynamic> _weeklyStats = [];
  List<dynamic> _monthlyStats = [];
  String _statsPeriod = 'weekly'; // 'weekly' or 'monthly'

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadProfile());
  }

  void _loadProfile() {
    final userId = context.read<AuthProvider>().userId;
    if (userId != null && userId.isNotEmpty) {
      context.read<ProfileProvider>().fetchProfile(userId);
      context.read<HomeProvider>().fetchHomeData(userId);
      _loadStats();
    }
  }

  Future<void> _loadStats() async {
    final userId = context.read<AuthProvider>().userId;
    if (userId == null || userId.isEmpty) return;

    if (!mounted) return;
    setState(() {
      _isLoadingStats = true;
    });

    try {
      final ApiClient apiClient = ApiClient();
      final weeklyRes = await apiClient.get('/users/$userId/stats/weekly?weeks=8');
      final monthlyRes = await apiClient.get('/users/$userId/stats/monthly?months=6');

      if (weeklyRes.statusCode == 200 && monthlyRes.statusCode == 200) {
        if (mounted) {
          setState(() {
            _weeklyStats = ApiClient.decodeResponse(weeklyRes) as List? ?? [];
            _monthlyStats = ApiClient.decodeResponse(monthlyRes) as List? ?? [];
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading stats: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingStats = false;
        });
      }
    }
  }

  Future<void> _navigateToAchievements() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AchievementsScreen()),
    );
    _loadProfile();
  }

  Color _getBmiColor(double bmi) {
    if (bmi <= 0) return AppColors.textSecondary;
    if (bmi < 18.5) return Colors.amber;
    if (bmi < 25.0) return Colors.green;
    if (bmi < 30.0) return Colors.orange;
    return AppColors.error;
  }

  @override
  Widget build(BuildContext context) {
    final profileProvider = context.watch<ProfileProvider>();
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: profileProvider.isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : CustomScrollView(
              slivers: [
                // App bar với avatar
                SliverToBoxAdapter(child: _buildHeader(profileProvider.profile, authProvider)),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      if (profileProvider.profile != null)
                        ..._buildProfileContent(profileProvider.profile!)
                      else
                        _buildNoProfileCard(),
                      const SizedBox(height: 20),
                      _buildSurveyButton(profileProvider.profile),
                      const SizedBox(height: 16),
                      _buildLogoutButton(authProvider),
                      const SizedBox(height: 40),
                    ]),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildHeader(CustomerProfile? profile, AuthProvider authProvider) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.primary.withOpacity(0.15),
            AppColors.background,
          ],
        ),
      ),
      child: Column(
        children: [
          // Avatar
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.primaryDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(color: AppColors.primary.withOpacity(0.5), width: 3),
              boxShadow: [
                BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 20, spreadRadius: 2),
              ],
            ),
            child: Center(
              child: Text(
                profile?.fullName.isNotEmpty == true
                    ? profile!.fullName[0].toUpperCase()
                    : '?',
                style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            profile?.fullName.isNotEmpty == true ? profile!.fullName : 'Người dùng GymSup',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 4),
          Text(
            profile?.email ?? '',
            style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
          if (profile != null && profile.experienceLevel.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.primary.withOpacity(0.4)),
              ),
              child: Text(
                profile.experienceDisplayName,
                style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ],
      ),
    );
  }

  List<Widget> _buildProfileContent(CustomerProfile profile) {
    final homeProvider = context.watch<HomeProvider>();
    final badges = homeProvider.homeData?.badges ?? [];

    return [
      // Chỉ số cơ thể
      _buildSectionTitle('Chỉ số cơ thể', Icons.monitor_heart_outlined),
      const SizedBox(height: 12),
      Row(
        children: [
          Expanded(child: _buildStatCard('Chiều cao', '${profile.heightCm > 0 ? profile.heightCm : "--"}', 'cm', Icons.height, AppColors.info)),
          const SizedBox(width: 12),
          Expanded(child: _buildStatCard('Cân nặng', '${profile.weightKg > 0 ? profile.weightKg : "--"}', 'kg', Icons.monitor_weight_outlined, AppColors.primary)),
          const SizedBox(width: 12),
          Expanded(child: _buildBmiCard(profile)),
        ],
      ),
      const SizedBox(height: 20),

      // Báo cáo tập luyện
      _buildAnalyticsSection(),
      const SizedBox(height: 20),

      // Thông tin cá nhân
      _buildSectionTitle('Thông tin cá nhân', Icons.person_outline),
      const SizedBox(height: 12),
      _buildInfoCard([
        _buildInfoRow(Icons.calendar_today_outlined, 'Tuổi', profile.age > 0 ? '${profile.age} tuổi' : 'Chưa cập nhật'),
        _buildInfoRow(Icons.wc_outlined, 'Giới tính',
            profile.gender == 'Male' ? 'Nam 👨' : profile.gender == 'Female' ? 'Nữ 👩' : profile.gender.isNotEmpty ? profile.gender : 'Chưa cập nhật'),
      ]),
      const SizedBox(height: 20),

      // Mục tiêu & Lịch tập
      _buildSectionTitle('Mục tiêu & Tập luyện', Icons.flag_outlined),
      const SizedBox(height: 12),
      _buildInfoCard([
        _buildInfoRow(Icons.emoji_events_outlined, 'Mục tiêu', profile.goalDisplayName),
        _buildInfoRow(Icons.trending_up_outlined, 'Trình độ', profile.experienceDisplayName),
        if (profile.injuryNotes.isNotEmpty)
          _buildInfoRow(Icons.health_and_safety_outlined, 'Lưu ý', profile.injuryNotes),
      ]),
      const SizedBox(height: 20),

      // Huy hiệu & Thành tích
      _buildBadgesSection(badges),
      const SizedBox(height: 8),
    ];
  }

  Widget _buildBadgesSection(List<dynamic> badges) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.emoji_events, color: AppColors.primary, size: 18),
                const SizedBox(width: 8),
                const Text('Huy hiệu & Thành tích',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              ],
            ),
            TextButton(
              onPressed: _navigateToAchievements,
              child: const Text('Xem tất cả →',
                  style: TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
        const SizedBox(height: 10),
        badges.isEmpty
            ? GestureDetector(
                onTap: _navigateToAchievements,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 22),
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.surfaceVariant),
                  ),
                  child: const Column(
                    children: [
                      Icon(Icons.emoji_events_outlined, size: 36, color: AppColors.textSecondary),
                      SizedBox(height: 8),
                      Text('Chưa có huy hiệu nào. Hãy bắt đầu tập luyện! 💪',
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          textAlign: TextAlign.center),
                    ],
                  ),
                ),
              )
            : SizedBox(
                height: 90,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: badges.length > 6 ? 6 : badges.length,
                  itemBuilder: (ctx, i) {
                    final badge = badges[i];
                    final String emoji = badge['emoji']?.toString() ?? '🏅';
                    final String name = badge['name']?.toString() ?? '';
                    return GestureDetector(
                      onTap: _navigateToAchievements,
                      child: Container(
                        width: 72,
                        margin: const EdgeInsets.only(right: 10),
                        decoration: BoxDecoration(
                          color: AppColors.cardBackground,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.08),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(emoji, style: const TextStyle(fontSize: 26)),
                            const SizedBox(height: 4),
                            Text(
                              name.replaceAll(RegExp(r'[\u{1F000}-\u{1FFFF}]', unicode: true), '').trim(),
                              style: const TextStyle(fontSize: 9, color: AppColors.textSecondary),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
      ],
    );
  }

  Widget _buildNoProfileCard() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceVariant),
      ),
      child: Column(
        children: [
          const Icon(Icons.assignment_ind_outlined, color: AppColors.textSecondary, size: 48),
          const SizedBox(height: 12),
          const Text('Chưa có hồ sơ thể trạng', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          const Text(
            'Hoàn thành khảo sát để GymSup cá nhân hóa lịch tập và chế độ dinh dưỡng phù hợp với bạn!',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildSurveyButton(CustomerProfile? profile) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: () => context.push('/profile/survey'),
        icon: Icon(profile == null ? Icons.assignment_ind : Icons.edit_outlined, color: Colors.white),
        label: Text(
          profile == null ? 'Làm khảo sát thể trạng' : 'Cập nhật thể trạng',
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
        ),
      ),
    );
  }

  Widget _buildLogoutButton(AuthProvider authProvider) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton.icon(
        onPressed: () async {
          final confirm = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              backgroundColor: AppColors.cardBackground,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text('Đăng xuất', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
              content: const Text('Bạn có chắc muốn đăng xuất không?', style: TextStyle(color: AppColors.textSecondary)),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Hủy', style: TextStyle(color: AppColors.textSecondary)),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Đăng xuất', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          );
          if (confirm == true && mounted) {
            await authProvider.logout();
          }
        },
        icon: const Icon(Icons.logout_rounded, color: AppColors.error),
        label: const Text('Đăng xuất', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.error)),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppColors.error, width: 1),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 18),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, String unit, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.surfaceVariant),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
          Text(unit, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildBmiCard(CustomerProfile profile) {
    final color = _getBmiColor(profile.bmi);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(Icons.monitor_weight_outlined, color: color, size: 22),
          const SizedBox(height: 8),
          Text(
            profile.bmi > 0 ? profile.bmi.toStringAsFixed(1) : '--',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color),
          ),
          Text('BMI', style: TextStyle(fontSize: 11, color: color)),
          const SizedBox(height: 2),
          Text(profile.bmiStatus, style: TextStyle(fontSize: 9, color: color, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildInfoCard(List<Widget> rows) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.surfaceVariant),
      ),
      child: Column(children: rows),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.surfaceVariant, width: 0.5)),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 18),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 14, color: AppColors.textPrimary, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsSection() {
    final stats = _statsPeriod == 'weekly' ? _weeklyStats : _monthlyStats;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.bar_chart_rounded, color: AppColors.primary, size: 18),
                const SizedBox(width: 8),
                const Text(
                  'Báo cáo tập luyện',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
              ],
            ),
            // Period Toggle
            Container(
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.surfaceVariant, width: 0.5),
              ),
              padding: const EdgeInsets.all(2),
              child: Row(
                children: [
                  _buildPeriodTab('weekly', 'Tuần'),
                  _buildPeriodTab('monthly', 'Tháng'),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Chart container
        Container(
          height: 250,
          padding: const EdgeInsets.fromLTRB(10, 20, 20, 10),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.surfaceVariant),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: _isLoadingStats
              ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
              : stats.isEmpty
                  ? const Center(
                      child: Text(
                        'Chưa có dữ liệu tập luyện.',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                      ),
                    )
                  : _buildBarChart(stats),
        ),
      ],
    );
  }

  Widget _buildPeriodTab(String period, String label) {
    final isSelected = _statsPeriod == period;
    return GestureDetector(
      onTap: () {
        setState(() {
          _statsPeriod = period;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildBarChart(List<dynamic> stats) {
    final List<BarChartGroupData> barGroups = [];
    double maxY = 4.0;

    for (int i = 0; i < stats.length; i++) {
      final item = stats[i];
      final val = (item['sessionCount'] as num? ?? 0).toDouble();

      if (val > maxY) {
        maxY = val;
      }

      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: val,
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.primary.withOpacity(0.6)],
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
              ),
              width: 14,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(4),
              ),
            ),
          ],
        ),
      );
    }

    maxY = (maxY * 1.15).ceilToDouble();
    if (maxY == 0) maxY = 4.0;

    return BarChart(
      BarChartData(
        maxY: maxY,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => AppColors.cardBackground.withOpacity(0.9),
            tooltipBorder: const BorderSide(color: AppColors.surfaceVariant, width: 1),
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final label = stats[group.x]['label'] ?? '';
              return BarTooltipItem(
                '$label\n',
                const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 12),
                children: [
                  TextSpan(
                    text: '${rod.toY.round()} buổi',
                    style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ],
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              getTitlesWidget: (value, meta) {
                if (value == meta.max) return const SizedBox.shrink();
                return Text(
                  value.toInt().toString(),
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 10),
                  textAlign: TextAlign.right,
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx >= 0 && idx < stats.length) {
                  final label = stats[idx]['label'] ?? '';
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      label,
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 9, fontWeight: FontWeight.bold),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) => const FlLine(
            color: AppColors.surfaceVariant,
            strokeWidth: 0.5,
          ),
        ),
        borderData: FlBorderData(show: false),
        barGroups: barGroups,
      ),
    );
  }
}
