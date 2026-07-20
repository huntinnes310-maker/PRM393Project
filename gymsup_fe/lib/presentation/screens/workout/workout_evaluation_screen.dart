import 'package:flutter/material.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_images.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/workout_evaluation.dart';
import '../../../providers/workout_session_provider.dart';
import '../../widgets/ai/premium_feature_gate.dart';

/// Báo cáo đánh giá AI sau khi hoàn thành buổi tập (tính năng Premium).
/// Toàn bộ số liệu do backend tính sẵn - màn này chỉ trình bày.
class WorkoutEvaluationScreen extends StatefulWidget {
  final String sessionLogId;

  const WorkoutEvaluationScreen({super.key, required this.sessionLogId});

  @override
  State<WorkoutEvaluationScreen> createState() =>
      _WorkoutEvaluationScreenState();
}

class _WorkoutEvaluationScreenState extends State<WorkoutEvaluationScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _load();
  }

  Future<void> _load() async {
    final provider = context.read<WorkoutSessionProvider>();
    await provider.evaluateWorkout(widget.sessionLogId);
    if (mounted) _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Animation<Offset> _slideIn(double start, double end) {
    return Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(start, end, curve: Curves.easeOutCubic),
      ),
    );
  }

  Animation<double> _fadeIn(double start, double end) {
    return CurvedAnimation(
      parent: _controller,
      curve: Interval(start, end, curve: Curves.easeOut),
    );
  }

  Widget _animated(Widget child, double start, {double span = 0.4}) {
    final end = (start + span).clamp(0.0, 1.0);
    return FadeTransition(
      opacity: _fadeIn(start, end),
      child: SlideTransition(position: _slideIn(start, end), child: child),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WorkoutSessionProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Đánh giá AI')),
      body: SafeArea(child: _buildBody(provider)),
    );
  }

  Widget _buildBody(WorkoutSessionProvider provider) {
    if (provider.isEvaluating) {
      return _buildLoading();
    }

    if (provider.evaluationErrorCode == 'PREMIUM_REQUIRED') {
      return const PremiumFeatureGate(
        title: 'Đánh giá AI là tính năng Premium',
        description:
            'Nâng cấp Premium để nhận báo cáo phân tích chi tiết sau mỗi buổi tập: điểm số, điểm mạnh/yếu, tình trạng hồi phục và gợi ý dinh dưỡng cá nhân hoá.',
      );
    }

    if (provider.evaluationError != null) {
      return _buildErrorState(provider.evaluationError!);
    }

    final evaluation = provider.evaluation;
    if (evaluation == null) {
      return _buildErrorState('Không thể tải đánh giá.');
    }

    return _buildReport(evaluation);
  }

  Widget _buildLoading() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.85, end: 1.05),
              duration: const Duration(milliseconds: 900),
              curve: Curves.easeInOut,
              builder: (context, value, child) =>
                  Transform.scale(scale: value, child: child),
              child: Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: AppColors.primary,
                  size: 40,
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'AI đang phân tích buổi tập của bạn...',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
            const SizedBox(height: 8),
            const Text(
              'Có thể mất vài giây',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: AppColors.error,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: _load, child: const Text('Thử lại')),
          ],
        ),
      ),
    );
  }

  Widget _buildReport(WorkoutEvaluation e) {
    final gradeColor = _gradeColor(e.grade);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      children: [
        _animated(_buildScoreHero(e, gradeColor), 0.0),
        const SizedBox(height: 16),
        _animated(_buildNarrativeCard(e), 0.05),
        const SizedBox(height: 16),
        _animated(_buildSummaryGrid(e.summary), 0.1),
        const SizedBox(height: 16),
        _animated(_buildComparisonCard(e.comparison), 0.12),
        if (e.highlights.isNotEmpty) ...[
          const SizedBox(height: 16),
          _animated(
            _buildListCard(
              title: 'Điểm nổi bật',
              color: AppColors.success,
              items: e.highlights,
            ),
            0.15,
          ),
        ],
        if (e.improvements.isNotEmpty) ...[
          const SizedBox(height: 16),
          _animated(
            _buildListCard(
              title: 'Cần cải thiện',
              color: AppColors.warning,
              items: e.improvements,
            ),
            0.2,
          ),
        ],
        if (e.recovery.isNotEmpty) ...[
          const SizedBox(height: 16),
          _animated(_buildRecoveryCard(e.recovery), 0.25),
        ],
        const SizedBox(height: 16),
        _animated(_buildNutritionCard(e.nutrition), 0.3),
        const SizedBox(height: 16),
        _animated(_buildNextWorkoutCard(e.suggestedNextWorkout), 0.35),
        const SizedBox(height: 16),
        _animated(_buildMotivationCard(e.motivationalMessage), 0.4),
      ],
    );
  }

  Color _gradeColor(String grade) {
    if (grade.startsWith('A')) return AppColors.success;
    if (grade.startsWith('B')) return AppColors.info;
    if (grade.startsWith('C')) return AppColors.warning;
    return AppColors.error;
  }

  Widget _buildScoreHero(WorkoutEvaluation e, Color gradeColor) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Stack(
        children: [
          Positioned.fill(
            child: Image.network(
              AppImages.workoutBanner,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) =>
                  Container(color: AppColors.cardBackground),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.background.withValues(alpha: 0.55),
                    AppColors.background.withValues(alpha: 0.92),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 28),
            child: Column(
              children: [
                CircularPercentIndicator(
                  radius: 72,
                  lineWidth: 12,
                  percent: (e.score / 100).clamp(0.0, 1.0),
                  animation: true,
                  animationDuration: 1000,
                  circularStrokeCap: CircularStrokeCap.round,
                  backgroundColor: Colors.white.withValues(alpha: 0.15),
                  progressColor: gradeColor,
                  center: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${e.score}',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                      const Text(
                        'điểm',
                        style: TextStyle(fontSize: 11, color: Colors.white70),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: gradeColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: gradeColor.withValues(alpha: 0.6),
                    ),
                  ),
                  child: Text(
                    'Hạng ${e.grade}',
                    style: TextStyle(
                      color: gradeColor,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonCard(WorkoutSessionComparison c) {
    if (!c.hasPrevious) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: const Text(
          'Đây là lần đầu tiên bạn tập buổi này — lần sau sẽ có so sánh chi tiết.',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13,
            height: 1.4,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'So với lần trước',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              Text(
                _formatShortDate(c.previousDate),
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _deltaStat(
                  'Khối lượng',
                  c.volumeDeltaPercent,
                  suffix: '%',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _deltaStat('Sets', c.setsDelta.toDouble(), suffix: ''),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _deltaStat(
                  'Thời gian',
                  c.durationDeltaMinutes.toDouble(),
                  suffix: 'p',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _deltaStat(String label, double delta, {required String suffix}) {
    final color = delta > 0
        ? AppColors.success
        : delta < 0
        ? AppColors.error
        : AppColors.textSecondary;
    final sign = delta > 0 ? '+' : '';
    final formatted = delta == delta.roundToDouble()
        ? delta.toStringAsFixed(0)
        : delta.toStringAsFixed(1);

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '$sign$formatted$suffix',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  String _formatShortDate(DateTime? date) {
    if (date == null) return '';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}';
  }

  Widget _buildNarrativeCard(WorkoutEvaluation e) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        e.narrativeSummary,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 14,
          height: 1.5,
        ),
      ),
    );
  }

  Widget _buildSummaryGrid(WorkoutEvaluationSummary s) {
    final items = [
      ('${s.durationMinutes} phút', 'Thời gian'),
      ('${s.exerciseCount}', 'Bài tập'),
      ('${s.totalSets}', 'Sets'),
      ('${s.totalReps}', 'Reps'),
      ('${s.totalVolumeKg.toStringAsFixed(0)}kg', 'Khối lượng'),
      ('${s.estimatedCalories}', 'Calo (ước tính)'),
    ];

    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.0,
      children: items
          .map(
            (item) => Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    item.$1,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 17,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.$2,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildListCard({
    required String title,
    required Color color,
    required List<String> items,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(fontWeight: FontWeight.w800, color: color),
          ),
          const SizedBox(height: 12),
          ...items.map(
            (text) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('•  ', style: TextStyle(color: color)),
                  Expanded(
                    child: Text(
                      text,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                        height: 1.4,
                      ),
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

  Widget _buildRecoveryCard(List<MuscleRecoveryStatus> recovery) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tình trạng hồi phục',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: recovery.map((r) {
              final color = _recoveryColor(r.status);
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: color.withValues(alpha: 0.35)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      r.muscleCategory,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      '${r.status} · ~${r.recoveryHours}h',
                      style: TextStyle(color: color, fontSize: 11),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Color _recoveryColor(String status) {
    switch (status) {
      case 'Cần nghỉ':
        return AppColors.error;
      case 'Đang hồi phục':
        return AppColors.warning;
      default:
        return AppColors.success;
    }
  }

  Widget _buildNutritionCard(NutritionRecommendation n) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Gợi ý dinh dưỡng',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: _nutritionStat('${n.proteinGrams}g', 'Đạm')),
              const SizedBox(width: 10),
              Expanded(
                child: _nutritionStat(
                  '${n.waterLiters.toStringAsFixed(1)}L',
                  'Nước',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            n.mealSuggestion,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _nutritionStat(String value, String label) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
          ),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNextWorkoutCard(String suggestion) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Buổi tập tiếp theo',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            suggestion,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMotivationCard(String message) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          const Icon(Icons.bolt_rounded, color: Colors.white, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
