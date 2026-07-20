import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/workout_plan.dart';

/// Hàng chip chọn ngày trong tuần (T2..CN), giá trị lưu là tên tiếng Anh.
class DayOfWeekSelector extends StatelessWidget {
  final Set<String> selectedDays;
  final ValueChanged<String> onToggle;

  const DayOfWeekSelector({
    super.key,
    required this.selectedDays,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: kWeekDays.map((d) {
        final value = d['value']!;
        final isSelected = selectedDays.contains(value);
        return GestureDetector(
          onTap: () => onToggle(value),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary : AppColors.cardBackground,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? AppColors.primary : AppColors.border,
              ),
            ),
            child: Center(
              child: Text(
                d['label']!,
                style: TextStyle(
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
