import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import '../../../providers/exercise_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/exercise.dart';

class ExerciseDetailScreen extends StatefulWidget {
  final String exerciseId;
  const ExerciseDetailScreen({super.key, required this.exerciseId});

  @override
  State<ExerciseDetailScreen> createState() => _ExerciseDetailScreenState();
}

class _ExerciseDetailScreenState extends State<ExerciseDetailScreen> {
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;
  bool _isVideoError = false;
  Map<String, dynamic>? _statsData;
  bool _isLoadingStats = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initVideoPlayer();
      _fetchExerciseStats();
    });
  }

  Future<void> _fetchExerciseStats() async {
    final auth = context.read<AuthProvider>();
    if (auth.userId == null) return;
    try {
      final res = await ApiClient().get('/users/${auth.userId}/exercise-stats/${widget.exerciseId}');
      if (res.statusCode == 200) {
        if (mounted) {
          setState(() {
            _statsData = ApiClient.decodeResponse(res);
            _isLoadingStats = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoadingStats = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching exercise stats: $e');
      if (mounted) {
        setState(() {
          _isLoadingStats = false;
        });
      }
    }
  }

  void _initVideoPlayer() {
    final provider = context.read<ExerciseProvider>();
    final exercise = provider.exercises.firstWhere(
      (e) => e.id == widget.exerciseId,
      orElse: () => throw Exception('Không tìm thấy bài tập'),
    );

    final videoPath = exercise.displayVideoPath;
    if (videoPath != null && videoPath.isNotEmpty) {
      if (exercise.isAssetVideo) {
        _videoController = VideoPlayerController.asset(videoPath);
      } else {
        _videoController = VideoPlayerController.networkUrl(Uri.parse(videoPath));
      }

      _videoController!.initialize().then((_) {
        setState(() {
          _isVideoInitialized = true;
          _videoController!.setLooping(true);
        });
      }).catchError((error) {
        debugPrint('Lỗi khởi tạo video: $error');
        setState(() {
          _isVideoError = true;
        });
      });
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ExerciseProvider>();
    final Exercise exercise;
    try {
      exercise = provider.exercises.firstWhere((e) => e.id == widget.exerciseId);
    } catch (_) {
      return Scaffold(
        appBar: AppBar(title: const Text('Chi Tiết Bài Tập')),
        body: const Center(child: Text('Bài tập không tồn tại.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          exercise.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Media Player (Video or Image)
            _buildMediaSection(exercise),
            const SizedBox(height: 20),

            // 2. Title and Badges
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    exercise.name,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                _buildDifficultyBadge(exercise.difficulty),
              ],
            ),
            const SizedBox(height: 8),

            // 3. Equipment & Target Muscle Info
            Row(
              children: [
                const Icon(Icons.handyman, size: 16, color: AppColors.primary),
                const SizedBox(width: 6),
                Text(
                  'Thiết bị: ${exercise.equipment}',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.timer_outlined, size: 16, color: AppColors.primary),
                const SizedBox(width: 6),
                Text(
                  'Mặc định: ${exercise.defaultSets} hiệp x ${exercise.defaultReps} lần | Nghỉ ${exercise.restTimeSeconds}s',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // 4. Muscle Impact Chart
            _buildSectionTitle('Tác động nhóm cơ 🧬'),
            const SizedBox(height: 10),
            _buildMuscleImpactSection(exercise, provider),
            const SizedBox(height: 24),

            // 4.5. Personal Records & Last Performance
            _buildStatsSection(),
            const SizedBox(height: 24),

            // 5. Description
            _buildSectionTitle('Giới thiệu bài tập'),
            const SizedBox(height: 8),
            _buildContentCard(
              content: exercise.description.isNotEmpty
                  ? exercise.description
                  : '${exercise.name} là một bài tập rất hiệu quả giúp tăng cường sức mạnh và khối lượng cơ bắp.',
              icon: Icons.info_outline,
              color: Colors.blueAccent,
            ),
            const SizedBox(height: 20),

            // 6. Step-by-Step Instructions
            _buildSectionTitle('Hướng dẫn thực hiện 📝'),
            const SizedBox(height: 8),
            _buildInstructionsList(exercise.instruction),
            const SizedBox(height: 20),

            // 7. Safety & Common Mistakes Callout
            _buildSectionTitle('Lưu ý đặc biệt ⚠️'),
            const SizedBox(height: 10),
            _buildCalloutBox(
              title: 'Lỗi thường gặp',
              content: exercise.commonMistakes.isNotEmpty
                  ? exercise.commonMistakes
                  : 'Không khóa khớp cùi chỏ/gối đột ngột. Tránh hạ tạ quá nhanh mất kiểm soát.',
              icon: Icons.warning_amber_rounded,
              color: Colors.orange,
            ),
            const SizedBox(height: 12),
            _buildCalloutBox(
              title: 'An toàn tập luyện',
              content: exercise.safetyNotes.isNotEmpty
                  ? exercise.safetyNotes
                  : 'Khởi động kỹ trước khi tập. Sử dụng người đỡ tạ (spotter) nếu tập mức tạ nặng.',
              icon: Icons.gpp_maybe_outlined,
              color: AppColors.error,
            ),
            const SizedBox(height: 12),
            _buildCalloutBox(
              title: 'Mẹo tối ưu (Tips)',
              content: exercise.tips.isNotEmpty
                  ? exercise.tips
                  : 'Hãy gồng cơ bụng (core) trong suốt quá trình đẩy và kiểm soát hơi thở.',
              icon: Icons.lightbulb_outline,
              color: Colors.green,
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
    );
  }

  // 1. Media Area
  Widget _buildMediaSection(Exercise exercise) {
    final videoPath = exercise.displayVideoPath;

    // Nếu không có video hoặc lỗi khởi tạo thì hiển thị ảnh
    if (videoPath == null || _isVideoError) {
      return _buildExerciseImage(exercise.displayImageUrl, exercise.isAssetImage);
    }

    return Container(
      width: double.infinity,
      height: 210,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceVariant),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (_isVideoInitialized && _videoController != null)
              AspectRatio(
                aspectRatio: _videoController!.value.aspectRatio,
                child: VideoPlayer(_videoController!),
              )
            else
              const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),

            // Nút play/pause overlay
            if (_isVideoInitialized && _videoController != null)
              Positioned(
                bottom: 8,
                right: 8,
                child: InkWell(
                  onTap: () {
                    setState(() {
                      if (_videoController!.value.isPlaying) {
                        _videoController!.pause();
                      } else {
                        _videoController!.play();
                      }
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _videoController!.value.isPlaying ? Icons.pause : Icons.play_arrow,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),

            // Huy hiệu video mẫu cục bộ
            if (exercise.isAssetVideo)
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.videocam, size: 12, color: Colors.white),
                      SizedBox(width: 4),
                      Text(
                        'Video mẫu',
                        style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildExerciseImage(String url, bool isAsset) {
    return Container(
      width: double.infinity,
      height: 210,
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceVariant),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: url.isNotEmpty
            ? (isAsset
                ? Image.asset(url, fit: BoxFit.cover)
                : Image.network(
                    url,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        const Icon(Icons.fitness_center, size: 50, color: AppColors.primary),
                  ))
            : const Icon(Icons.fitness_center, size: 50, color: AppColors.primary),
      ),
    );
  }

  // 2. Difficulty Badge
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color, width: 0.5),
      ),
      child: Text(
        difficulty,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  // 3. Muscle Impact Bars
  Widget _buildMuscleImpactSection(Exercise exercise, ExerciseProvider provider) {
    if (exercise.muscleImpacts.isEmpty) {
      return const Text(
        'Chưa có dữ liệu tác động cơ bắp.',
        style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
      );
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceVariant),
      ),
      child: Column(
        children: exercise.muscleImpacts.map((impact) {
          final muscleName = provider.getMuscleNameById(impact.muscleId);
          final double progress = impact.percentage / 100.0;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    muscleName,
                    style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                  ),
                ),
                Expanded(
                  flex: 5,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 6,
                      backgroundColor: AppColors.surfaceVariant,
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '${impact.percentage}%',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStatsSection() {
    if (_isLoadingStats) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.surfaceVariant),
        ),
        child: const Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
          ),
        ),
      );
    }

    if (_statsData == null || _statsData!['totalSessions'] == 0) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.surfaceVariant),
        ),
        child: const Row(
          children: [
            Icon(Icons.emoji_events_outlined, color: AppColors.textHint, size: 28),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Kỷ lục của bạn',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Hãy hoàn thành bài tập này để ghi nhận kỷ lục cá nhân đầu tiên!',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 11.5),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final pr = _statsData!['personalRecord'];
    final last = _statsData!['lastPerformance'];
    final totalSessions = _statsData!['totalSessions'] ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Thành tích của bạn 📈'),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.surfaceVariant),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hàng thông tin tổng quan
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Đã tập $totalSessions buổi',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: AppColors.primary,
                    ),
                  ),
                  const Icon(Icons.star, color: AppColors.goldBadge, size: 18),
                ],
              ),
              const Divider(color: AppColors.surfaceVariant, height: 20),

              // Kỷ lục cá nhân (PR)
              if (pr != null) ...[
                const Text(
                  'KỶ LỤC CÁ NHÂN (PR) 🏆',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textHint,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildStatMiniCard('Tạ nặng nhất', '${pr['maxWeight']} kg', Icons.fitness_center),
                    _buildStatMiniCard('Reps nhiều nhất', '${pr['maxReps']} cái', Icons.repeat),
                    _buildStatMiniCard('Volume lớn nhất', '${pr['bestVolume']} kg', Icons.bolt),
                  ],
                ),
                const SizedBox(height: 20),
              ],

              // Lần tập gần nhất
              if (last != null) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'LẦN TẬP GẦN NHẤT 📅',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textHint,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      '${last['date']}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: (last['sets'] as List? ?? []).map((s) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Hiệp ${s['setNumber']}',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              '${s['weight']} kg x ${s['reps']} lần',
                              style: const TextStyle(fontSize: 12, color: AppColors.textPrimary),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatMiniCard(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.surfaceVariant.withOpacity(0.5)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 16, color: AppColors.primary),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 9, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  // 4. Description Content Card
  Widget _buildContentCard({required String content, required IconData icon, required Color color}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceVariant),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              content,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 5. Instruction List
  Widget _buildInstructionsList(String instruction) {
    if (instruction.isEmpty) {
      return const Text(
        'Đang cập nhật hướng dẫn...',
        style: TextStyle(color: AppColors.textSecondary),
      );
    }

    // Tách các câu dựa trên dấu chấm
    final steps = instruction
        .split('.')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceVariant),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: steps.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 10,
                backgroundColor: AppColors.primary.withOpacity(0.2),
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '${steps[index]}.',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // 6. Callout Warnings Box
  Widget _buildCalloutBox({required String title, required String content, required IconData icon, required Color color}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            content,
            style: const TextStyle(
              fontSize: 12.5,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
