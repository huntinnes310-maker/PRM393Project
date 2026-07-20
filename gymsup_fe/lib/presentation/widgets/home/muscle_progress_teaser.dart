import 'package:flutter/material.dart';
import 'package:percent_indicator/percent_indicator.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/home_data.dart';
import 'rank_image.dart';

/// Tóm tắt tiến độ cơ bắp trên Home: 3 chỉ số nhanh + top 3 nhóm cơ mạnh nhất.
class MuscleProgressTeaser extends StatelessWidget {
  final List<MuscleProgress> muscleProgress;
  final VoidCallback onViewAll;

  const MuscleProgressTeaser({
    super.key,
    required this.muscleProgress,
    required this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    if (muscleProgress.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
        ),
        child: const Center(
          child: Text(
            'Chưa có tiến trình cơ bắp nào ghi nhận.',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
      );
    }

    final sorted = List<MuscleProgress>.from(muscleProgress)
      ..sort((a, b) {
        if (b.level != a.level) return b.level.compareTo(a.level);
        return b.totalExp.compareTo(a.totalExp);
      });
    final top3 = sorted.take(3).toList();
    final highest = sorted.first;
    final lowest = sorted.last;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _StatChip(label: 'Cơ bắp', value: '${muscleProgress.length}'),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatChip(label: 'Cao nhất', value: 'Lv.${highest.level}'),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatChip(label: 'Yếu nhất', value: lowest.name),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...top3.asMap().entries.map((e) {
            final index = e.key;
            final mp = e.value;
            return Padding(
              padding: EdgeInsets.only(bottom: index == top3.length - 1 ? 0 : 14),
              child: Row(
                children: [
                  RankImage(tier: mp.tier, size: 36, showContainer: false),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                              'Lv.${mp.level}',
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        LinearPercentIndicator(
                          lineHeight: 7,
                          percent: mp.progress.clamp(0.0, 1.0),
                          linearGradient: const LinearGradient(
                            colors: AppColors.expGradient,
                          ),
                          backgroundColor: AppColors.surfaceVariant,
                          barRadius: const Radius.circular(4),
                          animation: true,
                          padding: EdgeInsets.zero,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: onViewAll,
              child: const Text('Xem chi tiết'),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;

  const _StatChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13,
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
