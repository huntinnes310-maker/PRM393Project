import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/exercise.dart';
import '../../../data/models/workout_plan.dart';
import '../../../data/models/workout_session_log.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/exercise_provider.dart';
import '../../../providers/workout_plan_provider.dart';
import '../../../providers/workout_session_provider.dart';

/// Màn hình "Lịch tập" - điểm vào chính của tính năng tập luyện từ Home.
class TodayWorkoutScreen extends StatefulWidget {
  const TodayWorkoutScreen({super.key});

  @override
  State<TodayWorkoutScreen> createState() => _TodayWorkoutScreenState();
}

class _TodayWorkoutScreenState extends State<TodayWorkoutScreen> {
  bool _loading = true;
  String _todayWeekday = '';
  final Map<String, Exercise> _exerciseCatalog = {};
  Timer? _previewTimer;
  int _previewTick = 0;

  static const _englishWeekdays = [
    '',
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  @override
  void initState() {
    super.initState();
    _todayWeekday = _englishWeekdays[DateTime.now().weekday];
    _previewTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (mounted) setState(() => _previewTick++);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _previewTimer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final userId = context.read<AuthProvider>().userId;
    if (userId == null) {
      setState(() => _loading = false);
      return;
    }

    final sessionProvider = context.read<WorkoutSessionProvider>();
    final planProvider = context.read<WorkoutPlanProvider>();
    final exerciseProvider = context.read<ExerciseProvider>();

    await sessionProvider.fetchActiveSession(userId);
    if (sessionProvider.activeSession == null) {
      await planProvider.fetchActivePlan(userId);
      if (exerciseProvider.exercises.isEmpty) {
        await exerciseProvider.fetchExercises();
      }
      _exerciseCatalog
        ..clear()
        ..addEntries(exerciseProvider.exercises.map((e) => MapEntry(e.id, e)));
    }

    if (mounted) setState(() => _loading = false);
  }

  Future<void> _startSession(WorkoutPlan plan, PlanSession session) async {
    final userId = context.read<AuthProvider>().userId ?? '';
    final result = await context.read<WorkoutSessionProvider>().startSession(
      userId: userId,
      workoutPlanId: plan.id,
      planSessionId: session.id,
    );
    if (!mounted) return;
    if (result != null) {
      await context.push('/workout/session');
      if (mounted) _load();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không thể bắt đầu buổi tập.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _continueSession() async {
    await context.push('/workout/session');
    if (mounted) _load();
  }

  @override
  Widget build(BuildContext context) {
    final sessionProvider = context.watch<WorkoutSessionProvider>();
    final planProvider = context.watch<WorkoutPlanProvider>();
    final activeSession = sessionProvider.activeSession;
    final activePlan = planProvider.activePlan;

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(activePlan),
            Expanded(
              child: _loading
                  ? _buildSkeleton()
                  : RefreshIndicator(
                      onRefresh: _load,
                      color: AppColors.primary,
                      child: activeSession != null
                          ? _buildActiveSession(activeSession)
                          : activePlan == null
                          ? _buildEmptyState()
                          : _buildPlanView(activePlan),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(WorkoutPlan? activePlan) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 12, 0),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Lịch tập',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 26,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
              ),
            ),
          ),
          if (activePlan != null)
            IconButton(
              icon: const Icon(Icons.refresh_rounded, size: 22),
              color: AppColors.textSecondary,
              onPressed: _load,
            ),
          IconButton(
            icon: const Icon(Icons.swap_horiz_rounded, size: 22),
            color: AppColors.textSecondary,
            onPressed: () async {
              await context.push('/workout-plans');
              if (mounted) _load();
            },
          ),
          IconButton(
            icon: const Icon(Icons.history_rounded, size: 22),
            color: AppColors.textSecondary,
            onPressed: () => context.push('/workout/history'),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeleton() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _skeletonBox(height: 140),
          const SizedBox(height: 12),
          _skeletonBox(height: 96),
          const SizedBox(height: 10),
          _skeletonBox(height: 96),
        ],
      ),
    );
  }

  Widget _skeletonBox({required double height}) {
    return Container(
      width: double.infinity,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }

  Widget _buildEmptyState() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 60),
        const Icon(Icons.event_busy, size: 64, color: AppColors.textHint),
        const SizedBox(height: 16),
        const Text(
          'Chưa có lịch tập',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Chọn hoặc tạo một lịch tập để bắt đầu theo dõi quá trình luyện tập.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: () async {
            await context.push('/workout-plans');
            if (mounted) _load();
          },
          child: const Text('Chọn lịch tập'),
        ),
      ],
    );
  }

  // ── Active session (đang tiến hành) ───────────────────────────────────────

  Widget _buildActiveSession(WorkoutSessionLog activeSession) {
    final exercises = activeSession.exercises;
    int completedSets = 0;
    int totalSets = 0;
    for (final ex in exercises) {
      final planned = ex.plannedSets > ex.sets.length
          ? ex.plannedSets
          : ex.sets.length;
      totalSets += planned;
      completedSets += ex.sets.length;
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
      children: [
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.primaryDark, Color(0xFF3A1608)],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.15),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.play_arrow,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '● ĐANG TIẾN HÀNH',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                        ),
                      ),
                      Text(
                        'Buổi tập chưa hoàn thành',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  _statPill('Bài tập', '${exercises.length}'),
                  const SizedBox(width: 10),
                  _statPill('Đã xong', '$completedSets/$totalSets sets'),
                ],
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: exercises.isEmpty ? null : _continueSession,
                  icon: const Icon(Icons.play_arrow, size: 22),
                  label: const Text(
                    'Tiếp tục Workout',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'CÁC BÀI TẬP',
          style: TextStyle(
            color: AppColors.textHint,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 12),
        ...exercises.map((ex) {
          final done = ex.sets.length;
          final total = ex.plannedSets > done
              ? ex.plannedSets
              : (done == 0 ? 3 : done);
          final isDone = done >= total && total > 0;
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: isDone
                  ? AppColors.success.withValues(alpha: 0.06)
                  : AppColors.cardBackground,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDone
                    ? AppColors.success.withValues(alpha: 0.3)
                    : AppColors.border,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isDone ? Icons.check_circle : Icons.circle_outlined,
                  color: isDone ? AppColors.success : AppColors.textSecondary,
                  size: 22,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    ex.exerciseName,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  '$done/$total sets',
                  style: TextStyle(
                    color: isDone ? AppColors.success : AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _statPill(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label.toUpperCase(),
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Plan view (danh sách toàn bộ buổi tập trong tuần) ─────────────────────

  Widget _buildPlanView(WorkoutPlan plan) {
    final sessions = plan.sessions;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primary.withValues(alpha: 0.14),
                AppColors.cardBackground,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.25),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'KẾ HOẠCH HIỆN TẠI',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      plan.name,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${sessions.length} buổi/tuần',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(50),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  plan.goal.isEmpty ? 'Custom' : plan.goal,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'BUỔI TẬP',
          style: TextStyle(
            color: AppColors.textHint,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 12),
        ...sessions.asMap().entries.map((entry) {
          final i = entry.key;
          final session = entry.value;
          final isToday =
              session.dayOfWeek.trim().toLowerCase() ==
              _todayWeekday.toLowerCase();
          final previewExercise = session.exercises.isEmpty
              ? null
              : session.exercises[_previewTick % session.exercises.length];
          final previewCatalogEntry = previewExercise == null
              ? null
              : _exerciseCatalog[previewExercise.exerciseId];

          return Container(
            margin: EdgeInsets.only(bottom: i == sessions.length - 1 ? 0 : 10),
            decoration: BoxDecoration(
              color: isToday
                  ? AppColors.primary.withValues(alpha: 0.08)
                  : AppColors.cardBackground,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isToday
                    ? AppColors.primary.withValues(alpha: 0.4)
                    : AppColors.border,
                width: isToday ? 1.5 : 1,
              ),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () => _startSession(plan, session),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Container(
                      width: 68,
                      height: 68,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 500),
                        child: previewCatalogEntry != null
                            ? KeyedSubtree(
                                key: ValueKey(previewExercise!.exerciseId),
                                child: previewCatalogEntry.isAssetImage
                                    ? Image.asset(
                                        previewCatalogEntry.displayImageUrl,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, _, _) =>
                                            _fallbackImage(),
                                      )
                                    : Image.network(
                                        previewCatalogEntry.displayImageUrl,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, _, _) =>
                                            _fallbackImage(),
                                      ),
                              )
                            : _fallbackImage(),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              if (isToday)
                                Container(
                                  margin: const EdgeInsets.only(right: 8),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    borderRadius: BorderRadius.circular(50),
                                  ),
                                  child: const Text(
                                    'HÔM NAY',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              Flexible(
                                child: Text(
                                  session.focus.trim().isEmpty
                                      ? session.dayOfWeek
                                      : session.focus,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${session.dayOfWeek}  ·  ${session.exercises.length} bài tập',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                          if (previewExercise != null) ...[
                            const SizedBox(height: 4),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 400),
                              child: Text(
                                previewExercise.exerciseName,
                                key: ValueKey(
                                  '${previewExercise.exerciseId}_label',
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: isToday
                            ? AppColors.primary
                            : AppColors.surfaceVariant,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isToday ? Icons.play_arrow : Icons.arrow_forward,
                        color: isToday ? Colors.white : AppColors.textSecondary,
                        size: 22,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _fallbackImage() {
    return Container(
      color: AppColors.surfaceVariant,
      child: const Center(
        child: Icon(Icons.fitness_center, color: AppColors.textHint, size: 26),
      ),
    );
  }
}
