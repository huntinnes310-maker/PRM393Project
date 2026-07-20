import '../../core/utils/exercise_asset_resolver.dart';

class PopularExercise {
  final String id;
  final String name;
  final String imageUrl;
  final int workoutCount;
  final int completedSets;
  final DateTime? lastPerformedAt;

  PopularExercise({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.workoutCount,
    required this.completedSets,
    this.lastPerformedAt,
  });

  String get displayImageUrl {
    if (imageUrl.isNotEmpty && imageUrl.startsWith('http')) {
      return imageUrl;
    }
    return resolveExerciseAssetPath(name);
  }

  bool get isAssetImage => !displayImageUrl.startsWith('http');

  factory PopularExercise.fromJson(Map<String, dynamic> json) {
    return PopularExercise(
      id: json['id'] ?? '',
      name: json['name'] ?? 'Bài tập',
      imageUrl: json['imageUrl'] ?? '',
      workoutCount: json['workoutCount'] ?? 0,
      completedSets: json['completedSets'] ?? 0,
      lastPerformedAt: json['lastPerformedAt'] != null
          ? DateTime.tryParse(json['lastPerformedAt'].toString())
          : null,
    );
  }
}
