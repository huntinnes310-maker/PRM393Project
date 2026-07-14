import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/network/api_client.dart';
import '../../../providers/auth_provider.dart';

class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen>
    with SingleTickerProviderStateMixin {
  final ApiClient _apiClient = ApiClient();
  bool _isLoading = true;

  int _totalEarned = 0;
  int _totalAvailable = 0;
  int _currentStreak = 0;
  int _totalWorkouts = 0;
  List<dynamic> _badges = [];

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadBadges());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadBadges() async {
    final auth = context.read<AuthProvider>();
    if (auth.userId == null) return;

    setState(() => _isLoading = true);
    try {
      final res = await _apiClient.get('/badges/${auth.userId}/full');
      if (res.statusCode == 200) {
        final data = ApiClient.decodeResponse(res);
        setState(() {
          _totalEarned     = (data['totalEarned'] as num?)?.toInt() ?? 0;
          _totalAvailable  = (data['totalAvailable'] as num?)?.toInt() ?? 0;
          _currentStreak   = (data['currentStreak'] as num?)?.toInt() ?? 0;
          _totalWorkouts   = (data['totalWorkouts'] as num?)?.toInt() ?? 0;
          _badges          = data['badges'] ?? [];
        });
      }
    } catch (e) {
      debugPrint('Lỗi tải huy hiệu: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final earnedBadges  = _badges.where((b) => b['isEarned'] == true).toList();
    final lockedBadges  = _badges.where((b) => b['isEarned'] != true).toList();

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : NestedScrollView(
              headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
                return <Widget>[
                  SliverAppBar(
                    title: const Text('Kho thành tích 🏆',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                    backgroundColor: AppColors.cardBackground,
                    elevation: 0,
                    pinned: true,
                    floating: true,
                    snap: true,
                    forceElevated: innerBoxIsScrolled,
                  ),
                  SliverPersistentHeader(
                    pinned: false,
                    delegate: _StatsBannerHeaderDelegate(
                      totalEarned: _totalEarned,
                      totalAvailable: _totalAvailable,
                      currentStreak: _currentStreak,
                      totalWorkouts: _totalWorkouts,
                    ),
                  ),
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _SliverAppBarDelegate(
                      TabBar(
                        controller: _tabController,
                        labelColor: AppColors.primary,
                        unselectedLabelColor: AppColors.textSecondary,
                        indicatorColor: AppColors.primary,
                        tabs: [
                          Tab(text: 'Đã đạt ($_totalEarned)'),
                          Tab(text: 'Chưa đạt (${lockedBadges.length})'),
                        ],
                      ),
                    ),
                  ),
                ];
              },
              body: TabBarView(
                controller: _tabController,
                children: [
                  _buildBadgeGrid(earnedBadges, earned: true),
                  _buildBadgeGrid(lockedBadges, earned: false),
                ],
              ),
            ),
    );
  }

  Widget _buildBadgeGrid(List<dynamic> badges, {required bool earned}) {
    if (badges.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              earned ? Icons.emoji_events : Icons.lock_outline,
              size: 56,
              color: AppColors.textSecondary.withOpacity(0.4),
            ),
            const SizedBox(height: 12),
            Text(
              earned
                  ? 'Chưa có huy hiệu nào.\nHãy bắt đầu tập luyện! 💪'
                  : 'Bạn đã mở khóa tất cả huy hiệu! 🎉',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.9,
      ),
      itemCount: badges.length,
      itemBuilder: (ctx, i) {
        final badge = badges[i];
        return _buildBadgeCard(badge, earned: earned);
      },
    );
  }

  Widget _buildBadgeCard(dynamic badge, {required bool earned}) {
    final String name        = badge['name'] ?? '';
    final String emoji       = badge['emoji'] ?? '🏅';
    final int required       = (badge['requiredCount'] as num?)?.toInt() ?? 0;
    final int current        = (badge['currentProgress'] as num?)?.toInt() ?? 0;
    final String type        = badge['badgeType'] ?? '';
    final String? earnedAtStr = badge['earnedAt'] as String?;

    final double progress = required > 0
        ? (current / required).clamp(0.0, 1.0)
        : (earned ? 1.0 : 0.0);

    final Color badgeColor = _getBadgeColor(type);

    return AnimatedOpacity(
      opacity: earned ? 1.0 : 0.55,
      duration: const Duration(milliseconds: 300),
      child: GestureDetector(
        onTap: () => _showBadgeDetail(badge, earned: earned),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: earned
                  ? badgeColor.withOpacity(0.5)
                  : AppColors.surfaceVariant,
              width: earned ? 1.5 : 1,
            ),
            boxShadow: earned
                ? [
                    BoxShadow(
                      color: badgeColor.withOpacity(0.18),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ]
                : [],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Badge icon / emoji
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: earned
                      ? badgeColor.withOpacity(0.12)
                      : AppColors.surfaceVariant.withOpacity(0.6),
                  border: Border.all(
                    color: earned
                        ? badgeColor.withOpacity(0.4)
                        : AppColors.surfaceVariant,
                    width: 2,
                  ),
                ),
                child: earned
                    ? Center(
                        child: Text(emoji,
                            style: const TextStyle(fontSize: 28)))
                    : const Center(
                        child: Icon(Icons.lock_outline,
                            color: AppColors.textSecondary, size: 26)),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  name.replaceAll(RegExp(r'[\u{1F000}-\u{1FFFF}]', unicode: true), '').trim(),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: earned ? AppColors.textPrimary : AppColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              if (!earned) ...[
                // Progress bar for locked badges
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 4,
                          backgroundColor: AppColors.surfaceVariant,
                          valueColor: AlwaysStoppedAnimation<Color>(badgeColor),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$current / $required',
                        style: const TextStyle(
                            fontSize: 10, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ] else if (earnedAtStr != null) ...[
                Text(
                  _formatDate(earnedAtStr),
                  style: TextStyle(
                      fontSize: 10,
                      color: badgeColor,
                      fontWeight: FontWeight.w600),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showBadgeDetail(dynamic badge, {required bool earned}) {
    final String name        = badge['name'] ?? '';
    final String description = badge['description'] ?? '';
    final String emoji       = badge['emoji'] ?? '🏅';
    final int required       = (badge['requiredCount'] as num?)?.toInt() ?? 0;
    final int current        = (badge['currentProgress'] as num?)?.toInt() ?? 0;
    final String type        = badge['badgeType'] ?? '';
    final String? earnedAtStr = badge['earnedAt'] as String?;
    final Color color        = _getBadgeColor(type);
    final double progress    = required > 0 ? (current / required).clamp(0.0, 1.0) : 1.0;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(color: AppColors.surfaceVariant),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: earned ? color.withOpacity(0.12) : AppColors.surfaceVariant,
                border: Border.all(color: earned ? color.withOpacity(0.5) : AppColors.surfaceVariant, width: 2),
              ),
              child: Center(
                child: earned
                    ? Text(emoji, style: const TextStyle(fontSize: 38))
                    : const Icon(Icons.lock_outline, size: 34, color: AppColors.textSecondary),
              ),
            ),
            const SizedBox(height: 16),
            Text(name,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(description,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
            const SizedBox(height: 16),
            if (earned && earnedAtStr != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: color.withOpacity(0.3)),
                ),
                child: Text(
                  '✅ Đạt được vào ${_formatDateFull(earnedAtStr)}',
                  style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
            ] else ...[
              // Progress toward badge
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Tiến độ: $current / $required',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      Text('${(progress * 100).toInt()}%',
                          style: TextStyle(fontSize: 13, color: color, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 10,
                      backgroundColor: AppColors.surfaceVariant,
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Color _getBadgeColor(String type) {
    switch (type) {
      case 'streak':
        return Colors.deepOrange;
      case 'workout':
        return AppColors.primary;
      case 'muscle':
        return Colors.teal;
      default:
        return Colors.amber;
    }
  }

  String _formatDate(String? isoStr) {
    if (isoStr == null) return '';
    try {
      final dt = DateTime.parse(isoStr).toLocal();
      return DateFormat('dd/MM/yyyy').format(dt);
    } catch (_) {
      return '';
    }
  }

  String _formatDateFull(String? isoStr) {
    if (isoStr == null) return '';
    try {
      final dt = DateTime.parse(isoStr).toLocal();
      return DateFormat('dd/MM/yyyy – HH:mm').format(dt);
    } catch (_) {
      return '';
    }
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar);

  final TabBar _tabBar;

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: AppColors.cardBackground,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(covariant _SliverAppBarDelegate oldDelegate) {
    return false;
  }
}

class _StatsBannerHeaderDelegate extends SliverPersistentHeaderDelegate {
  final int totalEarned;
  final int totalAvailable;
  final int currentStreak;
  final int totalWorkouts;

  _StatsBannerHeaderDelegate({
    required this.totalEarned,
    required this.totalAvailable,
    required this.currentStreak,
    required this.totalWorkouts,
  });

  @override
  double get minExtent => 96.0;

  @override
  double get maxExtent => 190.0;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    final double shrinkProgress = (shrinkOffset / (maxExtent - minExtent)).clamp(0.0, 1.0);
    final double percent = totalAvailable > 0 ? totalEarned / totalAvailable : 0.0;

    final margin = EdgeInsets.lerp(
      const EdgeInsets.fromLTRB(16, 14, 16, 0),
      const EdgeInsets.fromLTRB(16, 8, 16, 8),
      shrinkProgress,
    )!;

    final padding = EdgeInsets.lerp(
      const EdgeInsets.all(18),
      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      shrinkProgress,
    )!;

    final double emojiSize = 22.0 - (6.0 * shrinkProgress);
    final double valueSize = 18.0 - (4.0 * shrinkProgress);
    final double labelSize = 11.0 - (2.0 * shrinkProgress);
    final double dividerHeight = 40.0 - (20.0 * shrinkProgress);

    return Container(
      color: AppColors.surface,
      child: Align(
        alignment: Alignment.topCenter,
        child: Container(
          margin: margin,
          padding: padding,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primary.withOpacity(0.85),
                AppColors.primaryDark.withOpacity(0.95),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.35 * (1.0 - shrinkProgress * 0.5)),
                blurRadius: 16.0 - (8.0 * shrinkProgress),
                offset: Offset(0, 6.0 - (3.0 * shrinkProgress)),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildBannerStat('🏅', '$totalEarned / $totalAvailable', 'Huy hiệu', emojiSize, valueSize, labelSize),
                  _buildBannerDivider(dividerHeight),
                  _buildBannerStat('🔥', '$currentStreak', 'Streak ngày', emojiSize, valueSize, labelSize),
                  _buildBannerDivider(dividerHeight),
                  _buildBannerStat('💪', '$totalWorkouts', 'Buổi tập', emojiSize, valueSize, labelSize),
                ],
              ),
              if (shrinkProgress < 0.9)
                Opacity(
                  opacity: (1.0 - shrinkProgress).clamp(0.0, 1.0),
                  child: ClipRect(
                    child: Align(
                      heightFactor: 1.0 - shrinkProgress,
                      alignment: Alignment.topCenter,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(height: 14),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Tiến độ mở khóa',
                                style: TextStyle(color: Colors.white70, fontSize: 12),
                              ),
                              Text(
                                '${(percent * 100).toStringAsFixed(0)}%',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: percent.clamp(0.0, 1.0),
                              minHeight: 8,
                              backgroundColor: Colors.white.withOpacity(0.25),
                              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBannerStat(String emoji, String value, String label, double emojiSize, double valueSize, double labelSize) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(emoji, style: TextStyle(fontSize: emojiSize)),
        const SizedBox(height: 2),
        Text(value,
            style: TextStyle(
                color: Colors.white,
                fontSize: valueSize,
                fontWeight: FontWeight.bold)),
        Text(label,
            style: TextStyle(color: Colors.white70, fontSize: labelSize)),
      ],
    );
  }

  Widget _buildBannerDivider(double height) {
    return Container(
      height: height,
      width: 1,
      color: Colors.white.withOpacity(0.3),
    );
  }

  @override
  bool shouldRebuild(covariant _StatsBannerHeaderDelegate oldDelegate) {
    return oldDelegate.totalEarned != totalEarned ||
        oldDelegate.totalAvailable != totalAvailable ||
        oldDelegate.currentStreak != currentStreak ||
        oldDelegate.totalWorkouts != totalWorkouts;
  }
}
