import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../providers/onboarding_provider.dart';
import '../../widgets/onboarding/onboarding_nav_buttons.dart';
import '../../widgets/onboarding/step_indicator.dart';

/// Bước 2/4 của onboarding: cân nặng + chiều cao, xem trước BMI.
class OnboardingMetricsStepScreen extends StatefulWidget {
  const OnboardingMetricsStepScreen({super.key});

  @override
  State<OnboardingMetricsStepScreen> createState() =>
      _OnboardingMetricsStepScreenState();
}

class _OnboardingMetricsStepScreenState
    extends State<OnboardingMetricsStepScreen> {
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  double _bmi = 0;

  @override
  void initState() {
    super.initState();
    final onboarding = context.read<OnboardingProvider>();
    if (onboarding.weightKg > 0) {
      _weightController.text = onboarding.weightKg.toString();
    }
    if (onboarding.heightCm > 0) {
      _heightController.text = onboarding.heightCm.toString();
    }
    _recalcBmi();
  }

  @override
  void dispose() {
    _weightController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  void _recalcBmi() {
    final w = double.tryParse(_weightController.text) ?? 0;
    final h = double.tryParse(_heightController.text) ?? 0;
    setState(() {
      if (w > 0 && h > 0) {
        final hm = h / 100.0;
        _bmi = double.parse((w / (hm * hm)).toStringAsFixed(1));
      } else {
        _bmi = 0;
      }
    });
  }

  String _bmiStatus(double bmi) {
    if (bmi <= 0) return '';
    if (bmi < 18.5) return 'Thiếu cân';
    if (bmi < 25.0) return 'Bình thường';
    if (bmi < 30.0) return 'Thừa cân';
    return 'Béo phì';
  }

  Color _bmiColor(double bmi) {
    if (bmi <= 0) return AppColors.textSecondary;
    if (bmi < 18.5) return Colors.amber;
    if (bmi < 25.0) return Colors.green;
    if (bmi < 30.0) return Colors.orange;
    return AppColors.error;
  }

  void _goNext() {
    final weight = int.tryParse(_weightController.text) ?? 0;
    final height = int.tryParse(_heightController.text) ?? 0;
    if (weight <= 0 || height <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập cân nặng và chiều cao')),
      );
      return;
    }
    context.read<OnboardingProvider>().setMetrics(
          heightCm: height,
          weightKg: weight,
        );
    context.push('/onboarding/goal');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Chỉ số cơ thể',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Giúp GymSup tính BMI và cá nhân hóa lịch tập',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 20),
              const StepIndicator(currentStep: 2, totalSteps: 4),
              const SizedBox(height: 28),

              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _weightController,
                      keyboardType: TextInputType.number,
                      onChanged: (_) => _recalcBmi(),
                      decoration: const InputDecoration(
                        labelText: 'Cân nặng',
                        suffixText: 'kg',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _heightController,
                      keyboardType: TextInputType.number,
                      onChanged: (_) => _recalcBmi(),
                      decoration: const InputDecoration(
                        labelText: 'Chiều cao',
                        suffixText: 'cm',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              if (_bmi > 0)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: _bmiColor(_bmi).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _bmiColor(_bmi).withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.monitor_weight_outlined,
                        color: _bmiColor(_bmi),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'BMI: ${_bmi.toStringAsFixed(1)}  •  ${_bmiStatus(_bmi)}',
                        style: TextStyle(
                          color: _bmiColor(_bmi),
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 28),

              OnboardingNavButtons(
                onBack: () => context.pop(),
                onNext: _goNext,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
