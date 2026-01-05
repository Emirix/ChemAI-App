import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  Future<String?> getUserId() async {
    await init();
    return _prefs?.getString('user_id');
  }

  Future<void> saveUserId(String userId) async {
    await init();
    await _prefs?.setString('user_id', userId);
  }

  Future<List?> getList(String key) async {
    await init();
    final jsonString = _prefs?.getString(key);
    if (jsonString == null) return null;
    return jsonDecode(jsonString) as List;
  }

  Future<void> saveList(String key, List data) async {
    await init();
    final jsonString = jsonEncode(data);
    await _prefs?.setString(key, jsonString);
  }

  Future<Map<String, dynamic>?> getMap(String key) async {
    await init();
    final jsonString = _prefs?.getString(key);
    if (jsonString == null) return null;
    return jsonDecode(jsonString) as Map<String, dynamic>;
  }

  Future<void> saveMap(String key, Map<String, dynamic> data) async {
    await init();
    final jsonString = jsonEncode(data);
    await _prefs?.setString(key, jsonString);
  }

  Future<String?> getString(String key) async {
    await init();
    return _prefs?.getString(key);
  }

  Future<void> saveString(String key, String value) async {
    await init();
    await _prefs?.setString(key, value);
  }

  Future<int?> getInt(String key) async {
    await init();
    return _prefs?.getInt(key);
  }

  Future<void> saveInt(String key, int value) async {
    await init();
    await _prefs?.setInt(key, value);
  }

  Future<bool?> getBool(String key) async {
    await init();
    return _prefs?.getBool(key);
  }

  Future<void> saveBool(String key, bool value) async {
    await init();
    await _prefs?.setBool(key, value);
  }

  Future<void> remove(String key) async {
    await init();
    await _prefs?.remove(key);
  }

  Future<void> clear() async {
    await init();
    await _prefs?.clear();
  }
}
