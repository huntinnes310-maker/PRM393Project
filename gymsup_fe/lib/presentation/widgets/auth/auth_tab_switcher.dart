import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

/// Pill toggle Đăng nhập/Đăng ký. Vì gymsup_fe giữ 2 route riêng (không gộp
/// thành 1 màn hình như gym_support), tap sẽ điều hướng thay vì đổi state cục bộ.
class AuthTabSwitcher extends StatelessWidget {
  final bool isLoginMode;
  final VoidCallback onTapLogin;
  final VoidCallback onTapRegister;

  const AuthTabSwitcher({
    super.key,
    required this.isLoginMode,
    required this.onTapLogin,
    required this.onTapRegister,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Stack(
        children: [
          AnimatedAlign(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeInOut,
            alignment: isLoginMode
                ? Alignment.centerLeft
                : Alignment.centerRight,
            child: FractionallySizedBox(
              widthFactor: 0.5,
              child: Container(
                margin: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onTapLogin,
                  child: Center(
                    child: Text(
                      'Đăng nhập',
                      style: TextStyle(
                        color: isLoginMode
                            ? Colors.white
                            : AppColors.textSecondary,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onTapRegister,
                  child: Center(
                    child: Text(
                      'Đăng ký',
                      style: TextStyle(
                        color: !isLoginMode
                            ? Colors.white
                            : AppColors.textSecondary,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
