import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class SearchHistoryService extends ChangeNotifier {
  static final SearchHistoryService _instance =
      SearchHistoryService._internal();
  factory SearchHistoryService() => _instance;
  SearchHistoryService._internal();

  static const String _msdsKey = 'recent_msds_searches';
  static const String _tdsKey = 'recent_tds_searches';
  static const int _maxItems = 5;

  Future<void> addSearch(String query, String type) async {
    if (query.trim().isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final key = type == 'msds' ? _msdsKey : _tdsKey;

    List<String> searches = prefs.getStringList(key) ?? [];

    // Remove if already exists (to move to top)
    searches.removeWhere(
      (item) => item.toLowerCase() == query.toLowerCase().trim(),
    );

    // Add to top
    searches.insert(0, query.trim());

    // Keep only last N items
    if (searches.length > _maxItems) {
      searches = searches.sublist(0, _maxItems);
    }

    await prefs.setStringList(key, searches);
    notifyListeners();
  }

  Future<List<String>> getRecentSearches(String type) async {
    final prefs = await SharedPreferences.getInstance();
    final key = type == 'msds' ? _msdsKey : _tdsKey;
    return prefs.getStringList(key) ?? [];
  }

  Future<void> clearHistory(String type) async {
    final prefs = await SharedPreferences.getInstance();
    final key = type == 'msds' ? _msdsKey : _tdsKey;
    await prefs.remove(key);
    notifyListeners();
  }
}
