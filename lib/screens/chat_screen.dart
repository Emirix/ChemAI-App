import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:chem_ai/core/constants/app_colors.dart';
import 'package:chem_ai/models/chat_message.dart';
import 'package:chem_ai/services/chat_service.dart';
import 'package:chem_ai/core/services/profile_service.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:intl/intl.dart';
import 'package:chem_ai/screens/ai_chat_list_screen.dart';
import 'package:chem_ai/core/utils/navigation_utils.dart';
import 'package:chem_ai/core/services/subscription_service.dart';
import 'package:chem_ai/screens/plus_membership_screen.dart';
import 'package:chem_ai/widgets/custom_header.dart';
import 'package:chem_ai/core/utils/language_utils.dart';

class ChatScreen extends StatefulWidget {
  final String? sessionId;
  final String? initialMessage;
  const ChatScreen({super.key, this.sessionId, this.initialMessage});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ChatService _chatService = ChatService();
  final ProfileService _profileService = ProfileService();

  List<ChatMessage> _messages = [];
  bool _isLoading = false;
  bool _isMessagesLoading = false;
  String? _userAvatarUrl;
  String? _activeSessionId;
  List<dynamic> _sessions = [];

  bool _showSessionList = false;
  bool _limitReached = false;

  @override
  void initState() {
    super.initState();
    _checkLimit(); // Check limit on init
    _activeSessionId = widget.sessionId;
    _loadUserData();

    // Eğer sessionId verildiyse o session'ı yükle, yoksa yeni chat başlat
    if (_activeSessionId != null) {
      _selectSession(_activeSessionId);
    } else {
      // Yeni Chat Modu
      _messages = [
        ChatMessage(
          role: 'assistant',
          content:
              'Merhaba! Ben ChemAI Kimyager asistanıyım. Nasıl yardımcı olabilirim?',
        ),
      ];

      if (widget.initialMessage != null) {
        _messageController.text = widget.initialMessage!;
      }
    }
  }

  Future<void> _loadUserData() async {
    try {
      final profile = await _profileService.getProfile();
      if (profile != null && mounted) {
        setState(() {
          _userAvatarUrl = profile['avatar_url'];
        });
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
    }
  }

  // Session listesini sadece gerekirse yükle (şu an liste dışarıda olduğu için buna pek ihtiyaç olmayabilir ama active session değişirse diye kalabilir)
  Future<void> _loadSessions() async {
    // Session listesi artık AiChatListScreen'de yönetiliyor
  }

  Future<void> _selectSession(String? sessionId) async {
    setState(() {
      _activeSessionId = sessionId;
      _messages = [];
    });

    if (sessionId == null) {
      // New Chat
      setState(() {
        _messages = [
          ChatMessage(
            role: 'assistant',
            content:
                'Merhaba! Ben ChemAI Kimyager asistanıyım. Nasıl yardımcı olabilirim?',
          ),
        ];
      });
      return;
    }

    setState(() => _isMessagesLoading = true);
    try {
      final messagesData = await _chatService.getMessages(sessionId);
      if (mounted) {
        setState(() {
          _messages = messagesData
              .map(
                (m) => ChatMessage(
                  role: m['role'],
                  content: m['content'],
                  timestamp: DateTime.parse(m['created_at']),
                ),
              )
              .toList();
        });
        _scrollToBottom();
      }
    } finally {
      if (mounted) setState(() => _isMessagesLoading = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _handleSendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isLoading) return;

    final userId = _profileService.userId;

    setState(() {
      _messages.add(ChatMessage(role: 'user', content: text));
      _messageController.clear();
      _isLoading = true;
    });

    _scrollToBottom();

    try {
      final history = _messages.map((msg) {
        return {
          'role': msg.role == 'user' ? 'user' : 'model',
          'parts': [
            {'text': msg.content},
          ],
        };
      }).toList();

      final response = await _chatService.sendMessage(
        message: text,
        language: LanguageUtils.getLanguageString(context),
        sessionId: _activeSessionId,
        userId: userId,
        history: history.sublist(0, history.length - 1),
      );

      if (response['success']) {
        if (_activeSessionId == null) {
          _activeSessionId = response['data']['sessionId'];
          _loadSessions(); // Refresh sessions list
        }
        setState(() {
          final suggestedQuestions =
              (response['data']['suggestedQuestions'] as List?)
                  ?.map((q) => q.toString())
                  .toList();

          _messages.add(
            ChatMessage(
              role: 'assistant',
              content: response['data']['content'],
              suggestedQuestions: suggestedQuestions,
            ),
          );
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hata oluştu, lütfen tekrar deneyin.')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
      _checkLimit(); // Re-check limit after message sent
      _scrollToBottom();
    }
  }

  Future<void> _checkLimit() async {
    final canSend = await SubscriptionService().checkDailyAiMessageLimit();
    if (mounted) {
      setState(() {
        _limitReached = !canSend;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : AppColors.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.arrow_back_ios_new,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: CustomHeader(title: 'Kimyager Asistanı'),
                  ),
                ],
              ),
            ),
            Expanded(child: _buildChatArea(isDark)),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionList(bool isDark) {
    return Column(
      children: [
        // New Chat Button at the top
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: InkWell(
            onTap: () => _selectSession(null),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary,
                    AppColors.primary.withValues(alpha: 0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Symbols.chat_add_on, color: Colors.white, fill: 1),
                  const SizedBox(width: 12),
                  Text(
                    'Yeni Sohbet Başlat',
                    style: GoogleFonts.spaceGrotesk(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Row(
            children: [
              Text(
                'Geçmiş Sohbetler',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _sessions.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Symbols.chat_bubble,
                        size: 48,
                        color: Colors.grey.withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Henüz bir sohbet geçmişi yok',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _sessions.length,
                  itemBuilder: (context, index) {
                    final session = _sessions[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        onTap: () => _selectSession(session['id']),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        tileColor: isDark
                            ? AppColors.surfaceDark
                            : Colors.white,
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Symbols.chat,
                            color: AppColors.primary,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          session['title'] ?? 'İsimsiz Sohbet',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          DateFormat(
                            'dd.MM.yyyy HH:mm',
                          ).format(DateTime.parse(session['created_at'])),
                          style: const TextStyle(fontSize: 12),
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildChatArea(bool isDark) {
    if (_isMessagesLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            itemCount: _messages.length + (_isLoading ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == _messages.length && _isLoading) {
                return _buildTypingIndicator(isDark);
              }
              return _buildMessageBubble(_messages[index], isDark);
            },
          ),
        ),
        _buildInputArea(isDark),
      ],
    );
  }

  Widget _buildMessageBubble(ChatMessage message, bool isDark) {
    bool isUser = message.isUser;
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
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary,
                    AppColors.primary.withValues(alpha: 1).withBlue(255),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Symbols.smart_toy,
                color: Colors.white,
                size: 14,
              ),
            ),
            const SizedBox(width: 12),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isUser
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isUser
                        ? AppColors.primary
                        : (isDark ? AppColors.surfaceDark : Colors.white),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isUser ? 16 : 0),
                      bottomRight: Radius.circular(isUser ? 0 : 16),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: isUser
                      ? Text(
                          message.content,
                          style: GoogleFonts.notoSans(
                            fontSize: 14,
                            color: Colors.white,
                            height: 1.5,
                          ),
                        )
                      : MarkdownBody(
                          data: message.content,
                          selectable: true,
                          styleSheet: MarkdownStyleSheet(
                            p: GoogleFonts.notoSans(
                              fontSize: 14,
                              color: isDark
                                  ? Colors.white
                                  : AppColors.textMainLight,
                              height: 1.6,
                            ),
                            h1: GoogleFonts.spaceGrotesk(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? Colors.white
                                  : AppColors.textMainLight,
                              height: 1.4,
                            ),
                            h2: GoogleFonts.spaceGrotesk(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? Colors.white
                                  : AppColors.textMainLight,
                              height: 1.4,
                            ),
                            h3: GoogleFonts.spaceGrotesk(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? Colors.white
                                  : AppColors.textMainLight,
                              height: 1.4,
                            ),
                            strong: GoogleFonts.notoSans(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? Colors.white
                                  : AppColors.textMainLight,
                            ),
                            em: GoogleFonts.notoSans(
                              fontSize: 14,
                              fontStyle: FontStyle.italic,
                              color: isDark
                                  ? Colors.white70
                                  : AppColors.textSecondaryLight,
                            ),
                            code: GoogleFonts.firaCode(
                              fontSize: 13,
                              color: isDark
                                  ? Colors.amber[300]
                                  : Colors.purple[700],
                              backgroundColor: isDark
                                  ? Colors.black26
                                  : Colors.grey[200],
                            ),
                            codeblockDecoration: BoxDecoration(
                              color: isDark ? Colors.black38 : Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isDark ? Colors.white12 : Colors.black12,
                              ),
                            ),
                            codeblockPadding: const EdgeInsets.all(12),
                            blockquote: GoogleFonts.notoSans(
                              fontSize: 14,
                              color: isDark
                                  ? Colors.white70
                                  : AppColors.textSecondaryLight,
                              fontStyle: FontStyle.italic,
                            ),
                            blockquoteDecoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.05)
                                  : Colors.grey[100],
                              borderRadius: BorderRadius.circular(4),
                              border: Border(
                                left: BorderSide(
                                  color: AppColors.primary,
                                  width: 3,
                                ),
                              ),
                            ),
                            blockquotePadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            listBullet: GoogleFonts.notoSans(
                              fontSize: 14,
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                            listIndent: 24,
                            h1Padding: const EdgeInsets.only(
                              top: 16,
                              bottom: 8,
                            ),
                            h2Padding: const EdgeInsets.only(
                              top: 12,
                              bottom: 6,
                            ),
                            h3Padding: const EdgeInsets.only(top: 8, bottom: 4),
                            pPadding: const EdgeInsets.only(bottom: 8),
                            blockSpacing: 8,
                          ),
                        ),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('HH:mm').format(message.timestamp),
                  style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                ),
                // Suggested Questions Chips
                if (!isUser &&
                    message.suggestedQuestions != null &&
                    message.suggestedQuestions!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: message.suggestedQuestions!.map((question) {
                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            _messageController.text = question;
                            _handleSendMessage();
                          },
                          borderRadius: BorderRadius.circular(24),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.primary,
                                  AppColors.primary.withValues(alpha: 0.85),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withValues(
                                    alpha: 0.3,
                                  ),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Symbols.arrow_forward,
                                  size: 16,
                                  color: Colors.white,
                                  fill: 1,
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    question,
                                    style: GoogleFonts.notoSans(
                                      fontSize: 13,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 12),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                shape: BoxShape.circle,
                color: Colors.grey[300],
                image: _userAvatarUrl != null
                    ? DecorationImage(
                        image: NetworkImage(_userAvatarUrl!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: _userAvatarUrl == null
                  ? const Icon(Icons.person, size: 20, color: Colors.grey)
                  : null,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTypingIndicator(bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary,
                  AppColors.primary.withValues(alpha: 0.8),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(Symbols.smart_toy, color: Colors.white, size: 14),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const _ChemicalLoadingAnimation(),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea(bool isDark) {
    if (_limitReached) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          border: Border(
            top: BorderSide(color: isDark ? Colors.white10 : Colors.black12),
          ),
        ),
        child: Column(
          children: [
            const Icon(Symbols.lock, color: Colors.amber, size: 24),
            const SizedBox(height: 8),
            const Text(
              'Günlük mesaj limitine ulaştınız.',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text(
              'Sınırsız sohbet için Plus üyeliğe geçin.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () {
                  NavigationUtils.pushWithSlide(
                    context,
                    const PlusMembershipScreen(),
                  );
                },
                icon: const Icon(Symbols.diamond, size: 16),
                label: const Text('Plus\'a Geç'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.backgroundDark.withValues(alpha: 0.95)
            : Colors.white.withValues(alpha: 0.95),
        border: Border(
          top: BorderSide(color: isDark ? Colors.white10 : Colors.black12),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : Colors.grey[100],
                borderRadius: BorderRadius.circular(24),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _messageController,
                maxLines: 4,
                minLines: 1,
                decoration: const InputDecoration(
                  hintText: 'Mesajınızı yazın...',
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _handleSendMessage,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Symbols.send,
                color: Colors.white,
                size: 24,
                fill: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Chemical Loading Animation Widget
class _ChemicalLoadingAnimation extends StatefulWidget {
  const _ChemicalLoadingAnimation();

  @override
  State<_ChemicalLoadingAnimation> createState() =>
      _ChemicalLoadingAnimationState();
}

class _ChemicalLoadingAnimationState extends State<_ChemicalLoadingAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return SizedBox(
          width: 80,
          height: 40,
          child: CustomPaint(
            painter: _ChemicalBeakerPainter(_controller.value),
          ),
        );
      },
    );
  }
}

class _ChemicalBeakerPainter extends CustomPainter {
  final double animationValue;

  _ChemicalBeakerPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final beakerWidth = size.width / 3 - 4;
    final beakerHeight = size.height * 0.7;

    // Draw three beakers
    for (int i = 0; i < 3; i++) {
      final xOffset = i * (beakerWidth + 6);

      // Beaker colors
      final colors = [
        AppColors.primary.withValues(alpha: 0.3),
        Colors.purple.withValues(alpha: 0.3),
        Colors.green.withValues(alpha: 0.3),
      ];

      // Draw beaker
      final beakerPaint = Paint()
        ..color = colors[i]
        ..style = PaintingStyle.fill;

      final beakerRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          xOffset,
          size.height - beakerHeight,
          beakerWidth,
          beakerHeight,
        ),
        const Radius.circular(2),
      );
      canvas.drawRRect(beakerRect, beakerPaint);

      // Draw beaker outline
      final outlinePaint = Paint()
        ..color = colors[i].withValues(alpha: 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawRRect(beakerRect, outlinePaint);

      // Draw bubbles
      final bubbleColors = [AppColors.primary, Colors.purple, Colors.green];

      for (int j = 0; j < 3; j++) {
        final bubbleOffset = (animationValue + j * 0.33) % 1.0;
        final bubbleY =
            size.height -
            beakerHeight * 0.2 -
            (bubbleOffset * beakerHeight * 0.6);
        final bubbleX = xOffset + beakerWidth / 2 + (j % 2 == 0 ? 3 : -3);
        final bubbleSize = 3.0 - (bubbleOffset * 1.5);

        final bubblePaint = Paint()
          ..color = bubbleColors[i].withValues(alpha: 1.0 - bubbleOffset)
          ..style = PaintingStyle.fill;

        canvas.drawCircle(Offset(bubbleX, bubbleY), bubbleSize, bubblePaint);
      }
    }
  }

  @override
  bool shouldRepaint(_ChemicalBeakerPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}
