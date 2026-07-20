import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../providers/exercise_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/muscle.dart';
import '../../../data/models/exercise.dart';

class ExerciseListScreen extends StatefulWidget {
  /// Khi true, màn hình hoạt động như 1 bộ chọn bài tập: chạm vào 1 item sẽ
  /// gọi [onPick] thay vì điều hướng sang màn chi tiết.
  final bool pickerMode;
  final void Function(Exercise exercise)? onPick;

  const ExerciseListScreen({super.key, this.pickerMode = false, this.onPick});

  @override
  State<ExerciseListScreen> createState() => _ExerciseListScreenState();
}

class _ExerciseListScreenState extends State<ExerciseListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'All';
  final Set<String> _selectedMuscleIds = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _loadData() {
    final provider = context.read<ExerciseProvider>();
    provider.fetchExercises();
    provider.fetchMuscles();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final exerciseProvider = context.watch<ExerciseProvider>();

    // Thực hiện lọc local bài tập theo từ khóa và danh mục
    final filteredExercises = exerciseProvider.exercises.where((exercise) {
      final nameMatches = exercise.name.toLowerCase().contains(
        _searchQuery.toLowerCase(),
      );
      final equipmentMatches = exercise.equipment.toLowerCase().contains(
        _searchQuery.toLowerCase(),
      );

      bool categoryMatches = true;
      if (_selectedCategory != 'All') {
        final categoryMuscleIds = exerciseProvider.muscles
            .where((m) => m.category.toLowerCase() == _selectedCategory.toLowerCase())
            .map((m) => m.id)
            .toSet();
        categoryMatches =
            exercise.muscleImpacts.any((impact) => categoryMuscleIds.contains(impact.muscleId));

        // Đã chọn thêm cơ nhỏ cụ thể bên trong cơ lớn -> thu hẹp thêm.
        if (categoryMatches && _selectedMuscleIds.isNotEmpty) {
          categoryMatches = exercise.muscleImpacts
              .any((impact) => _selectedMuscleIds.contains(impact.muscleId));
        }
      }

      return (nameMatches || equipmentMatches) && categoryMatches;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.pickerMode ? 'Chọn bài tập' : 'Thư Viện Bài Tập',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
      ),
      body: Column(
        children: [
          // 1. Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: TextField(
              controller: _searchController,
              onChanged: (val) {
                setState(() {
                  _searchQuery = val;
                });
              },
              decoration: InputDecoration(
                hintText: 'Tìm bài tập hoặc thiết bị...',
                hintStyle: const TextStyle(color: AppColors.textSecondary),
                prefixIcon: const Icon(
                  Icons.search,
                  color: AppColors.textSecondary,
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(
                          Icons.clear,
                          color: AppColors.textSecondary,
                        ),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppColors.cardBackground,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 0,
                  horizontal: 16,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.surfaceVariant),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: AppColors.primary,
                    width: 1.5,
                  ),
                ),
              ),
            ),
          ),

          // 2. Category Chips Horizontal Scroll
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: ['All', ...exerciseProvider.categories].map((category) {
                final isSelected = _selectedCategory == category;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: FilterChip(
                    label: Text(category == 'All' ? 'Tất cả' : category),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedCategory = category;
                        _selectedMuscleIds.clear();
                      });
                    },
                    selectedColor: AppColors.primary.withValues(alpha: 0.2),
                    checkmarkColor: AppColors.primary,
                    labelStyle: TextStyle(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.textSecondary,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                    backgroundColor: AppColors.cardBackground,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.surfaceVariant,
                        width: isSelected ? 1 : 0.5,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // 2b. Cơ nhỏ bên trong cơ lớn đã chọn (multi-select, tuỳ chỉnh)
          if (_selectedCategory != 'All')
            _buildMuscleSubFilter(exerciseProvider),

          const SizedBox(height: 12),

          // 3. Exercises List
          Expanded(
            child: exerciseProvider.isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  )
                : exerciseProvider.errorMessage != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: AppColors.error,
                          size: 48,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          exerciseProvider.errorMessage!,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: _loadData,
                          child: const Text('Thử lại'),
                        ),
                      ],
                    ),
                  )
                : filteredExercises.isEmpty
                ? const Center(
                    child: Text(
                      'Không tìm thấy bài tập phù hợp.',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    itemCount: filteredExercises.length,
                    itemBuilder: (context, index) {
                      final ex = filteredExercises[index];
                      // Lấy nhóm cơ chính hiển thị đại diện
                      String primaryMuscleName = 'Chưa xác định';
                      if (ex.muscleImpacts.isNotEmpty) {
                        primaryMuscleName = exerciseProvider.getMuscleNameById(
                          ex.muscleImpacts.first.muscleId,
                        );
                      }

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        color: AppColors.cardBackground,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: const BorderSide(
                            color: AppColors.surfaceVariant,
                          ),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () {
                            if (widget.pickerMode) {
                              widget.onPick?.call(ex);
                            } else {
                              context.push('/exercises/${ex.id}');
                            }
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Row(
                              children: [
                                // Exercise Image
                                Container(
                                  width: 75,
                                  height: 75,
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceVariant,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: ex.displayImageUrl.isNotEmpty
                                      ? ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          child: ex.isAssetImage
                                              ? Image.asset(
                                                  ex.displayImageUrl,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (_, _, _) =>
                                                      const Icon(
                                                        Icons.fitness_center,
                                                        color:
                                                            AppColors.primary,
                                                      ),
                                                )
                                              : Image.network(
                                                  ex.displayImageUrl,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (_, _, _) =>
                                                      const Icon(
                                                        Icons.fitness_center,
                                                        color:
                                                            AppColors.primary,
                                                      ),
                                                ),
                                        )
                                      : const Icon(
                                          Icons.fitness_center,
                                          color: AppColors.primary,
                                          size: 28,
                                        ),
                                ),
                                const SizedBox(width: 14),

                                // Info Text
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          // Difficulty Badge
                                          _buildDifficultyBadge(ex.difficulty),
                                          // Equipment Text
                                          Row(
                                            children: [
                                              const Icon(
                                                Icons.handyman_outlined,
                                                size: 12,
                                                color: AppColors.textSecondary,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                ex.equipment
                                                    .split(',')
                                                    .first, // Chỉ lấy thiết bị chính
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  color:
                                                      AppColors.textSecondary,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        ex.name,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Cơ chính: $primaryMuscleName',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(
                                  Icons.arrow_forward_ios,
                                  size: 16,
                                  color: AppColors.textSecondary,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildMuscleSubFilter(ExerciseProvider exerciseProvider) {
    final musclesInCategory = exerciseProvider.muscles
        .where((m) => m.category.toLowerCase() == _selectedCategory.toLowerCase())
        .toList();
    if (musclesInCategory.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: SizedBox(
        height: 34,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          children: musclesInCategory.map((muscle) {
            final isSelected = _selectedMuscleIds.contains(muscle.id);
            return Padding(
              padding: const EdgeInsets.only(right: 6.0),
              child: FilterChip(
                visualDensity: VisualDensity.compact,
                label: Text(muscle.name, style: const TextStyle(fontSize: 11)),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedMuscleIds.add(muscle.id);
                    } else {
                      _selectedMuscleIds.remove(muscle.id);
                    }
                  });
                },
                selectedColor: AppColors.primaryLight.withValues(alpha: 0.2),
                checkmarkColor: AppColors.primary,
                labelStyle: TextStyle(
                  color: isSelected ? AppColors.primary : AppColors.textHint,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                backgroundColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: isSelected ? AppColors.primary : AppColors.surfaceVariant,
                    width: isSelected ? 1 : 0.5,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildDifficultyBadge(String difficulty) {
    Color color;
    switch (difficulty.toLowerCase()) {
      case 'beginner':
        color = Colors.green;
        break;
      case 'intermediate':
        color = Colors.orange;
        break;
      case 'advanced':
        color = Colors.red;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color, width: 0.5),
      ),
      child: Text(
        difficulty,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

}
