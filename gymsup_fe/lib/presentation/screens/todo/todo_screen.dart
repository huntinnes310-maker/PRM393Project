import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/home_provider.dart';
import '../../../providers/exercise_provider.dart';
import '../../../providers/profile_provider.dart';
import '../../../data/models/home_data.dart';
import '../../../data/models/exercise.dart';
import '../../../core/network/api_client.dart';

class TodoScreen extends StatefulWidget {
  const TodoScreen({super.key});

  @override
  State<TodoScreen> createState() => _TodoScreenState();
}

class _TodoScreenState extends State<TodoScreen> {
  final ApiClient _apiClient = ApiClient();
  final Set<String> _completedIds = {};
  final Set<String> _submittedIds = {}; // Bài tập đã nộp XP
  final List<TodayExercise> _customExercises = [];
  bool _isInitLoaded = false;
  bool _isSubmitting = false; // Tránh bấm nhiều lần
  String _todayKey = '';

  @override
  void initState() {
    super.initState();
    _todayKey = DateFormat('yyyy-MM-dd').format(DateTime.now());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchLibrary();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final auth = Provider.of<AuthProvider>(context);
    if (auth.userId != null && !_isInitLoaded) {
      _loadState();
    }
  }

  Future<void> _fetchLibrary() async {
    final ep = context.read<ExerciseProvider>();
    if (ep.exercises.isEmpty) {
      await ep.fetchExercises();
    }
    if (ep.muscles.isEmpty) {
      await ep.fetchMuscles();
    }
  }

  Future<void> _loadState() async {
    final auth = context.read<AuthProvider>();
    if (auth.userId == null) return;

    try {
      final res = await _apiClient.get('/todo-checklist?userId=${auth.userId}&date=$_todayKey');
      if (res.statusCode == 200) {
        final data = ApiClient.decodeResponse(res);
        final List<String> completed = List<String>.from(data['completedExerciseIds'] ?? []);
        final List<String> submitted = List<String>.from(data['submittedExerciseIds'] ?? []);
        final List<String> customList = List<String>.from(data['customExerciseIds'] ?? []);

        final exerciseProvider = context.read<ExerciseProvider>();
        if (exerciseProvider.exercises.isEmpty) {
          await exerciseProvider.fetchExercises();
        }

        if (mounted) {
          setState(() {
            _completedIds.clear();
            _completedIds.addAll(completed);
            _submittedIds.clear();
            _submittedIds.addAll(submitted);
            _customExercises.clear();
            for (var customId in customList) {
              final found = exerciseProvider.exercises.firstWhere((e) => e.id == customId, orElse: () => _dummyFullExercise(customId));
              if (found.id.isNotEmpty) {
                _customExercises.add(TodayExercise(
                  id: found.id,
                  name: found.name.isNotEmpty ? found.name : 'Bài tập tự thêm',
                  muscle: found.muscleImpacts.isNotEmpty 
                      ? exerciseProvider.getMuscleNameById(found.muscleImpacts.first.muscleId)
                      : 'Khác',
                  imageUrl: found.imageUrl,
                  sets: found.defaultSets,
                  reps: found.defaultReps,
                ));
              }
            }
            _isInitLoaded = true;
          });
        }
      }
    } catch (e) {
      debugPrint('Lỗi tải checklist từ database: $e');
      if (mounted) {
        setState(() {
          _isInitLoaded = true;
        });
      }
    }
  }



  Future<void> _saveState() async {
    final auth = context.read<AuthProvider>();
    if (auth.userId == null) return;

    try {
      final customIds = _customExercises.map((e) => e.id).toList();
      await _apiClient.post('/todo-checklist', {
        'userId': auth.userId,
        'date': _todayKey,
        'customExerciseIds': customIds,
        'completedExerciseIds': _completedIds.toList(),
        'submittedExerciseIds': _submittedIds.toList(),
      });
    } catch (e) {
      debugPrint('Lỗi lưu checklist vào database: $e');
    }
  }

  Future<void> _toggleComplete(TodayExercise ex, bool? val) async {
    if (val == null) return;
    final auth = context.read<AuthProvider>();
    if (auth.userId == null) return;

    setState(() {
      if (val) {
        _completedIds.add(ex.id);
      } else {
        _completedIds.remove(ex.id);
        _submittedIds.remove(ex.id); // Nếu bỏ chọn thì reset trạng thái nộp XP
      }
    });
    await _saveState();
  }

  Future<void> _submitWorkout(List<TodayExercise> allExercises) async {
    final auth = context.read<AuthProvider>();
    final ep = context.read<ExerciseProvider>();
    final homeProvider = context.read<HomeProvider>();
    if (auth.userId == null) return;

    // Tìm các bài tập đã chọn hoàn thành nhưng CHƯA nộp XP
    final pending = allExercises.where(
      (e) => _completedIds.contains(e.id) && !_submittedIds.contains(e.id)
    ).toList();

    if (pending.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không có bài tập mới nào cần xác nhận!')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    String? sessionLogId;
    final plans = homeProvider.homeData?.plans ?? [];
    final activePlan = plans.firstWhere(
      (p) => p['isActive'] == true,
      orElse: () => plans.isNotEmpty ? plans.first : null,
    );

    if (activePlan != null) {
      final sessions = activePlan['sessions'] as List? ?? [];
      final todayDay = DateFormat('EEEE').format(DateTime.now()).toLowerCase();

      bool matchesDay(String? value, String today) {
        if (value == null) return false;
        final val = value.trim().toLowerCase();
        if (val == 'today') return true;

        String getVnDay(String day) {
          switch (day) {
            case 'monday': return 'thứ 2';
            case 'tuesday': return 'thứ 3';
            case 'wednesday': return 'thứ 4';
            case 'thursday': return 'thứ 5';
            case 'friday': return 'thứ 6';
            case 'saturday': return 'thứ 7';
            case 'sunday': return 'chủ nhật';
            default: return day;
          }
        }

        String getVnDayNoAccent(String day) {
          switch (day) {
            case 'monday': return 'thu 2';
            case 'tuesday': return 'thu 3';
            case 'wednesday': return 'thu 4';
            case 'thursday': return 'thu 5';
            case 'friday': return 'thu 6';
            case 'saturday': return 'thu 7';
            case 'sunday': return 'chu nhat';
            default: return day;
          }
        }

        return val == today || val == getVnDay(today) || val == getVnDayNoAccent(today);
      }

      final todaySession = sessions.firstWhere(
        (s) => matchesDay(s['dayOfWeek'], todayDay),
        orElse: () => sessions.isNotEmpty ? sessions.first : null,
      );

      if (todaySession != null) {
        try {
          // 1. Kiểm tra session đang hoạt động
          final activeRes = await _apiClient.get('/workout-session-logs/active/${auth.userId}');
          if (activeRes.statusCode == 200) {
            final activeData = ApiClient.decodeResponse(activeRes);
            sessionLogId = activeData['id'] ?? activeData['_id'];
          }

          // 2. Nếu không có session đang hoạt động, bắt đầu session mới
          if (sessionLogId == null) {
            final startRes = await _apiClient.post('/workout-session-logs/start', {
              'userId': auth.userId,
              'workoutPlanId': activePlan['id'] ?? activePlan['_id'] ?? '',
              'planSessionId': todaySession['id'] ?? todaySession['_id'] ?? '',
            });
            if (startRes.statusCode == 200 || startRes.statusCode == 201) {
              final startData = ApiClient.decodeResponse(startRes);
              sessionLogId = startData['id'] ?? startData['_id'];
            }
          }
        } catch (e) {
          debugPrint('Lỗi khởi tạo session: $e');
        }
      }
    }

    bool hasLevelUp = false;
    String levelUpMuscle = '';
    int newLevel = 1;
    int successCount = 0;

    for (var ex in pending) {
      final isCustom = _customExercises.any((ce) => ce.id == ex.id);

      if (!isCustom && sessionLogId != null) {
        // Bài tập chính thức: Gửi số set hoàn thành lên session log
        final setsCount = ex.sets ?? 3;
        final repsValue = int.tryParse(ex.reps ?? '') ?? 10;
        try {
          for (int s = 1; s <= setsCount; s++) {
            await _apiClient.post('/workout-session-logs/$sessionLogId/exercises/${ex.id}/sets', {
              'setNumber': s,
              'weight': 15.0, // Trọng lượng mặc định
              'reps': repsValue,
              'durationSeconds': 45,
              'rpe': 8,
            });
          }
          _submittedIds.add(ex.id);
          successCount++;
        } catch (e) {
          debugPrint('Lỗi gửi set bài tập chính thức ${ex.name}: $e');
        }
      } else {
        // Bài tập tự chọn hoặc khi không có sessionLogId: Cộng XP trực tiếp
        final fullEx = ep.exercises.firstWhere(
          (e) => e.id == ex.id,
          orElse: () => _dummyFullExercise(ex.id),
        );

        if (fullEx.id.isEmpty || fullEx.muscleImpacts.isEmpty) continue;

        for (var impact in fullEx.muscleImpacts) {
          int xp = (impact.percentage * 0.2).round().clamp(5, 20);
          try {
            final res = await _apiClient.post('/muscle-progress/add-xp', {
              'userId': auth.userId,
              'muscleId': impact.muscleId,
              'expAmount': xp
            });
            if (res.statusCode == 200) {
              final data = ApiClient.decodeResponse(res);
              if (data['isLevelUp'] == true) {
                hasLevelUp = true;
                levelUpMuscle = data['muscleName'] ?? '';
                newLevel = data['newLevel'] ?? 1;
              }
            }
          } catch (e) {
            debugPrint('Lỗi cộng XP bài tập custom ${ex.name}: $e');
          }
        }

        _submittedIds.add(ex.id);
        successCount++;
      }
    }

    // 4. Kết thúc session để cập nhật streak & số buổi tập
    if (sessionLogId != null) {
      try {
        final finishRes = await _apiClient.put('/workout-session-logs/$sessionLogId/finish', {});
        if (finishRes.statusCode == 200) {
          final finishData = ApiClient.decodeResponse(finishRes);
          // Check level up từ kết quả finish session
          if (finishData['session'] != null && finishData['session']['muscleExpGains'] != null) {
            final gains = finishData['session']['muscleExpGains'] as List;
            for (var gain in gains) {
              if (gain['isLevelUp'] == true) {
                hasLevelUp = true;
                levelUpMuscle = gain['muscleName'] ?? '';
                newLevel = (gain['newLevel'] as num?)?.toInt() ?? 1;
              }
            }
          }
        }
      } catch (e) {
        debugPrint('Lỗi kết thúc session: $e');
      }
    }

    await _saveState();

    if (mounted) {
      // Tải lại dữ liệu trang chủ & cá nhân để cập nhật giao diện ngay lập tức
      await context.read<HomeProvider>().fetchHomeData(auth.userId!);
      await context.read<ProfileProvider>().fetchProfile(auth.userId!);

      setState(() {
        _isSubmitting = false;
      });

      if (successCount > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.success,
            content: Text('Đã xác nhận hoàn thành $successCount bài tập và nhận điểm XP! 🎉'),
          ),
        );
      }

      if (hasLevelUp) {
        _showLevelUpDialog(levelUpMuscle, newLevel);
      }
    }
  }

  Exercise _dummyFullExercise(String id) => Exercise(
        id: id, name: '', equipment: '', difficulty: '', description: '',
        instruction: '', safetyNotes: '', commonMistakes: '', tips: '',
        defaultSets: 3, defaultReps: '10', restTimeSeconds: 60, imageUrl: '', videoUrl: '',
        muscleImpacts: []
      );

  void _showLevelUpDialog(String muscle, int level) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🏆 LEVEL UP! 🏆', style: TextStyle(color: AppColors.primary, fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            const Icon(Icons.flash_on, size: 64, color: AppColors.goldBadge),
            const SizedBox(height: 16),
            Text(
              'Nhóm cơ $muscle của bạn đã đạt Cấp độ $level!',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Bạn đang mạnh mẽ hơn mỗi ngày. Hãy duy trì phong độ nhé! 💪🔥',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text('Đồng ý'),
            ),
          ],
        ),
      ),
    );
  }

  void _openAddExerciseSheet() {
    final ep = context.read<ExerciseProvider>();
    String searchQuery = '';
    List<Exercise> filtered = List.from(ep.exercises);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (sheetCtx, setSheetState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.7,
              minChildSize: 0.5,
              maxChildSize: 0.9,
              expand: false,
              builder: (_, scrollController) {
                final todayOfficialExercises = context.read<HomeProvider>().homeData?.todayPlan?.exercises ?? [];

                return Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // Handle bar
                      Container(
                        width: 40,
                        height: 5,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      const Text(
                        'Thêm bài tập tự chọn',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 16),
                      // Search field
                      TextField(
                        onChanged: (val) {
                          searchQuery = val.toLowerCase();
                          setSheetState(() {
                            filtered = ep.exercises.where((e) {
                              return e.name.toLowerCase().contains(searchQuery) ||
                                  e.equipment.toLowerCase().contains(searchQuery);
                            }).toList();
                          });
                        },
                        decoration: InputDecoration(
                          hintText: 'Tìm kiếm bài tập...',
                          prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
                          fillColor: AppColors.cardBackground,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: ListView.builder(
                          controller: scrollController,
                          itemCount: filtered.length,
                          itemBuilder: (lCtx, index) {
                            final ex = filtered[index];
                            final isOfficial = todayOfficialExercises.any((e) => e.id == ex.id);
                            final isCustomAdded = _customExercises.any((e) => e.id == ex.id);

                            Widget trailingWidget;
                            if (isOfficial) {
                              trailingWidget = const Icon(Icons.check_circle, color: AppColors.textHint);
                            } else if (isCustomAdded) {
                              trailingWidget = IconButton(
                                icon: const Icon(Icons.remove_circle, color: AppColors.error),
                                onPressed: () async {
                                  setSheetState(() {
                                    _customExercises.removeWhere((e) => e.id == ex.id);
                                  });
                                  setState(() {}); // Đồng bộ màn hình chính
                                  await _saveState();
                                },
                              );
                            } else {
                              trailingWidget = IconButton(
                                icon: const Icon(Icons.add_circle, color: AppColors.primary),
                                onPressed: () async {
                                  setSheetState(() {
                                    _customExercises.add(TodayExercise(
                                      id: ex.id,
                                      name: ex.name,
                                      muscle: ex.muscleImpacts.isNotEmpty
                                          ? ep.getMuscleNameById(ex.muscleImpacts.first.muscleId)
                                          : 'Khác',
                                      imageUrl: ex.imageUrl,
                                      sets: ex.defaultSets,
                                      reps: ex.defaultReps,
                                    ));
                                  });
                                  setState(() {}); // Đồng bộ màn hình chính
                                  await _saveState();
                                },
                              );
                            }

                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    image: ex.imageUrl.isNotEmpty
                                        ? DecorationImage(image: NetworkImage(ex.imageUrl), fit: BoxFit.cover)
                                        : null,
                                  ),
                                  child: ex.imageUrl.isEmpty ? const Icon(Icons.fitness_center) : null,
                                ),
                                title: Text(ex.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                subtitle: Text('${ex.difficulty} • ${ex.equipment}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                trailing: trailingWidget,
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () async {
                            await _saveState();
                            if (mounted) Navigator.pop(ctx);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Text('Xác nhận thêm', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final homeProvider = context.watch<HomeProvider>();
    final ep = context.watch<ExerciseProvider>();
    final profile = context.watch<ProfileProvider>().profile;

    if (!_isInitLoaded || homeProvider.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    final todayPlan = homeProvider.homeData?.todayPlan;
    final allTodayExercises = <TodayExercise>[];
    if (todayPlan != null) {
      allTodayExercises.addAll(todayPlan.exercises);
    }
    allTodayExercises.addAll(_customExercises);

    // Lọc danh sách gợi ý phù hợp với trình độ người dùng và nhóm cơ hôm nay
    final userLevel = profile?.experienceLevel ?? 'beginner';
    final suggested = ep.exercises.where((e) {
      // Tránh trùng các bài đã có trong checklist
      if (allTodayExercises.any((te) => te.id == e.id)) return false;

      // Trùng mức độ khó
      final matchDifficulty = e.difficulty.toLowerCase() == userLevel.toLowerCase();

      // Trùng nhóm cơ hôm nay (focus)
      bool matchFocus = false;
      if (todayPlan != null && todayPlan.focus != null) {
        final focus = todayPlan.focus!.toLowerCase();
        for (var impact in e.muscleImpacts) {
          final mName = ep.getMuscleNameById(impact.muscleId).toLowerCase();
          if (focus.contains(mName)) {
            matchFocus = true;
            break;
          }
        }
      }
      return matchDifficulty && matchFocus;
    }).take(3).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('To-Do Checklist tập', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_task),
            tooltip: 'Thêm bài tập tự chọn',
            onPressed: _openAddExerciseSheet,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header Widget
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary.withOpacity(0.15), AppColors.surfaceVariant.withOpacity(0.3)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.primary.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.fitness_center, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text(
                      todayPlan != null ? todayPlan.day : 'Ngày nghỉ ngơi',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  todayPlan != null
                      ? 'Nhóm cơ tập trung: ${todayPlan.focus ?? "Tập luyện tự do"}'
                      : 'Hôm nay là ngày nghỉ ngơi của bạn. Bạn vẫn có thể tập nhẹ hoặc thêm bài tập!',
                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 12),
                // Tiến độ hoàn thành bài tập
                if (allTodayExercises.isNotEmpty) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Đã hoàn thành ${_completedIds.where((id) => allTodayExercises.any((e) => e.id == id)).length}/${allTodayExercises.length} bài tập',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${((_completedIds.where((id) => allTodayExercises.any((e) => e.id == id)).length / allTodayExercises.length) * 100).round()}%',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: _completedIds.where((id) => allTodayExercises.any((e) => e.id == id)).length / allTodayExercises.length,
                      backgroundColor: AppColors.surfaceVariant,
                      valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                      minHeight: 6,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),

          // To-Do Checklist Title
          const Text('Danh sách bài tập hôm nay', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),

          if (allTodayExercises.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const Icon(Icons.assignment_turned_in_outlined, size: 48, color: Colors.blueGrey),
                    const SizedBox(height: 12),
                    const Text('Checklist trống!', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    const Text(
                      'Bấm vào biểu tượng ở góc trên để thêm bài tập tự chọn từ thư viện của bạn.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _openAddExerciseSheet,
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Thêm bài tập'),
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else ...[
            ...allTodayExercises.map((ex) {
              final isCompleted = _completedIds.contains(ex.id);
              final isSubmitted = _submittedIds.contains(ex.id);
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: isCompleted
                      ? const BorderSide(color: AppColors.success, width: 0.5)
                      : BorderSide.none,
                ),
                child: ListTile(
                  onTap: () => GoRouter.of(context).push('/exercises/${ex.id}'),
                  leading: Checkbox(
                    value: isCompleted,
                    activeColor: AppColors.success,
                    onChanged: (val) => _toggleComplete(ex, val),
                  ),
                  title: Text(
                    ex.name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      decoration: isCompleted ? TextDecoration.lineThrough : null,
                      color: isCompleted ? AppColors.textSecondary : AppColors.textPrimary,
                    ),
                  ),
                  subtitle: Text(
                    '${ex.muscle} • ${ex.sets} Sets x ${ex.reps} Reps${isSubmitted ? " (Đã nhận XP)" : ""}',
                    style: TextStyle(
                      fontSize: 11,
                      color: isSubmitted ? AppColors.success : AppColors.textSecondary,
                    ),
                  ),
                  trailing: const Icon(Icons.chevron_right, size: 20, color: AppColors.textHint),
                ),
              );
            }),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _isSubmitting 
                  ? null 
                  : () => _submitWorkout(allTodayExercises),
              icon: _isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Icon(Icons.verified_outlined, size: 20),
              label: Text(
                _isSubmitting ? 'Đang gửi...' : 'Xác nhận hoàn thành buổi tập',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],

          // Lọc gợi ý bài tập
          if (suggested.isNotEmpty) ...[
            const SizedBox(height: 24),
            Row(
              children: [
                const Icon(Icons.lightbulb_outline, color: AppColors.primary, size: 18),
                const SizedBox(width: 6),
                const Text('Gợi ý cho buổi tập hôm nay', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 10),
            ...suggested.map((ex) {
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                color: AppColors.cardBackground.withOpacity(0.6),
                child: ListTile(
                  leading: const Icon(Icons.fitness_center_outlined, color: AppColors.primary),
                  title: Text(ex.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  subtitle: Text(
                    'Phù hợp trình độ ${ex.difficulty.toLowerCase()}',
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  ),
                  trailing: TextButton.icon(
                    onPressed: () async {
                      setState(() {
                        _customExercises.add(TodayExercise(
                          id: ex.id,
                          name: ex.name,
                          muscle: ex.muscleImpacts.isNotEmpty
                              ? ep.getMuscleNameById(ex.muscleImpacts.first.muscleId)
                              : 'Khác',
                          imageUrl: ex.imageUrl,
                          sets: ex.defaultSets,
                          reps: ex.defaultReps,
                        ));
                      });
                      await _saveState();
                    },
                    icon: const Icon(Icons.add, size: 14),
                    label: const Text('Thêm', style: TextStyle(fontSize: 12)),
                  ),
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}
