import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/workout_session_provider.dart';

/// Danh sách các buổi tập đã hoàn thành.
class WorkoutHistoryScreen extends StatefulWidget {
  const WorkoutHistoryScreen({super.key});

  @override
  State<WorkoutHistoryScreen> createState() => _WorkoutHistoryScreenState();
}

class _WorkoutHistoryScreenState extends State<WorkoutHistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = context.read<AuthProvider>().userId;
      if (userId != null) context.read<WorkoutSessionProvider>().fetchHistory(userId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WorkoutSessionProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Lịch sử tập luyện')),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : provider.history.isEmpty
              ? const Center(
                  child: Text(
                    'Chưa có buổi tập nào được ghi nhận.',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: provider.history.length,
                  itemBuilder: (context, index) {
                    final log = provider.history[index];
                    final minutes = (log.totalDurationSeconds / 60).round();
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.cardBackground,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: log.status == 'COMPLETED'
                                  ? AppColors.success.withValues(alpha: 0.15)
                                  : AppColors.surfaceVariant,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              log.status == 'COMPLETED' ? Icons.check : Icons.timelapse,
                              color: log.status == 'COMPLETED' ? AppColors.success : AppColors.textHint,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  log.name.isNotEmpty ? log.name : log.focus,
                                  style: const TextStyle(fontWeight: FontWeight.w700),
                                ),
                                Text(
                                  '${log.startTime != null ? _formatDate(log.startTime!) : ''} · $minutes phút · ${log.exercises.length} bài tập',
                                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }

  String _formatDate(DateTime date) {
    final local = date.toLocal();
    return '${local.day}/${local.month}/${local.year}';
  }
}
