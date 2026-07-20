import 'package:flutter/foundation.dart';

/// Giữ dữ liệu tạm của wizard onboarding (4 bước) trước khi submit lên backend.
/// Không gọi API, không validate - từng màn hình tự validate rồi mới sang bước tiếp theo.
class OnboardingProvider extends ChangeNotifier {
  String gender = 'Male';
  int age = 0;
  int heightCm = 0;
  int weightKg = 0;
  final List<String> selectedGoals = [];
  String selectedSchedule = '4 ngày/tuần';

  double get bmi {
    if (heightCm <= 0 || weightKg <= 0) return 0.0;
    final heightM = heightCm / 100.0;
    return double.parse((weightKg / (heightM * heightM)).toStringAsFixed(1));
  }

  void setGender(String value) {
    gender = value;
    notifyListeners();
  }

  void setAge(int value) {
    age = value;
    notifyListeners();
  }

  void setMetrics({required int heightCm, required int weightKg}) {
    this.heightCm = heightCm;
    this.weightKg = weightKg;
    notifyListeners();
  }

  void toggleGoal(String goal) {
    if (selectedGoals.contains(goal)) {
      selectedGoals.remove(goal);
    } else {
      selectedGoals.add(goal);
    }
    notifyListeners();
  }

  void setSchedule(String value) {
    selectedSchedule = value;
    notifyListeners();
  }

  void reset() {
    gender = 'Male';
    age = 0;
    heightCm = 0;
    weightKg = 0;
    selectedGoals.clear();
    selectedSchedule = '4 ngày/tuần';
  }
}
