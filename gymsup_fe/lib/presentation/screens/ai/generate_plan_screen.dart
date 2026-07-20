import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/network/api_client.dart';
import '../../../providers/profile_provider.dart';
import '../../widgets/onboarding/step_indicator.dart';

/// Màn hình AI tự tạo lịch tập, đi từng bước (wizard) thay vì một form dài.
class GeneratePlanScreen extends StatefulWidget {
  final bool embedded;

  const GeneratePlanScreen({super.key, this.embedded = false});

  @override
  State<GeneratePlanScreen> createState() => _GeneratePlanScreenState();
}

class _GeneratePlanScreenState extends State<GeneratePlanScreen> {
  final ApiClient _apiClient = ApiClient();
  final TextEditingController _healthController = TextEditingController();
  final PageController _pageController = PageController();

  static const int _totalSteps = 5;
  int _currentStep = 0;

  static const _aiDecide = 'AI Decide';
  String _goal = _aiDecide;
  String _experience = _aiDecide;
  int? _daysPerWeek;
  final Set<String> _trainingDays = {};
  String _intensity = _aiDecide;
  String _condition = _aiDecide;

  bool _loading = false;
  bool _applying = false;
  String? _error;
  Map<String, dynamic>? _result;
  List<Map<String, dynamic>> _suggestions = const [];

  static const _goals = [
    _aiDecide,
    'Tăng cơ',
    'Giảm mỡ',
    'Tăng sức mạnh',
    'Duy trì sức khỏe',
    'Cải thiện sức bền',
  ];
  static const _experiences = [
    _aiDecide,
    'Mới bắt đầu',
    'Đã tập dưới 1 năm',
    'Trung cấp',
    'Nâng cao',
  ];
  static const _intensities = [_aiDecide, 'Nhẹ', 'Vừa', 'Cao', 'Rất cao'];
  static const _conditions = [
    _aiDecide,
    'Tập tại gym đầy đủ máy',
    'Tập tại nhà với tạ đơn',
    'Tập tại nhà không dụng cụ',
    'Ít thời gian, buổi tập ngắn',
  ];
  static const _days = {
    'Monday': 'Thứ 2',
    'Tuesday': 'Thứ 3',
    'Wednesday': 'Thứ 4',
    'Thursday': 'Thứ 5',
    'Friday': 'Thứ 6',
    'Saturday': 'Thứ 7',
    'Sunday': 'CN',
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _prefillFromProfile());
  }

  void _prefillFromProfile() {
    final profile = context.read<ProfileProvider>().profile;
    if (profile == null) return;
    setState(() {
      if (profile.goal.isNotEmpty) _goal = profile.goal;
      if (profile.experienceLevel.isNotEmpty) {
        _experience = profile.experienceLevel;
      }
    });
  }

  @override
  void dispose() {
    _healthController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _goToStep(int step) {
    setState(() => _currentStep = step);
    _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _generate() async {
    setState(() {
      _loading = true;
      _error = null;
      _result = null;
      _suggestions = const [];
    });

    try {
      final response = await _apiClient.post('/ai/workout-plan', {
        'goal': _goal == _aiDecide ? '' : _goal,
        'experienceLevel': _experience == _aiDecide ? '' : _experience,
        'daysPerWeek': _daysPerWeek,
        'trainingDays': _trainingDays.toList(),
        'intensity': _intensity == _aiDecide ? '' : _intensity,
        'trainingCondition': _condition == _aiDecide ? '' : _condition,
        'healthIssues': _healthController.text.trim(),
      });

      if (response.statusCode != 200) {
        final data = ApiClient.decodeResponse(response);
        throw Exception(
          data is Map
              ? (data['message'] ?? 'Không thể tạo lịch tập.')
              : 'Không thể tạo lịch tập.',
        );
      }

      final res = ApiClient.decodeResponse(response) as Map<String, dynamic>;
      final rawSuggestions = res['suggestions'];
      final suggestions = rawSuggestions is List
          ? rawSuggestions
                .whereType<Map>()
                .map((item) => Map<String, dynamic>.from(item))
                .toList()
          : <Map<String, dynamic>>[];

      if (!mounted) return;
      setState(() {
        _result = res;
        _suggestions = suggestions;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _applyPlan() async {
    if (_suggestions.isEmpty) return;
    setState(() {
      _applying = true;
      _error = null;
    });

    try {
      final response = await _apiClient.post('/ai/apply', {
        'suggestions': _suggestions,
      });
      if (!mounted) return;

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã lưu lịch tập AI vào hệ thống')),
        );
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        _showVipUpsellDialog();
      } else {
        setState(() => _error = 'Không thể lưu lịch tập. Vui lòng thử lại.');
      }
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = 'Lỗi kết nối: $error');
    } finally {
      if (mounted) setState(() => _applying = false);
    }
  }

  void _showVipUpsellDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Hội Viên VIP 👑',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Tính năng tự động lưu lịch tập từ AI chỉ dành cho Hội viên VIP.',
          style: TextStyle(fontSize: 14, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<ProfileProvider>().profile;

    final content = Column(
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(20, widget.embedded ? 10 : 16, 20, 4),
          child: StepIndicator(
            currentStep: _currentStep + 1,
            totalSteps: _totalSteps,
          ),
        ),
        Expanded(
          child: PageView(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            onPageChanged: (i) => setState(() => _currentStep = i),
            children: [
              ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 26),
                children: [
                  _profileCard(profile),
                  _stepTitle('1', 'Mục tiêu tập luyện'),
                  _choiceWrap(_goals, _goal, (v) => setState(() => _goal = v)),
                ],
              ),
              ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 26),
                children: [
                  _stepTitle('2', 'Kinh nghiệm tập luyện'),
                  _choiceWrap(
                    _experiences,
                    _experience,
                    (v) => setState(() => _experience = v),
                  ),
                ],
              ),
              ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 26),
                children: [
                  _stepTitle('3', 'Số buổi trong tuần'),
                  _daysPerWeekSelector(),
                  _stepTitle('4', 'Thứ mấy'),
                  _trainingDaySelector(),
                ],
              ),
              ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 26),
                children: [
                  _stepTitle('5', 'Mức độ tập'),
                  _choiceWrap(
                    _intensities,
                    _intensity,
                    (v) => setState(() => _intensity = v),
                  ),
                  _stepTitle('6', 'Điều kiện tập luyện'),
                  _choiceWrap(
                    _conditions,
                    _condition,
                    (v) => setState(() => _condition = v),
                  ),
                ],
              ),
              ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 26),
                children: [
                  _stepTitle('7', 'Vấn đề sức khỏe'),
                  _healthField(),
                  const SizedBox(height: 18),
                  ElevatedButton.icon(
                    onPressed: _loading ? null : _generate,
                    icon: _loading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.auto_awesome),
                    label: Text(_loading ? 'Đang tạo lịch...' : 'Tạo lịch tập'),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 14),
                    _errorBox(_error!),
                  ],
                  if (_result != null) ...[
                    const SizedBox(height: 18),
                    _resultCard(),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: _suggestions.isEmpty || _applying
                          ? null
                          : _applyPlan,
                      icon: const Icon(Icons.save_outlined),
                      label: Text(_applying ? 'Đang lưu...' : 'Lưu lịch này'),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
        _buildNavBar(),
      ],
    );

    return widget.embedded
        ? content
        : Scaffold(
            appBar: AppBar(title: const Text('AI tạo lịch tập')),
            body: content,
          );
  }

  Widget _buildNavBar() {
    final isFirst = _currentStep == 0;
    final isLast = _currentStep == _totalSteps - 1;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          if (!isFirst)
            Expanded(
              child: OutlinedButton(
                onPressed: () => _goToStep(_currentStep - 1),
                child: const Text('Quay lại'),
              ),
            ),
          if (!isFirst && !isLast) const SizedBox(width: 12),
          if (!isLast)
            Expanded(
              child: ElevatedButton(
                onPressed: () => _goToStep(_currentStep + 1),
                child: const Text('Tiếp tục'),
              ),
            ),
        ],
      ),
    );
  }

  Widget _profileCard(profile) {
    final weight = profile?.weightKg != null && profile!.weightKg > 0
        ? '${profile.weightKg}'
        : '--';
    final height = profile?.heightCm != null && profile!.heightCm > 0
        ? '${profile.heightCm}'
        : '--';
    final bmi = profile?.bmi != null && profile!.bmi > 0
        ? profile.bmi.toStringAsFixed(1)
        : '--';

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.person_search, color: AppColors.primary),
              const SizedBox(width: 10),
              Text(
                profile?.fullName?.isNotEmpty == true
                    ? profile!.fullName
                    : 'Hồ sơ của bạn',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _metric(
                  'Cân nặng',
                  weight == '--' ? '--' : '$weight kg',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _metric(
                  'Chiều cao',
                  height == '--' ? '--' : '$height cm',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(child: _metric('BMI', bmi)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metric(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _stepTitle(String step, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          CircleAvatar(
            radius: 13,
            backgroundColor: AppColors.primary,
            child: Text(
              step,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _choiceWrap(
    List<String> options,
    String selected,
    ValueChanged<String> onSelected,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: options.map((option) {
          final active = option == selected;
          return ChoiceChip(
            label: Text(option),
            selected: active,
            onSelected: (_) => onSelected(option),
            selectedColor: AppColors.primary,
            labelStyle: TextStyle(
              color: active ? Colors.white : AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _daysPerWeekSelector() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _smallChip(_aiDecide, _daysPerWeek == null, () {
            setState(() {
              _daysPerWeek = null;
              _trainingDays.clear();
            });
          }),
          for (final dayCount in [2, 3, 4, 5, 6])
            _smallChip('$dayCount buổi', _daysPerWeek == dayCount, () {
              setState(() {
                _daysPerWeek = dayCount;
                if (_trainingDays.length > dayCount) {
                  final keep = _trainingDays.take(dayCount).toSet();
                  _trainingDays
                    ..clear()
                    ..addAll(keep);
                }
              });
            }),
        ],
      ),
    );
  }

  Widget _trainingDaySelector() {
    final aiSelected = _trainingDays.isEmpty;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _smallChip(
          _aiDecide,
          aiSelected,
          () => setState(() => _trainingDays.clear()),
        ),
        ..._days.entries.map((entry) {
          final active = _trainingDays.contains(entry.key);
          return _smallChip(entry.value, active, () {
            setState(() {
              if (active) {
                _trainingDays.remove(entry.key);
              } else {
                final maxDays = _daysPerWeek;
                if (maxDays != null && _trainingDays.length >= maxDays) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Chỉ chọn tối đa $maxDays buổi')),
                  );
                  return;
                }
                _trainingDays.add(entry.key);
              }
            });
          });
        }),
      ],
    );
  }

  Widget _smallChip(String label, bool selected, VoidCallback onTap) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: AppColors.primary,
      labelStyle: TextStyle(
        color: selected ? Colors.white : AppColors.textPrimary,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  Widget _healthField() {
    return TextField(
      controller: _healthController,
      maxLines: 3,
      decoration: const InputDecoration(
        hintText: 'Ví dụ: đau lưng dưới, chấn thương gối, huyết áp cao...',
      ),
    );
  }

  Widget _errorBox(String message) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.35)),
      ),
      child: Text(
        message,
        style: const TextStyle(color: AppColors.textPrimary, height: 1.35),
      ),
    );
  }

  Widget _resultCard() {
    final response =
        _result?['response']?.toString() ??
        _result?['aiResponse']?.toString() ??
        '';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Lịch AI đề xuất',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            response.isEmpty ? 'AI đã tạo dữ liệu lịch tập.' : response,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '${_suggestions.length} thao tác sẵn sàng để lưu',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
