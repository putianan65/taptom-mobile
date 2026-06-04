import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:heroicons/heroicons.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/chat_service.dart';
import '../../../core/services/voice_service.dart';
import '../../../core/services/database_helper.dart';
import '../../../core/services/permission_service.dart';
import '../../../data/models/chat_message.dart';
import '../widgets/message_bubble.dart';
import '../widgets/chat_input_bar.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  final ChatService _chatService = ChatService();
  final VoiceService _voiceService = VoiceService();
  final ImagePicker _imagePicker = ImagePicker();

  List<ChatMessage> _messages = [];
  bool _isLoading = false;
  bool _isRecording = false;
  File? _selectedImage;

  // Daily usage tracking
  int _dailyUsageRemaining = ChatService.dailyRequestLimit;
  int _dailyUsageLimit = ChatService.dailyRequestLimit;

  // Sample question suggestions
  final List<Map<String, dynamic>> _suggestions = [
    {
      'icon': HeroIcons.scale,
      'text': 'กระท่อมปลูกได้กี่ต้น?',
      'color': Colors.blue,
    },
    {
      'icon': HeroIcons.documentCheck,
      'text': 'ขั้นตอนขอ GAP มีอะไรบ้าง?',
      'color': Colors.green,
    },
    {
      'icon': HeroIcons.beaker,
      'text': 'ใช้ปุ๋ยอะไรดีสำหรับกระท่อม?',
      'color': Colors.orange,
    },
    {
      'icon': HeroIcons.bugAnt,
      'text': 'โรคใบไหม้กระท่อม รักษายังไง?',
      'color': Colors.red,
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadHistory();
    _loadDailyUsage();
    _voiceService.initialize();
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    final history = await DatabaseHelper.instance.getChatHistory();
    setState(() {
      _messages = history;
    });
    if (_messages.isNotEmpty) {
      _scrollToBottom();
    }
  }

  Future<void> _loadDailyUsage() async {
    final usage = await _chatService.getDailyUsage();
    if (mounted) {
      setState(() {
        _dailyUsageRemaining = usage.remaining;
        _dailyUsageLimit = usage.limit;
      });
    }
  }

  void _sendSuggestion(String text) {
    _textController.text = text;
    _sendMessage();
  }

  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty && _selectedImage == null) return;

    final userMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: text.isEmpty ? '📷 ส่งรูปภาพ' : text,
      imagePath: _selectedImage?.path,
      isUser: true,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(userMessage);
      _isLoading = true;
    });

    await DatabaseHelper.instance.saveMessage(userMessage);

    _textController.clear();
    final imageToSend = _selectedImage;
    _selectedImage = null;
    _scrollToBottom();

    setState(() {
      _messages.add(ChatMessage.loading());
    });

    try {
      String response;
      if (imageToSend != null) {
        response = await _chatService.sendMessageWithImage(text, imageToSend);
      } else {
        response = await _chatService.sendMessage(text);
      }

      setState(() {
        _messages.removeLast();
        final aiMessage = ChatMessage(
          id: 'ai_${DateTime.now().millisecondsSinceEpoch}',
          content: response,
          isUser: false,
          timestamp: DateTime.now(),
        );
        _messages.add(aiMessage);
        DatabaseHelper.instance.saveMessage(aiMessage);
        _isLoading = false;
      });

      // Refresh daily usage counter
      _loadDailyUsage();
    } catch (e) {
      setState(() {
        _messages.removeLast();
        _messages.add(
          ChatMessage(
            id: 'error_${DateTime.now().millisecondsSinceEpoch}',
            content:
                '❌ เกิดข้อผิดพลาด: ${e.toString()}\n\nกรุณาตรวจสอบการเชื่อมต่ออินเทอร์เน็ต',
            isUser: false,
            timestamp: DateTime.now(),
          ),
        );
        _isLoading = false;
      });
    }

    _scrollToBottom();
  }

  Future<void> _pickImage() async {
    // Request permission first
    final hasPermission = await PermissionService.requestPhotosPermission(
      context,
    );
    if (!hasPermission) return;

    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      // Silent failure - user will see image picker didn't work
    }
  }

  void _startVoiceInput() async {
    // Request permission first
    final hasPermission = await PermissionService.requestMicrophonePermission(
      context,
    );
    if (!hasPermission) return;

    setState(() => _isRecording = true);

    _voiceService.startListening(
      onResult: (text) {
        setState(() {
          _textController.value = TextEditingValue(
            text: text,
            selection: TextSelection.collapsed(offset: text.length),
          );
          _isRecording = false;
        });
      },
      onListeningStopped: () {
        setState(() => _isRecording = false);
      },
    );
  }

  void _stopVoiceInput() {
    _voiceService.stopListening();
    setState(() => _isRecording = false);
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _clearSelectedImage() {
    setState(() => _selectedImage = null);
  }

  void _resetChat() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.refresh, color: Colors.red, size: 20),
            ),
            const SizedBox(width: 12),
            Text(
              'เริ่มบทสนทนาใหม่?',
              style: GoogleFonts.prompt(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
        content: Text(
          'ข้อความทั้งหมดจะถูกลบ',
          style: GoogleFonts.prompt(color: Colors.grey[600]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'ยกเลิก',
              style: GoogleFonts.prompt(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await DatabaseHelper.instance.clearChatHistory();
              setState(() {
                _messages.clear();
                _chatService.resetChat();
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'ล้างแชท',
              style: GoogleFonts.prompt(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/Chat.png'),
            fit: BoxFit.cover,
            alignment: Alignment.center,
          ),
        ),
        child: Container(
          // Dark overlay for readability
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.75),
                Colors.black.withOpacity(0.80),
                Colors.black.withOpacity(0.75),
              ],
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Column(
              children: [
                // Custom App Bar
                _buildAppBar(),

                // Context reset hint banner
                if (_chatService.shouldSuggestReset && _messages.isNotEmpty)
                  _buildResetHintBanner(),

                // Messages List or Welcome Screen
                Expanded(
                  child: _messages.isEmpty
                      ? _buildWelcomeScreen()
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          itemCount: _messages.length,
                          itemBuilder: (context, index) {
                            return _GlassMessageBubble(
                              message: _messages[index],
                            );
                          },
                        ),
                ),

                // Input Bar
                ChatInputBar(
                  controller: _textController,
                  focusNode: _focusNode,
                  onSend: _sendMessage,
                  onImagePick: _pickImage,
                  onVoiceStart: _startVoiceInput,
                  onVoiceStop: _stopVoiceInput,
                  isRecording: _isRecording,
                  isLoading: _isLoading,
                  selectedImage: _selectedImage,
                  onClearImage: _clearSelectedImage,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeScreen() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 40),
          // AI Avatar
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.primaryDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Center(
              child: HeroIcon(
                HeroIcons.sparkles,
                style: HeroIconStyle.solid,
                color: Colors.white,
                size: 36,
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Welcome Text
          Text(
            'AI ผู้ช่วยเกษตรกร',
            style: GoogleFonts.prompt(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              shadows: [const Shadow(color: Colors.black45, blurRadius: 8)],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'พร้อมตอบทุกคำถามเกี่ยวกับ\nกฎหมาย การเกษตร และมาตรฐาน GAP',
            style: GoogleFonts.prompt(
              fontSize: 14,
              color: Colors.white70,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 40),

          // Suggestion Label
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'ลองถามคำถามเหล่านี้:',
              style: GoogleFonts.prompt(
                fontSize: 14,
                color: Colors.white70,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Suggestion Chips
          ..._suggestions
              .map(
                (s) => _buildSuggestionChip(
                  icon: s['icon'] as HeroIcons,
                  text: s['text'] as String,
                  color: s['color'] as Color,
                ),
              )
              .toList(),
        ],
      ),
    );
  }

  Widget _buildSuggestionChip({
    required HeroIcons icon,
    required String text,
    required Color color,
  }) {
    return GestureDetector(
      onTap: () => _sendSuggestion(text),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.75),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.15), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.25),
                borderRadius: BorderRadius.circular(12),
              ),
              child: HeroIcon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                text,
                style: GoogleFonts.prompt(
                  fontSize: 14,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            HeroIcon(HeroIcons.chevronRight, color: Colors.white70, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            border: Border(
              bottom: BorderSide(color: Colors.white.withOpacity(0.1)),
            ),
          ),
          child: Row(
            children: [
              // Back Button
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const HeroIcon(
                    HeroIcons.chevronLeft,
                    style: HeroIconStyle.outline,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // AI Avatar & Title
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Center(
                  child: HeroIcon(
                    HeroIcons.sparkles,
                    style: HeroIconStyle.solid,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Title
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI ผู้ช่วย',
                      style: GoogleFonts.prompt(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'กฎหมาย • เกษตร • วิเคราะห์ภาพ',
                      style: GoogleFonts.prompt(
                        fontSize: 11,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),

              // Daily usage badge
              _buildUsageBadge(),
              const SizedBox(width: 8),

              // Reset Button
              GestureDetector(
                onTap: _resetChat,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const HeroIcon(
                    HeroIcons.arrowPath,
                    style: HeroIconStyle.outline,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Daily usage indicator badge
  Widget _buildUsageBadge() {
    final isLow = _dailyUsageRemaining <= 10;
    final isEmpty = _dailyUsageRemaining <= 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isEmpty
            ? Colors.red.withOpacity(0.25)
            : isLow
                ? Colors.orange.withOpacity(0.2)
                : Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isEmpty
              ? Colors.red.withOpacity(0.4)
              : isLow
                  ? Colors.orange.withOpacity(0.3)
                  : Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isEmpty
                ? Icons.block
                : isLow
                    ? Icons.warning_amber_rounded
                    : Icons.bolt,
            color: isEmpty
                ? Colors.red[300]
                : isLow
                    ? Colors.orange[300]
                    : Colors.white70,
            size: 14,
          ),
          const SizedBox(width: 4),
          Text(
            '$_dailyUsageRemaining/$_dailyUsageLimit',
            style: GoogleFonts.prompt(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isEmpty
                  ? Colors.red[300]
                  : isLow
                      ? Colors.orange[300]
                      : Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  /// Hint banner suggesting conversation reset when history is long
  Widget _buildResetHintBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.amber.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            color: Colors.amber[300],
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'บทสนทนายาวขึ้น แนะนำกด ↻ เริ่มใหม่เพื่อคุณภาพคำตอบที่ดีขึ้น',
              style: GoogleFonts.prompt(
                fontSize: 11,
                color: Colors.amber[200],
              ),
            ),
          ),
          GestureDetector(
            onTap: () => setState(() {}), // Dismiss by rebuilding
            child: Icon(
              Icons.close,
              color: Colors.amber[300],
              size: 16,
            ),
          ),
        ],
      ),
    );
  }
}

/// Glassmorphism Message Bubble for chat with background image
class _GlassMessageBubble extends StatelessWidget {
  final ChatMessage message;

  const _GlassMessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    if (message.isLoading) {
      return _buildLoadingBubble();
    }

    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          left: message.isUser ? 60 : 12,
          right: message.isUser ? 12 : 60,
          bottom: 12,
        ),
        child: Column(
          crossAxisAlignment: message.isUser
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // AI Avatar
                if (!message.isUser) ...[
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.primary, AppColors.primaryDark],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.3),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: const Center(
                      child: HeroIcon(
                        HeroIcons.sparkles,
                        style: HeroIconStyle.solid,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],

                // Message Bubble
                Flexible(
                  child: Column(
                    crossAxisAlignment: message.isUser
                        ? CrossAxisAlignment.end
                        : CrossAxisAlignment.start,
                    children: [
                      // Image Preview
                      if (message.imagePath != null) ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.file(
                            File(message.imagePath!),
                            width: 200,
                            height: 150,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                      // Solid Message Bubble (No blur for clarity)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          gradient: message.isUser
                              ? const LinearGradient(
                                  colors: [
                                    AppColors.primary,
                                    AppColors.primaryDark,
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                )
                              : null,
                          color: message.isUser ? null : Colors.white,
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(20),
                            topRight: const Radius.circular(20),
                            bottomLeft: Radius.circular(
                              message.isUser ? 20 : 4,
                            ),
                            bottomRight: Radius.circular(
                              message.isUser ? 4 : 20,
                            ),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.25),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Text(
                          message.content,
                          style: GoogleFonts.prompt(
                            fontSize: 15,
                            color: message.isUser
                                ? Colors.white
                                : const Color(0xFF1E293B),
                            fontWeight: FontWeight.w400,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Timestamp
            Padding(
              padding: EdgeInsets.only(
                top: 4,
                left: message.isUser ? 0 : 40,
                right: 4,
              ),
              child: Text(
                _formatTime(message.timestamp),
                style: GoogleFonts.prompt(fontSize: 10, color: Colors.white60),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingBubble() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(left: 12, right: 60, bottom: 12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryDark],
                ),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: HeroIcon(
                  HeroIcons.sparkles,
                  style: HeroIconStyle.solid,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
            const SizedBox(width: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.85),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _TypingDot(delay: 0),
                      SizedBox(width: 4),
                      _TypingDot(delay: 150),
                      SizedBox(width: 4),
                      _TypingDot(delay: 300),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

/// Animated typing dot
class _TypingDot extends StatefulWidget {
  final int delay;
  const _TypingDot({required this.delay});

  @override
  State<_TypingDot> createState() => _TypingDotState();
}

class _TypingDotState extends State<_TypingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _animation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) {
        _controller.repeat(reverse: true);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(
              0.3 + (0.7 * _animation.value),
            ),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }
}
