import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/workout_session_log.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/workout_session_provider.dart';
import '../../widgets/workout/set_input_row.dart';

/// Màn hình ghi nhận buổi tập đang diễn ra: đồng hồ, nhập set thật (cân nặng/reps).
class WorkoutSessionScreen extends StatefulWidget {
  const WorkoutSessionScreen({super.key});

  @override
  State<WorkoutSessionScreen> createState() => _WorkoutSessionScreenState();
}

class _WorkoutSessionScreenState extends State<WorkoutSessionScreen>
    with SingleTickerProviderStateMixin {
  final Stopwatch _stopwatch = Stopwatch();
  Timer? _timer;
  String _timeDisplay = '00:00';
  TabController? _tabController;
  bool _isFinishing = false;
  final Map<String, bool> _savingSet = {};

  final Map<String, List<TextEditingController>> _weightControllers = {};
  final Map<String, List<TextEditingController>> _repsControllers = {};

  @override
  void initState() {
    super.initState();
    _stopwatch.start();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final d = _stopwatch.elapsed;
      setState(() {
        _timeDisplay =
            '${d.inMinutes.remainder(60).toString().padLeft(2, '0')}:${d.inSeconds.remainder(60).toString().padLeft(2, '0')}';
      });
    });

    WidgetsBinding.instance.addPostFrameCallback((_) => _initControllers());
  }

  void _initControllers() {
    final session = context.read<WorkoutSessionProvider>().activeSession;
    if (session == null) return;

    for (final ex in session.exercises) {
      final setCount = ex.plannedSets > ex.sets.length ? ex.plannedSets : ex.sets.length;
      final weightList = <TextEditingController>[];
      final repsList = <TextEditingController>[];
      for (int i = 0; i < setCount; i++) {
        final existing = i < ex.sets.length ? ex.sets[i] : null;
        weightList.add(TextEditingController(text: existing?.weight?.toString() ?? ''));
        repsList.add(TextEditingController(text: existing?.reps?.toString() ?? _extractReps(ex.plannedReps)));
      }
      _weightControllers[ex.id] = weightList;
      _repsControllers[ex.id] = repsList;

      final userId = context.read<AuthProvider>().userId;
      if (userId != null) {
        context.read<WorkoutSessionProvider>().fetchExerciseStats(userId, ex.exerciseId);
      }
    }

    _tabController?.dispose();
    _tabController = TabController(length: session.exercises.length, vsync: this);
    setState(() {});
  }

  String _extractReps(String reps) {
    final match = RegExp(r'\d+').firstMatch(reps);
    return match?.group(0) ?? '10';
  }

  @override
  void dispose() {
    _timer?.cancel();
    _tabController?.dispose();
    for (final list in _weightControllers.values) {
      for (final c in list) {
        c.dispose();
      }
    }
    for (final list in _repsControllers.values) {
      for (final c in list) {
        c.dispose();
      }
    }
    super.dispose();
  }

  Future<void> _confirmSet(WorkoutExerciseLog ex, int setIndex) async {
    final weightText = _weightControllers[ex.id]![setIndex].text;
    final repsText = _repsControllers[ex.id]![setIndex].text;
    final reps = int.tryParse(repsText) ?? 0;
    if (reps <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập số reps hợp lệ')),
      );
      return;
    }
    final weight = double.tryParse(weightText);

    final key = '${ex.id}_$setIndex';
    setState(() => _savingSet[key] = true);

    final provider = context.read<WorkoutSessionProvider>();
    final session = provider.activeSession!;
    final ok = await provider.logSet(
      sessionLogId: session.id,
      exerciseLogId: ex.id,
      setNumber: setIndex + 1,
      weight: weight,
      reps: reps,
    );

    if (!mounted) return;
    setState(() => _savingSet[key] = false);

    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể lưu set này'), backgroundColor: AppColors.error),
      );
      return;
    }

    _checkPR(ex.exerciseId, weight, reps);
  }

  void _checkPR(String exerciseId, double? weight, int reps) {
    if (weight == null) return;
    final userId = context.read<AuthProvider>().userId;
    if (userId == null) return;
    final stats = context.read<WorkoutSessionProvider>();
    final cached = stats.fetchExerciseStats(userId, exerciseId);
    cached.then((data) {
      if (data == null || !mounted) return;
      final pr = data['personalRecord'];
      if (pr == null) return;
      final prevMaxWeight = (pr['maxWeight'] as num?)?.toDouble() ?? 0;
      final prevMaxReps = (pr['maxReps'] as num?)?.toInt() ?? 0;
      final isNewPR = weight > prevMaxWeight || (weight >= prevMaxWeight && reps > prevMaxReps);
      if (isNewPR) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎉 Kỷ lục cá nhân mới!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    });
  }

  Future<void> _finishWorkout() async {
    final session = context.read<WorkoutSessionProvider>().activeSession;
    if (session == null) return;
    final hasAnySet = session.exercises.any((e) => e.sets.isNotEmpty);
    if (!hasAnySet) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hãy hoàn thành ít nhất 1 set trước khi kết thúc')),
      );
      return;
    }

    setState(() => _isFinishing = true);
    final result = await context.read<WorkoutSessionProvider>().finishSession(session.id);
    if (!mounted) return;
    setState(() => _isFinishing = false);

    if (result != null) {
      _timer?.cancel();
      context.pushReplacement('/workout/summary', extra: result);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể hoàn thành buổi tập.'), backgroundColor: AppColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<WorkoutSessionProvider>().activeSession;

    if (session == null || _tabController == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(session.name.isNotEmpty ? session.name : session.focus),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                _timeDisplay,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
        bottom: session.exercises.length > 1
            ? TabBar(
                controller: _tabController,
                isScrollable: true,
                tabs: session.exercises.map((e) => Tab(text: e.exerciseName)).toList(),
              )
            : null,
      ),
      body: TabBarView(
        controller: _tabController,
        children: session.exercises.map((ex) {
          final weightControllers = _weightControllers[ex.id] ?? [];
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: weightControllers.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return _buildLastPerformanceBanner(ex.exerciseId);
              }
              final setIndex = index - 1;
              final key = '${ex.id}_$setIndex';
              final isDone = setIndex < ex.sets.length;
              return SetInputRow(
                setNumber: setIndex + 1,
                weightController: _weightControllers[ex.id]![setIndex],
                repsController: _repsControllers[ex.id]![setIndex],
                isDone: isDone,
                isSaving: _savingSet[key] ?? false,
                onConfirm: () => _confirmSet(ex, setIndex),
              );
            },
          );
        }).toList(),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isFinishing ? null : _finishWorkout,
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
              child: _isFinishing
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Text('Hoàn thành buổi tập'),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLastPerformanceBanner(String exerciseId) {
    final userId = context.read<AuthProvider>().userId;
    if (userId == null) return const SizedBox.shrink();

    return FutureBuilder<Map<String, dynamic>?>(
      future: context.read<WorkoutSessionProvider>().fetchExerciseStats(userId, exerciseId),
      builder: (context, snapshot) {
        final data = snapshot.data;
        final lastPerformance = data?['lastPerformance'];
        if (lastPerformance == null) return const SizedBox.shrink();

        final sets = (lastPerformance['sets'] as List? ?? [])
            .map((s) => '${s['weight'] ?? 0}kg x ${s['reps'] ?? 0}')
            .join(' · ');
        final date = lastPerformance['date']?.toString() ?? '';

        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(Icons.history, size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Lần trước ($date): $sets',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
