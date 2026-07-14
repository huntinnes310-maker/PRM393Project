class Exercise {
  final String id;
  final String name;
  final String equipment;
  final String difficulty;
  final String description;
  final String instruction;
  final String safetyNotes;
  final String commonMistakes;
  final String tips;
  final int defaultSets;
  final String defaultReps;
  final int restTimeSeconds;
  final String imageUrl;
  final String videoUrl;
  final List<MuscleImpact> muscleImpacts;

  Exercise({
    required this.id,
    required this.name,
    required this.equipment,
    required this.difficulty,
    required this.description,
    required this.instruction,
    required this.safetyNotes,
    required this.commonMistakes,
    required this.tips,
    required this.defaultSets,
    required this.defaultReps,
    required this.restTimeSeconds,
    required this.imageUrl,
    required this.videoUrl,
    required this.muscleImpacts,
  });

  factory Exercise.fromJson(Map<String, dynamic> json) {
    return Exercise(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      equipment: json['equipment'] ?? '',
      difficulty: json['difficulty'] ?? 'Beginner',
      description: json['description'] ?? '',
      instruction: json['instruction'] ?? '',
      safetyNotes: json['safetyNotes'] ?? '',
      commonMistakes: json['commonMistakes'] ?? '',
      tips: json['tips'] ?? '',
      defaultSets: json['defaultSets'] ?? 3,
      defaultReps: json['defaultReps']?.toString() ?? '10',
      restTimeSeconds: json['restTimeSeconds'] ?? 60,
      imageUrl: json['imageUrl'] ?? '',
      videoUrl: json['videoUrl'] ?? '',
      muscleImpacts: (json['muscleImpacts'] as List? ?? [])
          .map((x) => MuscleImpact.fromJson(x))
          .toList(),
    );
  }

  String get slug {
    return name
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'-+$|^-+'), '');
  }

  String get displayImageUrl {
    if (imageUrl.isNotEmpty && imageUrl.startsWith('http')) {
      return imageUrl;
    }
    // Đối với ảnh cục bộ đã chép sang assets
    if (slug == 'barbell-bench-press' ||
        slug == 'dumbbell-bench-press' ||
        slug == 'incline-barbell-press') {
      return 'assets/exercises/images/$slug.png';
    }
    return 'assets/exercises/images/$slug.webp';
  }

  bool get isAssetImage => !displayImageUrl.startsWith('http');

  String? get displayVideoPath {
    if (videoUrl.isNotEmpty && videoUrl.startsWith('http')) {
      return videoUrl;
    }
    // Chúng ta chỉ có 1 video mẫu cục bộ là barbell-bench-press.mp4
    if (slug == 'barbell-bench-press') {
      return 'assets/exercises/videos/$slug.mp4';
    }
    return null;
  }

  bool get isAssetVideo => displayVideoPath != null && !displayVideoPath!.startsWith('http');
}

class MuscleImpact {
  final String muscleId;
  final int percentage;

  MuscleImpact({
    required this.muscleId,
    required this.percentage,
  });

  factory MuscleImpact.fromJson(Map<String, dynamic> json) {
    return MuscleImpact(
      muscleId: json['muscleId'] ?? '',
      percentage: json['percentage'] ?? 0,
    );
  }
}
