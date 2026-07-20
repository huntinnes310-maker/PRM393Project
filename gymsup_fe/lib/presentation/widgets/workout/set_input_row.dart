import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

/// 1 dòng nhập set: số set, cân nặng, số reps, nút xác nhận hoàn thành set.
class SetInputRow extends StatelessWidget {
  final int setNumber;
  final TextEditingController weightController;
  final TextEditingController repsController;
  final bool isDone;
  final bool isSaving;
  final VoidCallback onConfirm;

  const SetInputRow({
    super.key,
    required this.setNumber,
    required this.weightController,
    required this.repsController,
    required this.isDone,
    required this.onConfirm,
    this.isSaving = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDone
            ? AppColors.primary.withValues(alpha: 0.08)
            : AppColors.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDone ? AppColors.primary.withValues(alpha: 0.4) : AppColors.border,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              shape: BoxShape.circle,
            ),
            child: Text(
              '$setNumber',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: weightController,
              enabled: !isDone,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Kg',
                isDense: true,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: repsController,
              enabled: !isDone,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Reps',
                isDense: true,
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 40,
            height: 40,
            child: isSaving
                ? const Padding(
                    padding: EdgeInsets.all(8),
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : IconButton(
                    onPressed: isDone ? null : onConfirm,
                    icon: Icon(
                      isDone ? Icons.check_circle : Icons.check_circle_outline,
                      color: isDone ? AppColors.success : AppColors.textHint,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
