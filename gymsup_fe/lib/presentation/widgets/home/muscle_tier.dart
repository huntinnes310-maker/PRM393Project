import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

/// Màu đại diện cho 1 tier cơ bắp (Iron -> Champion), dùng chung cho
/// body map, teaser, modal, detail screen thay vì lặp lại switch ở từng nơi.
Color muscleTierColor(String tier) {
  switch (tier.toLowerCase()) {
    case 'bronze':
      return AppColors.bronzeBadge;
    case 'silver':
      return AppColors.silverBadge;
    case 'gold':
      return AppColors.goldBadge;
    case 'platinum':
      return AppColors.platinumBadge;
    case 'diamond':
      return AppColors.diamondBadge;
    case 'champion':
    case 'legend':
      return AppColors.championBadge;
    case 'iron':
    default:
      return AppColors.ironBadge;
  }
}

const List<String> kMuscleTiers = [
  'Iron',
  'Bronze',
  'Silver',
  'Gold',
  'Platinum',
  'Diamond',
  'Champion',
];
