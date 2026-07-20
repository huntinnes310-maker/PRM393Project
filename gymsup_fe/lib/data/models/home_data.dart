import '../../core/utils/exercise_asset_resolver.dart';
import 'popular_exercise.dart';

class HomeData {
  final List<dynamic> history;
  final List<dynamic> plans;
  final TodayPlan? todayPlan;
  final HomeNutrition nutrition;
  final List<MuscleProgress> muscleProgress;
  final List<PopularExercise> popularExercises;
  final int streak;
  final int workoutCount;
  final List<dynamic> badges;

  HomeData({
    required this.history,
    required this.plans,
    this.todayPlan,
    required this.nutrition,
    required this.muscleProgress,
    required this.popularExercises,
    required this.streak,
    required this.workoutCount,
    required this.badges,
  });

  factory HomeData.fromJson(Map<String, dynamic> json) {
    return HomeData(
      history: json['history'] ?? [],
      plans: json['plans'] ?? [],
      todayPlan: json['todayPlan'] != null
          ? TodayPlan.fromJson(json['todayPlan'])
          : null,
      nutrition: HomeNutrition.fromJson(json['nutrition'] ?? {}),
      muscleProgress: (json['muscleProgress'] as List? ?? [])
          .map((x) => MuscleProgress.fromJson(x))
          .toList(),
      popularExercises: (json['popularExercises'] as List? ?? [])
          .map((x) => PopularExercise.fromJson(x))
          .toList(),
      streak: json['streak'] ?? 0,
      workoutCount: json['workoutCount'] ?? 0,
      badges: json['badges'] ?? [],
    );
  }
}

class TodayPlan {
  final String day;
  final String? focus;
  final List<TodayExercise> exercises;

  TodayPlan({
    required this.day,
    this.focus,
    required this.exercises,
  });

  factory TodayPlan.fromJson(Map<String, dynamic> json) {
    return TodayPlan(
      day: json['day'] ?? 'Today',
      focus: json['focus'],
      exercises: (json['exercises'] as List? ?? [])
          .map((x) => TodayExercise.fromJson(x))
          .toList(),
    );
  }
}

class TodayExercise {
  final String id;
  final String name;
  final String muscle;
  final String imageUrl;
  final int? sets;
  final String? reps;
  final String? notes;

  TodayExercise({
    required this.id,
    required this.name,
    required this.muscle,
    required this.imageUrl,
    this.sets,
    this.reps,
    this.notes,
  });

  String get displayImageUrl {
    if (imageUrl.isNotEmpty && imageUrl.startsWith('http')) {
      return imageUrl;
    }
    return resolveExerciseAssetPath(name);
  }

  bool get isAssetImage => !displayImageUrl.startsWith('http');

  factory TodayExercise.fromJson(Map<String, dynamic> json) {
    return TodayExercise(
      id: json['id'] ?? '',
      name: json['name'] ?? 'Bài tập',
      muscle: json['muscle'] ?? 'Unknown',
      imageUrl: json['imageUrl'] ?? '',
      sets: json['sets'],
      reps: json['reps']?.toString(),
      notes: json['notes'],
    );
  }
}

class HomeNutrition {
  final String calories;
  final String protein;
  final String water;
  final double caloriesPercent;
  final double proteinPercent;
  final double waterPercent;

  HomeNutrition({
    required this.calories,
    required this.protein,
    required this.water,
    required this.caloriesPercent,
    required this.proteinPercent,
    required this.waterPercent,
  });

  factory HomeNutrition.fromJson(Map<String, dynamic> json) {
    return HomeNutrition(
      calories: json['calories']?.toString() ?? '—',
      protein: json['protein']?.toString() ?? '—',
      water: json['water']?.toString() ?? '—',
      caloriesPercent: (json['caloriesPercent'] as num?)?.toDouble() ?? 0.0,
      proteinPercent: (json['proteinPercent'] as num?)?.toDouble() ?? 0.0,
      waterPercent: (json['waterPercent'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class MuscleProgress {
  final String muscleId;
  final String name;
  final String category;
  final int totalExp;
  final int level;
  final int currentLevelExp;
  final int expToNextLevel;
  final double progress;
  final String tier;
  final bool isLagging;

  MuscleProgress({
    required this.muscleId,
    required this.name,
    required this.category,
    required this.totalExp,
    required this.level,
    required this.currentLevelExp,
    required this.expToNextLevel,
    required this.progress,
    required this.tier,
    required this.isLagging,
  });

  factory MuscleProgress.fromJson(Map<String, dynamic> json) {
    return MuscleProgress(
      muscleId: json['muscleId'] ?? '',
      name: json['name'] ?? '',
      category: json['category'] ?? '',
      totalExp: json['totalExp'] ?? 0,
      level: json['level'] ?? 1,
      currentLevelExp: json['currentLevelExp'] ?? 0,
      expToNextLevel: json['expToNextLevel'] ?? 100,
      progress: (json['progress'] as num?)?.toDouble() ?? 0.0,
      tier: json['tier'] ?? 'Iron',
      isLagging: json['isLagging'] ?? false,
    );
  }
}
