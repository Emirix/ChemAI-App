import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:chem_ai/core/constants/api_constants.dart';

class FeedbackService {
  static String get baseUrl => ApiConstants.baseUrl;

  /// Submit user feedback
  Future<Map<String, dynamic>> submitFeedback({
    required String userId,
    required String type,
    required String subject,
    required String message,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/feedback/submit'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'user_id': userId,
          'type': type,
          'subject': subject,
          'message': message,
        }),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 201 && data['success'] == true) {
        return data;
      } else {
        throw Exception(data['error'] ?? 'Failed to submit feedback');
      }
    } catch (e) {
      print('Error submitting feedback: $e');
      rethrow;
    }
  }

  /// Get user's feedback history
  Future<List<Map<String, dynamic>>> getUserFeedback({
    required String userId,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/feedback/user/$userId').replace(
        queryParameters: {
          'limit': limit.toString(),
          'offset': offset.toString(),
        },
      );

      final response = await http.get(uri);
      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return List<Map<String, dynamic>>.from(data['data']);
      } else {
        throw Exception(data['error'] ?? 'Failed to fetch feedback');
      }
    } catch (e) {
      print('Error fetching user feedback: $e');
      rethrow;
    }
  }

  /// Test Telegram connection (for debugging)
  Future<Map<String, dynamic>> testTelegram() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/feedback/test-telegram'),
      );

      final data = json.decode(response.body);
      return data;
    } catch (e) {
      print('Error testing Telegram: $e');
      rethrow;
    }
  }
}
