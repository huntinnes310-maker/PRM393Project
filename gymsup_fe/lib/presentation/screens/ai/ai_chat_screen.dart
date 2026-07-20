import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/network/api_client.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/ai_usage_provider.dart';
import 'generate_plan_screen.dart';
import 'scan_equipment_screen.dart';

class ChatSuggestionModel {
  final String action;
  final String planId;
  final String sessionId;
  final String exerciseId;
  final String planName;
  final String goal;
  final String planDescription;
  final int daysPerWeek;
  final String dayOfWeek;
  final String focus;
  final int sets;
  final String reps;
  final String notes;

  // Meal suggestion fields
  final String mealType;
  final String mealName;
  final int calories;
  final int protein;
  final int carbs;
  final int fat;

  ChatSuggestionModel({
    required this.action,
    required this.planId,
    required this.sessionId,
    required this.exerciseId,
    required this.planName,
    required this.goal,
    required this.planDescription,
    required this.daysPerWeek,
    required this.dayOfWeek,
    required this.focus,
    required this.sets,
    required this.reps,
    required this.notes,
    required this.mealType,
    required this.mealName,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  factory ChatSuggestionModel.fromJson(Map<String, dynamic> json) {
    return ChatSuggestionModel(
      action: json['action'] ?? '',
      planId: json['planId'] ?? '',
      sessionId: json['sessionId'] ?? '',
      exerciseId: json['exerciseId'] ?? '',
      planName: json['planName'] ?? '',
      goal: json['goal'] ?? '',
      planDescription: json['planDescription'] ?? '',
      daysPerWeek: json['daysPerWeek'] ?? 0,
      dayOfWeek: json['dayOfWeek'] ?? '',
      focus: json['focus'] ?? '',
      sets: json['sets'] ?? 0,
      reps: json['reps'] ?? '',
      notes: json['notes'] ?? '',
      mealType: json['mealType'] ?? '',
      mealName: json['mealName'] ?? '',
      calories: json['calories'] ?? 0,
      protein: json['protein'] ?? 0,
      carbs: json['carbs'] ?? 0,
      fat: json['fat'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'action': action,
      'planId': planId,
      'sessionId': sessionId,
      'exerciseId': exerciseId,
      'planName': planName,
      'goal': goal,
      'planDescription': planDescription,
      'daysPerWeek': daysPerWeek,
      'dayOfWeek': dayOfWeek,
      'focus': focus,
      'sets': sets,
      'reps': reps,
      'notes': notes,
      'mealType': mealType,
      'mealName': mealName,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
    };
  }
}

class ChatMessageModel {
  final String role;
  final String content;
  final DateTime createdAt;
  final List<ChatSuggestionModel> suggestions;

  ChatMessageModel({
    required this.role,
    required this.content,
    required this.createdAt,
    this.suggestions = const [],
  });

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    var rawSuggestions = json['suggestions'] as List?;
    List<ChatSuggestionModel> parsedSuggestions = [];
    if (rawSuggestions != null) {
      parsedSuggestions = rawSuggestions
          .map((x) => ChatSuggestionModel.fromJson(x as Map<String, dynamic>))
          .toList();
    }
    return ChatMessageModel(
      role: json['role'] ?? 'user',
      content: json['content'] ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      suggestions: parsedSuggestions,
    );
  }
}

class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key});

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  static const _aiPrimary = Color(0xFF9185FF);
  static const _aiAccent = Color(0xFF56D6C9);
  static const _aiSurface = Color(0xFF17181F);
  final ApiClient _apiClient = ApiClient();
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessageModel> _messages = [];
  bool _isLoading = true;
  bool _isThinking = false;
  bool _isApplying = false;
  final Set<int> _appliedIndices = {};

  final List<String> _suggestedQuestions = [
    'Làm sao để tập ngực hiệu quả nhất?',
    'Cho tôi một thực đơn 2000 kcal tăng cơ.',
    'Lịch tập 3 ngày/tuần nên chia thế nào?',
    'Tôi bị đau khớp vai thì nên tập bài gì?',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadChatHistory();
      context.read<AiUsageProvider>().refresh();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _openScanEquipment() async {
    final result = await Navigator.of(
      context,
    ).push<Map>(MaterialPageRoute(builder: (_) => const ScanEquipmentScreen()));
    if (result == null) return;
    final text = result['text']?.toString() ?? '';
    if (text.isNotEmpty) {
      _sendMessage(text);
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  Future<void> _loadChatHistory() async {
    final auth = context.read<AuthProvider>();
    if (auth.userId == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final res = await _apiClient.get('/ai/history/${auth.userId}');
      if (res.statusCode == 200) {
        final List raw = ApiClient.decodeResponse(res) as List;
        setState(() {
          _messages.clear();
          _messages.addAll(
            raw.map((x) => ChatMessageModel.fromJson(x)).toList(),
          );
        });
        _scrollToBottom();
      }
    } catch (e) {
      debugPrint('Lỗi tải lịch sử chat: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;
    final auth = context.read<AuthProvider>();
    if (auth.userId == null) return;

    final userMsg = ChatMessageModel(
      role: 'user',
      content: text.trim(),
      createdAt: DateTime.now(),
    );

    setState(() {
      _messages.add(userMsg);
      _isThinking = true;
    });
    _inputController.clear();
    _scrollToBottom();

    try {
      final res = await _apiClient.post('/ai/chat', {
        'message': userMsg.content,
      });

      if (res.statusCode == 200) {
        final data = ApiClient.decodeResponse(res);
        final replyText = data['response'] ?? '';
        final rawSuggestions = data['suggestions'] as List?;
        List<ChatSuggestionModel> parsedSuggestions = [];
        if (rawSuggestions != null) {
          parsedSuggestions = rawSuggestions
              .map(
                (x) => ChatSuggestionModel.fromJson(x as Map<String, dynamic>),
              )
              .toList();
        }

        setState(() {
          _messages.add(
            ChatMessageModel(
              role: 'assistant',
              content: replyText,
              createdAt: DateTime.now(),
              suggestions: parsedSuggestions,
            ),
          );
        });
      } else if (res.statusCode == 429 || res.statusCode == 403) {
        String errorMsg = 'Bạn đã hết lượt dùng tính năng này lúc này.';
        try {
          final data = ApiClient.decodeResponse(res);
          if (data is Map && data['message'] != null) {
            errorMsg = data['message'].toString();
          }
        } catch (_) {}
        setState(() {
          _messages.add(
            ChatMessageModel(
              role: 'assistant',
              content: errorMsg,
              createdAt: DateTime.now(),
            ),
          );
        });
      } else {
        String errorMsg =
            'Xin lỗi, tôi gặp sự cố kết nối. Hãy thử lại sau ít phút!';
        try {
          final data = ApiClient.decodeResponse(res);
          if (data is Map && data.containsKey('message')) {
            errorMsg = 'Lỗi hệ thống: ${data['message']}';
          }
        } catch (_) {}
        setState(() {
          _messages.add(
            ChatMessageModel(
              role: 'assistant',
              content: errorMsg,
              createdAt: DateTime.now(),
            ),
          );
        });
      }
    } catch (e) {
      setState(() {
        _messages.add(
          ChatMessageModel(
            role: 'assistant',
            content: 'Không thể kết nối đến máy chủ AI: $e',
            createdAt: DateTime.now(),
          ),
        );
      });
    } finally {
      setState(() {
        _isThinking = false;
      });
      _scrollToBottom();
      if (mounted) context.read<AiUsageProvider>().refresh();
    }
  }

  Future<void> _clearChatHistory() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Xóa lịch sử chat?',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Bạn có chắc muốn xóa toàn bộ tin nhắn trước đây với AI Coach? Hành động này không thể hoàn tác.',
          style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Hủy',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Xóa', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() {
        _isLoading = true;
      });
      try {
        final res = await _apiClient.delete('/ai/history');
        if (!mounted) return;
        if (res.statusCode == 200) {
          setState(() {
            _messages.clear();
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Lịch sử cuộc trò chuyện đã được xóa sạch!'),
            ),
          );
        }
      } catch (e) {
        debugPrint('Lỗi xóa lịch sử chat: $e');
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        toolbarHeight: 72,
        title: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [_aiPrimary, Color(0xFF695BE8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: _aiPrimary.withValues(alpha: 0.24),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
                color: Colors.white,
                size: 21,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI Coach',
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w700,
                    fontSize: 17,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: _aiAccent,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Sẵn sàng hỗ trợ bạn',
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Consumer<AiUsageProvider>(
                      builder: (context, usage, _) {
                        final chat = usage.status?.chat;
                        if (chat == null) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: Text(
                            '· ${chat.used}/${chat.limit} lượt hôm nay',
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: chat.isExhausted
                                  ? AppColors.error
                                  : AppColors.textSecondary,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        backgroundColor: AppColors.background,
        elevation: 0,
        actions: [
          if (_messages.isNotEmpty)
            IconButton.filledTonal(
              icon: const Icon(Icons.delete_outline_rounded, size: 19),
              tooltip: 'Xóa lịch sử chat',
              onPressed: _clearChatHistory,
            ),
          const SizedBox(width: 12),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: _aiPrimary,
          labelColor: _aiPrimary,
          unselectedLabelColor: AppColors.textSecondary,
          tabs: const [
            Tab(text: 'Trò chuyện'),
            Tab(text: 'Tạo lịch AI'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildChatTab(), const GeneratePlanScreen(embedded: true)],
      ),
    );
  }

  Widget _buildChatTab() {
    return _isLoading
        ? const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          )
        : Column(
            children: [
              Expanded(
                child: _messages.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.fromLTRB(18, 20, 18, 12),
                        itemCount: _messages.length,
                        itemBuilder: (ctx, index) {
                          return _buildMessageItem(index, _messages[index]);
                        },
                      ),
              ),
              if (_isThinking) _buildThinkingIndicator(),
              _buildInputBar(),
            ],
          );
  }

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 32),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 880),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF211F35), _aiSurface, Color(0xFF15171C)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: _aiPrimary.withValues(alpha: 0.25)),
                  boxShadow: [
                    BoxShadow(
                      color: _aiPrimary.withValues(alpha: 0.07),
                      blurRadius: 28,
                      offset: const Offset(0, 14),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [_aiPrimary, Color(0xFF6558DE)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: _aiPrimary.withValues(alpha: 0.24),
                            blurRadius: 18,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.auto_awesome_rounded,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Huấn luyện thông minh hơn',
                            style: GoogleFonts.outfit(
                              color: AppColors.textPrimary,
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 7),
                          Text(
                            'Hỏi về bài tập, dinh dưỡng hoặc để AI Coach xây dựng kế hoạch phù hợp với mục tiêu của bạn.',
                            style: GoogleFonts.outfit(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                              height: 1.45,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              Text(
                'Bắt đầu với một câu hỏi',
                style: GoogleFonts.outfit(
                  color: AppColors.textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Chọn một chủ đề hoặc nhập câu hỏi của riêng bạn.',
                style: GoogleFonts.outfit(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 14),
              LayoutBuilder(
                builder: (context, constraints) {
                  final cardWidth = constraints.maxWidth >= 680
                      ? (constraints.maxWidth - 12) / 2
                      : constraints.maxWidth;
                  return Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: List.generate(_suggestedQuestions.length, (
                      index,
                    ) {
                      final question = _suggestedQuestions[index];
                      return SizedBox(
                        width: cardWidth,
                        child: _buildPromptCard(index, question),
                      );
                    }),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPromptCard(int index, String question) {
    final icons = [
      Icons.fitness_center_rounded,
      Icons.restaurant_rounded,
      Icons.calendar_month_rounded,
      Icons.health_and_safety_rounded,
    ];
    final accents = [
      _aiPrimary,
      const Color(0xFF58C996),
      const Color(0xFF65A7FF),
      const Color(0xFFE4C46C),
    ];
    final accent = accents[index % accents.length];

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _sendMessage(question),
        borderRadius: BorderRadius.circular(17),
        hoverColor: accent.withValues(alpha: 0.04),
        child: Ink(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: _aiSurface,
            borderRadius: BorderRadius.circular(17),
            border: Border.all(color: accent.withValues(alpha: 0.18)),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.11),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icons[index % icons.length],
                  color: accent,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  question,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    color: AppColors.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.arrow_outward_rounded,
                color: accent.withValues(alpha: 0.85),
                size: 17,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessageItem(int index, ChatMessageModel msg) {
    final isUser = msg.role == 'user';
    final timeStr = DateFormat('HH:mm').format(msg.createdAt);
    final hasSuggestions = msg.suggestions.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [_aiPrimary, Color(0xFF6558DE)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(13),
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isUser
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    gradient: isUser
                        ? const LinearGradient(
                            colors: [_aiPrimary, Color(0xFF7063E8)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : const LinearGradient(
                            colors: [_aiSurface, Color(0xFF15161B)],
                          ),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: Radius.circular(isUser ? 18 : 5),
                      bottomRight: Radius.circular(isUser ? 5 : 18),
                    ),
                    border: isUser ? null : Border.all(color: AppColors.border),
                    boxShadow: [
                      BoxShadow(
                        color: isUser
                            ? _aiPrimary.withValues(alpha: 0.13)
                            : Colors.black.withValues(alpha: 0.12),
                        blurRadius: 12,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Text(
                    msg.content,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.4,
                      color: isUser ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                ),
                if (!isUser && hasSuggestions) ...[
                  const SizedBox(height: 8),
                  _buildSuggestionsCard(index, msg.suggestions),
                ],
                const SizedBox(height: 4),
                Text(
                  timeStr,
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(13),
                border: Border.all(color: AppColors.border),
              ),
              child: const Icon(
                Icons.person_rounded,
                color: AppColors.textSecondary,
                size: 18,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSuggestionsCard(
    int msgIndex,
    List<ChatSuggestionModel> suggestions,
  ) {
    final isApplied = _appliedIndices.contains(msgIndex);

    final mealSuggestions = suggestions
        .where((s) => s.action.toLowerCase() == 'add_meal')
        .toList();
    final workoutSuggestions = suggestions
        .where((s) => s.action.toLowerCase() != 'add_meal')
        .toList();

    List<Widget> children = [];

    if (mealSuggestions.isNotEmpty) {
      children.add(
        Card(
          margin: const EdgeInsets.only(top: 4, bottom: 8),
          color: AppColors.cardBackground.withValues(alpha: 0.9),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(
              color: isApplied
                  ? AppColors.success.withValues(alpha: 0.3)
                  : AppColors.primary.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.restaurant_menu,
                      color: Colors.orangeAccent,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Gợi ý dinh dưỡng 🍎',
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ...mealSuggestions.map(
                  (m) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '• ${m.mealName} (${m.mealType})',
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          '  Calories: ${m.calories} kcal (P: ${m.protein}g | C: ${m.carbs}g | F: ${m.fat}g)',
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Divider(color: AppColors.surfaceVariant, height: 16),
                SizedBox(
                  width: double.infinity,
                  child: isApplied
                      ? Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: AppColors.success.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.check_circle_outline,
                                color: AppColors.success,
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Đã lưu vào nhật ký',
                                style: GoogleFonts.outfit(
                                  color: AppColors.success,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ElevatedButton.icon(
                          onPressed: _isApplying
                              ? null
                              : () => _applySuggestions(
                                  msgIndex,
                                  mealSuggestions,
                                ),
                          icon: const Icon(Icons.add_task, size: 16),
                          label: Text(
                            'Ghi nhận bữa ăn này',
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            backgroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (workoutSuggestions.isNotEmpty) {
      final createPlanAct = workoutSuggestions.firstWhere(
        (s) => s.action.toLowerCase() == 'create_plan',
        orElse: () => ChatSuggestionModel(
          action: '',
          planId: '',
          sessionId: '',
          exerciseId: '',
          planName: 'Lịch tập đề xuất',
          goal: '',
          planDescription: '',
          daysPerWeek: 0,
          dayOfWeek: '',
          focus: '',
          sets: 0,
          reps: '',
          notes: '',
          mealType: '',
          mealName: '',
          calories: 0,
          protein: 0,
          carbs: 0,
          fat: 0,
        ),
      );

      final exercises = workoutSuggestions
          .where((s) => s.action.toLowerCase() == 'add_exercise')
          .toList();

      children.add(
        Card(
          margin: const EdgeInsets.only(top: 4, bottom: 8),
          color: AppColors.cardBackground.withValues(alpha: 0.9),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(
              color: isApplied
                  ? AppColors.success.withValues(alpha: 0.3)
                  : AppColors.primary.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.fitness_center,
                      color: Colors.blueAccent,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Đề xuất lịch tập từ AI 🏋️‍♂️',
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (createPlanAct.action.isNotEmpty) ...[
                  Text(
                    'Lịch: ${createPlanAct.planName}',
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: AppColors.primaryLight,
                    ),
                  ),
                  if (createPlanAct.planDescription.isNotEmpty)
                    Text(
                      createPlanAct.planDescription,
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  const SizedBox(height: 8),
                ],
                Text(
                  'Chi tiết bài tập:',
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                ...exercises.map(
                  (e) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      '• [${e.dayOfWeek}] ${e.focus}: ${e.sets} sets x ${e.reps} reps',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),
                const Divider(color: AppColors.surfaceVariant, height: 16),
                SizedBox(
                  width: double.infinity,
                  child: isApplied
                      ? Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: AppColors.success.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.check_circle_outline,
                                color: AppColors.success,
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Đã lưu lịch tập thành công',
                                style: GoogleFonts.outfit(
                                  color: AppColors.success,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ElevatedButton.icon(
                          onPressed: _isApplying
                              ? null
                              : () => _applySuggestions(
                                  msgIndex,
                                  workoutSuggestions,
                                ),
                          icon: const Icon(Icons.playlist_add_check, size: 18),
                          label: Text(
                            'Lưu lịch tập này',
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            backgroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    );
  }

  Future<void> _applySuggestions(
    int msgIndex,
    List<ChatSuggestionModel> suggestions,
  ) async {
    if (_isApplying) return;

    setState(() {
      _isApplying = true;
    });

    try {
      final res = await _apiClient.post('/ai/apply', {
        'suggestions': suggestions.map((s) => s.toJson()).toList(),
      });
      if (!mounted) return;

      if (res.statusCode == 200) {
        setState(() {
          _appliedIndices.add(msgIndex);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã áp dụng gợi ý của AI Coach thành công! 🎉'),
            backgroundColor: AppColors.success,
          ),
        );
      } else if (res.statusCode == 403 || res.statusCode == 401) {
        _showVipUpsellDialog();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không thể áp dụng gợi ý. Vui lòng thử lại.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi kết nối khi áp dụng gợi ý: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isApplying = false;
        });
      }
    }
  }

  void _showVipUpsellDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.star, color: Colors.amber),
            SizedBox(width: 8),
            Text(
              'Hội Viên VIP 👑',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: const Text(
          'Tính năng tự động lưu lịch tập và ghi nhật ký dinh dưỡng trực tiếp từ cuộc hội thoại chỉ dành cho Hội viên VIP.\n\nHãy nâng cấp để mở khóa trợ lý AI Coach đắc lực nhé!',
          style: TextStyle(fontSize: 14, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Đóng',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              GoRouter.of(context).push('/subscription');
            },
            child: const Text('Tìm hiểu VIP'),
          ),
        ],
      ),
    );
  }

  Widget _buildThinkingIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_aiPrimary, Color(0xFF6558DE)],
              ),
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
            decoration: BoxDecoration(
              color: _aiSurface,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
                bottomLeft: Radius.circular(5),
                bottomRight: Radius.circular(18),
              ),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: _aiPrimary,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'AI Coach đang phân tích...',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.98),
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.055)),
        ),
      ),
      child: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 5, 6, 5),
              decoration: BoxDecoration(
                color: _aiSurface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _aiPrimary.withValues(alpha: 0.18)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.18),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'Phân tích ảnh/video bằng AI',
                    onPressed: _openScanEquipment,
                    icon: const Icon(
                      Icons.add_photo_alternate_outlined,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _inputController,
                      style: GoogleFonts.outfit(fontSize: 14),
                      minLines: 1,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: 'Hỏi AI Coach bất kỳ điều gì...',
                        hintStyle: GoogleFonts.outfit(
                          color: AppColors.textHint,
                          fontSize: 13,
                        ),
                        filled: false,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 12,
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                      ),
                      onSubmitted: _sendMessage,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [_aiPrimary, Color(0xFF6558DE)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: _aiPrimary.withValues(alpha: 0.22),
                          blurRadius: 12,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: IconButton(
                      tooltip: 'Gửi tin nhắn',
                      icon: const Icon(
                        Icons.arrow_upward_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                      onPressed: _isThinking
                          ? null
                          : () => _sendMessage(_inputController.text),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
