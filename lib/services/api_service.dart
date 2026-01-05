import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/safety_data.dart';
import '../models/tds_data.dart';
import 'package:flutter/foundation.dart';
import 'dart:io' show SocketException;
import '../core/constants/api_constants.dart';
import '../core/services/http_client_service.dart';

class ApiService {
  static String get baseUrl => ApiConstants.baseUrl;
  final _httpClient = HttpClientService();

  Future<Map<String, dynamic>?> getSafetyData(String productName, String language, {String? userId}) async {
    final url = '$baseUrl/safety-data';
    debugPrint('ApiService: Requesting safety data for $productName at $url');
    try {
      final response = await _httpClient.postWithRetry(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'productName': productName,
          'language': language,
          if (userId != null) 'userId': userId,
        }),
        timeout: const Duration(seconds: 60),
        maxRetries: 2,
      );

      debugPrint('ApiService: Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> result = jsonDecode(response.body);
        if (result['success'] == true) {
          debugPrint('ApiService: Success, parsing data...');
          return {
            'data': SafetyData.fromJson(result['data']),
            'cached': result['cached'] == true,
          };
        } else {
          debugPrint('ApiService: Error from API: ${result['error']}');
        }
      } else {
        debugPrint('ApiService: Server returned error: ${response.body}');
      }
      return null;
    } on SocketException catch (e) {
      debugPrint('ApiService: Connection error (SocketException): $e');
      return null;
    } catch (e) {
      debugPrint('ApiService: Error: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> getRawMaterialDetails(
    String productName,
    String language,
  ) async {
    final url = '$baseUrl/raw-material-details';
    debugPrint(
      'ApiService: Requesting raw material details for $productName at $url',
    );
    try {
      final response = await _httpClient.postWithRetry(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'productName': productName,
          'language': language,
        }),
        timeout: const Duration(seconds: 60),
        maxRetries: 2,
      );

      if (response.statusCode == 200) {
        // Backend currently returns the JSON object directly (aiData) or result.data depending on structure.
        // My controller returns res.json(aiData) or storedData.data.
        // Stored data structure in DB: { ..., data: { ... } }. Controller returns `existingData.data` which is the JSON.
        // So generic response is the JSON map.
        // However, if there was an error, it might be { error: ... }
        final dynamic result = jsonDecode(response.body);
        if (result is Map<String, dynamic> && !result.containsKey('error')) {
          return result;
        } else {
          debugPrint('ApiService: Error from API: ${result['error']}');
        }
      } else {
        debugPrint('ApiService: Server returned error: ${response.body}');
      }
      return null;
    } catch (e) {
      debugPrint('ApiService: Error getting raw material details: $e');
      return null;
    }
  }

  Future<Map<String, String>?> generateChatMetadata(
    List<Map<String, dynamic>> messages,
  ) async {
    final url = '$baseUrl/chat/generate-metadata';
    debugPrint('ApiService: Generating chat metadata at $url');
    try {
      final response = await _httpClient.postWithRetry(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'messages': messages}),
        timeout: const Duration(seconds: 20),
        maxRetries: 2,
      );

      debugPrint('ApiService: Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> result = jsonDecode(response.body);
        if (result['success'] == true) {
          debugPrint('ApiService: Success, metadata generated');
          return {
            'title': result['data']['title'] as String,
            'icon': result['data']['icon'] as String,
          };
        } else {
          debugPrint('ApiService: Error from API: ${result['error']}');
        }
      } else {
        debugPrint('ApiService: Server returned error: ${response.body}');
      }
      return null;
    } on SocketException catch (e) {
      debugPrint('ApiService: Connection error (SocketException): $e');
      return null;
    } catch (e) {
      if (e.toString().contains('TimeoutException')) {
        debugPrint('ApiService: Request timed out after 30 seconds');
      } else {
        debugPrint('ApiService: Unknown error: $e');
      }
      return null;
    }
  }

  Future<Map<String, dynamic>?> getTdsData(String productName, String language, {String? userId}) async {
    final url = '$baseUrl/tds-data';
    debugPrint('ApiService: Requesting TDS data for $productName at $url');
    try {
      final response = await _httpClient.postWithRetry(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'productName': productName,
          'language': language,
          if (userId != null) 'userId': userId,
        }),
        timeout: const Duration(seconds: 60),
        maxRetries: 2,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> result = jsonDecode(response.body);
        if (result['success'] == true) {
          return {
            'data': TdsData.fromJson(result['data']),
            'cached': result['cached'] == true,
          };
        }
      }
      return null;
    } catch (e) {
      debugPrint('ApiService: Error getting TDS data: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> identifyChemicalFromText(
    String text,
    String language,
  ) async {
    final url = '$baseUrl/identify-chemical';
    try {
      final response = await _httpClient.postWithRetry(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'text': text,
          'language': language,
        }),
        timeout: const Duration(seconds: 30),
        maxRetries: 2,
      );

      debugPrint('ApiService: response status code: ${response.statusCode}');
      if (response.statusCode == 200) {
        final Map<String, dynamic> result = jsonDecode(response.body);
        debugPrint('ApiService: Decoded JSON: $result');
        if (result['status'] == 'success') {
          return result['data'];
        } else {
          debugPrint('ApiService: Identified status was not success: ${result['status']}');
        }
      } else {
        debugPrint('ApiService: identifyChemicalFromText server error: ${response.body}');
      }
      return null;
    } catch (e) {
      debugPrint('ApiService: identifyChemicalFromText exception: $e');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>?> searchSuppliers(String query) async {
    final url = '$baseUrl/suppliers/search';
    debugPrint('ApiService: Searching suppliers for $query at $url');
    try {
      final response = await _httpClient.postWithRetry(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'query': query}),
        timeout: const Duration(seconds: 30),
        maxRetries: 2,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> result = jsonDecode(response.body);
        if (result['success'] == true) {
          return List<Map<String, dynamic>>.from(result['data']);
        }
      }
      return null;
    } catch (e) {
      debugPrint('ApiService: Error searching suppliers: $e');
      return null;
    }
  }
}
