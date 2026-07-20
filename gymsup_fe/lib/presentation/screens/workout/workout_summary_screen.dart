import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/finish_workout_result.dart';

/// Màn hình tổng kết sau khi hoàn thành buổi tập.
class WorkoutSummaryScreen extends StatelessWidget {
  final FinishWorkoutResult result;

  const WorkoutSummaryScreen({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final session = result.session;
    final minutes = (session.totalDurationSeconds / 60).round();

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const SizedBox(height: 20),
            const Icon(Icons.emoji_events, color: AppColors.goldBadge, size: 72),
            const SizedBox(height: 16),
            const Text(
              'Hoàn thành buổi tập! 🎉',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(child: _StatTile(label: 'Thời gian', value: '$minutes phút')),
                const SizedBox(width: 10),
                Expanded(child: _StatTile(label: 'Tổng số set', value: '${session.totalSets}')),
                const SizedBox(width: 10),
                Expanded(child: _StatTile(label: 'EXP nhận', value: '+${session.totalExpGained}')),
              ],
            ),
            if (result.currentStreak > 0) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.local_fire_department, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text(
                      'Chuỗi tập luyện: ${result.currentStreak} ngày',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ],
            if (result.newBadge != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.goldBadge.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.goldBadge),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.military_tech, color: AppColors.goldBadge),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Huy hiệu mới: ${result.newBadge!.name}',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (session.muscleExpGains.isNotEmpty) ...[
              const SizedBox(height: 20),
              const Text('Tiến độ cơ bắp', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
              const SizedBox(height: 10),
              ...session.muscleExpGains.map((gain) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Expanded(child: Text(gain.muscleName)),
                        Text('+${gain.expGained} XP', style: const TextStyle(color: AppColors.primary)),
                        if (gain.isLevelUp) ...[
                          const SizedBox(width: 8),
                          Text('Lv.${gain.oldLevel}→${gain.newLevel} 🎉'),
                        ],
                      ],
                    ),
                  )),
            ],
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => context.go('/home'),
                child: const Text('Về trang chủ'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;

  const _StatTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Text(value, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
        ],
      ),
    );
  }
}
