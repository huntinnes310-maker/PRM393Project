import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/exercise.dart';
import '../../../data/models/workout_plan.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/workout_plan_provider.dart';
import '../../widgets/workout/day_of_week_selector.dart';
import '../exercise/exercise_list_screen.dart';

/// Wizard 4 bước tạo lịch tập mới: Thông tin -> Lịch tập -> Bài tập -> Xác nhận.
class BuildRoutineScreen extends StatefulWidget {
  const BuildRoutineScreen({super.key});

  @override
  State<BuildRoutineScreen> createState() => _BuildRoutineScreenState();
}

class _BuildRoutineScreenState extends State<BuildRoutineScreen> {
  int _step = 0;
  final _nameController = TextEditingController();
  final _goalController = TextEditingController();
  final Set<String> _selectedDays = {'Monday', 'Wednesday', 'Friday'};
  final Map<String, List<PlanExercise>> _dayExercises = {};
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _goalController.dispose();
    super.dispose();
  }

  String _dayLabel(String value) =>
      kWeekDays.firstWhere((d) => d['value'] == value, orElse: () => {'label': value})['label']!;

  bool _validateStep(int step) {
    if (step == 0) {
      if (_nameController.text.trim().isEmpty) {
        _showError('Vui lòng nhập tên lịch tập');
        return false;
      }
    } else if (step == 1) {
      if (_selectedDays.isEmpty) {
        _showError('Vui lòng chọn ít nhất 1 ngày tập');
        return false;
      }
    } else if (step == 2) {
      for (final day in _selectedDays) {
        if ((_dayExercises[day] ?? []).isEmpty) {
          _showError('Mỗi ngày cần ít nhất 1 bài tập (${_dayLabel(day)} đang trống)');
          return false;
        }
      }
    }
    return true;
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.error),
    );
  }

  void _next() {
    if (!_validateStep(_step)) return;
    if (_step < 3) {
      setState(() => _step++);
    } else {
      _save();
    }
  }

  void _back() {
    if (_step > 0) setState(() => _step--);
  }

  Future<void> _addExerciseToDay(String day) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ExerciseListScreen(
          pickerMode: true,
          onPick: (exercise) async {
            Navigator.of(context).pop();
            final result = await _showSetsRepsSheet(exercise);
            if (result != null) {
              setState(() {
                _dayExercises.putIfAbsent(day, () => []).add(result);
              });
            }
          },
        ),
      ),
    );
  }

  Future<PlanExercise?> _showSetsRepsSheet(Exercise exercise) async {
    final setsController = TextEditingController(text: exercise.defaultSets.toString());
    final repsController = TextEditingController(text: exercise.defaultReps);
    final notesController = TextEditingController();

    return showModalBottomSheet<PlanExercise>(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              exercise.name,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: setsController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Số set'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: repsController,
                    decoration: const InputDecoration(labelText: 'Reps'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: notesController,
              decoration: const InputDecoration(labelText: 'Ghi chú (không bắt buộc)'),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  final sets = int.tryParse(setsController.text) ?? exercise.defaultSets;
                  final reps = repsController.text.trim().isEmpty
                      ? exercise.defaultReps
                      : repsController.text.trim();
                  Navigator.pop(
                    context,
                    PlanExercise(
                      exerciseId: exercise.id,
                      exerciseName: exercise.name,
                      sets: sets,
                      reps: reps,
                      notes: notesController.text,
                    ),
                  );
                },
                child: const Text('Thêm vào ngày này'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    final userId = context.read<AuthProvider>().userId ?? '';
    final payload = {
      'userId': userId,
      'name': _nameController.text.trim(),
      'goal': _goalController.text.trim(),
      'daysPerWeek': _selectedDays.length,
      'sessions': _selectedDays.map((day) {
        return {
          'dayOfWeek': day,
          'focus': _goalController.text.trim(),
          'exercises': (_dayExercises[day] ?? []).map((e) => e.toJson()).toList(),
        };
      }).toList(),
    };

    final plan = await context.read<WorkoutPlanProvider>().createRoutine(payload);

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (plan != null) {
      context.go('/workout-plans');
    } else {
      _showError('Không thể tạo lịch tập. Vui lòng thử lại.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tạo lịch tập mới')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: List.generate(4, (i) {
                final active = i <= _step;
                return Expanded(
                  child: Container(
                    height: 4,
                    margin: EdgeInsets.only(right: i == 3 ? 0 : 6),
                    decoration: BoxDecoration(
                      color: active ? AppColors.primary : AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                );
              }),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: _buildStepContent(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Row(
              children: [
                if (_step > 0)
                  Expanded(
                    child: OutlinedButton(onPressed: _back, child: const Text('Quay lại')),
                  ),
                if (_step > 0) const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _next,
                    child: _isSaving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : Text(_step == 3 ? 'Lưu lịch tập' : 'Tiếp tục'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_step) {
      case 0:
        return ListView(
          children: [
            const Text('Thông tin', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
            const SizedBox(height: 20),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Tên lịch tập'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _goalController,
              decoration: const InputDecoration(labelText: 'Mục tiêu'),
            ),
          ],
        );
      case 1:
        return ListView(
          children: [
            const Text('Lịch tập', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
            const SizedBox(height: 4),
            const Text(
              'Chọn các ngày tập trong tuần',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 20),
            DayOfWeekSelector(
              selectedDays: _selectedDays,
              onToggle: (day) => setState(() {
                if (_selectedDays.contains(day)) {
                  _selectedDays.remove(day);
                } else {
                  _selectedDays.add(day);
                }
              }),
            ),
          ],
        );
      case 2:
        final sortedDays = kWeekDays
            .map((d) => d['value']!)
            .where((v) => _selectedDays.contains(v))
            .toList();
        return DefaultTabController(
          length: sortedDays.length,
          child: Column(
            children: [
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('Bài tập', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
              ),
              const SizedBox(height: 12),
              TabBar(
                isScrollable: true,
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.textSecondary,
                tabs: sortedDays.map((d) => Tab(text: _dayLabel(d))).toList(),
              ),
              Expanded(
                child: TabBarView(
                  children: sortedDays.map((day) {
                    final exercises = _dayExercises[day] ?? [];
                    return ListView(
                      children: [
                        const SizedBox(height: 12),
                        ...exercises.map((ex) => ListTile(
                              title: Text(ex.exerciseName),
                              subtitle: Text('${ex.sets} sets x ${ex.reps} reps'),
                              trailing: IconButton(
                                icon: const Icon(Icons.close, size: 18),
                                onPressed: () => setState(() => exercises.remove(ex)),
                              ),
                            )),
                        OutlinedButton.icon(
                          onPressed: () => _addExerciseToDay(day),
                          icon: const Icon(Icons.add),
                          label: const Text('Thêm bài tập'),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      default:
        return ListView(
          children: [
            const Text('Xác nhận', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
            const SizedBox(height: 16),
            Text(_nameController.text, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            Text(_goalController.text, style: const TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 16),
            ..._selectedDays.map((day) {
              final exercises = _dayExercises[day] ?? [];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_dayLabel(day), style: const TextStyle(fontWeight: FontWeight.w700)),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: exercises
                          .map((e) => Chip(label: Text(e.exerciseName)))
                          .toList(),
                    ),
                  ],
                ),
              );
            }),
          ],
        );
    }
  }
}
