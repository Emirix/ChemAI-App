import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  FirebaseAnalyticsObserver get analyticsObserver =>
      FirebaseAnalyticsObserver(analytics: _analytics);

  Future<void> logEvent({
    required String name,
    Map<String, Object>? parameters,
  }) async {
    try {
      await _analytics.logEvent(
        name: name,
        parameters: parameters,
      );
      if (kDebugMode) {
        print('📊 Analytics Log: $name - $parameters');
      }
    } catch (e) {
      if (kDebugMode) {
        print('🚨 Analytics Error: $e');
      }
    }
  }

  Future<void> setUserInfo({
    String? id,
    String? email,
  }) async {
    try {
      if (id != null) await _analytics.setUserId(id: id);
      if (email != null) await _analytics.setUserProperty(name: 'email', value: email);
    } catch (e) {
       if (kDebugMode) {
        print('🚨 Analytics Set User Error: $e');
      }
    }
  }

  Future<void> logScreenView({required String screenName}) async {
    try {
      await _analytics.logScreenView(screenName: screenName);
    } catch (e) {
      if (kDebugMode) {
        print('🚨 Analytics Screen View Error: $e');
      }
    }
  }
}
