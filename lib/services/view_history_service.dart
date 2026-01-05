import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ViewHistoryItem {
  final int id;
  final String title;
  final String subtitle;
  final String type; // 'msds', 'tds', 'msds_pdf', 'tds_pdf'
  final DateTime createdAt;
  final Map<String, dynamic> metadata;

  ViewHistoryItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.type,
    required this.createdAt,
    this.metadata = const {},
  });

  factory ViewHistoryItem.fromJson(Map<String, dynamic> json) {
    return ViewHistoryItem(
      id: json['id'],
      title: json['title'] ?? '',
      subtitle: json['subtitle'] ?? '',
      type: json['type'] ?? 'unknown',
      createdAt: DateTime.parse(json['created_at']).toLocal(),
      metadata: json['metadata'] is Map ? json['metadata'] : {},
    );
  }

  bool get isDocument => type.endsWith('_pdf');
}

class ViewHistoryService extends ChangeNotifier {
  static final ViewHistoryService _instance = ViewHistoryService._internal();
  factory ViewHistoryService() => _instance;
  ViewHistoryService._internal();

  final _supabase = Supabase.instance.client;

  Future<void> addEntry({
    required String title,
    required String subtitle,
    required String type,
    Map<String, dynamic>? metadata,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    try {
      await _supabase.from('view_history').insert({
        'user_id': user.id,
        'title': title,
        'subtitle': subtitle,
        'type': type,
        'metadata': metadata ?? {},
        'created_at': DateTime.now().toUtc().toIso8601String(),
      });
      notifyListeners();
    } catch (e) {
      // Fail silently or log
      debugPrint('Error adding view history: $e');
    }
  }

  Future<List<ViewHistoryItem>> getHistory({int limit = 20}) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return [];

    try {
      final response = await _supabase
          .from('view_history')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false)
          .limit(limit);

      return (response as List)
          .map((e) => ViewHistoryItem.fromJson(e))
          .toList();
    } catch (e) {
      debugPrint('Error fetching view history: $e');
      return [];
    }
  }
}
