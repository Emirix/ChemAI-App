class ChatMessage {
  final String content;
  final String role; // 'user' or 'assistant'
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;
  final List<String>? suggestedQuestions;

  ChatMessage({
    required this.content,
    required this.role,
    DateTime? timestamp,
    this.metadata,
    this.suggestedQuestions,
  }) : timestamp = timestamp ?? DateTime.now();

  bool get isUser => role == 'user';
}
