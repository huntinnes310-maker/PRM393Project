import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/network/api_client.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/home_provider.dart';

class NutritionDetailScreen extends StatefulWidget {
  const NutritionDetailScreen({super.key});

  @override
  State<NutritionDetailScreen> createState() => _NutritionDetailScreenState();
}

class _NutritionDetailScreenState extends State<NutritionDetailScreen> {
  final ApiClient _apiClient = ApiClient();
  bool _isLoading = true;

  // Goals & Logged values from backend
  int _caloriesGoal = 2000;
  int _caloriesLogged = 0;
  int _proteinGoal = 100;
  int _proteinLogged = 0;
  int _carbsGoal = 250;
  int _carbsLogged = 0;
  int _fatGoal = 70;
  int _fatLogged = 0;
  double _waterGoal = 2.0;
  double _waterLogged = 0.0;
  List<dynamic> _meals = [];

  final String _todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadTodayNutrition();
    });
  }

  Future<void> _loadTodayNutrition() async {
    final auth = context.read<AuthProvider>();
    if (auth.userId == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final res = await _apiClient.get(
        '/nutrition/today?userId=${auth.userId}&date=$_todayStr',
      );
      if (res.statusCode == 200) {
        final data = ApiClient.decodeResponse(res);
        setState(() {
          _caloriesGoal = (data['caloriesGoal'] as num?)?.toInt() ?? 2000;
          _caloriesLogged = (data['caloriesLogged'] as num?)?.toInt() ?? 0;
          _proteinGoal = (data['proteinGoal'] as num?)?.toInt() ?? 100;
          _proteinLogged = (data['proteinLogged'] as num?)?.toInt() ?? 0;
          _carbsGoal = (data['carbsGoal'] as num?)?.toInt() ?? 250;
          _carbsLogged = (data['carbsLogged'] as num?)?.toInt() ?? 0;
          _fatGoal = (data['fatGoal'] as num?)?.toInt() ?? 70;
          _fatLogged = (data['fatLogged'] as num?)?.toInt() ?? 0;
          _waterGoal = (data['waterGoal'] as num?)?.toDouble() ?? 2.0;
          _waterLogged = (data['waterLogged'] as num?)?.toDouble() ?? 0.0;
          _meals = data['meals'] ?? [];
        });
      }
    } catch (e) {
      debugPrint('Lỗi tải dinh dưỡng: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _logWater(double liters) async {
    final auth = context.read<AuthProvider>();
    if (auth.userId == null) return;

    try {
      final res = await _apiClient.post('/nutrition/water', {
        'userId': auth.userId,
        'date': _todayStr,
        'liters': liters,
      });

      if (res.statusCode == 200) {
        _loadTodayNutrition();
        // Refresh dashboard statistics
        context.read<HomeProvider>().fetchHomeData(auth.userId!);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã ghi nhận +${(liters * 1000).toInt()} ml nước uống! 💧'),
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      debugPrint('Lỗi ghi nhận nước: $e');
    }
  }

  Future<void> _addMeal(String type, String name, int calories, int protein, int carbs, int fat) async {
    final auth = context.read<AuthProvider>();
    if (auth.userId == null) return;

    try {
      final res = await _apiClient.post('/nutrition/meal', {
        'userId': auth.userId,
        'date': _todayStr,
        'type': type,
        'name': name,
        'calories': calories,
        'protein': protein,
        'carbs': carbs,
        'fat': fat,
      });

      if (res.statusCode == 200) {
        _loadTodayNutrition();
        context.read<HomeProvider>().fetchHomeData(auth.userId!);
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã thêm món ăn thành công! 🍳'),
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      debugPrint('Lỗi thêm món ăn: $e');
    }
  }

  Future<void> _deleteMeal(int index) async {
    final auth = context.read<AuthProvider>();
    if (auth.userId == null) return;

    try {
      final res = await _apiClient.delete(
        '/nutrition/meal/$index?userId=${auth.userId}&date=$_todayStr',
      );

      if (res.statusCode == 200) {
        _loadTodayNutrition();
        context.read<HomeProvider>().fetchHomeData(auth.userId!);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã xóa món ăn!'),
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      debugPrint('Lỗi xóa món ăn: $e');
    }
  }

  void _showAddMealDialog() {
    final nameController = TextEditingController();
    final calController = TextEditingController();
    final proteinController = TextEditingController();
    final carbsController = TextEditingController();
    final fatController = TextEditingController();
    String selectedType = 'Breakfast';

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.cardBackground,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text('Thêm món ăn', style: TextStyle(fontWeight: FontWeight.bold)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      dropdownColor: AppColors.cardBackground,
                      value: selectedType,
                      decoration: const InputDecoration(labelText: 'Bữa ăn'),
                      items: const [
                        DropdownMenuItem(value: 'Breakfast', child: Text('Bữa sáng')),
                        DropdownMenuItem(value: 'Lunch', child: Text('Bữa trưa')),
                        DropdownMenuItem(value: 'Dinner', child: Text('Bữa tối')),
                        DropdownMenuItem(value: 'Snack', child: Text('Bữa nhẹ')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() {
                            selectedType = val;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Tên món ăn (Ví dụ: Ức gà 150g)'),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: calController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Lượng Calories (kcal)'),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: proteinController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Protein (g)'),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: carbsController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Carbohydrate (g)'),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: fatController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Chất béo/Fat (g)'),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Hủy', style: TextStyle(color: AppColors.textSecondary)),
                ),
                ElevatedButton(
                  onPressed: () {
                    final name = nameController.text.trim();
                    final cal = int.tryParse(calController.text) ?? 0;
                    final prot = int.tryParse(proteinController.text) ?? 0;
                    final carb = int.tryParse(carbsController.text) ?? 0;
                    final fat = int.tryParse(fatController.text) ?? 0;

                    if (name.isEmpty || cal <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Vui lòng điền tên món và lượng calo lớn hơn 0')),
                      );
                      return;
                    }

                    _addMeal(selectedType, name, cal, prot, carb, fat);
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                  child: const Text('Thêm', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('dd/MM/yyyy');
    final displayDate = df.format(DateTime.now());

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Nhật ký dinh dưỡng 🍎', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: AppColors.cardBackground,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddMealDialog,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Date Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Hôm nay',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        displayDate,
                        style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 1. Calories Summary Card
                  _buildCaloriesProgressCard(),
                  const SizedBox(height: 16),

                  // 2. Macros Row
                  Row(
                    children: [
                      Expanded(
                        child: _buildMacroSubCard(
                          title: 'Protein',
                          logged: _proteinLogged,
                          goal: _proteinGoal,
                          unit: 'g',
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildMacroSubCard(
                          title: 'Carbs',
                          logged: _carbsLogged,
                          goal: _carbsGoal,
                          unit: 'g',
                          color: Colors.amber,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildMacroSubCard(
                          title: 'Fat',
                          logged: _fatLogged,
                          goal: _fatGoal,
                          unit: 'g',
                          color: Colors.teal,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 3. Water Intake Card
                  _buildWaterCard(),
                  const SizedBox(height: 20),

                  // 4. Meal list
                  const Text(
                    'Bữa ăn trong ngày 🍳',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  _meals.isEmpty
                      ? _buildEmptyMealView()
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _meals.length,
                          itemBuilder: (ctx, index) {
                            final meal = _meals[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: AppColors.surfaceVariant,
                                  child: Icon(
                                    _getMealIcon(meal['type']),
                                    color: AppColors.primary,
                                    size: 18,
                                  ),
                                ),
                                title: Text(
                                  meal['name'] ?? '',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                                subtitle: Text(
                                  _getMealTypeText(meal['type']),
                                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '${meal['calories']} kcal',
                                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange, fontSize: 13),
                                    ),
                                    const SizedBox(width: 8),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, color: AppColors.error, size: 18),
                                      onPressed: () => _deleteMeal(index),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                  const SizedBox(height: 60),
                ],
              ),
            ),
    );
  }

  Widget _buildCaloriesProgressCard() {
    double progress = _caloriesGoal > 0 ? _caloriesLogged / _caloriesGoal : 0.0;
    progress = progress.clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Năng lượng Calories',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              Text(
                '$_caloriesLogged / $_caloriesGoal kcal',
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 12,
              backgroundColor: AppColors.surfaceVariant,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.orange),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            progress >= 1.0
                ? '🎉 Bạn đã đạt mục tiêu calories ngày hôm nay!'
                : 'Còn thiếu ${Math.max(0, _caloriesGoal - _caloriesLogged)} kcal để đạt mục tiêu.',
            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
          )
        ],
      ),
    );
  }

  Widget _buildMacroSubCard({
    required String title,
    required int logged,
    required int goal,
    required String unit,
    required Color color,
  }) {
    double progress = goal > 0 ? logged / goal : 0.0;
    progress = progress.clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.surfaceVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 4),
          Text(
            '$logged / $goal$unit',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 4,
              backgroundColor: AppColors.surfaceVariant,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWaterCard() {
    double progress = _waterGoal > 0 ? _waterLogged / _waterGoal : 0.0;
    progress = progress.clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.local_drink, color: Colors.blue),
                  SizedBox(width: 8),
                  Text('Nước uống hàng ngày', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                ],
              ),
              Text(
                '${_waterLogged.toStringAsFixed(1)} / ${_waterGoal.toStringAsFixed(1)} L',
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _logWater(0.25),
                  icon: const Icon(Icons.add, size: 16, color: Colors.blue),
                  label: const Text('+ 250ml', style: TextStyle(color: Colors.blue, fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.withOpacity(0.05),
                    elevation: 0,
                    side: const BorderSide(color: Colors.blue, width: 0.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _logWater(0.5),
                  icon: const Icon(Icons.add, size: 16, color: Colors.blue),
                  label: const Text('+ 500ml', style: TextStyle(color: Colors.blue, fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.withOpacity(0.05),
                    elevation: 0,
                    side: const BorderSide(color: Colors.blue, width: 0.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyMealView() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 30),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceVariant),
      ),
      child: const Column(
        children: [
          Icon(Icons.restaurant_menu, size: 40, color: AppColors.textSecondary),
          SizedBox(height: 8),
          Text(
            'Hôm nay chưa ghi nhận món ăn nào.',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  IconData _getMealIcon(dynamic type) {
    final typeStr = type?.toString().toLowerCase() ?? '';
    if (typeStr.contains('breakfast') || typeStr.contains('sáng')) return Icons.wb_twilight;
    if (typeStr.contains('lunch') || typeStr.contains('trưa')) return Icons.wb_sunny;
    if (typeStr.contains('dinner') || typeStr.contains('tối')) return Icons.brightness_3;
    return Icons.local_cafe;
  }

  String _getMealTypeText(dynamic type) {
    final typeStr = type?.toString().toLowerCase() ?? '';
    if (typeStr.contains('breakfast')) return 'Bữa sáng';
    if (typeStr.contains('lunch')) return 'Bữa trưa';
    if (typeStr.contains('dinner')) return 'Bữa tối';
    return 'Bữa nhẹ';
  }
}

class Math {
  static num max(num a, num b) => a > b ? a : b;
}
