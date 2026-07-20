import 'package:flutter/material.dart';
import 'package:percent_indicator/percent_indicator.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/home_data.dart';
import 'muscle_tier.dart';
import 'rank_image.dart';

/// Popup chi tiết 1 nhóm cơ: huy hiệu tier, chỉ số level/XP, thanh tiến trình.
class MuscleDetailModal extends StatelessWidget {
  final MuscleProgress data;
  final VoidCallback onClose;

  const MuscleDetailModal({super.key, required this.data, required this.onClose});

  @override
  Widget build(BuildContext context) {
    final tierColor = muscleTierColor(data.tier);

    return Dialog(
      backgroundColor: AppColors.cardBackground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.topRight,
              child: IconButton(
                onPressed: onClose,
                icon: const Icon(Icons.close, color: AppColors.textSecondary),
              ),
            ),
            RankImage(tier: data.tier, size: 120, isSelected: true),
            const SizedBox(height: 16),
            Text(
              data.name,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: tierColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: tierColor, width: 1),
              ),
              child: Text(
                data.tier,
                style: TextStyle(
                  color: tierColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            if (data.isLagging) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.info_outline, color: AppColors.warning, size: 16),
                    SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'Nhóm cơ này đang tập ít hơn so với các nhóm khác',
                        style: TextStyle(color: AppColors.warning, fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(child: _StatCell(label: 'Cấp độ', value: 'Lv.${data.level}')),
                Expanded(child: _StatCell(label: 'Tổng XP', value: '${data.totalExp}')),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _StatCell(
                    label: 'XP hiện tại',
                    value: '${data.currentLevelExp}/${data.expToNextLevel}',
                  ),
                ),
                Expanded(
                  child: _StatCell(
                    label: 'Còn lại',
                    value: '${data.expToNextLevel - data.currentLevelExp} XP',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            LinearPercentIndicator(
              lineHeight: 10,
              percent: data.progress.clamp(0.0, 1.0),
              linearGradient: const LinearGradient(colors: AppColors.expGradient),
              backgroundColor: AppColors.surfaceVariant,
              barRadius: const Radius.circular(6),
              animation: true,
              padding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  final String label;
  final String value;

  const _StatCell({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
          ),
        ],
      ),
    );
  }
}
