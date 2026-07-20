class WorkoutSetLog {
  final String id;
  final int setNumber;
  final double? weight;
  final int? reps;
  final int? durationSeconds;
  final int? rpe;
  final String status;

  WorkoutSetLog({
    required this.id,
    required this.setNumber,
    this.weight,
    this.reps,
    this.durationSeconds,
    this.rpe,
    this.status = 'COMPLETED',
  });

  factory WorkoutSetLog.fromJson(Map<String, dynamic> json) {
    return WorkoutSetLog(
      id: json['id'] ?? '',
      setNumber: json['setNumber'] ?? 0,
      weight: (json['weight'] as num?)?.toDouble(),
      reps: json['reps'],
      durationSeconds: json['durationSeconds'],
      rpe: json['rpe'],
      status: json['status'] ?? 'COMPLETED',
    );
  }
}

class WorkoutExerciseLog {
  final String id;
  final String exerciseId;
  final String exerciseName;
  final List<String> muscleIds;
  final int orderIndex;
  final String status;
  final int plannedSets;
  final String plannedReps;
  final List<WorkoutSetLog> sets;

  WorkoutExerciseLog({
    required this.id,
    required this.exerciseId,
    required this.exerciseName,
    required this.muscleIds,
    required this.orderIndex,
    required this.status,
    required this.plannedSets,
    required this.plannedReps,
    required this.sets,
  });

  factory WorkoutExerciseLog.fromJson(Map<String, dynamic> json) {
    return WorkoutExerciseLog(
      id: json['id'] ?? '',
      exerciseId: json['exerciseId'] ?? '',
      exerciseName: json['exerciseName'] ?? '',
      muscleIds: (json['muscleIds'] as List? ?? []).map((e) => e.toString()).toList(),
      orderIndex: json['orderIndex'] ?? 0,
      status: json['status'] ?? 'PENDING',
      plannedSets: json['plannedSets'] ?? 0,
      plannedReps: json['plannedReps']?.toString() ?? '',
      sets: (json['sets'] as List? ?? []).map((x) => WorkoutSetLog.fromJson(x)).toList(),
    );
  }
}

class MuscleExpGain {
  final String muscleId;
  final String muscleName;
  final int expGained;
  final int oldLevel;
  final int newLevel;
  final bool isLevelUp;

  MuscleExpGain({
    required this.muscleId,
    required this.muscleName,
    required this.expGained,
    required this.oldLevel,
    required this.newLevel,
    required this.isLevelUp,
  });

  factory MuscleExpGain.fromJson(Map<String, dynamic> json) {
    return MuscleExpGain(
      muscleId: json['muscleId'] ?? '',
      muscleName: json['muscleName'] ?? '',
      expGained: json['expGained'] ?? 0,
      oldLevel: json['oldLevel'] ?? 1,
      newLevel: json['newLevel'] ?? 1,
      isLevelUp: json['isLevelUp'] ?? false,
    );
  }
}

class WorkoutSessionLog {
  final String id;
  final String userId;
  final String? workoutPlanId;
  final String? planSessionId;
  final String name;
  final String focus;
  final DateTime? startTime;
  final DateTime? endTime;
  final String status;
  final int totalDurationSeconds;
  final int totalSets;
  final double totalVolume;
  final int totalExpGained;
  final String? notes;
  final List<WorkoutExerciseLog> exercises;
  final List<MuscleExpGain> muscleExpGains;
  final List<String> scheduledDaysOfWeek;

  WorkoutSessionLog({
    required this.id,
    required this.userId,
    this.workoutPlanId,
    this.planSessionId,
    required this.name,
    required this.focus,
    this.startTime,
    this.endTime,
    required this.status,
    required this.totalDurationSeconds,
    required this.totalSets,
    required this.totalVolume,
    required this.totalExpGained,
    this.notes,
    required this.exercises,
    required this.muscleExpGains,
    required this.scheduledDaysOfWeek,
  });

  factory WorkoutSessionLog.fromJson(Map<String, dynamic> json) {
    return WorkoutSessionLog(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      workoutPlanId: json['workoutPlanId'],
      planSessionId: json['planSessionId'],
      name: json['name'] ?? '',
      focus: json['focus'] ?? '',
      startTime: json['startTime'] != null ? DateTime.tryParse(json['startTime'].toString()) : null,
      endTime: json['endTime'] != null ? DateTime.tryParse(json['endTime'].toString()) : null,
      status: json['status'] ?? 'IN_PROGRESS',
      totalDurationSeconds: json['totalDurationSeconds'] ?? 0,
      totalSets: json['totalSets'] ?? 0,
      totalVolume: (json['totalVolume'] as num?)?.toDouble() ?? 0.0,
      totalExpGained: json['totalExpGained'] ?? 0,
      notes: json['notes'],
      exercises: (json['exercises'] as List? ?? [])
          .map((x) => WorkoutExerciseLog.fromJson(x))
          .toList(),
      muscleExpGains: (json['muscleExpGains'] as List? ?? [])
          .map((x) => MuscleExpGain.fromJson(x))
          .toList(),
      scheduledDaysOfWeek:
          (json['scheduledDaysOfWeek'] as List? ?? []).map((e) => e.toString()).toList(),
    );
  }
}
