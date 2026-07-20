class WorkoutEvaluationSummary {
  final int durationMinutes;
  final int exerciseCount;
  final int totalSets;
  final int totalReps;
  final double totalVolumeKg;
  final int estimatedCalories;

  WorkoutEvaluationSummary({
    required this.durationMinutes,
    required this.exerciseCount,
    required this.totalSets,
    required this.totalReps,
    required this.totalVolumeKg,
    required this.estimatedCalories,
  });

  factory WorkoutEvaluationSummary.fromJson(Map<String, dynamic> json) {
    return WorkoutEvaluationSummary(
      durationMinutes: json['durationMinutes'] ?? 0,
      exerciseCount: json['exerciseCount'] ?? 0,
      totalSets: json['totalSets'] ?? 0,
      totalReps: json['totalReps'] ?? 0,
      totalVolumeKg: (json['totalVolumeKg'] as num?)?.toDouble() ?? 0.0,
      estimatedCalories: json['estimatedCalories'] ?? 0,
    );
  }
}

class WorkoutSessionComparison {
  final bool hasPrevious;
  final DateTime? previousDate;
  final double previousVolumeKg;
  final double volumeDeltaPercent;
  final int previousSets;
  final int setsDelta;
  final int previousDurationMinutes;
  final int durationDeltaMinutes;

  WorkoutSessionComparison({
    required this.hasPrevious,
    this.previousDate,
    required this.previousVolumeKg,
    required this.volumeDeltaPercent,
    required this.previousSets,
    required this.setsDelta,
    required this.previousDurationMinutes,
    required this.durationDeltaMinutes,
  });

  factory WorkoutSessionComparison.fromJson(Map<String, dynamic> json) {
    return WorkoutSessionComparison(
      hasPrevious: json['hasPrevious'] == true,
      previousDate: json['previousDate'] != null
          ? DateTime.tryParse(json['previousDate'].toString())
          : null,
      previousVolumeKg: (json['previousVolumeKg'] as num?)?.toDouble() ?? 0.0,
      volumeDeltaPercent:
          (json['volumeDeltaPercent'] as num?)?.toDouble() ?? 0.0,
      previousSets: json['previousSets'] ?? 0,
      setsDelta: json['setsDelta'] ?? 0,
      previousDurationMinutes: json['previousDurationMinutes'] ?? 0,
      durationDeltaMinutes: json['durationDeltaMinutes'] ?? 0,
    );
  }
}

class MuscleRecoveryStatus {
  final String muscleCategory;
  final String status;
  final int recoveryHours;
  final DateTime? readyAt;

  MuscleRecoveryStatus({
    required this.muscleCategory,
    required this.status,
    required this.recoveryHours,
    this.readyAt,
  });

  factory MuscleRecoveryStatus.fromJson(Map<String, dynamic> json) {
    return MuscleRecoveryStatus(
      muscleCategory: json['muscleCategory'] ?? '',
      status: json['status'] ?? '',
      recoveryHours: json['recoveryHours'] ?? 0,
      readyAt: json['readyAt'] != null
          ? DateTime.tryParse(json['readyAt'].toString())
          : null,
    );
  }
}

class NutritionRecommendation {
  final int proteinGrams;
  final double waterLiters;
  final String mealSuggestion;

  NutritionRecommendation({
    required this.proteinGrams,
    required this.waterLiters,
    required this.mealSuggestion,
  });

  factory NutritionRecommendation.fromJson(Map<String, dynamic> json) {
    return NutritionRecommendation(
      proteinGrams: json['proteinGrams'] ?? 0,
      waterLiters: (json['waterLiters'] as num?)?.toDouble() ?? 0.0,
      mealSuggestion: json['mealSuggestion'] ?? '',
    );
  }
}

class WorkoutEvaluation {
  final int score;
  final String grade;
  final WorkoutEvaluationSummary summary;
  final WorkoutSessionComparison comparison;
  final List<String> highlights;
  final List<String> improvements;
  final List<MuscleRecoveryStatus> recovery;
  final NutritionRecommendation nutrition;
  final String narrativeSummary;
  final String suggestedNextWorkout;
  final String motivationalMessage;

  WorkoutEvaluation({
    required this.score,
    required this.grade,
    required this.summary,
    required this.comparison,
    required this.highlights,
    required this.improvements,
    required this.recovery,
    required this.nutrition,
    required this.narrativeSummary,
    required this.suggestedNextWorkout,
    required this.motivationalMessage,
  });

  factory WorkoutEvaluation.fromJson(Map<String, dynamic> json) {
    return WorkoutEvaluation(
      score: json['score'] ?? 0,
      grade: json['grade'] ?? '',
      summary: WorkoutEvaluationSummary.fromJson(
        Map<String, dynamic>.from(json['summary'] ?? {}),
      ),
      comparison: WorkoutSessionComparison.fromJson(
        Map<String, dynamic>.from(json['comparison'] ?? {}),
      ),
      highlights: (json['highlights'] as List? ?? [])
          .map((e) => e.toString())
          .toList(),
      improvements: (json['improvements'] as List? ?? [])
          .map((e) => e.toString())
          .toList(),
      recovery: (json['recovery'] as List? ?? [])
          .map((x) => MuscleRecoveryStatus.fromJson(x))
          .toList(),
      nutrition: NutritionRecommendation.fromJson(
        Map<String, dynamic>.from(json['nutrition'] ?? {}),
      ),
      narrativeSummary: json['narrativeSummary'] ?? '',
      suggestedNextWorkout: json['suggestedNextWorkout'] ?? '',
      motivationalMessage: json['motivationalMessage'] ?? '',
    );
  }
}
