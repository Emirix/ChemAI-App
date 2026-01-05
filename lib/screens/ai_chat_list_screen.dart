import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:chem_ai/screens/chat_screen.dart';
import 'package:chem_ai/services/chat_service.dart';
import 'package:chem_ai/core/services/profile_service.dart';
import 'package:chem_ai/core/constants/app_colors.dart';
import 'package:material_symbols_icons/symbols.dart';

class AiChatListScreen extends StatefulWidget {
  const AiChatListScreen({super.key});

  @override
  State<AiChatListScreen> createState() => _AiChatListScreenState();
}

class _AiChatListScreenState extends State<AiChatListScreen> {
  final ChatService _chatService = ChatService();
  final ProfileService _profileService = ProfileService();

  List<ChatConversation> recentChats = [];
  List<ChatConversation> olderChats = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadChats();
  }

  Future<void> _loadChats() async {
    setState(() => isLoading = true);

    final userId = _profileService.userId;
    if (userId == null) {
      if (mounted) setState(() => isLoading = false);
      return;
    }

    try {
      final sessions = await _chatService.getSessions(userId);
      if (!mounted) return;

      final chats = sessions.map((session) {
        return ChatConversation(
          id: session['id'],
          title: session['title'] ?? 'İsimsiz Sohbet',
          icon: 'chat',
          iconColor: AppColors.primary,
          iconBgColor: AppColors.primary.withValues(alpha: 0.1),
          preview: 'Sohbet geçmişini görüntülemek için tıklayın...',
          timestamp: DateTime.parse(session['created_at']),
          messages: [],
        );
      }).toList();

      final now = DateTime.now();
      final oneWeekAgo = now.subtract(const Duration(days: 7));

      if (mounted) {
        setState(() {
          recentChats = chats
              .where((chat) => chat.timestamp.isAfter(oneWeekAgo))
              .toList();
          olderChats = chats
              .where((chat) => chat.timestamp.isBefore(oneWeekAgo))
              .toList();
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading chats: $e');
      if (mounted) setState(() => isLoading = false);
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inHours < 24) {
      return DateFormat('HH:mm').format(timestamp);
    } else if (difference.inDays < 2) {
      return 'Yesterday';
    } else if (difference.inDays < 365) {
      return DateFormat('MMM dd').format(timestamp);
    } else {
      return DateFormat('MMM dd, yyyy').format(timestamp);
    }
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'science':
        return Icons.science;
      case 'biotech':
        return Icons.biotech;
      case 'eco':
        return Icons.eco;
      case 'warning':
        return Icons.warning;
      case 'lab_profile':
        return Icons.science_outlined;
      case 'vial':
        return Icons.science;
      case 'chemistry':
        return Icons.science;
      case 'experiment':
        return Icons.science;
      case 'safety':
        return Icons.shield;
      default:
        return Symbols.chat;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0f1923)
          : const Color(0xFFf5f7f8),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              decoration: BoxDecoration(
                color: (isDark ? const Color(0xFF1c262f) : Colors.white)
                    .withOpacity(0.8),
                border: Border(
                  bottom: BorderSide(
                    color: isDark
                        ? const Color(0xFF374151)
                        : const Color(0xFFE5E7EB),
                    width: 1,
                  ),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back),
                    color: isDark
                        ? const Color(0xFF9ca3af)
                        : const Color(0xFF637788),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'AI Chat',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? const Color(0xFFe0e6ed)
                                : const Color(0xFF111518),
                          ),
                        ),
                        Text(
                          'Geçmiş sohbetleriniz',
                          style: GoogleFonts.notoSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: isDark
                                ? const Color(0xFF9ca3af)
                                : const Color(0xFF637788),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFF374151)
                            : const Color(0xFFE5E7EB),
                      ),
                      color: AppColors.primary.withValues(alpha: 0.1),
                    ),
                    child: const Icon(
                      Icons.person,
                      size: 20,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : RefreshIndicator(
                      onRefresh: _loadChats,
                      child: ListView(
                        padding: const EdgeInsets.only(bottom: 80),
                        children: [
                          // Hero Banner
                          _buildHeroBanner(),

                          // Recent Chats
                          if (recentChats.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'SON SOHBETLER',
                                    style: GoogleFonts.spaceGrotesk(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: isDark
                                          ? const Color(0xFF9ca3af)
                                          : const Color(0xFF637788),
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  ...recentChats.map(
                                    (chat) => _buildChatItem(chat, isDark),
                                  ),
                                ],
                              ),
                            ),

                          // Older Chats
                          if (olderChats.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'ÖNCEKİLER',
                                    style: GoogleFonts.spaceGrotesk(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: isDark
                                          ? const Color(0xFF9ca3af)
                                          : const Color(0xFF637788),
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  ...olderChats.map(
                                    (chat) => _buildChatItem(chat, isDark),
                                  ),
                                ],
                              ),
                            ),

                          if (recentChats.isEmpty && olderChats.isEmpty)
                            Padding(
                              padding: const EdgeInsets.all(32.0),
                              child: Center(
                                child: Text(
                                  'Henüz bir sohbet geçmişiniz yok.',
                                  style: TextStyle(
                                    color: isDark
                                        ? Colors.white54
                                        : Colors.grey,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // New Chat -> sessionId: null
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ChatScreen(sessionId: null),
            ),
          ).then((_) => _loadChats()); // Döndüğünde listeyi güncelle
        },
        backgroundColor: const Color(0xFF359EFF),
        icon: const Icon(Icons.add_comment),
        label: const Text('New Chat'),
      ),
    );
  }

  Widget _buildHeroBanner() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF359EFF), Color(0xFF2563EB)],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 40, 16, 24),
      child: Stack(
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: 0.2,
              child: CustomPaint(painter: DotPatternPainter()),
            ),
          ),
          Positioned(
            right: -30,
            top: -30,
            child: Transform.rotate(
              angle: 0.26,
              child: Icon(
                Icons.smart_toy,
                size: 150,
                color: Colors.white.withOpacity(0.4),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.science,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'AI ASİSTAN',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Kimyager Asistanı\nile Sohbet Edin',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Reaksiyonlar, stokiyometri ve laboratuvar güvenliği hakkında karmaşık sorular sorun.',
                style: GoogleFonts.notoSans(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChatItem(ChatConversation chat, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1c262f) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // Existing Chat -> sessionId: chat.id
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChatScreen(sessionId: chat.id),
              ),
            ).then((_) => _loadChats()); // Döndüğünde listeyi güncelle
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isDark
                        ? chat.iconColor.withOpacity(0.2)
                        : chat.iconBgColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    _getIconData(chat.icon),
                    color: chat.iconColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              chat.title,
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? const Color(0xFFe0e6ed)
                                    : const Color(0xFF111518),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _formatTimestamp(chat.timestamp),
                            style: GoogleFonts.notoSans(
                              fontSize: 10,
                              color: isDark
                                  ? const Color(0xFF9ca3af)
                                  : const Color(0xFF637788),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        chat.preview,
                        style: GoogleFonts.notoSans(
                          fontSize: 14,
                          color: isDark
                              ? const Color(0xFF9ca3af)
                              : const Color(0xFF637788),
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ChatConversation {
  final String id;
  final String title;
  final String icon;
  final Color iconColor;
  final Color iconBgColor;
  final String preview;
  final DateTime timestamp;
  final List<Map<String, dynamic>> messages;

  ChatConversation({
    required this.id,
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
    required this.preview,
    required this.timestamp,
    required this.messages,
  });
}

class DotPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..style = PaintingStyle.fill;

    const spacing = 10.0;
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
