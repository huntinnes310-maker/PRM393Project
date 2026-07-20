import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_images.dart';

/// Banner ảnh + gradient scrim ở đầu màn hình đăng nhập/đăng ký, giống gym_support.
class AuthHeroHeader extends StatelessWidget {
  const AuthHeroHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 280,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            AppImages.gymHero,
            fit: BoxFit.cover,
            alignment: Alignment.center,
            errorBuilder: (_, _, _) =>
                Container(color: AppColors.surfaceVariant),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.55),
                  Colors.black.withValues(alpha: 0.35),
                  AppColors.background,
                ],
                stops: const [0.0, 0.55, 1.0],
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: const [
                  Text(
                    'GymSup',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.8,
                      shadows: [
                        Shadow(
                          color: Colors.black87,
                          blurRadius: 16,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Đồng hành cùng hành trình tập luyện của bạn',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      height: 1.4,
                      shadows: [
                        Shadow(
                          color: Colors.black87,
                          blurRadius: 12,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
