class CustomerProfile {
  final String id;
  final String userId;
  final String fullName;
  final String email;
  final String gender;
  final int age;
  final double bmi;
  final int heightCm;
  final int weightKg;
  final String goal;
  final String experienceLevel;
  final String injuryNotes;

  CustomerProfile({
    required this.id,
    required this.userId,
    required this.fullName,
    required this.email,
    required this.gender,
    required this.age,
    required this.bmi,
    required this.heightCm,
    required this.weightKg,
    required this.goal,
    required this.experienceLevel,
    required this.injuryNotes,
  });

  factory CustomerProfile.fromJson(Map<String, dynamic> json) {
    return CustomerProfile(
      id: json['id'] ?? json['_id'] ?? '',
      userId: json['userId'] ?? '',
      fullName: json['fullName'] ?? '',
      email: json['email'] ?? '',
      gender: json['gender'] ?? '',
      age: json['age'] ?? 0,
      bmi: (json['bmi'] ?? 0.0).toDouble(),
      heightCm: json['heightCm'] ?? 0,
      weightKg: json['weightKg'] ?? 0,
      goal: json['goal'] ?? '',
      experienceLevel: json['experienceLevel'] ?? '',
      injuryNotes: json['injuryNotes'] ?? '',
    );
  }

  // Đánh giá trạng thái BMI
  String get bmiStatus {
    if (bmi <= 0) return 'Chưa có dữ liệu';
    if (bmi < 18.5) return 'Thiếu cân';
    if (bmi < 25.0) return 'Bình thường';
    if (bmi < 30.0) return 'Thừa cân';
    return 'Béo phì';
  }

  String get goalDisplayName {
    switch (goal.toLowerCase()) {
      case 'muscle_gain':
      case 'musclegain':
        return 'Tăng cơ bắp 💪';
      case 'fat_loss':
      case 'fatloss':
        return 'Giảm mỡ 🔥';
      case 'endurance':
        return 'Tăng sức bền ⚡';
      case 'general_fitness':
      case 'generalfitness':
        return 'Tập thể dục tổng hợp 🏃';
      case 'strength':
        return 'Tăng sức mạnh 🏋️';
      default:
        return goal.isNotEmpty ? goal : 'Chưa xác định';
    }
  }

  String get experienceDisplayName {
    switch (experienceLevel.toLowerCase()) {
      case 'beginner':
        return 'Mới bắt đầu 🌱';
      case 'intermediate':
        return 'Trung cấp ⭐';
      case 'advanced':
        return 'Nâng cao 🏆';
      default:
        return experienceLevel.isNotEmpty ? experienceLevel : 'Chưa xác định';
    }
  }
}
