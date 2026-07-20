class PlanExercise {
  final String exerciseId;
  final String exerciseName;
  final int sets;
  final String reps;
  final String notes;

  PlanExercise({
    required this.exerciseId,
    required this.exerciseName,
    required this.sets,
    required this.reps,
    this.notes = '',
  });

  factory PlanExercise.fromJson(Map<String, dynamic> json) {
    return PlanExercise(
      exerciseId: json['exerciseId'] ?? '',
      exerciseName: json['exerciseName'] ?? '',
      sets: json['sets'] ?? 3,
      reps: json['reps']?.toString() ?? '10',
      notes: json['notes'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'exerciseId': exerciseId,
        'exerciseName': exerciseName,
        'sets': sets,
        'reps': reps,
        'notes': notes,
      };
}

class PlanSession {
  final String id;
  final String dayOfWeek;
  final String focus;
  final List<PlanExercise> exercises;

  PlanSession({
    required this.id,
    required this.dayOfWeek,
    required this.focus,
    required this.exercises,
  });

  factory PlanSession.fromJson(Map<String, dynamic> json) {
    return PlanSession(
      id: json['id'] ?? '',
      dayOfWeek: json['dayOfWeek'] ?? '',
      focus: json['focus'] ?? '',
      exercises: (json['exercises'] as List? ?? [])
          .map((x) => PlanExercise.fromJson(x))
          .toList(),
    );
  }
}

class WorkoutPlan {
  final String id;
  final String userId;
  final String name;
  final String goal;
  final String description;
  final int daysPerWeek;
  final bool isActive;
  final DateTime? createdAt;
  final List<PlanSession> sessions;

  WorkoutPlan({
    required this.id,
    required this.userId,
    required this.name,
    required this.goal,
    this.description = '',
    required this.daysPerWeek,
    required this.isActive,
    this.createdAt,
    required this.sessions,
  });

  factory WorkoutPlan.fromJson(Map<String, dynamic> json) {
    return WorkoutPlan(
      id: json['id'] ?? json['_id'] ?? '',
      userId: json['userId'] ?? '',
      name: json['name'] ?? '',
      goal: json['goal'] ?? '',
      description: json['description'] ?? '',
      daysPerWeek: json['daysPerWeek'] ?? 0,
      isActive: json['isActive'] ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      sessions: (json['sessions'] as List? ?? [])
          .map((x) => PlanSession.fromJson(x))
          .toList(),
    );
  }
}

/// Danh sách ngày trong tuần dùng cho lịch tập - giá trị tiếng Anh để khớp
/// với logic tính streak ở backend, nhãn hiển thị tiếng Việt.
const List<Map<String, String>> kWeekDays = [
  {'value': 'Monday', 'label': 'T2'},
  {'value': 'Tuesday', 'label': 'T3'},
  {'value': 'Wednesday', 'label': 'T4'},
  {'value': 'Thursday', 'label': 'T5'},
  {'value': 'Friday', 'label': 'T6'},
  {'value': 'Saturday', 'label': 'T7'},
  {'value': 'Sunday', 'label': 'CN'},
];
