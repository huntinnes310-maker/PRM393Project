import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/popular_exercise.dart';

/// Danh sách ngang các bài tập được tập nhiều nhất trong 7 ngày qua.
class PopularExercisesSection extends StatelessWidget {
  final List<PopularExercise> exercises;

  const PopularExercisesSection({super.key, required this.exercises});

  @override
  Widget build(BuildContext context) {
    if (exercises.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: 148,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: exercises.length,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final ex = exercises[index];
          return Container(
            width: 120,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: SizedBox(
                        width: double.infinity,
                        height: 70,
                        child: ex.isAssetImage
                            ? Image.asset(
                                ex.displayImageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => Container(
                                  color: AppColors.surfaceVariant,
                                  child: const Icon(
                                    Icons.fitness_center,
                                    color: AppColors.primary,
                                  ),
                                ),
                              )
                            : Image.network(
                                ex.displayImageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => Container(
                                  color: AppColors.surfaceVariant,
                                  child: const Icon(
                                    Icons.fitness_center,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '${ex.workoutCount}×',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  ex.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
