import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/profile_provider.dart';
import '../../../providers/home_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/network/api_client.dart';

class SurveyScreen extends StatefulWidget {
  const SurveyScreen({super.key});

  @override
  State<SurveyScreen> createState() => _SurveyScreenState();
}

class _SurveyScreenState extends State<SurveyScreen> {
  final _formKey = GlobalKey<FormState>();

  String _selectedGender = 'Male';
  String _selectedGoal = 'muscle_gain';
  String _selectedExperience = 'beginner';
  final List<String> _selectedDays = ['Monday', 'Wednesday', 'Friday'];

  final List<Map<String, String>> _weekDays = [
    {'value': 'Monday', 'label': 'Thứ 2'},
    {'value': 'Tuesday', 'label': 'Thứ 3'},
    {'value': 'Wednesday', 'label': 'Thứ 4'},
    {'value': 'Thursday', 'label': 'Thứ 5'},
    {'value': 'Friday', 'label': 'Thứ 6'},
    {'value': 'Saturday', 'label': 'Thứ 7'},
    {'value': 'Sunday', 'label': 'Chủ nhật'},
  ];

  final _ageController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  final _injuryController = TextEditingController();

  double _previewBmi = 0.0;

  final List<Map<String, String>> _genders = [
    {'value': 'Male', 'label': 'Nam 👨'},
    {'value': 'Female', 'label': 'Nữ 👩'},
    {'value': 'Other', 'label': 'Khác 🧑'},
  ];

  final List<Map<String, String>> _goals = [
    {'value': 'muscle_gain', 'label': 'Tăng cơ bắp 💪'},
    {'value': 'fat_loss', 'label': 'Giảm mỡ 🔥'},
    {'value': 'strength', 'label': 'Tăng sức mạnh 🏋️'},
    {'value': 'endurance', 'label': 'Tăng sức bền ⚡'},
    {'value': 'general_fitness', 'label': 'Tập thể dục tổng hợp 🏃'},
  ];

  final List<Map<String, String>> _experiences = [
    {'value': 'beginner', 'label': 'Mới bắt đầu 🌱'},
    {'value': 'intermediate', 'label': 'Trung cấp ⭐'},
    {'value': 'advanced', 'label': 'Nâng cao 🏆'},
  ];

  @override
  void initState() {
    super.initState();
    _loadExistingData();
  }

  void _loadExistingData() {
    final profile = context.read<ProfileProvider>().profile;
    if (profile != null) {
      _selectedGender = profile.gender.isNotEmpty ? profile.gender : 'Male';
      _selectedGoal = profile.goal.isNotEmpty ? profile.goal : 'muscle_gain';
      _selectedExperience = profile.experienceLevel.isNotEmpty ? profile.experienceLevel : 'beginner';
      _ageController.text = profile.age > 0 ? profile.age.toString() : '';
      _heightController.text = profile.heightCm > 0 ? profile.heightCm.toString() : '';
      _weightController.text = profile.weightKg > 0 ? profile.weightKg.toString() : '';
      _injuryController.text = profile.injuryNotes;
      _recalcBmi();
    }
    _loadActivePlanDays();
  }

  Future<void> _loadActivePlanDays() async {
    final userId = context.read<AuthProvider>().userId;
    if (userId == null) return;
    try {
      final res = await ApiClient().get('/workoutplans/user/$userId/active');
      if (res.statusCode == 200) {
        final plan = ApiClient.decodeResponse(res);
        final sessions = plan['sessions'] as List? ?? [];
        final days = sessions
            .map((s) => s['dayOfWeek'] as String)
            .where((d) => d.isNotEmpty)
            .toList();
        if (days.length == 3) {
          if (mounted) {
            setState(() {
              _selectedDays.clear();
              _selectedDays.addAll(days);
            });
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading active plan days: $e');
    }
  }

  @override
  void dispose() {
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _injuryController.dispose();
    super.dispose();
  }

  void _recalcBmi() {
    final h = double.tryParse(_heightController.text) ?? 0;
    final w = double.tryParse(_weightController.text) ?? 0;
    if (h > 0 && w > 0) {
      final hm = h / 100.0;
      setState(() {
        _previewBmi = double.parse((w / (hm * hm)).toStringAsFixed(1));
      });
    } else {
      setState(() {
        _previewBmi = 0.0;
      });
    }
  }

  String _getBmiStatus(double bmi) {
    if (bmi <= 0) return '';
    if (bmi < 18.5) return 'Thiếu cân 🟡';
    if (bmi < 25.0) return 'Bình thường 🟢';
    if (bmi < 30.0) return 'Thừa cân 🟠';
    return 'Béo phì 🔴';
  }

  Color _getBmiColor(double bmi) {
    if (bmi <= 0) return AppColors.textSecondary;
    if (bmi < 18.5) return Colors.amber;
    if (bmi < 25.0) return Colors.green;
    if (bmi < 30.0) return Colors.orange;
    return AppColors.error;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedDays.length != 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn chính xác 3 ngày tập trong tuần!'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final userId = context.read<AuthProvider>().userId ?? '';
    final success = await context.read<ProfileProvider>().saveProfile(
      userId: userId,
      gender: _selectedGender,
      age: int.tryParse(_ageController.text) ?? 0,
      heightCm: int.tryParse(_heightController.text) ?? 0,
      weightKg: int.tryParse(_weightController.text) ?? 0,
      goal: _selectedGoal,
      experienceLevel: _selectedExperience,
      injuryNotes: _injuryController.text,
    );

    if (!mounted) return;

    final msg = context.read<ProfileProvider>().saveMessage ?? '';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: success ? Colors.green : AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );

    if (success) {
      // Cập nhật ngày tập của các session trong active plan
      try {
        final res = await ApiClient().get('/workoutplans/user/$userId/active');
        if (res.statusCode == 200) {
          final plan = ApiClient.decodeResponse(res);
          final planId = plan['id'] ?? plan['_id'];
          final List sessions = plan['sessions'] as List? ?? [];
          
          if (planId != null && sessions.length >= 3) {
            // Sắp xếp các ngày đã chọn theo thứ tự chuẩn trong tuần
            final weekOrder = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
            _selectedDays.sort((a, b) => weekOrder.indexOf(a).compareTo(weekOrder.indexOf(b)));
            
            for (int i = 0; i < 3; i++) {
              final session = sessions[i];
              final sessionId = session['id'] ?? session['_id'];
              final currentFocus = session['focus'] ?? '';
              
              if (sessionId != null) {
                await ApiClient().put('/workoutplans/$planId/sessions/$sessionId', {
                  'dayOfWeek': _selectedDays[i],
                  'focus': currentFocus,
                });
              }
            }
          }
        }
      } catch (e) {
        debugPrint('Lỗi cập nhật lịch tập: $e');
      }

      if (mounted) {
        // Tải lại dữ liệu Trang chủ ngay lập tức
        context.read<HomeProvider>().fetchHomeData(userId);
        context.pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileProvider = context.watch<ProfileProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Khảo sát thể trạng', style: TextStyle(fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => context.pop(),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary.withOpacity(0.2), AppColors.primary.withOpacity(0.05)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primary.withOpacity(0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.assignment_ind, color: AppColors.primary, size: 32),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Thiết lập thể trạng cá nhân',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary)),
                        SizedBox(height: 4),
                        Text('GymSup sẽ cá nhân hóa lịch tập và dinh dưỡng phù hợp với bạn.',
                            style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Giới tính
            _buildSectionLabel('Giới tính', Icons.wc),
            const SizedBox(height: 10),
            Row(
              children: _genders.map((g) {
                final isSelected = _selectedGender == g['value'];
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedGender = g['value']!),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primary.withOpacity(0.2) : AppColors.cardBackground,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? AppColors.primary : AppColors.surfaceVariant,
                            width: isSelected ? 1.5 : 0.5,
                          ),
                        ),
                        child: Text(
                          g['label']!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected ? AppColors.primary : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Thông tin thể chất
            _buildSectionLabel('Thông tin thể chất', Icons.straighten),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _buildNumberField(
                    controller: _ageController,
                    label: 'Tuổi',
                    hint: 'VD: 22',
                    suffix: 'tuổi',
                    validator: (v) => (int.tryParse(v ?? '') ?? 0) > 0 ? null : 'Nhập tuổi',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildNumberField(
                    controller: _heightController,
                    label: 'Chiều cao',
                    hint: 'VD: 170',
                    suffix: 'cm',
                    onChange: (_) => _recalcBmi(),
                    validator: (v) => (int.tryParse(v ?? '') ?? 0) > 0 ? null : 'Nhập chiều cao',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildNumberField(
                    controller: _weightController,
                    label: 'Cân nặng',
                    hint: 'VD: 65',
                    suffix: 'kg',
                    onChange: (_) => _recalcBmi(),
                    validator: (v) => (int.tryParse(v ?? '') ?? 0) > 0 ? null : 'Nhập cân nặng',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // BMI Preview
            if (_previewBmi > 0)
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: _getBmiColor(_previewBmi).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _getBmiColor(_previewBmi).withOpacity(0.4)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.monitor_weight_outlined, color: _getBmiColor(_previewBmi), size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'BMI: ${_previewBmi.toStringAsFixed(1)}  •  ${_getBmiStatus(_previewBmi)}',
                      style: TextStyle(
                        color: _getBmiColor(_previewBmi),
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 20),

            // Chọn ngày tập trong tuần
            _buildSectionLabel('Chọn 3 ngày tập trong tuần 🗓️', Icons.calendar_month),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: _weekDays.map((d) {
                final isSelected = _selectedDays.contains(d['value']);
                return FilterChip(
                  label: Text(d['label']!),
                  selected: isSelected,
                  selectedColor: AppColors.primary.withOpacity(0.2),
                  checkmarkColor: AppColors.primary,
                  onSelected: (bool selected) {
                    setState(() {
                      if (selected) {
                        _selectedDays.add(d['value']!);
                      } else {
                        _selectedDays.remove(d['value']);
                      }
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Mục tiêu tập luyện
            _buildSectionLabel('Mục tiêu tập luyện', Icons.flag_outlined),
            const SizedBox(height: 10),
            ..._goals.map((g) => _buildSelectCard(
              value: g['value']!,
              label: g['label']!,
              groupValue: _selectedGoal,
              onTap: () => setState(() => _selectedGoal = g['value']!),
            )),
            const SizedBox(height: 20),

            // Trình độ kinh nghiệm
            _buildSectionLabel('Trình độ tập luyện', Icons.trending_up),
            const SizedBox(height: 10),
            ..._experiences.map((e) => _buildSelectCard(
              value: e['value']!,
              label: e['label']!,
              groupValue: _selectedExperience,
              onTap: () => setState(() => _selectedExperience = e['value']!),
            )),
            const SizedBox(height: 20),

            // Ghi chú chấn thương
            _buildSectionLabel('Chấn thương / Lưu ý sức khỏe', Icons.health_and_safety_outlined),
            const SizedBox(height: 10),
            TextFormField(
              controller: _injuryController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'VD: Đau gối trái, tránh squat nặng... (có thể bỏ trống)',
                hintStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                filled: true,
                fillColor: AppColors.cardBackground,
                contentPadding: const EdgeInsets.all(16),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.surfaceVariant),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                ),
              ),
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
            ),
            const SizedBox(height: 32),

            // Nút Lưu
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: profileProvider.isSaving ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: profileProvider.isSaving
                    ? const SizedBox(
                        width: 24, height: 24,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.save_rounded, color: Colors.white),
                          SizedBox(width: 8),
                          Text('Lưu thông tin', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 18),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
      ],
    );
  }

  Widget _buildNumberField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required String suffix,
    ValueChanged<String>? onChange,
    FormFieldValidator<String>? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: TextInputType.number,
          onChanged: onChange,
          validator: validator,
          textAlign: TextAlign.center,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
            suffixText: suffix,
            suffixStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
            filled: true,
            fillColor: AppColors.cardBackground,
            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.surfaceVariant),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: AppColors.error),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: AppColors.error, width: 1.5),
            ),
          ),
          style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildSelectCard({
    required String value,
    required String label,
    required String groupValue,
    required VoidCallback onTap,
  }) {
    final isSelected = value == groupValue;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.15) : AppColors.cardBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.surfaceVariant,
            width: isSelected ? 1.5 : 0.5,
          ),
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.textSecondary,
                  width: isSelected ? 6 : 1.5,
                ),
                color: isSelected ? AppColors.primary : Colors.transparent,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: isSelected ? AppColors.primary : AppColors.textPrimary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
