import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:chem_ai/models/news_article.dart';
import '../core/constants/api_constants.dart';

class NewsService {
  static String get baseUrl => ApiConstants.baseUrl;

  /// Get news articles
  Future<List<NewsArticle>> getNews({
    int limit = 20,
    int offset = 0,
    String? category,
    String language = 'tr',
  }) async {
    try {
      // Enforce valid languages (tr or en)
      String effectiveLanguage = (language == 'en') ? 'en' : 'tr';
      
      final queryParams = {
        'limit': limit.toString(),
        'offset': offset.toString(),
        'language': effectiveLanguage,
      };

      if (category != null && category.isNotEmpty) {
        queryParams['category'] = category;
      }

      final uri = Uri.parse(
        '$baseUrl/news',
      ).replace(queryParameters: queryParams);

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['success'] == true && data['data'] != null) {
          final List<dynamic> newsData = data['data'];
          return newsData.map((item) => NewsArticle.fromJson(item)).toList();
        }
      }

      throw Exception('Failed to load news');
    } catch (e) {
      print('Error fetching news: $e');
      rethrow;
    }
  }

  /// Get news categories
  Future<List<NewsCategory>> getCategories() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/news/categories'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['success'] == true && data['data'] != null) {
          final List<dynamic> categoriesData = data['data'];
          return categoriesData
              .map((item) => NewsCategory.fromJson(item))
              .toList();
        }
      }

      throw Exception('Failed to load categories');
    } catch (e) {
      print('Error fetching categories: $e');
      rethrow;
    }
  }

  /// Trigger manual daily news fetch (admin/debug)
  Future<Map<String, dynamic>> fetchDailyNews() async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/news/fetch-daily'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data;
      }

      throw Exception('Failed to trigger daily news fetch');
    } catch (e) {
      print('Error triggering daily news fetch: $e');
      rethrow;
    }
  }
}
