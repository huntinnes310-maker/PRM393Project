import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/static/onboarding_options.dart';
import '../../../providers/onboarding_provider.dart';
import '../../widgets/onboarding/goal_option_card.dart';
import '../../widgets/onboarding/onboarding_nav_buttons.dart';
import '../../widgets/onboarding/step_indicator.dart';

/// Bước 3/4 của onboarding: chọn (đa lựa chọn) mục tiêu tập luyện.
class OnboardingGoalStepScreen extends StatelessWidget {
  const OnboardingGoalStepScreen({super.key});

  void _goNext(BuildContext context) {
    final onboarding = context.read<OnboardingProvider>();
    if (onboarding.selectedGoals.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn ít nhất 1 mục tiêu')),
      );
      return;
    }
    context.push('/onboarding/schedule');
  }

  @override
  Widget build(BuildContext context) {
    final onboarding = context.watch<OnboardingProvider>();

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Mục tiêu của bạn?',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Chọn những gì bạn muốn đạt được (có thể chọn nhiều)',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 20),
              const StepIndicator(currentStep: 3, totalSteps: 4),
              const SizedBox(height: 28),

              if (onboarding.selectedGoals.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.check_circle,
                        color: Colors.white,
                        size: 14,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${onboarding.selectedGoals.length} mục tiêu đã chọn',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              ...kOnboardingGoals.map((goal) {
                final isSelected = onboarding.selectedGoals.contains(
                  goal.title,
                );
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: GoalOptionCard(
                    goal: goal,
                    isSelected: isSelected,
                    onTap: () => onboarding.toggleGoal(goal.title),
                  ),
                );
              }),
              const SizedBox(height: 16),

              OnboardingNavButtons(
                onBack: () => context.pop(),
                onNext: () => _goNext(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
