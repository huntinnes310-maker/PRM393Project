import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/network/api_client.dart';
import '../../../providers/auth_provider.dart';

class ChatMessageModel {
  final String role;
  final String content;
  final DateTime createdAt;

  ChatMessageModel({
    required this.role,
    required this.content,
    required this.createdAt,
  });

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    return ChatMessageModel(
      role: json['role'] ?? 'user',
      content: json['content'] ?? '',
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : DateTime.now(),
    );
  }
}

class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key});

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final ApiClient _apiClient = ApiClient();
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessageModel> _messages = [];
  bool _isLoading = true;
  bool _isThinking = false;

  final List<String> _suggestedQuestions = [
    'Làm sao để tập ngực hiệu quả nhất?',
    'Cho tôi một thực đơn 2000 kcal tăng cơ.',
    'Lịch tập 3 ngày/tuần nên chia thế nào?',
    'Tôi bị đau khớp vai thì nên tập bài gì?',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadChatHistory();
    });
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
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
          _messages.addAll(raw.map((x) => ChatMessageModel.fromJson(x)).toList());
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
        
        setState(() {
          _messages.add(ChatMessageModel(
            role: 'assistant',
            content: replyText,
            createdAt: DateTime.now(),
          ));
        });
      } else {
        String errorMsg = 'Xin lỗi, tôi gặp sự cố kết nối. Hãy thử lại sau ít phút!';
        try {
          final data = ApiClient.decodeResponse(res);
          if (data is Map && data.containsKey('message')) {
            errorMsg = 'Lỗi hệ thống: ${data['message']}';
          }
        } catch (_) {}
        setState(() {
          _messages.add(ChatMessageModel(
            role: 'assistant',
            content: errorMsg,
            createdAt: DateTime.now(),
          ));
        });
      }
    } catch (e) {
      setState(() {
        _messages.add(ChatMessageModel(
          role: 'assistant',
          content: 'Không thể kết nối đến máy chủ AI: $e',
          createdAt: DateTime.now(),
        ));
      });
    } finally {
      setState(() {
        _isThinking = false;
      });
      _scrollToBottom();
    }
  }

  Future<void> _clearChatHistory() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Xóa lịch sử chat?', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text(
          'Bạn có chắc muốn xóa toàn bộ tin nhắn trước đây với AI Coach? Hành động này không thể hoàn tác.',
          style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy', style: TextStyle(color: AppColors.textSecondary)),
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
        if (res.statusCode == 200) {
          setState(() {
            _messages.clear();
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Lịch sử cuộc trò chuyện đã được xóa sạch!')),
          );
        }
      } catch (e) {
        debugPrint('Lỗi xóa lịch sử chat: $e');
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.psychology, color: AppColors.primary),
            SizedBox(width: 8),
            Text('Trợ lý AI Coach', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        backgroundColor: AppColors.cardBackground,
        elevation: 0,
        actions: [
          if (_messages.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined, color: AppColors.textSecondary),
              tooltip: 'Xóa lịch sử chat',
              onPressed: _clearChatHistory,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : Column(
              children: [
                Expanded(
                  child: _messages.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(16),
                          itemCount: _messages.length,
                          itemBuilder: (ctx, index) {
                            return _buildMessageItem(_messages[index]);
                          },
                        ),
                ),
                if (_isThinking) _buildThinkingIndicator(),
                _buildInputBar(),
              ],
            ),
    );
  }

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 40),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.psychology, size: 72, color: AppColors.primary),
          ),
          const SizedBox(height: 20),
          const Text(
            'Hỏi AI Coach bất kỳ điều gì!',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tôi ở đây để tư vấn thực đơn, hướng dẫn bài tập và hỗ trợ hành trình thể hình của bạn.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 40),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '💡 Câu hỏi gợi ý:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
          const SizedBox(height: 12),
          ..._suggestedQuestions.map((q) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  title: Text(q, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                  trailing: const Icon(Icons.arrow_forward, size: 16, color: AppColors.primary),
                  onTap: () => _sendMessage(q),
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildMessageItem(ChatMessageModel msg) {
    final isUser = msg.role == 'user';
    final timeStr = DateFormat('HH:mm').format(msg.createdAt);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.primary.withOpacity(0.1),
              child: const Icon(Icons.psychology, color: AppColors.primary, size: 18),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isUser ? AppColors.primary : AppColors.cardBackground,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isUser ? 16 : 0),
                      bottomRight: Radius.circular(isUser ? 0 : 16),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      )
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
                const SizedBox(height: 4),
                Text(
                  timeStr,
                  style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.surfaceVariant,
              child: const Icon(Icons.person, color: AppColors.textSecondary, size: 18),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildThinkingIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.primary.withOpacity(0.1),
            child: const Icon(Icons.psychology, color: AppColors.primary, size: 18),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                ),
                SizedBox(width: 10),
                Text(
                  'AI Coach đang suy nghĩ...',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary, fontStyle: FontStyle.italic),
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
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        color: AppColors.cardBackground,
        border: Border(
          top: BorderSide(color: AppColors.surfaceVariant, width: 0.5),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _inputController,
                style: const TextStyle(fontSize: 14),
                minLines: 1,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Nhập tin nhắn cho AI Coach...',
                  hintStyle: const TextStyle(color: AppColors.textHint, fontSize: 13),
                  fillColor: AppColors.surface,
                  filled: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none,
                  ),
                ),
                onSubmitted: _sendMessage,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.send, color: Colors.white, size: 18),
                onPressed: () => _sendMessage(_inputController.text),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
