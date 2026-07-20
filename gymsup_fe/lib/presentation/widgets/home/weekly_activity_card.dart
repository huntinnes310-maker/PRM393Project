import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../common/app_card.dart';

const _kDayLabels = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];

/// Số buổi tập đã hoàn thành trong tuần này + 7 chấm ngày (T2-CN), tính thật
/// từ `history` (không copy logic "mọi ngày trước hôm nay coi như đã tập"
/// của bản gốc, vì đó chỉ là hiệu ứng thị giác không phản ánh dữ liệu thật).
class WeeklyActivityCard extends StatelessWidget {
  final List<dynamic> history;

  const WeeklyActivityCard({super.key, required this.history});

  Set<DateTime> _completedDatesThisWeek(DateTime startOfWeek, DateTime endOfWeek) {
    final dates = <DateTime>{};
    for (final entry in history) {
      if (entry is! Map) continue;
      final status = entry['status']?.toString().toUpperCase() ?? '';
      if (status != 'COMPLETED') continue;
      final raw = entry['endTime'] ?? entry['startTime'];
      if (raw == null) continue;
      final parsed = DateTime.tryParse(raw.toString())?.toLocal();
      if (parsed == null) continue;
      final dateOnly = DateTime(parsed.year, parsed.month, parsed.day);
      if (dateOnly.isBefore(startOfWeek) || !dateOnly.isBefore(endOfWeek)) continue;
      dates.add(dateOnly);
    }
    return dates;
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 7));
    final completed = _completedDatesThisWeek(startOfWeek, endOfWeek);

    return AppCard(
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${completed.length} buổi',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'Tuần này',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
            ],
          ),
          const Spacer(),
          Row(
            children: List.generate(7, (i) {
              final day = startOfWeek.add(Duration(days: i));
              final isDone = completed.contains(day);
              final isToday = day == today;
              return Padding(
                padding: const EdgeInsets.only(left: 6),
                child: Column(
                  children: [
                    Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: isDone
                            ? AppColors.primary
                            : AppColors.surfaceVariant,
                        shape: BoxShape.circle,
                        border: isToday
                            ? Border.all(color: AppColors.primary, width: 1.5)
                            : null,
                      ),
                      child: isDone
                          ? const Icon(Icons.check, color: Colors.white, size: 14)
                          : null,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _kDayLabels[i],
                      style: TextStyle(
                        color: isToday ? AppColors.primary : AppColors.textHint,
                        fontSize: 10,
                        fontWeight: isToday ? FontWeight.w800 : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
