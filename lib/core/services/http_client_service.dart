import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

/// Optimized HTTP client service with connection pooling and retry logic
class HttpClientService {
  static final HttpClientService _instance = HttpClientService._internal();
  factory HttpClientService() => _instance;
  HttpClientService._internal();

  late final http.Client _client;
  bool _initialized = false;

  /// Initialize the HTTP client (call once at app startup)
  void initialize() {
    if (!_initialized) {
      _client = http.Client();
      _initialized = true;
      debugPrint('✅ HttpClientService initialized with connection pooling');
    }
  }

  /// Get the shared HTTP client instance
  http.Client get client {
    if (!_initialized) {
      initialize();
    }
    return _client;
  }

  /// Make a POST request with automatic retry logic
  Future<http.Response> postWithRetry(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Duration timeout = const Duration(seconds: 60),
    int maxRetries = 3,
  }) async {
    int retryCount = 0;
    Duration retryDelay = const Duration(seconds: 1);

    while (retryCount < maxRetries) {
      try {
        debugPrint('🌐 HTTP POST: $url (attempt ${retryCount + 1}/$maxRetries)');
        
        final response = await client
            .post(url, headers: headers, body: body)
            .timeout(timeout);

        if (response.statusCode >= 200 && response.statusCode < 300) {
          debugPrint('✅ HTTP POST success: ${response.statusCode}');
          return response;
        } else if (response.statusCode >= 500) {
          // Server error - retry
          throw Exception('Server error: ${response.statusCode}');
        } else {
          // Client error - don't retry
          debugPrint('⚠️ HTTP POST client error: ${response.statusCode}');
          return response;
        }
      } catch (e) {
        retryCount++;
        
        if (retryCount >= maxRetries) {
          debugPrint('❌ HTTP POST failed after $maxRetries attempts: $e');
          rethrow;
        }

        debugPrint('⚠️ HTTP POST failed, retrying in ${retryDelay.inSeconds}s... ($e)');
        await Future.delayed(retryDelay);
        
        // Exponential backoff
        retryDelay *= 2;
      }
    }

    throw Exception('Max retries exceeded');
  }

  /// Make a GET request with automatic retry logic
  Future<http.Response> getWithRetry(
    Uri url, {
    Map<String, String>? headers,
    Duration timeout = const Duration(seconds: 30),
    int maxRetries = 3,
  }) async {
    int retryCount = 0;
    Duration retryDelay = const Duration(seconds: 1);

    while (retryCount < maxRetries) {
      try {
        debugPrint('🌐 HTTP GET: $url (attempt ${retryCount + 1}/$maxRetries)');
        
        final response = await client
            .get(url, headers: headers)
            .timeout(timeout);

        if (response.statusCode >= 200 && response.statusCode < 300) {
          debugPrint('✅ HTTP GET success: ${response.statusCode}');
          return response;
        } else if (response.statusCode >= 500) {
          throw Exception('Server error: ${response.statusCode}');
        } else {
          debugPrint('⚠️ HTTP GET client error: ${response.statusCode}');
          return response;
        }
      } catch (e) {
        retryCount++;
        
        if (retryCount >= maxRetries) {
          debugPrint('❌ HTTP GET failed after $maxRetries attempts: $e');
          rethrow;
        }

        debugPrint('⚠️ HTTP GET failed, retrying in ${retryDelay.inSeconds}s... ($e)');
        await Future.delayed(retryDelay);
        retryDelay *= 2;
      }
    }

    throw Exception('Max retries exceeded');
  }

  /// Dispose the client when app is closing
  void dispose() {
    if (_initialized) {
      _client.close();
      _initialized = false;
      debugPrint('🔒 HttpClientService disposed');
    }
  }
}
