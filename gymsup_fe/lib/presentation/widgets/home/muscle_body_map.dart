import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/home_data.dart';
import 'muscle_tier.dart';

/// Bản đồ cơ thể: tô màu từng nhóm cơ theo tier, lật mặt trước/sau.
/// Chỉ hiển thị, không có tương tác bấm/phát sáng/hiện popup trên từng vùng cơ.
class MuscleBodyMap extends StatefulWidget {
  final List<MuscleProgress> items;

  const MuscleBodyMap({super.key, required this.items});

  @override
  State<MuscleBodyMap> createState() => _MuscleBodyMapState();
}

class _MuscleBodyMapState extends State<MuscleBodyMap> {
  bool _showFront = true;

  /// Ánh xạ tên cơ (tiếng Anh/Việt, so khớp gần đúng) sang ảnh mask + mặt hiển thị.
  /// Lưu ý: calves/forearms/adductors/shoulders_lateral có cả ảnh mask mặt trước
  /// lẫn mặt sau trên đĩa, nhưng chỉ mặt trước được dùng - giữ nguyên như bản gốc.
  (bool isFront, String path)? _muscleToMask(String name) {
    final n = name.toLowerCase().trim();

    if (n.contains('chest') || n.contains('ngực')) {
      return (true, 'assets/body/masks/front_chest.png');
    }
    if (n.contains('bicep') || n.contains('nhị đầu')) {
      return (true, 'assets/body/masks/front_biceps.png');
    }
    if (n.contains('quad') || n.contains('đùi trước')) {
      return (true, 'assets/body/masks/front_quads.png');
    }
    if (n.contains('abs') || n.contains('bụng') || n.contains('abdomin')) {
      return (true, 'assets/body/masks/front_abs.png');
    }
    if (n.contains('core')) {
      return (true, 'assets/body/masks/front_core.png');
    }
    if (n.contains('oblique')) {
      return (true, 'assets/body/masks/front_obliques.png');
    }
    if (n.contains('forearm') || n.contains('cẳng tay')) {
      return (true, 'assets/body/masks/front_forearms.png');
    }
    if (n.contains('calf') || n.contains('calves') || n.contains('bắp chân')) {
      return (true, 'assets/body/masks/front_calves.png');
    }
    if (n.contains('adductor')) {
      return (true, 'assets/body/masks/front_adductors.png');
    }
    if (n.contains('anterior delt') ||
        n.contains('front delt') ||
        n.contains('vai trước')) {
      return (true, 'assets/body/masks/front_shoulders_anterior.png');
    }
    if (n.contains('lateral delt') ||
        n.contains('side delt') ||
        n.contains('vai bên') ||
        n.contains('shoulder') ||
        n.contains('vai')) {
      return (true, 'assets/body/masks/front_shoulders_lateral.png');
    }

    if (n.contains('lat') || n.contains('lưng rộng') || n.contains('latissimus')) {
      return (false, 'assets/body/masks/back_lats.png');
    }
    if (n.contains('trap') || n.contains('trapezius') || n.contains('thang')) {
      return (false, 'assets/body/masks/back_traps.png');
    }
    if (n.contains('tricep') || n.contains('tam đầu')) {
      return (false, 'assets/body/masks/back_triceps.png');
    }
    if (n.contains('hamstring') || n.contains('đùi sau')) {
      return (false, 'assets/body/masks/back_hamstrings.png');
    }
    if (n.contains('glute') || n.contains('gluteus') || n.contains('mông')) {
      return (false, 'assets/body/masks/back_glute.png');
    }
    if (n.contains('rear delt') ||
        n.contains('posterior delt') ||
        n.contains('vai sau')) {
      return (false, 'assets/body/masks/back_shoulders_posterior.png');
    }
    if (n.contains('rhomboid')) {
      return (false, 'assets/body/masks/back_rhomboids.png');
    }
    if (n.contains('teres')) {
      return (false, 'assets/body/masks/back_teres_major.png');
    }
    if (n.contains('back') || n.contains('lưng')) {
      return (false, 'assets/body/masks/back_lats.png');
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
        ),
        child: const Column(
          children: [
            Icon(Icons.person_outline, color: AppColors.textHint, size: 48),
            SizedBox(height: 12),
            Text(
              'Chưa có dữ liệu tiến độ',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
          ],
        ),
      );
    }

    final maskColors = <String, MuscleProgress>{};
    for (final item in widget.items) {
      final mapping = _muscleToMask(item.name);
      if (mapping == null) continue;
      final (isFront, path) = mapping;
      if (isFront != _showFront) continue;
      maskColors[path] = item;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Bản đồ cơ bắp',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              GestureDetector(
                onTap: () => setState(() => _showFront = !_showFront),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(50),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.flip_camera_android_outlined,
                        color: AppColors.primary,
                        size: 15,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _showFront ? 'Mặt trước' : 'Mặt sau',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 280,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
              child: KeyedSubtree(
                key: ValueKey(_showFront),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Opacity(
                      opacity: 0.15,
                      child: Image.asset(
                        _showFront ? 'assets/body/body_front.png' : 'assets/body/body_back.png',
                        height: 280,
                        fit: BoxFit.contain,
                      ),
                    ),
                    ...maskColors.entries.map((entry) {
                      final tierColor = muscleTierColor(entry.value.tier);
                      return Image.asset(
                        entry.key,
                        height: 280,
                        fit: BoxFit.contain,
                        color: tierColor.withValues(alpha: 0.8),
                        colorBlendMode: BlendMode.srcIn,
                      );
                    }),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 12,
            runSpacing: 8,
            children: kMuscleTiers
                .map((tier) => _TierLegendItem(tier, muscleTierColor(tier)))
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _TierLegendItem extends StatelessWidget {
  final String label;
  final Color color;

  const _TierLegendItem(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 4)],
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
