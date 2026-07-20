import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// Danh sách mục tiêu tập luyện cố định cho bước chọn Goal của onboarding.
/// Backend không có endpoint tra cứu goal - chuỗi `title` được gửi thẳng
/// (nối bằng ', ' nếu chọn nhiều) vào field `goal` của Customer.
class GoalOption {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;

  const GoalOption({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
  });
}

const List<GoalOption> kOnboardingGoals = [
  GoalOption(
    title: 'Tăng Cơ Bắp',
    subtitle: 'Build Muscle',
    icon: Icons.fitness_center,
    color: AppColors.primary,
  ),
  GoalOption(
    title: 'Giảm Cân',
    subtitle: 'Lose Weight',
    icon: Icons.local_fire_department,
    color: Color(0xFFFFB545),
  ),
  GoalOption(
    title: 'Tăng Sức Mạnh',
    subtitle: 'Increase Strength',
    icon: Icons.bolt,
    color: Color(0xFF8B5CF6),
  ),
  GoalOption(
    title: 'Tăng Sức Bền',
    subtitle: 'Boost Endurance',
    icon: Icons.show_chart,
    color: Color(0xFF06B6D4),
  ),
  GoalOption(
    title: 'Giữ Sức Khỏe',
    subtitle: 'Stay Healthy',
    icon: Icons.favorite,
    color: Color(0xFFFF5C8A),
  ),
];

/// Danh sách tần suất tập luyện cố định cho bước chọn Schedule của onboarding.
/// Backend không có field lịch tập riêng - chuỗi `title` được gửi vào field
/// `experienceLevel` của Customer (tái sử dụng field này để lưu tần suất).
class ScheduleOption {
  final String title;
  final String subtitle;
  final String description;
  final IconData icon;
  final Color color;

  const ScheduleOption({
    required this.title,
    required this.subtitle,
    required this.description,
    required this.icon,
    required this.color,
  });
}

const List<ScheduleOption> kOnboardingSchedules = [
  ScheduleOption(
    title: '3 ngày/tuần',
    subtitle: 'Beginner',
    description: 'Phù hợp người mới bắt đầu, dễ duy trì.',
    icon: Icons.calendar_today_outlined,
    color: AppColors.primary,
  ),
  ScheduleOption(
    title: '4 ngày/tuần',
    subtitle: 'Balanced',
    description: 'Cân bằng giữa tập luyện và phục hồi.',
    icon: Icons.event_available,
    color: Color(0xFF06B6D4),
  ),
  ScheduleOption(
    title: '5 ngày/tuần',
    subtitle: 'Intermediate',
    description: 'Tốt cho người đã quen tập đều đặn.',
    icon: Icons.fitness_center,
    color: Color(0xFFFFB545),
  ),
  ScheduleOption(
    title: '6 ngày/tuần',
    subtitle: 'Advanced',
    description: 'Cường độ cao, cần ngủ và ăn uống tốt.',
    icon: Icons.bolt,
    color: Color(0xFFC084FC),
  ),
  ScheduleOption(
    title: '7 ngày/tuần',
    subtitle: 'Athlete',
    description: 'Chỉ nên dùng nếu có ngày tập nhẹ/phục hồi.',
    icon: Icons.emoji_events,
    color: Color(0xFFFF5C8A),
  ),
];
