import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/home_data.dart';

/// Thẻ dinh dưỡng hôm nay: 4 chỉ số ước tính (Calo/Protein/Nước/BMI).
/// Backend chỉ trả về chuỗi hiển thị sẵn (ước tính BMR), không có số liệu
/// phần trăm thật - nên không dùng vòng tròn phần trăm như bản cũ.
class NutritionCard extends StatelessWidget {
  final HomeNutrition nutrition;
  final double? bmi;

  const NutritionCard({super.key, required this.nutrition, this.bmi});

  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.local_fire_department, Colors.orange, 'Calo mục tiêu', nutrition.calories),
      (Icons.fitness_center, AppColors.primary, 'Protein', nutrition.protein),
      (Icons.local_drink, Colors.blue, 'Nước uống', nutrition.water),
      (
        Icons.monitor_weight_outlined,
        AppColors.info,
        'BMI',
        (bmi != null && bmi! > 0) ? bmi!.toStringAsFixed(1) : '—',
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: items.map((item) {
          return Expanded(
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: item.$2.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(item.$1, color: item.$2, size: 20),
                ),
                const SizedBox(height: 8),
                Text(
                  item.$4,
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
                  item.$3,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 10),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
