import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/workout_plan.dart';

/// Thẻ hiển thị 1 lịch tập trong danh sách - dùng chung cho WorkoutPlansScreen.
class PlanListCard extends StatelessWidget {
  final WorkoutPlan plan;
  final VoidCallback onTap;
  final VoidCallback? onActivate;

  const PlanListCard({
    super.key,
    required this.plan,
    required this.onTap,
    this.onActivate,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: AppColors.cardBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.surfaceVariant),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: plan.isActive
                      ? AppColors.primary.withValues(alpha: 0.15)
                      : AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.fitness_center,
                  color: plan.isActive ? AppColors.primary : AppColors.textHint,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            plan.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (plan.isActive)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: const Text(
                              'Đang dùng',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${plan.goal.isNotEmpty ? plan.goal : "Chưa có mục tiêu"} · ${plan.daysPerWeek} ngày/tuần',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (!plan.isActive && onActivate != null)
                TextButton(
                  onPressed: onActivate,
                  child: const Text('Kích hoạt'),
                )
              else
                const Icon(Icons.chevron_right, color: AppColors.textHint),
            ],
          ),
        ),
      ),
    );
  }
}
