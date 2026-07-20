import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/network/api_client.dart';

/// Màn hình phân tích hình ảnh/video bằng AI: vóc dáng, form tập, máy tập.
class ScanEquipmentScreen extends StatefulWidget {
  final String initialMode;

  const ScanEquipmentScreen({super.key, this.initialMode = 'equipment_info'});

  @override
  State<ScanEquipmentScreen> createState() => _ScanEquipmentScreenState();
}

class _ScanEquipmentScreenState extends State<ScanEquipmentScreen> {
  final ApiClient _apiClient = ApiClient();
  late String _currentMode;

  final Map<String, Map<String, dynamic>?> _resultsByMode = {
    'body_check': null,
    'form_check': null,
    'equipment_info': null,
  };
  final Map<String, bool> _loadingByMode = {
    'body_check': false,
    'form_check': false,
    'equipment_info': false,
  };
  final Map<String, String?> _errorsByMode = {
    'body_check': null,
    'form_check': null,
    'equipment_info': null,
  };
  final Map<String, XFile?> _mediaByMode = {
    'body_check': null,
    'form_check': null,
    'equipment_info': null,
  };

  @override
  void initState() {
    super.initState();
    _currentMode = widget.initialMode;
  }

  Future<void> _pickMedia(ImageSource src) async {
    final picker = ImagePicker();
    final selectedMode = _currentMode;
    final isVideo = selectedMode == 'form_check';
    final file = isVideo
        ? await picker.pickVideo(source: src, maxDuration: const Duration(minutes: 1))
        : await picker.pickImage(source: src, maxWidth: 1200, maxHeight: 1200, imageQuality: 80);

    if (file == null) return;

    if (isVideo) {
      final lowerName = file.name.toLowerCase();
      if (!lowerName.endsWith('.mp4') && !lowerName.endsWith('.mov')) {
        setState(() => _errorsByMode[selectedMode] = 'Chỉ hỗ trợ video MP4 hoặc MOV.');
        return;
      }
      const maxVideoBytes = 25 * 1024 * 1024;
      if (await file.length() > maxVideoBytes) {
        setState(() => _errorsByMode[selectedMode] = 'Video không được vượt quá 25 MB.');
        return;
      }
    }

    if (!mounted) return;
    setState(() {
      _mediaByMode[selectedMode] = file;
      _resultsByMode[selectedMode] = null;
      _errorsByMode[selectedMode] = null;
    });
  }

  Future<void> _analyzeMedia() async {
    final selectedMode = _currentMode;
    final media = _mediaByMode[selectedMode];
    final isVideo = selectedMode == 'form_check';
    if (media == null) {
      setState(() => _errorsByMode[selectedMode] =
          isVideo ? 'Vui lòng chọn video trước khi phân tích.' : 'Vui lòng chọn ảnh trước khi phân tích.');
      return;
    }

    setState(() {
      _loadingByMode[selectedMode] = true;
      _errorsByMode[selectedMode] = null;
    });

    try {
      final bytes = await media.readAsBytes();
      final response = isVideo
          ? await _apiClient.postMultipart(
              '/ai/analyze-form-video',
              fileField: 'video',
              fileBytes: bytes,
              filename: media.name,
            )
          : await _apiClient.postMultipart(
              '/ai/analyze-image',
              fileField: 'image',
              fileBytes: bytes,
              filename: media.name,
              fields: {'mode': selectedMode},
            );

      if (response.statusCode != 200) {
        final data = ApiClient.decodeResponse(response);
        throw Exception(data is Map ? (data['message'] ?? 'Không thể phân tích.') : 'Không thể phân tích.');
      }

      final result = ApiClient.decodeResponse(response) as Map<String, dynamic>;
      if (!mounted) return;
      setState(() => _resultsByMode[selectedMode] = result);
    } catch (_) {
      if (!mounted) return;
      setState(() => _errorsByMode[selectedMode] =
          isVideo ? 'Không thể phân tích video. Vui lòng thử lại.' : 'Không thể phân tích ảnh. Vui lòng thử lại.');
    } finally {
      if (mounted) setState(() => _loadingByMode[selectedMode] = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AI Phân tích')),
      body: Column(
        children: [
          _buildModeSelector(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildGuideText(),
                  const SizedBox(height: 20),
                  _buildMediaPreview(),
                  const SizedBox(height: 20),
                  _buildActionButtons(),
                  const SizedBox(height: 24),
                  _buildContent(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeSelector() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: AppColors.cardBackground, borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: [
          _ModeTab(label: 'Vóc dáng', isActive: _currentMode == 'body_check', onTap: () => setState(() => _currentMode = 'body_check')),
          _ModeTab(label: 'Form tập', isActive: _currentMode == 'form_check', onTap: () => setState(() => _currentMode = 'form_check')),
          _ModeTab(label: 'Máy tập', isActive: _currentMode == 'equipment_info', onTap: () => setState(() => _currentMode = 'equipment_info')),
        ],
      ),
    );
  }

  Widget _buildGuideText() {
    String guide = '';
    switch (_currentMode) {
      case 'body_check':
        guide = 'Chụp ảnh toàn thân hoặc nửa thân rõ ràng, đủ sáng. Kết quả chỉ mang tính tham khảo, không phải chẩn đoán y tế.';
        break;
      case 'form_check':
        guide = 'Quay video toàn bộ động tác, tối đa 1 phút và 25 MB. Góc quay bên hông hoặc 45 độ thường cho kết quả rõ nhất.';
        break;
      case 'equipment_info':
        guide = 'Chụp rõ máy tập hoặc dụng cụ, tránh ảnh quá gần làm mất toàn cảnh máy.';
        break;
    }
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.info.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.info.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: AppColors.info, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(guide, style: const TextStyle(color: AppColors.textPrimary, fontSize: 12, height: 1.4))),
        ],
      ),
    );
  }

  Widget _buildMediaPreview() {
    final media = _mediaByMode[_currentMode];
    final isVideo = _currentMode == 'form_check';
    return GestureDetector(
      onTap: _showPickOptions,
      child: Container(
        height: 220,
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
        ),
        child: media != null
            ? (isVideo
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.videocam, size: 64, color: AppColors.primary),
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Text(media.name, maxLines: 2, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center),
                      ),
                      const SizedBox(height: 6),
                      const Text('Video đã sẵn sàng để phân tích', style: TextStyle(color: AppColors.textSecondary)),
                    ],
                  )
                : ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: kIsWeb
                        ? Image.network(media.path, fit: BoxFit.cover, width: double.infinity)
                        : Image.file(File(media.path), fit: BoxFit.cover, width: double.infinity),
                  ))
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(isVideo ? Icons.videocam_outlined : Icons.image_outlined, size: 48, color: AppColors.textHint),
                  const SizedBox(height: 12),
                  Text(isVideo ? 'Bấm để chọn video' : 'Bấm để chọn ảnh', style: const TextStyle(color: AppColors.textHint)),
                ],
              ),
      ),
    );
  }

  void _showPickOptions() {
    final isVideo = _currentMode == 'form_check';
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardBackground,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(isVideo ? Icons.videocam : Icons.camera_alt),
              title: Text(isVideo ? 'Quay video' : 'Máy ảnh'),
              onTap: () {
                Navigator.pop(ctx);
                _pickMedia(ImageSource.camera);
              },
            ),
            ListTile(
              leading: Icon(isVideo ? Icons.video_library : Icons.photo_library),
              title: Text(isVideo ? 'Chọn video từ thư viện' : 'Thư viện ảnh'),
              onTap: () {
                Navigator.pop(ctx);
                _pickMedia(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    final isLoading = _loadingByMode[_currentMode] ?? false;
    final hasMedia = _mediaByMode[_currentMode] != null;

    return Row(
      children: [
        if (hasMedia)
          Expanded(
            child: ElevatedButton.icon(
              onPressed: isLoading ? null : _analyzeMedia,
              icon: isLoading
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.auto_awesome, size: 20),
              label: Text(isLoading ? 'Đang phân tích...' : 'Bắt đầu phân tích'),
            ),
          ),
        if (hasMedia && !isLoading) ...[
          const SizedBox(width: 12),
          IconButton(
            onPressed: () => setState(() => _mediaByMode[_currentMode] = null),
            icon: const Icon(Icons.delete_outline, color: AppColors.error),
          ),
        ],
      ],
    );
  }

  Widget _buildContent() {
    final isLoading = _loadingByMode[_currentMode] ?? false;
    final error = _errorsByMode[_currentMode];
    final result = _resultsByMode[_currentMode];

    if (isLoading) return const SizedBox.shrink();
    if (error != null) {
      return Center(child: Text(error, style: const TextStyle(color: AppColors.error, fontSize: 13)));
    }
    if (result == null) return _buildEmptyState();

    switch (_currentMode) {
      case 'body_check':
        return _buildBodyCheckResult(result);
      case 'form_check':
        return _buildFormCheckResult(result);
      case 'equipment_info':
        return _buildEquipmentInfoResult(result);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildEmptyState() {
    String msg = '';
    switch (_currentMode) {
      case 'body_check':
        msg = 'Bạn chưa phân tích vóc dáng.\nHãy chọn ảnh cơ thể rõ ràng rồi bấm phân tích.';
        break;
      case 'form_check':
        msg = 'Bạn chưa kiểm tra form tập.\nHãy chọn video động tác rồi bấm phân tích.';
        break;
      case 'equipment_info':
        msg = 'Bạn chưa phân tích máy tập.\nHãy chọn ảnh máy tập hoặc dụng cụ rồi bấm phân tích.';
        break;
    }
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Text(msg, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.5)),
      ),
    );
  }

  Widget _buildBodyCheckResult(Map<String, dynamic> data) {
    return Column(
      children: [
        _buildSummaryCard(data),
        _buildListSection('Nhận xét vóc dáng', data['bodyObservations'], Icons.visibility_outlined),
        _buildListSection('Nhóm cơ nên ưu tiên', data['priorityMuscles'], Icons.star_outline, isPrimary: true),
        _buildListSection('Nhóm cơ liên quan', data['muscles'], Icons.fitness_center),
        _buildListSection('Bài tập gợi ý', data['suggestedExercises'], Icons.directions_run),
        _buildListSection('Lời khuyên tập luyện', data['trainingAdvice'], Icons.lightbulb_outline),
        _buildListSection('Cảnh báo', data['warnings'], Icons.warning_amber_outlined, color: Colors.orangeAccent),
        const SizedBox(height: 20),
        _buildSendToChatButton(data),
      ],
    );
  }

  Widget _buildFormCheckResult(Map<String, dynamic> data) {
    return Column(
      children: [
        _buildSummaryCard(data),
        _buildListSection('Bài tập phát hiện', data['detectedExercise'], Icons.fitness_center, isPrimary: true),
        _buildListSection('Đánh giá tổng quan', data['overallVerdict'], Icons.assignment_outlined),
        _buildListSection('Tóm tắt chuyển động', data['movementSummary'], Icons.directions_run),
        _buildListSection('Lỗi nghiêm trọng', data['majorIssues'], Icons.error_outline, color: Colors.redAccent),
        _buildListSection('Lỗi cần cải thiện', data['minorIssues'], Icons.info_outline, color: Colors.orangeAccent),
        _buildListSection('Điểm thực hiện đúng', data['correctPoints'], Icons.check_circle_outline, color: AppColors.primary),
        _buildListSection('Cơ tham gia', data['muscles'], Icons.fitness_center),
        _buildListSection('Cue sửa kỹ thuật', data['correctiveCues'], Icons.build_outlined),
        _buildListSection('Cách cải thiện', data['suggestedFixes'], Icons.lightbulb_outline),
        _buildListSection('Cảnh báo an toàn', data['warnings'], Icons.shield_outlined, color: Colors.redAccent),
        const SizedBox(height: 20),
        _buildSendToChatButton(data),
      ],
    );
  }

  Widget _buildEquipmentInfoResult(Map<String, dynamic> data) {
    return Column(
      children: [
        _buildSummaryCard(data),
        _buildListSection('Vật thể phát hiện', data['detectedItems'], Icons.grid_view),
        _buildListSection('Nhóm cơ tác động', data['muscles'], Icons.bolt, isPrimary: true),
        _buildListSection('Bài tập thực hiện', data['suggestedExercises'], Icons.play_circle_outline),
        _buildListSection('Cách dùng / Lời khuyên', data['trainingAdvice'], Icons.help_outline),
        _buildListSection('Cảnh báo an toàn', data['warnings'], Icons.warning_amber_outlined, color: Colors.orangeAccent),
        const SizedBox(height: 20),
        _buildSendToChatButton(data),
      ],
    );
  }

  Widget _buildSummaryCard(Map<String, dynamic> data) {
    final title = data['title']?.toString() ?? 'Kết quả phân tích';
    final summary = data['summary']?.toString() ?? '';
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title.toUpperCase(), style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800, fontSize: 16)),
          if (summary.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(summary, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, height: 1.5)),
          ],
        ],
      ),
    );
  }

  Widget _buildListSection(String title, dynamic list, IconData icon, {bool isPrimary = false, Color? color}) {
    if (list == null || (list is List && list.isEmpty)) return const SizedBox.shrink();
    final items = list is List ? list : [list];
    final themeColor = color ?? (isPrimary ? AppColors.primary : AppColors.textPrimary);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: AppColors.cardBackground, borderRadius: BorderRadius.circular(18), border: Border.all(color: AppColors.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, color: themeColor, size: 18),
            const SizedBox(width: 10),
            Text(title, style: TextStyle(color: themeColor, fontWeight: FontWeight.w800, fontSize: 13)),
          ]),
          const SizedBox(height: 12),
          ...items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• ', style: TextStyle(color: AppColors.textHint)),
                    Expanded(child: Text(item.toString(), style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, height: 1.4))),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildSendToChatButton(Map<String, dynamic> data) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: OutlinedButton.icon(
        onPressed: () {
          Navigator.of(context).pop({'text': _buildChatSummaryMessage(data)});
        },
        icon: const Icon(Icons.chat_bubble_outline, size: 18),
        label: const Text('Gửi vào Chat AI'),
      ),
    );
  }

  String _buildChatSummaryMessage(Map<String, dynamic> data) {
    final buffer = StringBuffer();
    String prefix = 'Kết quả phân tích';
    if (_currentMode == 'form_check') prefix = 'Kiểm tra Form';
    if (_currentMode == 'body_check') prefix = 'Phân tích vóc dáng';
    if (_currentMode == 'equipment_info') prefix = 'Phân tích máy tập';

    buffer.writeln('[$prefix]');
    buffer.writeln('Tiêu đề: ${data['title'] ?? 'N/A'}');
    buffer.writeln('Tóm tắt: ${data['summary'] ?? ''}');
    if (_currentMode == 'form_check') {
      buffer.writeln('Bài tập: ${data['detectedExercise'] ?? 'N/A'}');
      buffer.writeln('Đánh giá: ${data['overallVerdict'] ?? ''}');
    }
    return buffer.toString().trim();
  }
}

class _ModeTab extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _ModeTab({required this.label, required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(color: isActive ? Colors.white : AppColors.textSecondary, fontWeight: FontWeight.w800, fontSize: 12),
          ),
        ),
      ),
    );
  }
}
