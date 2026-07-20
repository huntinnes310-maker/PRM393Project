import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

/// Huy hiệu tier (Iron..Champion) dạng ảnh, dùng cho muscle progress.
class RankImage extends StatelessWidget {
  final String tier;
  final double size;
  final bool isSelected;
  final bool showContainer;

  const RankImage({
    super.key,
    required this.tier,
    this.size = 100,
    this.isSelected = false,
    this.showContainer = true,
  });

  String _assetPath(String tier) {
    switch (tier.toLowerCase()) {
      case 'iron':
        return 'assets/images/ranks/rank_iron.png';
      case 'bronze':
        return 'assets/images/ranks/rank_bronze.png';
      case 'silver':
        return 'assets/images/ranks/rank_silver.png';
      case 'gold':
        return 'assets/images/ranks/rank_gold.png';
      case 'platinum':
        return 'assets/images/ranks/rank_platinum.png';
      case 'diamond':
        return 'assets/images/ranks/rank_diamond.png';
      case 'champion':
      case 'legend':
        return 'assets/images/ranks/rank_legend.png';
      default:
        return 'assets/images/ranks/rank_iron.png';
    }
  }

  @override
  Widget build(BuildContext context) {
    final rankImage = AnimatedScale(
      scale: isSelected ? 1.1 : 1.0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.elasticOut,
      child: AnimatedOpacity(
        opacity: isSelected ? 1.0 : 0.9,
        duration: const Duration(milliseconds: 300),
        child: Image.asset(
          _assetPath(tier),
          width: size,
          height: size,
          fit: BoxFit.contain,
        ),
      ),
    );

    if (!showContainer) return rankImage;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(size * 0.15),
      ),
      child: rankImage,
    );
  }
}
