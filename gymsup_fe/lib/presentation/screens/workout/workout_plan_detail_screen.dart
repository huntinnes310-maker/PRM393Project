import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/workout_plan.dart';
import '../../../providers/workout_plan_provider.dart';
import '../exercise/exercise_list_screen.dart';

/// Chi tiết 1 lịch tập: sửa thông tin, quản lý bài tập từng buổi, kích hoạt/xoá.
class WorkoutPlanDetailScreen extends StatefulWidget {
  final String planId;

  const WorkoutPlanDetailScreen({super.key, required this.planId});

  @override
  State<WorkoutPlanDetailScreen> createState() => _WorkoutPlanDetailScreenState();
}

class _WorkoutPlanDetailScreenState extends State<WorkoutPlanDetailScreen> {
  final Set<String> _expandedSessions = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  void _load() {
    context.read<WorkoutPlanProvider>().fetchPlanById(widget.planId);
  }

  Future<void> _editInfo(WorkoutPlan plan) async {
    final nameController = TextEditingController(text: plan.name);
    final goalController = TextEditingController(text: plan.goal);
    final daysController = TextEditingController(text: plan.daysPerWeek.toString());

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sửa thông tin lịch tập'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Tên')),
            TextField(controller: goalController, decoration: const InputDecoration(labelText: 'Mục tiêu')),
            TextField(
              controller: daysController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Số ngày/tuần'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Huỷ')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Lưu')),
        ],
      ),
    );

    if (saved == true && mounted) {
      await context.read<WorkoutPlanProvider>().updatePlan(plan.id, {
        'name': nameController.text,
        'goal': goalController.text,
        'daysPerWeek': int.tryParse(daysController.text) ?? plan.daysPerWeek,
      });
      _load();
    }
  }

  Future<void> _deletePlan(WorkoutPlan plan) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xoá lịch tập?'),
        content: Text('Bạn có chắc muốn xoá "${plan.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Huỷ')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xoá', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await context.read<WorkoutPlanProvider>().deletePlan(plan.id);
      if (mounted) Navigator.pop(context, true);
    }
  }

  Future<void> _addExercise(WorkoutPlan plan, PlanSession session) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ExerciseListScreen(
          pickerMode: true,
          onPick: (exercise) async {
            Navigator.of(context).pop();
            await context.read<WorkoutPlanProvider>().addExerciseToSession(
                  planId: plan.id,
                  sessionId: session.id,
                  exerciseId: exercise.id,
                  exerciseName: exercise.name,
                  sets: exercise.defaultSets,
                  reps: exercise.defaultReps,
                );
            _load();
          },
        ),
      ),
    );
  }

  Future<void> _editExercise(WorkoutPlan plan, PlanSession session, PlanExercise ex) async {
    final setsController = TextEditingController(text: ex.sets.toString());
    final repsController = TextEditingController(text: ex.reps);
    final notesController = TextEditingController(text: ex.notes);

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(ex.exerciseName),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: setsController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Số set'),
            ),
            TextField(controller: repsController, decoration: const InputDecoration(labelText: 'Reps')),
            TextField(controller: notesController, decoration: const InputDecoration(labelText: 'Ghi chú')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Huỷ')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Lưu')),
        ],
      ),
    );

    if (saved == true && mounted) {
      await context.read<WorkoutPlanProvider>().updateExerciseInSession(
            planId: plan.id,
            sessionId: session.id,
            exerciseId: ex.exerciseId,
            sets: int.tryParse(setsController.text) ?? ex.sets,
            reps: repsController.text,
            notes: notesController.text,
          );
      _load();
    }
  }

  Future<void> _deleteExercise(WorkoutPlan plan, PlanSession session, PlanExercise ex) async {
    await context.read<WorkoutPlanProvider>().deleteExerciseFromSession(
          planId: plan.id,
          sessionId: session.id,
          exerciseId: ex.exerciseId,
        );
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WorkoutPlanProvider>();
    final plan = provider.selectedPlan;

    return Scaffold(
      appBar: AppBar(
        title: Text(plan?.name ?? 'Chi tiết lịch tập'),
        actions: plan == null
            ? null
            : [
                IconButton(onPressed: () => _editInfo(plan), icon: const Icon(Icons.edit_outlined)),
                IconButton(
                  onPressed: () => _deletePlan(plan),
                  icon: const Icon(Icons.delete_outline, color: AppColors.error),
                ),
              ],
      ),
      body: provider.isLoading || plan == null
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              plan.goal.isNotEmpty ? plan.goal : 'Chưa có mục tiêu',
                              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${plan.daysPerWeek} ngày/tuần',
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (!plan.isActive)
                        ElevatedButton(
                          onPressed: () async {
                            await context.read<WorkoutPlanProvider>().activatePlan(plan.id);
                            _load();
                          },
                          child: const Text('Kích hoạt'),
                        )
                      else
                        const Icon(Icons.check_circle, color: AppColors.primary),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                ...plan.sessions.map((session) {
                  final isExpanded = _expandedSessions.contains(session.id);
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: AppColors.cardBackground,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      children: [
                        InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () => setState(() {
                            if (isExpanded) {
                              _expandedSessions.remove(session.id);
                            } else {
                              _expandedSessions.add(session.id);
                            }
                          }),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        session.dayOfWeek,
                                        style: const TextStyle(
                                          color: AppColors.textPrimary,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      Text(
                                        session.focus.isNotEmpty ? session.focus : 'Tập luyện tự do',
                                        style: const TextStyle(
                                          color: AppColors.textSecondary,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  isExpanded ? Icons.expand_less : Icons.expand_more,
                                  color: AppColors.textHint,
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (isExpanded) ...[
                          const Divider(height: 1, color: AppColors.surfaceVariant),
                          ...session.exercises.map((ex) => ListTile(
                                title: Text(
                                  ex.exerciseName,
                                  style: const TextStyle(color: AppColors.textPrimary),
                                ),
                                subtitle: Text(
                                  '${ex.sets} sets x ${ex.reps} reps',
                                  style: const TextStyle(color: AppColors.textSecondary),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      onPressed: () => _editExercise(plan, session, ex),
                                      icon: const Icon(Icons.edit, size: 18),
                                    ),
                                    IconButton(
                                      onPressed: () => _deleteExercise(plan, session, ex),
                                      icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.error),
                                    ),
                                  ],
                                ),
                              )),
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: OutlinedButton.icon(
                              onPressed: () => _addExercise(plan, session),
                              icon: const Icon(Icons.add, size: 18),
                              label: const Text('Thêm bài tập'),
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                }),
              ],
            ),
    );
  }
}
