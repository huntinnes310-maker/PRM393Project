import 'package:flutter/material.dart';

/// Hàng nút Back/Continue dùng chung cho các bước 2-4 của onboarding.
class OnboardingNavButtons extends StatelessWidget {
  final VoidCallback onBack;
  final VoidCallback onNext;
  final String nextLabel;
  final bool loading;

  const OnboardingNavButtons({
    super.key,
    required this.onBack,
    required this.onNext,
    this.nextLabel = 'Tiếp tục',
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 100,
          height: 52,
          child: OutlinedButton(
            onPressed: loading ? null : onBack,
            child: const Text('Quay lại'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: loading ? null : onNext,
              child: loading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(nextLabel),
            ),
          ),
        ),
      ],
    );
  }
}
