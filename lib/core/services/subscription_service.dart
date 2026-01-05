import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

class SubscriptionService {
  final _supabase = Supabase.instance.client;

  // Limits
  static const int maxDailyMsds = 5;
  static const int maxDailyAiMessages = 10;
  static const int maxCompanies = 1;

  Future<bool> isPlus() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return false;

      final profile = await _supabase
          .from('profiles')
          .select('is_plus')
          .eq('id', user.id)
          .maybeSingle();

      return profile?['is_plus'] ?? false;
    } catch (e) {
      debugPrint('Error checking isPlus: $e');
      return false;
    }
  }

  Future<bool> canGeneratePdf() async {
    return await isPlus();
  }

  Future<bool> canAddCompany(int currentCount) async {
    if (await isPlus()) return true;
    return currentCount < maxCompanies;
  }

  Future<bool> checkDailyMsdsLimit() async {
    if (await isPlus()) return true;

    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return false;

      final now = DateTime.now();
      final startOfDay = DateTime(
        now.year,
        now.month,
        now.day,
      ); // Local midnight
      final startOfDayUtc = startOfDay.toUtc().toIso8601String();

      final response = await _supabase
          .from('view_history')
          .select('id')
          .eq('user_id', user.id)
          .eq('type', 'msds')
          .gte('created_at', startOfDayUtc)
          .count(CountOption.exact);

      final count = response.count;
      debugPrint('Daily MSDS: $count / $maxDailyMsds');
      return count < maxDailyMsds;
    } catch (e) {
      debugPrint('Error checking MSDS limit: $e');
      return true; // Fail open if error
    }
  }

  Future<bool> checkDailyAiMessageLimit() async {
    if (await isPlus()) return true;

    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return false;

      final now = DateTime.now();
      final startOfDay = DateTime(
        now.year,
        now.month,
        now.day,
      ); // Local midnight
      final startOfDayUtc = startOfDay.toUtc().toIso8601String();

      // We check chat_messages table where role = 'user'
      final response = await _supabase
          .from('chat_messages')
          .select('id')
          .eq('user_id', user.id)
          .eq('role', 'user')
          .gte('created_at', startOfDayUtc)
          .count(CountOption.exact);

      final count = response.count;
      debugPrint('Daily AI Messages: $count / $maxDailyAiMessages');
      return count < maxDailyAiMessages;
    } catch (e) {
      debugPrint('Error checking AI message limit: $e');
      return true; // Fail open
    }
  }
}
