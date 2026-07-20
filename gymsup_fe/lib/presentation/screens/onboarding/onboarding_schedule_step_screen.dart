import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/static/onboarding_options.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/onboarding_provider.dart';
import '../../../providers/profile_provider.dart';
import '../../widgets/onboarding/schedule_option_card.dart';

/// Bước 4/4 (cuối) của onboarding: chọn tần suất tập luyện rồi lưu hồ sơ.
class OnboardingScheduleStepScreen extends StatefulWidget {
  const OnboardingScheduleStepScreen({super.key});

  @override
  State<OnboardingScheduleStepScreen> createState() =>
      _OnboardingScheduleStepScreenState();
}

class _OnboardingScheduleStepScreenState
    extends State<OnboardingScheduleStepScreen> {
  bool _isSaving = false;

  Future<void> _finish() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    final userId = context.read<AuthProvider>().userId ?? '';
    final onboarding = context.read<OnboardingProvider>();
    final profileProvider = context.read<ProfileProvider>();

    final ok = await profileProvider.saveProfile(
      userId: userId,
      gender: onboarding.gender,
      age: onboarding.age,
      heightCm: onboarding.heightCm,
      weightKg: onboarding.weightKg,
      goal: onboarding.selectedGoals.join(', '),
      // Backend không có field lịch tập riêng - tái sử dụng experienceLevel
      // để lưu tần suất đã chọn, giống cách gym_support đang làm.
      experienceLevel: onboarding.selectedSchedule,
    );

    if (!mounted) return;

    if (ok) {
      context.read<AuthProvider>().markOnboardingComplete();
      context.go('/home');
    } else {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            profileProvider.saveMessage ?? 'Không thể lưu hồ sơ.',
          ),
          backgroundColor: AppColors.error,
        ),
      );
    }
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
                'Lịch tập luyện',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Chọn tần suất phù hợp với lối sống của bạn',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 20),
              ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: const SizedBox(
                  height: 4,
                  child: LinearProgressIndicator(
                    value: 1.0,
                    backgroundColor: AppColors.surfaceVariant,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 28),

              ...kOnboardingSchedules.map((schedule) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: ScheduleOptionCard(
                    schedule: schedule,
                    isSelected: onboarding.selectedSchedule == schedule.title,
                    onTap: () => onboarding.setSchedule(schedule.title),
                  ),
                );
              }),
              const SizedBox(height: 16),

              Row(
                children: [
                  SizedBox(
                    width: 100,
                    height: 52,
                    child: OutlinedButton(
                      onPressed: _isSaving ? null : () => context.pop(),
                      child: const Text('Quay lại'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _finish,
                        child: _isSaving
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Bắt đầu ngay'),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
