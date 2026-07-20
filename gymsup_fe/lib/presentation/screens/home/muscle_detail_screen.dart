import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/home_data.dart';
import '../../widgets/home/muscle_body_map.dart';
import '../../widgets/home/muscle_detail_modal.dart';
import '../../widgets/home/muscle_tier.dart';
import '../../widgets/home/rank_image.dart';

/// Màn hình chi tiết toàn bộ tiến độ cơ bắp: bản đồ cơ thể + danh sách đầy đủ.
/// Nhận sẵn dữ liệu từ HomeProvider (đã fetch khi vào Home) - không gọi API lại.
class MuscleDetailScreen extends StatelessWidget {
  final List<MuscleProgress> muscleProgress;

  const MuscleDetailScreen({super.key, required this.muscleProgress});

  void _showDetail(BuildContext context, MuscleProgress mp) {
    showDialog(
      context: context,
      builder: (context) => MuscleDetailModal(
        data: mp,
        onClose: () => Navigator.pop(context),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sorted = List<MuscleProgress>.from(muscleProgress)
      ..sort((a, b) {
        if (b.level != a.level) return b.level.compareTo(a.level);
        return b.totalExp.compareTo(a.totalExp);
      });
    final top6 = sorted.take(6).toList();

    final totalExp = muscleProgress.fold<int>(0, (sum, m) => sum + m.totalExp);
    final avgLevel = muscleProgress.isEmpty
        ? 0
        : (muscleProgress.fold<int>(0, (sum, m) => sum + m.level) / muscleProgress.length);
    final laggingCount = muscleProgress.where((m) => m.isLagging).length;
    final highestLevel = muscleProgress.isEmpty
        ? 0
        : muscleProgress.map((m) => m.level).reduce((a, b) => a > b ? a : b);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Tiến độ cơ bắp 💪',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        backgroundColor: AppColors.cardBackground,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Row(
            children: [
              Expanded(child: _StatCard(label: 'Tổng XP', value: '$totalExp')),
              const SizedBox(width: 10),
              Expanded(
                child: _StatCard(label: 'Cấp TB', value: avgLevel.toStringAsFixed(1)),
              ),
              const SizedBox(width: 10),
              Expanded(child: _StatCard(label: 'Cao nhất', value: 'Lv.$highestLevel')),
              const SizedBox(width: 10),
              Expanded(child: _StatCard(label: 'Đang yếu', value: '$laggingCount')),
            ],
          ),
          const SizedBox(height: 20),
          MuscleBodyMap(items: muscleProgress),
          const SizedBox(height: 24),
          const Text(
            'Top nhóm cơ',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 6,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            children: top6.map((mp) {
              return GestureDetector(
                onTap: () => _showDetail(context, mp),
                child: RankImage(tier: mp.tier, size: 48),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          const Text(
            'Tất cả nhóm cơ',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          ...sorted.map((mp) {
            final tierColor = muscleTierColor(mp.tier);
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: InkWell(
                onTap: () => _showDetail(context, mp),
                borderRadius: BorderRadius.circular(14),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(color: tierColor, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            mp.name,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            'Lv.${mp.level} · ${(mp.progress * 100).toStringAsFixed(0)}% · ${mp.totalExp} XP',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: AppColors.textHint),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;

  const _StatCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 10),
          ),
        ],
      ),
    );
  }
}
