import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:chem_ai/core/constants/api_constants.dart';
import 'package:chem_ai/core/services/subscription_service.dart';
import 'package:chem_ai/core/services/http_client_service.dart';
import 'package:chem_ai/services/analytics_service.dart';

class ChatService {
  final String baseUrl = ApiConstants.baseUrl;
  final _supabase = Supabase.instance.client;
  final _httpClient = HttpClientService();

  Future<Map<String, dynamic>> sendMessage({
    required String message,
    required String language,
    String? sessionId,
    String? userId,
    List<Map<String, dynamic>> history = const [],
  }) async {
    AnalyticsService().logEvent(
      name: 'chat_send_message',
      parameters: {
        'language': language,
        'message_length': message.length,
        'has_history': history.isNotEmpty,
      },
    );
    try {
      // Check Subscription Limit
      final canSend = await SubscriptionService().checkDailyAiMessageLimit();
      if (!canSend) {
        throw Exception(
          'Günlük mesaj limitine ulaştınız. Devam etmek için Plus\'a geçin.',
        );
      }

      // 1. Manage Session and User Message in DB
      String effectiveSessionId = sessionId ?? '';

      if (sessionId == null && userId != null) {
        final title = message.length > 40
            ? '${message.substring(0, 40)}...'
            : message;
        final sessionData = await _supabase
            .from('chat_sessions')
            .insert({'user_id': userId, 'title': title})
            .select()
            .single();
        effectiveSessionId = sessionData['id'];
      }

      // Save User Message
      if (effectiveSessionId.isNotEmpty) {
        await _supabase.from('chat_messages').insert({
          'session_id': effectiveSessionId,
          'user_id': userId,
          'role': 'user',
          'content': message,
        });
      }

      // 2. Get AI Response from Backend with optimized HTTP client
      final response = await _httpClient.postWithRetry(
        Uri.parse('$baseUrl/chat'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'message': message,
          'language': language,
          'history': history,
        }),
        timeout: const Duration(seconds: 30),
        maxRetries: 1,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final aiContent = data['data']['content'];

        // 3. Save AI Response to DB
        if (effectiveSessionId.isNotEmpty) {
          await _supabase.from('chat_messages').insert({
            'session_id': effectiveSessionId,
            'user_id': userId,
            'role': 'assistant',
            'content': aiContent,
          });
        }

        return {
          'success': true,
          'data': {'sessionId': effectiveSessionId, 'content': aiContent},
        };
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('ChatService Error: $e');
      rethrow;
    }
  }

  Future<List<dynamic>> getSessions(String userId) async {
    try {
      final data = await _supabase
          .from('chat_sessions')
          .select('*')
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      return data;
    } catch (e) {
      debugPrint('Error fetching sessions: $e');
      return [];
    }
  }

  Future<List<dynamic>> getMessages(String sessionId) async {
    try {
      final data = await _supabase
          .from('chat_messages')
          .select('*')
          .eq('session_id', sessionId)
          .order('created_at', ascending: true);
      return data;
    } catch (e) {
      debugPrint('Error fetching messages: $e');
      return [];
    }
  }
}
