import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

/// Thanh chỉ báo bước dạng chấm tròn nối nhau, dùng cho wizard onboarding.
class StepIndicator extends StatelessWidget {
  final int currentStep;
  final int totalSteps;

  const StepIndicator({
    super.key,
    required this.currentStep,
    required this.totalSteps,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(totalSteps * 2 - 1, (i) {
        if (i.isOdd) {
          final stepIndex = (i ~/ 2) + 1;
          final filled = stepIndex < currentStep;
          return Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: 2,
              decoration: BoxDecoration(
                color: filled ? AppColors.primary : AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          );
        }

        final stepIndex = i ~/ 2 + 1;
        final isDone = stepIndex < currentStep;
        final isActive = stepIndex == currentStep;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: (isDone || isActive)
                ? AppColors.primary
                : AppColors.surfaceVariant,
            shape: BoxShape.circle,
            border: (!isDone && !isActive)
                ? Border.all(color: AppColors.border)
                : null,
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.35),
                      blurRadius: 8,
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: isDone
                ? const Icon(Icons.check, color: Colors.white, size: 14)
                : Text(
                    '$stepIndex',
                    style: TextStyle(
                      color: isActive ? Colors.white : AppColors.textHint,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
          ),
        );
      }),
    );
  }
}
