import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/onboarding_provider.dart';
import '../../../providers/profile_provider.dart';
import '../../widgets/onboarding/gender_select_button.dart';
import '../../widgets/onboarding/step_indicator.dart';

/// Bước 1/4 của onboarding: xác nhận tên (chỉ đọc, lấy từ lúc đăng ký) + giới tính + tuổi.
class OnboardingNameStepScreen extends StatefulWidget {
  const OnboardingNameStepScreen({super.key});

  @override
  State<OnboardingNameStepScreen> createState() =>
      _OnboardingNameStepScreenState();
}

class _OnboardingNameStepScreenState extends State<OnboardingNameStepScreen> {
  final _ageController = TextEditingController();

  static const _genders = [
    {'value': 'Male', 'label': 'Nam'},
    {'value': 'Female', 'label': 'Nữ'},
    {'value': 'Other', 'label': 'Khác'},
  ];

  @override
  void initState() {
    super.initState();
    final onboarding = context.read<OnboardingProvider>();
    onboarding.reset();
    final userId = context.read<AuthProvider>().userId;
    if (userId != null) {
      context.read<ProfileProvider>().fetchProfile(userId);
    }
  }

  @override
  void dispose() {
    _ageController.dispose();
    super.dispose();
  }

  void _goNext() {
    final age = int.tryParse(_ageController.text) ?? 0;
    context.read<OnboardingProvider>().setAge(age);
    context.push('/onboarding/metrics');
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<ProfileProvider>().profile;
    final onboarding = context.watch<OnboardingProvider>();

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.waving_hand, color: AppColors.primary, size: 48),
              const SizedBox(height: 16),
              Text(
                'Chào mừng bạn!',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Hãy cho GymSup biết thêm một chút về bạn',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 20),
              const StepIndicator(currentStep: 1, totalSteps: 4),
              const SizedBox(height: 28),

              const Text(
                'Tên của bạn',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(
                  profile?.fullName.isNotEmpty == true
                      ? profile!.fullName
                      : 'Đang tải...',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              const Text(
                'Giới tính',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: _genders.map((g) {
                  final isSelected = onboarding.gender == g['value'];
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GenderSelectButton(
                        label: g['label']!,
                        isSelected: isSelected,
                        onTap: () => onboarding.setGender(g['value']!),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              const Text(
                'Tuổi (không bắt buộc)',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _ageController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(hintText: 'VD: 22'),
              ),
              const SizedBox(height: 28),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _goNext,
                  child: const Text('Tiếp tục'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
