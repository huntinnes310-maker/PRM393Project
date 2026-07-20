import 'workout_session_log.dart';

class SimpleBadge {
  final String? id;
  final String name;
  final String? iconUrl;
  final String? description;

  SimpleBadge({this.id, required this.name, this.iconUrl, this.description});

  factory SimpleBadge.fromJson(Map<String, dynamic> json) {
    return SimpleBadge(
      id: json['id'],
      name: json['name'] ?? json['badgeName'] ?? '',
      iconUrl: json['iconUrl'],
      description: json['description'],
    );
  }
}

class FinishWorkoutResult {
  final WorkoutSessionLog session;
  final int currentStreak;
  final SimpleBadge? newBadge;

  FinishWorkoutResult({
    required this.session,
    required this.currentStreak,
    this.newBadge,
  });

  factory FinishWorkoutResult.fromJson(Map<String, dynamic> json) {
    return FinishWorkoutResult(
      session: WorkoutSessionLog.fromJson(json['session'] ?? {}),
      currentStreak: json['currentStreak'] ?? 0,
      newBadge: json['newBadge'] != null ? SimpleBadge.fromJson(json['newBadge']) : null,
    );
  }
}
